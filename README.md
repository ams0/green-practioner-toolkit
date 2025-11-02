# Green Practitioner Toolkit

> An open-source toolkit to measure and reduce the cost and carbon footprint of AI and Kubernetes workloads.

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)
[![CI](https://github.com/ams0/green-practioner-toolkit/actions/workflows/ci.yml/badge.svg)](https://github.com/ams0/green-practioner-toolkit/actions)

## 🌱 Quick Start

```bash
# Run the full demo
make demo

# Access Grafana at http://localhost:3000
# Username: admin, Password: prom-operator

# Query metrics with CLI
make cli-query
```

## 📦 What's Included

- **Kepler**: Energy monitoring at the container level
- **OpenCost**: Real-time Kubernetes cost tracking
- **OpenTelemetry Collector**: Metrics aggregation
- **Grafana**: Pre-configured dashboards for carbon & cost
- **CLI Tool**: Query Prometheus and calculate CO2e emissions
- **kind Demo**: Local Kubernetes cluster for testing

## 📚 Documentation

See the [full documentation](docs/README.md) for:
- Architecture overview
- Component details
- CLI usage
- Development guide
- Carbon intensity calculations

## 🚀 Features

✅ 100% open source - no proprietary dependencies  
✅ Easy local setup with kind  
✅ Real-time energy and cost monitoring  
✅ Carbon emissions calculations  
✅ Grafana dashboards included  
✅ Go CLI for querying metrics  
✅ GitHub Actions CI/CD  

## 🛠️ Prerequisites

- Docker
- kind (Kubernetes in Docker)
- kubectl
- Helm v3+
- Go 1.21+

## 📊 Example Output

```
Energy Metrics:
  Power Consumption: 12.45 Watts
  Energy (over 5m0s): 0.0104 kWh

Carbon Emissions:
  CO2e: 0.0049 kg (4.94 g)

Cost Metrics:
  Total Cost: $0.0125

Per-Request Metrics:
  CO2e per request: 0.003293 g
  Cost per request: $0.00000833
```

## 📝 License

Apache License 2.0 - see [LICENSE](LICENSE) for details.

## 🤝 Contributing

Contributions welcome! Please see our [contributing guidelines](docs/README.md#contributing).
