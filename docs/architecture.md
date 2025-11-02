# Architecture

## Overview

The Green Practitioner Toolkit (GPTK) is designed as a modular, cloud-native solution for measuring and optimizing the environmental and cost impact of AI and Kubernetes workloads.

## System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        Kubernetes Cluster                        │
│                                                                  │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │                      Workload Layer                         │ │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐    │ │
│  │  │ LLM Inference│  │  Batch Jobs  │  │  GPU Workload│    │ │
│  │  └──────────────┘  └──────────────┘  └──────────────┘    │ │
│  └────────────────────────────────────────────────────────────┘ │
│                            ▼                                     │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │                  Instrumentation Layer                      │ │
│  │                                                             │ │
│  │  ┌──────────────┐         ┌──────────────┐                │ │
│  │  │   Kepler     │         │  OpenCost    │                │ │
│  │  │  (Power &    │         │  (Cost       │                │ │
│  │  │   Energy)    │         │   Tracking)  │                │ │
│  │  └──────┬───────┘         └──────┬───────┘                │ │
│  └─────────┼────────────────────────┼────────────────────────┘ │
│            │                        │                           │
│            ▼                        ▼                           │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │            OpenTelemetry Collector                          │ │
│  │  ┌──────────┐  ┌───────────┐  ┌──────────┐               │ │
│  │  │Receivers │─▶│Processors │─▶│Exporters │               │ │
│  │  └──────────┘  └───────────┘  └──────────┘               │ │
│  └─────────────────────┬──────────────────────────────────────┘ │
│                        ▼                                         │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │                    Storage Layer                            │ │
│  │                ┌──────────────┐                             │ │
│  │                │  Prometheus  │                             │ │
│  │                │  (Metrics)   │                             │ │
│  │                └──────┬───────┘                             │ │
│  └───────────────────────┼─────────────────────────────────────┘ │
│                          ▼                                       │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │               Visualization Layer                           │ │
│  │                ┌──────────────┐                             │ │
│  │                │   Grafana    │                             │ │
│  │                │ (Dashboards) │                             │ │
│  │                └──────────────┘                             │ │
│  └────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
                           ▲
                           │ Query API
                           │
                  ┌────────┴────────┐
                  │   gptk CLI      │
                  │  (User Tool)    │
                  └─────────────────┘
```

## Components

### 1. Kepler (Kubernetes Efficient Power Level Exporter)

**Purpose**: Real-time power consumption monitoring

**Key Features**:
- eBPF-based power measurement
- Per-pod and per-container energy metrics
- CPU and DRAM power consumption tracking
- Model-based estimation for environments without hardware sensors

**Metrics Exposed**:
- `kepler_container_joules_total`: Total energy consumption per container
- `kepler_node_platform_joules_total`: Platform-level energy consumption
- `kepler_container_package_joules_total`: CPU package energy

**Integration**:
- Deploys as a DaemonSet on all nodes
- Exposes metrics via Prometheus endpoint (port 9102)
- Scraped by Prometheus for storage and querying

### 2. OpenCost

**Purpose**: Kubernetes cost allocation and monitoring

**Key Features**:
- Real-time cost monitoring for Kubernetes resources
- Multi-cloud cost support (AWS, GCP, Azure)
- Namespace and pod-level cost breakdown
- Historical cost data

**Metrics Exposed**:
- `opencost_allocation_cpu_cost`: CPU cost allocation
- `opencost_allocation_memory_cost`: Memory cost allocation
- `opencost_allocation_gpu_cost`: GPU cost (if available)

**Integration**:
- Deploys as a single pod in dedicated namespace
- Provides REST API and Prometheus metrics
- Connects to cloud provider APIs for accurate pricing

### 3. OpenTelemetry Collector

**Purpose**: Unified observability pipeline

**Key Features**:
- Collects metrics from multiple sources
- Enriches data with sustainability metadata
- Routes data to multiple backends
- Batch processing for efficiency

**Pipeline Configuration**:

```yaml
receivers:
  - otlp (traces and metrics from workloads)
  - prometheus (scrape Kepler and OpenCost)

processors:
  - attributes (add carbon and cost context)
  - batch (efficient data processing)
  - memory_limiter (resource control)

exporters:
  - prometheus (expose aggregated metrics)
  - prometheusremotewrite (send to Prometheus)
  - logging (debugging)
```

**Custom Attributes Added**:
- `carbon.source`: Origin of carbon data
- `cost.source`: Origin of cost data
- `workload.type`: Type of workload (inference, batch, etc.)

### 4. Prometheus

**Purpose**: Metrics storage and query engine

**Key Features**:
- Time-series database for all metrics
- PromQL query language
- 15-day retention (configurable)
- Service discovery for automatic scraping

**Data Sources**:
- Kepler metrics (power/energy)
- OpenCost metrics (cost)
- OTel Collector metrics (aggregated)
- Workload metrics (application-specific)

### 5. Grafana

**Purpose**: Visualization and dashboards

**Pre-configured Dashboards**:
1. **Carbon & Cost Overview**: High-level sustainability metrics
2. **Energy Efficiency**: Power vs utilization analysis
3. **Cost Analysis**: Detailed cost breakdown
4. **Workload Comparison**: Compare different workloads

**Data Sources**:
- Primary: Prometheus (all metrics)
- Secondary: OpenCost API (detailed cost data)

### 6. gptk CLI

**Purpose**: Command-line tool for querying and reporting

**Commands**:
- `gptk carbon`: Query carbon emissions
- `gptk cost`: Query cost metrics
- `gptk report`: Generate comprehensive reports

**Features**:
- Direct Prometheus queries
- OpenCost API integration
- Multiple output formats (JSON, YAML, Markdown)
- Batch processing support

## Data Flow

### 1. Metrics Collection

```
Workload → Kepler → Prometheus
        ↘ OpenCost ↗
```

1. Workloads run on Kubernetes nodes
2. Kepler measures power consumption via eBPF
3. OpenCost tracks resource allocation and costs
4. Both export metrics to Prometheus

### 2. Metrics Enrichment

```
Prometheus → OTel Collector → Prometheus
                 ↓
            (add metadata)
```

1. OTel Collector scrapes raw metrics
2. Adds sustainability and context metadata
3. Exports enriched metrics back to Prometheus

### 3. Visualization

```
Prometheus → Grafana → User
```

1. Grafana queries Prometheus
2. Renders dashboards with calculated metrics
3. Users view real-time sustainability data

### 4. CLI Queries

```
User → gptk CLI → Prometheus/OpenCost → Results
```

1. User runs gptk command
2. CLI queries relevant data sources
3. Processes and formats results
4. Displays or exports data

## Calculation Methods

### Carbon Emissions

Formula: `CO₂e (grams) = Energy (kWh) × Carbon Intensity (g/kWh)`

**Carbon Intensity Sources**:
- Global average: 475 g/kWh
- Cloud-provider-specific values (from API)
- Region-specific values (configurable)

### Cost per Inference

Formula: `Cost per Inference = Total Cost / Request Count`

### Energy per Request

Formula: `Energy per Request = Total Energy / Request Count`

## Deployment Architecture

### Namespaces

- `kepler-system`: Kepler DaemonSet and Prometheus
- `opencost`: OpenCost deployment
- `otel-system`: OpenTelemetry Collector
- `monitoring`: Grafana
- `demo-workloads`: Example workloads

### Network Topology

```
┌─────────────────────────────────────────┐
│            External Access              │
│                                         │
│  Port Forward: 3000 → Grafana          │
│  Port Forward: 9102 → Kepler           │
│  Port Forward: 9003 → OpenCost         │
└─────────────────────────────────────────┘
                    ▼
┌─────────────────────────────────────────┐
│         Kubernetes Services             │
│                                         │
│  grafana.monitoring.svc                │
│  kepler-exporter.kepler-system.svc     │
│  opencost.opencost.svc                 │
│  prometheus-server.kepler-system.svc   │
└─────────────────────────────────────────┘
```

## Scalability Considerations

### Horizontal Scaling
- Kepler: Scales with cluster nodes (DaemonSet)
- OpenCost: Single instance sufficient for most clusters
- OTel Collector: Can be scaled based on metric volume
- Prometheus: May need federation for large clusters

### Vertical Scaling
- Adjust resource limits in Helm values
- Monitor memory usage of Prometheus (largest consumer)
- OTel Collector memory limiter prevents OOM

### Performance Optimization
- Batch processing in OTel Collector
- Prometheus retention tuning
- Grafana query caching
- Efficient PromQL queries in dashboards

## Security Considerations

### Access Control
- RBAC for all components
- ServiceAccounts with minimal permissions
- NetworkPolicies (optional, not enabled by default)

### Data Privacy
- Metrics don't contain sensitive workload data
- No PII in exported metrics
- Cost data stays within cluster

### Secret Management
- Grafana admin password via Secret
- Cloud provider credentials via Secrets
- No plaintext credentials in configs

## Extensibility

### Adding Custom Metrics
1. Create custom ServiceMonitor
2. Add scrape config to OTel Collector
3. Create Grafana dashboard panel

### Multi-Cloud Support
1. Configure cloud provider credentials in OpenCost
2. Update carbon intensity values per region
3. Add cloud-specific dashboards

### Custom Workloads
1. Add Prometheus annotations to workload
2. Instrument with OTel SDK (optional)
3. View metrics in existing dashboards

## Future Enhancements

- [ ] Real-time optimization recommendations
- [ ] Integration with Carbon Aware SDK
- [ ] Multi-cluster support
- [ ] Historical trend analysis
- [ ] Cost forecasting
- [ ] Automated workload scheduling based on carbon intensity
- [ ] Web UI for non-CLI users
- [ ] Slack/Teams integration for alerts
