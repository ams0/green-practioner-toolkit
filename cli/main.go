package main

import (
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"os"
	"time"

	"github.com/spf13/cobra"
)

const (
	defaultPrometheusURL = "http://localhost:9090"
	// Carbon intensity factor (gCO2e/kWh) - global average
	carbonIntensityFactor = 475.0
)

type PrometheusResponse struct {
	Status string `json:"status"`
	Data   struct {
		ResultType string `json:"resultType"`
		Result     []struct {
			Metric map[string]string `json:"metric"`
			Value  []interface{}     `json:"value"`
		} `json:"result"`
	} `json:"data"`
}

func main() {
	rootCmd := &cobra.Command{
		Use:   "green-toolkit",
		Short: "Green Practitioner Toolkit - Measure carbon and cost of workloads",
		Long:  `A CLI tool to query Prometheus metrics and calculate CO2e emissions and cost per request for Kubernetes workloads.`,
	}

	queryCmd := &cobra.Command{
		Use:   "query",
		Short: "Query metrics and calculate carbon/cost",
		RunE:  runQuery,
	}

	queryCmd.Flags().String("prometheus-url", defaultPrometheusURL, "Prometheus server URL")
	queryCmd.Flags().String("namespace", "", "Filter by namespace")
	queryCmd.Flags().Duration("range", 5*time.Minute, "Time range for metrics")

	rootCmd.AddCommand(queryCmd)

	if err := rootCmd.Execute(); err != nil {
		fmt.Fprintf(os.Stderr, "Error: %v\n", err)
		os.Exit(1)
	}
}

func runQuery(cmd *cobra.Command, args []string) error {
	prometheusURL, _ := cmd.Flags().GetString("prometheus-url")
	namespace, _ := cmd.Flags().GetString("namespace")
	timeRange, _ := cmd.Flags().GetDuration("range")

	fmt.Println("Green Practitioner Toolkit - Metrics Query")
	fmt.Println("==========================================")
	fmt.Printf("Prometheus URL: %s\n", prometheusURL)
	fmt.Printf("Time Range: %s\n\n", timeRange)

	// Query energy metrics from Kepler
	energyQuery := "sum(rate(kepler_container_joules_total[5m]))"
	if namespace != "" {
		energyQuery = fmt.Sprintf(`sum(rate(kepler_container_joules_total{namespace="%s"}[5m]))`, namespace)
	}

	energyWatts, err := queryPrometheus(prometheusURL, energyQuery)
	if err != nil {
		fmt.Printf("Warning: Could not fetch energy metrics: %v\n", err)
		energyWatts = 0
	}

	// Query cost metrics from OpenCost
	costQuery := "sum(opencost_cpu_cost + opencost_memory_cost)"
	if namespace != "" {
		costQuery = fmt.Sprintf(`sum(opencost_cpu_cost{namespace="%s"} + opencost_memory_cost{namespace="%s"})`, namespace, namespace)
	}

	totalCost, err := queryPrometheus(prometheusURL, costQuery)
	if err != nil {
		fmt.Printf("Warning: Could not fetch cost metrics: %v\n", err)
		totalCost = 0
	}

	// Calculate carbon emissions
	// Convert Watts to kW, multiply by time range in hours, then by carbon intensity
	energyKWh := energyWatts * timeRange.Hours() / 1000.0
	carbonGrams := energyKWh * carbonIntensityFactor
	carbonKg := carbonGrams / 1000.0

	// Display results
	fmt.Println("Energy Metrics:")
	fmt.Printf("  Power Consumption: %.2f Watts\n", energyWatts)
	fmt.Printf("  Energy (over %s): %.4f kWh\n", timeRange, energyKWh)
	fmt.Println()

	fmt.Println("Carbon Emissions:")
	fmt.Printf("  CO2e: %.4f kg (%.2f g)\n", carbonKg, carbonGrams)
	fmt.Printf("  (Using global avg carbon intensity: %.0f gCO2e/kWh)\n", carbonIntensityFactor)
	fmt.Println()

	fmt.Println("Cost Metrics:")
	fmt.Printf("  Total Cost: $%.4f\n", totalCost)
	fmt.Println()

	// Query request count if available
	requestQuery := "sum(rate(http_requests_total[5m]))"
	if namespace != "" {
		requestQuery = fmt.Sprintf(`sum(rate(http_requests_total{namespace="%s"}[5m]))`, namespace)
	}

	requestsPerSec, err := queryPrometheus(prometheusURL, requestQuery)
	if err == nil && requestsPerSec > 0 {
		totalRequests := requestsPerSec * timeRange.Seconds()
		co2ePerRequest := (carbonGrams / totalRequests)
		costPerRequest := (totalCost / totalRequests)

		fmt.Println("Per-Request Metrics:")
		fmt.Printf("  Requests: %.0f (%.2f req/s)\n", totalRequests, requestsPerSec)
		fmt.Printf("  CO2e per request: %.6f g\n", co2ePerRequest)
		fmt.Printf("  Cost per request: $%.8f\n", costPerRequest)
	} else {
		fmt.Println("Per-Request Metrics: Not available (no request metrics found)")
	}

	return nil
}

func queryPrometheus(baseURL, query string) (float64, error) {
	url := fmt.Sprintf("%s/api/v1/query?query=%s", baseURL, query)

	client := &http.Client{Timeout: 10 * time.Second}
	resp, err := client.Get(url)
	if err != nil {
		return 0, fmt.Errorf("failed to query Prometheus: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(resp.Body)
		return 0, fmt.Errorf("Prometheus returned status %d: %s", resp.StatusCode, string(body))
	}

	var promResp PrometheusResponse
	if err := json.NewDecoder(resp.Body).Decode(&promResp); err != nil {
		return 0, fmt.Errorf("failed to decode response: %w", err)
	}

	if promResp.Status != "success" {
		return 0, fmt.Errorf("query failed: status=%s", promResp.Status)
	}

	if len(promResp.Data.Result) == 0 {
		return 0, fmt.Errorf("no data returned")
	}

	// Extract the value
	if len(promResp.Data.Result[0].Value) < 2 {
		return 0, fmt.Errorf("invalid value format")
	}

	valueStr, ok := promResp.Data.Result[0].Value[1].(string)
	if !ok {
		return 0, fmt.Errorf("value is not a string")
	}

	var value float64
	_, err = fmt.Sscanf(valueStr, "%f", &value)
	if err != nil {
		return 0, fmt.Errorf("failed to parse value: %w", err)
	}

	return value, nil
}
