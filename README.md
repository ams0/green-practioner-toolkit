# 🌱 Green Practitioner Toolkit (GPTK)

> A practical, developer-friendly toolkit for measuring, visualizing, and reducing the **cost + carbon impact of AI and Kubernetes workloads**.

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-1.28+-326CE5?logo=kubernetes)](https://kubernetes.io)
[![Go Version](https://img.shields.io/badge/Go-1.21+-00ADD8?logo=go)](https://golang.org)

## 🎯 Vision

The Green Practitioner Toolkit empowers Cloud Native and AI engineers to:
- 📊 **Measure** real-time power consumption and carbon emissions of Kubernetes workloads
- 💰 **Visualize** cost per inference, per token, or per job
- ♻️ **Optimize** GPU/CPU utilization vs energy draw
- 🔍 **Trace** sustainability metadata through OpenTelemetry pipelines

**100% open source. Vendor-neutral. No paid dependencies.**

## ✨ Features

- **Kubernetes Demo Environment**: Pre-configured kind cluster with all components
- **Power Monitoring**: Kepler for real-time power usage metrics
- **Cost Visibility**: OpenCost integration for resource cost tracking
- **Observability Pipeline**: OpenTelemetry Collector for instrumentation
- **Grafana Dashboards**: Pre-built visualizations for:
  - CO₂e per request/inference
  - $/token or $/job
  - GPU/CPU utilization vs energy consumption
- **CLI Tool**: `gptk` command-line tool to query metrics and generate reports
- **Example Workloads**: GPU and CPU demo workloads (LLM inference, batch jobs)

## 🚀 Quick Start

### Prerequisites

- [Docker](https://docs.docker.com/get-docker/) (20.10+)
- [kind](https://kind.sigs.k8s.io/) (0.20+) or [k3d](https://k3d.io/)
- [kubectl](https://kubernetes.io/docs/tasks/tools/) (1.28+)
- [Helm](https://helm.sh/docs/intro/install/) (3.12+)
- [Go](https://golang.org/doc/install) (1.21+) - for building the CLI

### One-Command Demo

```bash
make demo
```

This will:
1. Create a local Kubernetes cluster (kind)
2. Deploy Kepler, OpenCost, OpenTelemetry Collector, and Grafana
3. Deploy example AI/batch workloads
4. Configure Grafana dashboards
5. Print access URLs

### Access the Dashboard

```bash
# Forward Grafana port
kubectl port-forward -n monitoring svc/grafana 3000:3000

# Open in browser
open http://localhost:3000
# Default credentials: admin/admin
```

### Using the CLI

```bash
# Build the CLI
make build-cli

# Query carbon emissions
./bin/gptk carbon --namespace default --workload llm-inference

# Query costs
./bin/gptk cost --namespace default --workload llm-inference --interval 1h

# Generate report
./bin/gptk report --output report.json
```

## 📚 Documentation

- [Architecture Overview](docs/architecture.md)
- [Getting Started Guide](docs/getting-started.md)
- [How It Works](docs/how-it-works.md)
- [Contributing Guidelines](docs/contributing.md)

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Kubernetes Cluster                       │
│                                                              │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐ │
│  │   Kepler     │───▶│     OTel     │───▶│  Prometheus  │ │
│  │  (Power)     │    │  Collector   │    │              │ │
│  └──────────────┘    └──────────────┘    └──────┬───────┘ │
│                                                    │         │
│  ┌──────────────┐    ┌──────────────┐           │         │
│  │  OpenCost    │───▶│   Grafana    │◀──────────┘         │
│  │   (Cost)     │    │ (Dashboards) │                      │
│  └──────────────┘    └──────────────┘                      │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐  │
│  │         Example Workloads (LLM, Batch Jobs)          │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                              ▲
                              │
                    ┌─────────┴─────────┐
                    │   gptk CLI Tool   │
                    └───────────────────┘
```

## 🎨 Example Metrics

The toolkit provides out-of-the-box metrics like:

- `gptk_carbon_grams_per_inference` - Carbon emissions per AI inference
- `gptk_cost_per_1k_tokens` - Cost per 1,000 tokens processed
- `gptk_energy_joules_per_request` - Energy consumption per request
- `gptk_gpu_utilization_percent` - GPU utilization percentage
- `gptk_power_watts` - Real-time power consumption

## 🛠️ Makefile Commands

```bash
make help           # Show all available commands
make demo           # Run full demo environment
make clean          # Clean up demo environment
make build-cli      # Build gptk CLI
make install-deps   # Install required dependencies
make deploy-kepler  # Deploy only Kepler
make deploy-opencost # Deploy only OpenCost
make test           # Run tests
make lint           # Run linters
```

## 🔧 Modular Design

You can use components individually:

```bash
# Just Kepler + Prometheus
make deploy-kepler

# Just OpenCost
make deploy-opencost

# Just OTel Collector
make deploy-otel
```

## 🤝 Contributing

We welcome contributions! Please see [CONTRIBUTING.md](docs/contributing.md) for details.

## 📊 Example Dashboard

The toolkit includes pre-configured Grafana dashboards:

- **Carbon Impact Dashboard**: Real-time CO₂ emissions per workload
- **Cost Analysis Dashboard**: Cost breakdown by namespace/workload
- **Energy Efficiency Dashboard**: Power vs utilization correlation
- **AI Workload Dashboard**: Token/inference metrics with carbon footprint

## 🔗 Related Projects

- [Kepler](https://github.com/sustainable-computing-io/kepler) - Kubernetes-based Efficient Power Level Exporter
- [OpenCost](https://github.com/opencost/opencost) - Open source cost monitoring for Kubernetes
- [OpenTelemetry](https://opentelemetry.io/) - Observability framework
- [Grafana](https://grafana.com/) - Observability and monitoring platform

## 📜 License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.

## 🌍 Why This Matters

AI and cloud workloads have significant environmental impact. A single large language model training run can emit as much CO₂ as 5 cars over their lifetime. This toolkit helps engineers:

1. **Understand** the environmental cost of their infrastructure
2. **Identify** optimization opportunities
3. **Track** improvements over time
4. **Make informed decisions** about resource allocation

## 🚦 Roadmap

- [x] Core infrastructure scaffolding
- [ ] Complete Helm charts for all components
- [ ] Implement gptk CLI core functionality
- [ ] Create comprehensive Grafana dashboards
- [ ] Add GPU workload examples
- [ ] Add multi-cloud carbon coefficient support
- [ ] Integration with Carbon Aware SDK
- [ ] Real-time optimization recommendations
- [ ] Web UI for non-CLI users

## 💬 Community

- **Issues**: [GitHub Issues](https://github.com/ams0/green-practioner-toolkit/issues)
- **Discussions**: [GitHub Discussions](https://github.com/ams0/green-practioner-toolkit/discussions)

---

**Made with 💚 by the Cloud Native community**
