# How It Works

This document explains the technical details of how GPTK measures carbon emissions, tracks costs, and calculates sustainability metrics.

## Power Measurement with Kepler

### What is Kepler?

Kepler (Kubernetes Efficient Power Level Exporter) is a CNCF project that uses eBPF to measure the energy consumption of Kubernetes pods and containers.

### How Kepler Measures Power

Kepler uses multiple methods depending on the available hardware:

#### 1. Hardware-Based Measurement (RAPL)

On systems with Intel CPUs, Kepler uses **RAPL (Running Average Power Limit)** interfaces:

- `MSR (Model-Specific Registers)`: Direct CPU power readings
- `powercap`: Linux kernel interface to RAPL
- Provides real-time CPU and DRAM energy consumption

```
Hardware Counters → eBPF Program → Kepler → Prometheus
```

#### 2. Model-Based Estimation

On systems without hardware counters (VMs, some cloud instances), Kepler uses machine learning models:

- Collects performance metrics (CPU utilization, instructions, cache misses)
- Applies pre-trained power models
- Estimates energy based on workload characteristics

### Metrics Exposed by Kepler

```prometheus
# Total energy in joules (cumulative counter)
kepler_container_joules_total{container_name="my-app"}

# CPU package energy
kepler_container_package_joules_total{container_name="my-app"}

# DRAM energy
kepler_container_dram_joules_total{container_name="my-app"}

# GPU energy (if available)
kepler_container_gpu_joules_total{container_name="my-app"}
```

### Converting Energy to Power

Prometheus calculates instantaneous power using rate:

```promql
# Power in watts
rate(kepler_container_joules_total[5m])
```

### Accuracy Considerations

- **Hardware counters**: ±5% accuracy
- **Model-based**: ±15% accuracy
- **VM environments**: Lower accuracy due to hypervisor overhead
- **Calibration**: Models improve over time with training data

## Carbon Emission Calculation

### Formula

```
CO₂ Emissions (grams) = Energy (kWh) × Carbon Intensity (g/kWh)
```

### Step-by-Step Calculation

#### Step 1: Get Energy Consumption

Query Kepler for energy over a time period:

```promql
# Energy in joules over 1 hour
increase(kepler_container_joules_total{namespace="demo"}[1h])
```

#### Step 2: Convert Joules to kWh

```
kWh = Joules / 3,600,000
```

Example:
```
1,130,000 joules = 0.314 kWh
```

#### Step 3: Apply Carbon Intensity

Carbon intensity varies by:
- **Geographic region**: Clean vs. fossil fuel grids
- **Time of day**: Renewable availability
- **Cloud provider**: Data center energy mix

**Default Values**:
- Global average: 475 g CO₂/kWh
- US average: 386 g CO₂/kWh
- EU average: 275 g CO₂/kWh
- AWS us-east-1: 415 g CO₂/kWh (varies by region)
- Google Cloud Iowa: 394 g CO₂/kWh
- Azure West US: 230 g CO₂/kWh

Example:
```
0.314 kWh × 475 g/kWh = 149.15 grams CO₂
```

### Grafana Query Example

Complete query for CO₂ emissions:

```promql
# grams CO₂ per hour by namespace
sum by (namespace) (
  increase(kepler_container_joules_total[1h]) / 3600000
) * 475
```

### Per-Request CO₂ Calculation

To calculate emissions per inference/request:

```promql
# grams CO₂ per request
(
  sum(rate(kepler_container_joules_total{app="llm-inference"}[5m])) / 3600000 * 475
) / sum(rate(http_requests_total{app="llm-inference"}[5m]))
```

This divides total emissions by request rate to get per-request impact.

## Cost Tracking with OpenCost

### How OpenCost Works

OpenCost allocates infrastructure costs to Kubernetes resources based on:

1. **Resource Usage**: CPU, memory, storage, network
2. **Cloud Pricing**: Real-time pricing from cloud providers
3. **Shared Costs**: Node overhead, system pods

### Cost Components

#### 1. CPU Cost

```
CPU Cost = (CPU Requested / Node CPU) × Node Cost × Time
```

Example:
- Pod requests 2 CPUs
- Node has 8 CPUs at $0.096/hour
- Pod runs for 1 hour
- Cost: (2/8) × $0.096 × 1 = $0.024

#### 2. Memory Cost

```
Memory Cost = (Memory Requested / Node Memory) × Node Cost × Time
```

#### 3. GPU Cost

```
GPU Cost = (GPU Requested / Node GPUs) × GPU Node Cost × Time
```

#### 4. Storage Cost

```
Storage Cost = Storage GB × Cloud Storage Rate × Time
```

### Metrics Exposed by OpenCost

```prometheus
# CPU cost (hourly rate)
opencost_allocation_cpu_cost{namespace="demo",pod="app-1"}

# Memory cost (hourly rate)
opencost_allocation_memory_cost{namespace="demo",pod="app-1"}

# Total allocated cost
opencost_allocation_total_cost{namespace="demo"}
```

### Cost per Token/Inference

To calculate cost efficiency:

```promql
# $ per 1K tokens
(
  sum(opencost_allocation_cpu_cost{app="llm"} + opencost_allocation_memory_cost{app="llm"})
) / (sum(rate(tokens_processed_total{app="llm"}[1h])) * 3600) * 1000
```

### Cloud-Specific Pricing

OpenCost pulls pricing from:
- **AWS**: EC2 pricing API
- **GCP**: Cloud Billing API
- **Azure**: Retail Rates API
- **On-prem**: Custom pricing configuration

## OpenTelemetry Integration

### Distributed Tracing with Sustainability Context

OTel Collector enriches traces and metrics with sustainability data:

#### Trace Enrichment

```yaml
processors:
  attributes:
    actions:
      - key: carbon.grams_co2e
        value: <calculated from Kepler>
        action: insert
      - key: cost.usd
        value: <calculated from OpenCost>
        action: insert
      - key: energy.kwh
        value: <calculated from Kepler>
        action: insert
```

#### Example Enriched Span

```json
{
  "traceId": "abc123",
  "spanId": "def456",
  "operationName": "llm_inference",
  "duration": 1.5,
  "attributes": {
    "carbon.grams_co2e": 0.0023,
    "cost.usd": 0.00012,
    "energy.kwh": 0.0000048,
    "tokens.count": 150
  }
}
```

### Metric Aggregation Pipeline

```
Kepler Metrics → OTel Collector → Process/Enrich → Prometheus
OpenCost Metrics → OTel Collector → Process/Enrich → Prometheus
```

The collector:
1. Scrapes raw metrics from sources
2. Adds metadata (labels, attributes)
3. Batches for efficiency
4. Exports to Prometheus

### Sustainability Metrics

Custom metrics created by OTel:

```prometheus
# Carbon per inference
gptk_carbon_grams_per_inference{app="llm"}

# Cost per 1K tokens
gptk_cost_per_1k_tokens{app="llm"}

# Energy efficiency (inferences per kWh)
gptk_inferences_per_kwh{app="llm"}
```

## Dashboard Calculations

### Real-Time Power (Watts)

```promql
rate(kepler_container_joules_total[5m])
```

This calculates instantaneous power by taking the rate of energy increase.

### Cumulative CO₂ Today

```promql
sum(increase(kepler_container_joules_total[24h])) / 3600000 * 475
```

### Energy Efficiency Score

```promql
# Requests per kWh
sum(rate(http_requests_total[5m])) * 3600 / 
(sum(rate(kepler_container_joules_total[5m])) / 1000000)
```

Higher is better - more work done per unit energy.

### Cost Efficiency

```promql
# Cost per 1M requests
(sum(opencost_allocation_total_cost) / 
 sum(increase(http_requests_total[24h]))) * 1000000
```

### GPU Utilization vs Power

```promql
# GPU efficiency
(avg(gpu_utilization_percent) / 100) / 
(rate(kepler_container_gpu_joules_total[5m]) / 1000)
```

Shows how much work you get per watt of GPU power.

## Practical Examples

### Example 1: LLM Inference Sustainability

**Scenario**: A GPT-style model serving 10 requests/second

**Measurements**:
- Power consumption: 50W average
- Tokens per request: 150 (average)
- Running 24/7 in us-east-1

**Calculations**:

Energy per day:
```
50W × 24h = 1,200 Wh = 1.2 kWh
```

CO₂ per day (us-east-1, 415 g/kWh):
```
1.2 kWh × 415 g/kWh = 498 grams CO₂
```

CO₂ per inference:
```
498 g / (10 req/s × 86,400s) = 0.00058 grams/inference
```

CO₂ per 1M tokens:
```
0.00058 g/inference × 1,000,000 / 150 tokens = 3.86 grams/1M tokens
```

### Example 2: Batch Job Optimization

**Before Optimization**:
- Duration: 4 hours
- Power: 200W
- Cost: $0.48

**After Optimization** (better resource sizing):
- Duration: 2 hours
- Power: 150W
- Cost: $0.30

**Savings**:
- Time: 50% faster
- Energy: 400Wh → 300Wh (25% reduction)
- CO₂: 190g → 142.5g (25% reduction)
- Cost: $0.18 saved (37.5% reduction)

### Example 3: GPU Workload

**Scenario**: Training job on 4× A100 GPUs

**Measurements**:
- Power per GPU: 250W
- Total power: 1,000W
- Duration: 8 hours

**Calculations**:

Total energy:
```
1,000W × 8h = 8,000 Wh = 8 kWh
```

CO₂ (assuming 300 g/kWh for green data center):
```
8 kWh × 300 g/kWh = 2,400 grams = 2.4 kg CO₂
```

Cost (at $3/hour for 4× A100):
```
$3/hour × 8 hours = $24
```

## Limitations and Accuracy

### Kepler Limitations

- **VM overhead**: Harder to measure in virtualized environments
- **GPU accuracy**: Varies by hardware support
- **Network/storage**: Not measured by default
- **Cooling**: Indirect power usage not included (PUE factor)

### OpenCost Limitations

- **Spot instances**: Price fluctuation
- **Reserved instances**: Requires configuration
- **Egress costs**: May not be fully captured
- **Licensing**: Software licenses not included

### Carbon Intensity

- **Temporal variation**: Grid mix changes hourly
- **Marginal vs. average**: Different calculation methods
- **Upstream emissions**: Manufacturing not included
- **Cooling/PUE**: Data center overhead varies

## Improving Accuracy

### For Power Measurement

1. **Enable RAPL**: Ensure nodes support hardware counters
2. **Calibrate models**: Provide training data for your workloads
3. **Add PUE factor**: Multiply by data center PUE (typically 1.2-1.5)

### For Carbon Calculation

1. **Use regional data**: Configure carbon intensity per region
2. **Real-time grid data**: Integrate with electricity maps API
3. **Consider time-shifting**: Schedule in low-carbon hours

### For Cost Tracking

1. **Configure cloud credentials**: Enable real-time pricing
2. **Add custom rates**: For reserved instances or on-prem
3. **Include egress**: Add network cost configuration

## Further Reading

- [Kepler Documentation](https://sustainable-computing.io/)
- [OpenCost Documentation](https://www.opencost.io/docs/)
- [OpenTelemetry Documentation](https://opentelemetry.io/docs/)
- [Green Software Foundation](https://greensoftware.foundation/)
- [Carbon Aware SDK](https://github.com/Green-Software-Foundation/carbon-aware-sdk)
