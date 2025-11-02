package main

import (
	"fmt"
	"os"

	"github.com/ams0/green-practioner-toolkit/pkg/carbon"
	"github.com/ams0/green-practioner-toolkit/pkg/cost"
	"github.com/spf13/cobra"
)

var (
	version = "0.1.0"
)

func main() {
	rootCmd := &cobra.Command{
		Use:   "gptk",
		Short: "Green Practitioner Toolkit - Measure carbon and cost impact of AI/K8s workloads",
		Long: `GPTK (Green Practitioner ToolKit) helps you measure, visualize, and reduce
the cost and carbon impact of AI and Kubernetes workloads.

It queries Prometheus, OpenCost, and Kepler to provide insights on:
- Carbon emissions (grams CO₂e) per inference/job
- Cost (€/$) per 1K tokens or per job
- Energy efficiency metrics`,
		Version: version,
	}

	// Carbon command
	carbonCmd := &cobra.Command{
		Use:   "carbon",
		Short: "Query carbon emissions metrics",
		Long:  "Query carbon emissions data for workloads using Kepler metrics",
		RunE:  runCarbonCommand,
	}
	carbonCmd.Flags().StringP("namespace", "n", "default", "Kubernetes namespace to query")
	carbonCmd.Flags().StringP("workload", "w", "", "Workload name to query")
	carbonCmd.Flags().StringP("prometheus-url", "p", "http://localhost:9090", "Prometheus URL")
	carbonCmd.Flags().StringP("interval", "i", "1h", "Time interval to query (e.g., 1h, 24h)")

	// Cost command
	costCmd := &cobra.Command{
		Use:   "cost",
		Short: "Query cost metrics",
		Long:  "Query cost data for workloads using OpenCost metrics",
		RunE:  runCostCommand,
	}
	costCmd.Flags().StringP("namespace", "n", "default", "Kubernetes namespace to query")
	costCmd.Flags().StringP("workload", "w", "", "Workload name to query")
	costCmd.Flags().StringP("opencost-url", "o", "http://localhost:9003", "OpenCost URL")
	costCmd.Flags().StringP("interval", "i", "1h", "Time interval to query (e.g., 1h, 24h)")

	// Report command
	reportCmd := &cobra.Command{
		Use:   "report",
		Short: "Generate comprehensive sustainability report",
		Long:  "Generate a report combining carbon, cost, and efficiency metrics",
		RunE:  runReportCommand,
	}
	reportCmd.Flags().StringP("output", "o", "report.json", "Output file path")
	reportCmd.Flags().StringP("format", "f", "json", "Output format (json, yaml, markdown)")
	reportCmd.Flags().StringP("namespace", "n", "default", "Kubernetes namespace to query")
	reportCmd.Flags().StringP("prometheus-url", "p", "http://localhost:9090", "Prometheus URL")
	reportCmd.Flags().StringP("opencost-url", "c", "http://localhost:9003", "OpenCost URL")

	rootCmd.AddCommand(carbonCmd)
	rootCmd.AddCommand(costCmd)
	rootCmd.AddCommand(reportCmd)

	if err := rootCmd.Execute(); err != nil {
		fmt.Fprintf(os.Stderr, "Error: %v\n", err)
		os.Exit(1)
	}
}

func runCarbonCommand(cmd *cobra.Command, args []string) error {
	namespace, _ := cmd.Flags().GetString("namespace")
	workload, _ := cmd.Flags().GetString("workload")
	prometheusURL, _ := cmd.Flags().GetString("prometheus-url")
	interval, _ := cmd.Flags().GetString("interval")

	fmt.Printf("🌱 Querying carbon emissions...\n")
	fmt.Printf("   Namespace: %s\n", namespace)
	fmt.Printf("   Workload: %s\n", workload)
	fmt.Printf("   Interval: %s\n", interval)
	fmt.Printf("   Prometheus: %s\n\n", prometheusURL)

	metrics, err := carbon.QueryCarbonMetrics(prometheusURL, namespace, workload, interval)
	if err != nil {
		return fmt.Errorf("failed to query carbon metrics: %w", err)
	}

	fmt.Printf("📊 Results:\n")
	fmt.Printf("   Total CO₂e: %.2f grams\n", metrics.TotalCO2Grams)
	fmt.Printf("   Per inference: %.4f grams\n", metrics.PerInference)
	fmt.Printf("   Energy consumed: %.2f kWh\n", metrics.EnergyKWh)
	fmt.Printf("   Measurement period: %s\n", interval)

	return nil
}

func runCostCommand(cmd *cobra.Command, args []string) error {
	namespace, _ := cmd.Flags().GetString("namespace")
	workload, _ := cmd.Flags().GetString("workload")
	opencostURL, _ := cmd.Flags().GetString("opencost-url")
	interval, _ := cmd.Flags().GetString("interval")

	fmt.Printf("💰 Querying cost metrics...\n")
	fmt.Printf("   Namespace: %s\n", namespace)
	fmt.Printf("   Workload: %s\n", workload)
	fmt.Printf("   Interval: %s\n", interval)
	fmt.Printf("   OpenCost: %s\n\n", opencostURL)

	metrics, err := cost.QueryCostMetrics(opencostURL, namespace, workload, interval)
	if err != nil {
		return fmt.Errorf("failed to query cost metrics: %w", err)
	}

	fmt.Printf("📊 Results:\n")
	fmt.Printf("   Total cost: $%.4f\n", metrics.TotalCost)
	fmt.Printf("   CPU cost: $%.4f\n", metrics.CPUCost)
	fmt.Printf("   Memory cost: $%.4f\n", metrics.MemoryCost)
	fmt.Printf("   Per 1K tokens: $%.6f\n", metrics.Per1KTokens)
	fmt.Printf("   Measurement period: %s\n", interval)

	return nil
}

func runReportCommand(cmd *cobra.Command, args []string) error {
	output, _ := cmd.Flags().GetString("output")
	format, _ := cmd.Flags().GetString("format")
	namespace, _ := cmd.Flags().GetString("namespace")

	fmt.Printf("📋 Generating sustainability report...\n")
	fmt.Printf("   Namespace: %s\n", namespace)
	fmt.Printf("   Format: %s\n", format)
	fmt.Printf("   Output: %s\n\n", output)

	// TODO: Implement comprehensive report generation
	fmt.Printf("⚠️  Report generation not yet implemented\n")
	fmt.Printf("   This will combine carbon, cost, and efficiency metrics\n")
	fmt.Printf("   into a comprehensive sustainability report.\n")

	return nil
}
