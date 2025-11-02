# Green Practitioner Toolkit

An open-source toolkit to measure and reduce the cost and carbon footprint of AI and Kubernetes workloads.

## Overview

The Green Practitioner Toolkit provides:

- **Energy Monitoring**: Using Kepler to track power consumption at the container level
- **Cost Tracking**: Using OpenCost to monitor resource costs
- **Observability**: OpenTelemetry Collector for metrics aggregation
- **Visualization**: Grafana dashboards for carbon and cost insights
- **CLI Tool**: Query Prometheus and calculate CO2e emissions and cost per request
- **Demo Environment**: Local kind cluster with all components pre-configured

## Features

- ✅ No proprietary dependencies - 100% open source
- ✅ Easy local setup with kind
- ✅ Helm and Kustomize deployments
- ✅ Real-time energy and cost monitoring
- ✅ Carbon emissions calculations
- ✅ Sample workload included
- ✅ CI/CD with GitHub Actions

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/)
- [kind](https://kind.sigs.k8s.io/docs/user/quick-start/#installation) (Kubernetes in Docker)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- [Helm](https://helm.sh/docs/intro/install/) (v3+)
- [Go](https://golang.org/doc/install) (1.21+)

## Quick Start

### 1. Full Demo Setup

Run the complete demo environment with a single command:

```bash
make demo
```

This will:
1. Create a kind cluster
2. Deploy Prometheus with monitoring stack
3. Deploy Kepler for energy monitoring
4. Deploy OpenCost for cost tracking
5. Deploy OpenTelemetry Collector
6. Deploy Grafana with custom dashboards
7. Deploy a sample workload

### 2. Access the Dashboard

Once deployed, access:
- **Grafana**: http://localhost:3000 (username: `admin`, password: `prom-operator`)
- **Prometheus**: http://localhost:9090

### 3. Query Metrics with CLI

Build and run the CLI tool:

```bash
make cli-query
```

Or manually:

```bash
cd cli
go build -o green-toolkit .
./green-toolkit query
```

Example output:
```
Green Practitioner Toolkit - Metrics Query
==========================================
Prometheus URL: http://localhost:9090
Time Range: 5m0s

Energy Metrics:
  Power Consumption: 12.45 Watts
  Energy (over 5m0s): 0.0104 kWh

Carbon Emissions:
  CO2e: 0.0049 kg (4.94 g)
  (Using global avg carbon intensity: 475 gCO2e/kWh)

Cost Metrics:
  Total Cost: $0.0125

Per-Request Metrics:
  Requests: 1500 (5.00 req/s)
  CO2e per request: 0.003293 g
  Cost per request: $0.00000833
```

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                         kind Cluster                         │
│                                                              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │   Kepler     │  │  OpenCost    │  │ OTel Collector│     │
│  │  (Energy)    │  │   (Cost)     │  │  (Metrics)    │     │
│  └──────┬───────┘  └──────┬───────┘  └──────┬────────┘     │
│         │                  │                  │              │
│         └──────────────────┴──────────────────┘              │
│                            │                                 │
│                     ┌──────▼───────┐                        │
│                     │  Prometheus  │◄───┐                   │
│                     └──────┬───────┘    │                   │
│                            │             │                   │
│                     ┌──────▼───────┐    │                   │
│                     │   Grafana    │    │                   │
│                     └──────────────┘    │                   │
│                                          │                   │
│  ┌──────────────────────────────────────┘                   │
│  │  Sample Workload (nginx)                                 │
│  └──────────────────────────────────────────────────────────│
└─────────────────────────────────────────────────────────────┘
                            ▲
                            │
                   ┌────────┴────────┐
                   │  CLI Tool (Go)  │
                   │  - Query metrics │
                   │  - Calculate CO2e│
                   │  - Report costs  │
                   └─────────────────┘
```

## Components

### Kepler (Kubernetes Efficient Power Level Exporter)

Kepler uses eBPF to probe energy-related system stats and exports as Prometheus metrics. It provides:
- Container-level power consumption
- Node-level energy metrics
- CPU, memory, and GPU power usage

### OpenCost

OpenCost provides real-time cost monitoring for Kubernetes:
- CPU and memory costs
- Storage costs
- Network egress costs
- Multi-cloud support

### OpenTelemetry Collector

The OTel Collector receives, processes, and exports telemetry data:
- OTLP receiver for traces and metrics
- Prometheus exporter for metrics
- Batch processing for efficiency

### Grafana Dashboards

Pre-configured dashboards showing:
- Total power consumption over time
- Cost per namespace
- Energy consumption by pod
- Carbon emissions trends

## CLI Tool

The `green-toolkit` CLI queries Prometheus and calculates:
- Real-time power consumption
- Energy usage over time
- CO2e emissions (using configurable carbon intensity)
- Cost metrics
- Per-request carbon and cost metrics

### CLI Usage

```bash
# Query all metrics
./cli/green-toolkit query

# Query specific namespace
./cli/green-toolkit query --namespace=sample-workload

# Query with custom time range
./cli/green-toolkit query --range=10m

# Query custom Prometheus URL
./cli/green-toolkit query --prometheus-url=http://prometheus.example.com:9090
```

## Makefile Commands

```bash
make help              # Show all available commands
make deps              # Check dependencies
make cluster-create    # Create kind cluster
make cluster-delete    # Delete kind cluster
make deploy-all        # Deploy all components
make demo              # Full demo setup
make cli-build         # Build CLI tool
make cli-query         # Query metrics
make lint              # Run linters
make test              # Run tests
make clean             # Clean up everything
```

## Development

### Project Structure

```
.
├── cli/                    # Go CLI tool
│   ├── main.go
│   ├── main_test.go
│   └── go.mod
├── deploy/                 # Kubernetes manifests
│   ├── kind/              # kind cluster config
│   ├── kepler/            # Kepler deployment
│   ├── opencost/          # OpenCost deployment
│   ├── otel-collector/    # OTel Collector
│   ├── grafana/           # Grafana dashboards
│   └── sample-workload/   # Sample nginx deployment
├── docs/                   # Documentation
├── Makefile               # Build and deployment tasks
└── README.md              # This file
```

### Running Locally

1. Start the demo environment:
   ```bash
   make demo
   ```

2. Wait for all pods to be ready:
   ```bash
   kubectl get pods -A
   ```

3. Access Grafana at http://localhost:3000

4. Run queries with the CLI:
   ```bash
   make cli-query
   ```

### Testing

Run tests:
```bash
make test
```

Run linters:
```bash
make lint
```

## Carbon Intensity

The CLI uses a default global average carbon intensity of **475 gCO2e/kWh**. You can modify this in the CLI source code or use region-specific values:

- **US Average**: 386 gCO2e/kWh
- **EU Average**: 255 gCO2e/kWh
- **Renewable Energy**: 0-50 gCO2e/kWh

For region-specific data, see:
- [Electricity Maps](https://app.electricitymaps.com/)
- [Carbon Intensity API](https://carbonintensity.org.uk/)

## Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Run linters and tests
6. Submit a pull request

## License

This project is licensed under the Apache License 2.0. See [LICENSE](LICENSE) for details.

## Resources

- [Kepler Project](https://sustainable-computing.io/)
- [OpenCost](https://www.opencost.io/)
- [OpenTelemetry](https://opentelemetry.io/)
- [CNCF Environmental Sustainability TAG](https://tag-env-sustainability.cncf.io/)
- [Green Software Foundation](https://greensoftware.foundation/)

## Acknowledgments

This toolkit builds on the excellent work of:
- The Kepler team at the Sustainable Computing community
- The OpenCost and Kubecost teams
- The CNCF Environmental Sustainability TAG
- The OpenTelemetry community
