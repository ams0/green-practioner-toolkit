# Architecture

## System Overview

The Green Practitioner Toolkit is designed as a modular system for measuring and reducing the environmental and cost impact of Kubernetes workloads.

## Components

### 1. Kepler (Kubernetes Efficient Power Level Exporter)

**Purpose**: Measure power consumption at the container level

**Technology**: 
- Uses eBPF (Extended Berkeley Packet Filter) to probe kernel stats
- Exports metrics in Prometheus format
- Runs as a DaemonSet on every node

**Metrics Exposed**:
- `kepler_container_joules_total`: Total energy consumed by container
- `kepler_node_package_joules_total`: CPU package energy
- `kepler_node_dram_joules_total`: Memory energy
- `kepler_node_other_joules_total`: Other components energy

**Configuration**:
- Requires privileged access to read hardware counters
- Mounts `/sys` and `/lib/modules` for energy metrics
- Uses RAPL (Running Average Power Limit) or estimated models

### 2. OpenCost

**Purpose**: Track and allocate Kubernetes costs

**Features**:
- Real-time cost allocation
- Multi-cloud pricing support
- Pod-level, namespace-level, and cluster-level costs
- Integrates with Prometheus for metrics

**Metrics Exposed**:
- `opencost_cpu_cost`: CPU cost by resource
- `opencost_memory_cost`: Memory cost by resource
- `opencost_storage_cost`: Storage cost
- `opencost_network_cost`: Network egress cost

**Configuration**:
- Connects to Prometheus for resource utilization
- Uses cloud provider pricing APIs
- Supports custom pricing models

### 3. OpenTelemetry Collector

**Purpose**: Centralized telemetry data collection and export

**Receivers**:
- OTLP (gRPC and HTTP)
- Prometheus scraper

**Processors**:
- Batch processing for efficiency
- Memory limiting to prevent OOM
- Attribute manipulation

**Exporters**:
- Prometheus for metrics
- Logging for debugging

**Use Cases**:
- Collect application traces
- Aggregate metrics from multiple sources
- Export to various backends

### 4. Prometheus

**Purpose**: Time-series database and monitoring system

**Features**:
- Scrapes metrics from all components
- ServiceMonitor CRDs for auto-discovery
- PromQL for querying
- Alert management

**Integration Points**:
- Scrapes Kepler for energy metrics
- Scrapes OpenCost for cost metrics
- Scrapes OTel Collector for application metrics
- Provides data source for Grafana

### 5. Grafana

**Purpose**: Visualization and dashboards

**Dashboards Included**:
- Carbon & Cost Overview
- Energy consumption by pod
- Cost breakdown by namespace
- Time-series trends

**Features**:
- Pre-configured Prometheus data source
- Custom dashboard for sustainability metrics
- Alert visualization
- Query builder for ad-hoc analysis

### 6. CLI Tool

**Purpose**: Command-line interface for querying metrics

**Implementation**: Go
**Dependencies**: 
- Cobra (CLI framework)
- Standard library HTTP client

**Features**:
- Query Prometheus directly
- Calculate CO2e from energy metrics
- Display cost per request
- Support for namespace filtering
- Configurable time ranges

**Calculation Methods**:
1. Query energy from Kepler: `rate(kepler_container_joules_total[5m])`
2. Convert to kWh: `(Watts * hours) / 1000`
3. Calculate CO2e: `kWh * carbon_intensity_factor`
4. Query costs from OpenCost
5. Calculate per-request metrics if available

## Data Flow

```
┌─────────────┐
│  Container  │
└──────┬──────┘
       │ Energy consumption
       ▼
┌─────────────┐     Prometheus      ┌─────────────┐
│   Kepler    │────────────────────>│ Prometheus  │
└─────────────┘     metrics         └──────┬──────┘
                                           │
┌─────────────┐                            │
│  OpenCost   │────────────────────────────┤
└─────────────┘                            │
                                           │
┌─────────────┐                            │
│ OTel Coll.  │────────────────────────────┤
└─────────────┘                            │
                                           │
                         ┌─────────────────┴──────┬──────────────┐
                         ▼                        ▼              ▼
                  ┌─────────────┐         ┌─────────────┐  ┌─────────┐
                  │  Grafana    │         │  CLI Tool   │  │  Alerts │
                  └─────────────┘         └─────────────┘  └─────────┘
```

## Deployment Model

### Local Development (kind)
- Single control-plane node
- Two worker nodes
- Port forwarding for external access
- Suitable for testing and development

### Production Considerations
- Multi-node clusters
- High availability for monitoring stack
- Persistent storage for metrics
- Security hardening (RBAC, NetworkPolicies)
- Resource limits and requests
- Alert routing and notification

## Security Model

### RBAC
- ServiceAccounts for each component
- ClusterRoles with minimal permissions
- ClusterRoleBindings scoped appropriately

### Network
- ClusterIP services by default
- NodePort only for external access (demo)
- Consider NetworkPolicies in production

### Secrets
- No credentials stored in manifests
- Use Kubernetes secrets for sensitive data
- Consider external secret management

## Scaling Considerations

### Metrics Volume
- Kepler: ~50 metrics per container
- OpenCost: ~20 metrics per pod
- OTel: Variable based on application

### Storage
- Prometheus retention: Default 15 days
- Consider long-term storage (Thanos, Cortex)
- Grafana dashboards stored in ConfigMaps

### Performance
- Kepler overhead: <1% CPU per node
- OpenCost: Minimal overhead
- OTel: Configure batch sizes appropriately

## Extensibility

### Adding Custom Metrics
1. Create ServiceMonitor for auto-discovery
2. Add Prometheus scrape config
3. Create Grafana dashboard
4. Update CLI queries if needed

### Adding New Exporters
1. Deploy exporter to cluster
2. Create Service and ServiceMonitor
3. Verify metrics in Prometheus
4. Create visualizations

### Custom Carbon Intensity
- Update CLI source code
- Use region-specific APIs
- Implement dynamic lookup

## Alternatives Considered

### Energy Monitoring
- **Scaphandre**: Rust-based, similar to Kepler
- **PowerAPI**: Framework for power monitoring
- **Chosen**: Kepler for eBPF integration and CNCF alignment

### Cost Tracking
- **Kubecost**: Commercial offering with free tier
- **Cloud provider tools**: Vendor-specific
- **Chosen**: OpenCost for open-source and multi-cloud

### Observability
- **Grafana Agent**: Lightweight alternative
- **Telegraf**: General-purpose agent
- **Chosen**: OTel Collector for standardization

## References

- [Kepler Documentation](https://sustainable-computing.io/)
- [OpenCost Documentation](https://www.opencost.io/docs/)
- [OpenTelemetry Documentation](https://opentelemetry.io/docs/)
- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)
