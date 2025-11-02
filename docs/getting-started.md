# Getting Started with GPTK

This guide will walk you through setting up and running the Green Practitioner Toolkit.

## Prerequisites

Before you begin, ensure you have the following tools installed:

- **Docker** (20.10+): [Installation Guide](https://docs.docker.com/get-docker/)
- **kind** (0.20+): [Installation Guide](https://kind.sigs.k8s.io/docs/user/quick-start/#installation)
- **kubectl** (1.28+): [Installation Guide](https://kubernetes.io/docs/tasks/tools/)
- **Helm** (3.12+): [Installation Guide](https://helm.sh/docs/intro/install/)
- **Go** (1.21+): [Installation Guide](https://golang.org/doc/install) - Only needed for building the CLI

### Quick Installation

On Linux/macOS, you can install dependencies using:

```bash
make install-deps
```

Or manually:

```bash
# Install kind
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-$(uname)-amd64
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind

# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/$(uname | tr '[:upper:]' '[:lower:]')/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/

# Install helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

## Quick Start (5 minutes)

The fastest way to get started is using the one-command demo:

```bash
make demo
```

This command will:
1. ✅ Create a local Kubernetes cluster using kind
2. ✅ Deploy Kepler for power monitoring
3. ✅ Deploy OpenCost for cost tracking
4. ✅ Deploy OpenTelemetry Collector
5. ✅ Deploy Grafana with pre-configured dashboards
6. ✅ Deploy example AI/batch workloads
7. ✅ Configure all integrations

**Time required**: ~3-5 minutes depending on your internet connection.

## Step-by-Step Setup

If you prefer a step-by-step approach:

### Step 1: Create the Kubernetes Cluster

```bash
make create-cluster
```

Verify the cluster is running:

```bash
kubectl cluster-info
kubectl get nodes
```

You should see a control-plane and 2 worker nodes.

### Step 2: Deploy Monitoring Stack

Deploy Kepler for power monitoring:

```bash
make deploy-kepler
```

Deploy OpenCost for cost visibility:

```bash
make deploy-opencost
```

Deploy OpenTelemetry Collector:

```bash
make deploy-otel
```

Deploy Grafana with dashboards:

```bash
make deploy-grafana
```

### Step 3: Deploy Demo Workloads

```bash
make deploy-workload
```

This deploys:
- LLM inference simulator (2 replicas)
- Batch job processor (1 replica)

### Step 4: Verify Deployment

Check that all components are running:

```bash
make status
```

You should see pods in the following namespaces:
- `kepler-system`: Kepler DaemonSet and Prometheus
- `opencost`: OpenCost deployment
- `otel-system`: OTel Collector
- `monitoring`: Grafana
- `demo-workloads`: Demo workloads

## Accessing the Dashboard

### Option 1: Using Make

```bash
make port-forward-grafana
```

Then open your browser to: `http://localhost:3000`

### Option 2: Manual Port Forward

```bash
kubectl port-forward -n monitoring svc/grafana 3000:3000
```

Then open your browser to: `http://localhost:3000`

### Login Credentials

- **Username**: `admin`
- **Password**: Get it by running:
  ```bash
  make get-grafana-password
  ```

## Exploring the Dashboards

Once logged in to Grafana:

1. Navigate to **Dashboards** → **Browse**
2. Look for the **GPTK** folder
3. Open **"GPTK - Carbon & Cost Overview"**

You should see:
- Real-time power consumption graphs
- CO₂ emissions calculations
- Cost breakdown by workload
- Energy efficiency metrics

**Note**: It may take 2-3 minutes for metrics to start appearing after deployment.

## Building the CLI

Build the `gptk` command-line tool:

```bash
make build-cli
```

This creates the binary at `./bin/gptk`.

### Using the CLI

Check CLI version:

```bash
./bin/gptk version
```

Query carbon metrics:

```bash
# First, port-forward Prometheus
kubectl port-forward -n kepler-system svc/prometheus-server 9090:80 &

# Query carbon data
./bin/gptk carbon \
  --namespace demo-workloads \
  --workload llm-inference \
  --prometheus-url http://localhost:9090 \
  --interval 1h
```

Query cost metrics:

```bash
# First, port-forward OpenCost
kubectl port-forward -n opencost svc/opencost 9003:9003 &

# Query cost data
./bin/gptk cost \
  --namespace demo-workloads \
  --workload llm-inference \
  --opencost-url http://localhost:9003 \
  --interval 1h
```

Generate a report:

```bash
./bin/gptk report \
  --namespace demo-workloads \
  --output report.json \
  --format json
```

## Exploring Metrics Manually

### Kepler Metrics

Port-forward Kepler:

```bash
kubectl port-forward -n kepler-system svc/kepler-exporter 9102:9102
```

View raw metrics:

```bash
curl http://localhost:9102/metrics | grep kepler_container
```

### OpenCost Metrics

Port-forward OpenCost:

```bash
kubectl port-forward -n opencost svc/opencost 9003:9003
```

View cost allocation:

```bash
curl http://localhost:9003/allocation/compute?window=1h
```

### Prometheus Queries

Port-forward Prometheus:

```bash
kubectl port-forward -n kepler-system svc/prometheus-server 9090:80
```

Open Prometheus UI: `http://localhost:9090`

Example queries:

```promql
# Total power consumption by namespace
sum by (namespace) (rate(kepler_container_joules_total[5m]))

# Cost per pod
sum by (pod) (opencost_allocation_cpu_cost + opencost_allocation_memory_cost)

# CO₂ per hour (approximate)
sum(increase(kepler_container_joules_total[1h])) * 0.0004 / 3600
```

## Viewing Logs

View logs from all components:

```bash
make logs
```

Or view specific component logs:

```bash
# Kepler logs
kubectl logs -n kepler-system -l app.kubernetes.io/name=kepler --tail=50

# OpenCost logs
kubectl logs -n opencost -l app.kubernetes.io/name=opencost --tail=50

# OTel Collector logs
kubectl logs -n otel-system -l app.kubernetes.io/name=opentelemetry-collector --tail=50

# Grafana logs
kubectl logs -n monitoring -l app.kubernetes.io/name=grafana --tail=50
```

## Customizing the Setup

### Adjusting Resource Limits

Edit the Helm values files in `deploy/helm/*/values.yaml` and redeploy:

```bash
# Edit values
vim deploy/helm/kepler/values.yaml

# Redeploy
make deploy-kepler
```

### Adding Your Own Workloads

To monitor your own workloads:

1. Add Prometheus annotations to your pods:

```yaml
annotations:
  prometheus.io/scrape: "true"
  prometheus.io/port: "8080"
```

2. Label your workloads:

```yaml
labels:
  workload-type: "your-type"
```

3. Metrics will automatically be collected by Kepler and OpenCost

### Creating Custom Dashboards

1. Access Grafana at `http://localhost:3000`
2. Click **+ Create** → **Dashboard**
3. Add panels with PromQL queries
4. Save your dashboard to the GPTK folder

## Troubleshooting

### Pods Not Starting

Check pod status:

```bash
kubectl get pods -A | grep -v Running
```

Describe problematic pods:

```bash
kubectl describe pod <pod-name> -n <namespace>
```

### Metrics Not Appearing

1. **Check Prometheus targets**:
   ```bash
   kubectl port-forward -n kepler-system svc/prometheus-server 9090:80
   # Open http://localhost:9090/targets
   ```

2. **Verify Kepler is scraping**:
   ```bash
   kubectl logs -n kepler-system -l app.kubernetes.io/name=kepler
   ```

3. **Check Grafana datasources**:
   - Login to Grafana
   - Go to Configuration → Data Sources
   - Test each datasource

### Cluster Issues

Delete and recreate the cluster:

```bash
make clean
make demo
```

### CLI Connection Issues

Ensure port-forwards are running:

```bash
# Check for existing port-forwards
ps aux | grep port-forward

# Kill all port-forwards
pkill -f port-forward

# Restart needed port-forwards
kubectl port-forward -n kepler-system svc/prometheus-server 9090:80 &
kubectl port-forward -n opencost svc/opencost 9003:9003 &
```

## Next Steps

Now that you have GPTK running:

1. **Learn the Architecture**: Read [architecture.md](architecture.md) to understand how components work together
2. **Understand the Metrics**: Read [how-it-works.md](how-it-works.md) to learn about calculations
3. **Contribute**: Check [contributing.md](contributing.md) to help improve GPTK
4. **Deploy Your Workloads**: Start monitoring your own AI/K8s workloads

## Clean Up

When you're done experimenting:

```bash
make clean
```

This will delete the entire kind cluster and all resources.

## Getting Help

- **Issues**: [GitHub Issues](https://github.com/ams0/green-practioner-toolkit/issues)
- **Discussions**: [GitHub Discussions](https://github.com/ams0/green-practioner-toolkit/discussions)
- **Documentation**: Check other docs in `/docs/`

## Summary of Commands

```bash
# Full demo
make demo

# Individual components
make create-cluster
make deploy-kepler
make deploy-opencost
make deploy-otel
make deploy-grafana
make deploy-workload

# Access
make port-forward-grafana
make get-grafana-password

# CLI
make build-cli
./bin/gptk --help

# Monitoring
make status
make logs

# Cleanup
make clean
```
