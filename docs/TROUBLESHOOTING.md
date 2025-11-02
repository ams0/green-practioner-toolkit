# Troubleshooting Guide

## Common Issues and Solutions

### Kind Cluster Issues

#### Cluster Creation Fails

**Symptom**: `kind create cluster` fails with error

**Solutions**:
1. Check Docker is running:
   ```bash
   docker ps
   ```

2. Clean up existing clusters:
   ```bash
   kind delete cluster --name green-practitioner-toolkit
   ```

3. Check port availability (3000, 9090):
   ```bash
   lsof -i :3000
   lsof -i :9090
   ```

#### Cluster Not Responding

**Symptom**: `kubectl` commands timeout

**Solutions**:
1. Check cluster status:
   ```bash
   kubectl cluster-info
   ```

2. Restart cluster:
   ```bash
   make cluster-delete
   make cluster-create
   ```

### Deployment Issues

#### Pods Not Starting

**Symptom**: Pods stuck in `Pending` or `CrashLoopBackOff`

**Diagnosis**:
```bash
# Check pod status
kubectl get pods -A

# Describe problem pod
kubectl describe pod <pod-name> -n <namespace>

# Check logs
kubectl logs <pod-name> -n <namespace>
```

**Solutions**:

1. **Insufficient Resources**:
   ```bash
   # Check node resources
   kubectl top nodes
   kubectl describe nodes
   ```

2. **Image Pull Issues**:
   ```bash
   # Check events
   kubectl get events -n <namespace> --sort-by='.lastTimestamp'
   ```

3. **ConfigMap/Secret Issues**:
   ```bash
   # Verify ConfigMaps exist
   kubectl get configmap -n <namespace>
   ```

#### Prometheus Not Scraping Metrics

**Symptom**: No data in Grafana or CLI returns errors

**Diagnosis**:
```bash
# Check Prometheus targets
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090
# Visit http://localhost:9090/targets
```

**Solutions**:

1. **ServiceMonitor Not Created**:
   ```bash
   kubectl get servicemonitor -A
   ```

2. **Service Labels Mismatch**:
   ```bash
   # Check ServiceMonitor selector
   kubectl get servicemonitor <name> -n <namespace> -o yaml
   
   # Check Service labels
   kubectl get svc <name> -n <namespace> -o yaml
   ```

3. **Network Policies Blocking**:
   ```bash
   kubectl get networkpolicies -A
   ```

### Kepler Issues

#### Kepler Pods Not Running

**Symptom**: Kepler DaemonSet pods failing

**Diagnosis**:
```bash
kubectl logs -n kepler -l app=kepler
kubectl describe daemonset -n kepler kepler
```

**Solutions**:

1. **Privileged Mode Required**:
   - Kepler needs privileged access for eBPF
   - Verify DaemonSet security context

2. **Kernel Module Issues**:
   - Check if `/sys` and `/lib/modules` are available
   - Some environments don't expose power metrics

3. **Fallback to Estimation**:
   - Kepler can estimate power when hardware counters unavailable
   - Check logs for estimation mode

#### No Energy Metrics

**Symptom**: Kepler running but no `kepler_*` metrics

**Solutions**:

1. Check metrics endpoint:
   ```bash
   kubectl port-forward -n kepler svc/kepler 9102:9102
   curl http://localhost:9102/metrics | grep kepler_
   ```

2. Verify Prometheus scraping:
   ```bash
   # In Prometheus UI, check targets
   ```

3. Known limitation: kind/Docker doesn't expose real power metrics
   - Kepler will estimate based on CPU usage
   - Real hardware/VMs needed for accurate measurements

### OpenCost Issues

#### OpenCost Not Starting

**Symptom**: OpenCost pod failing to start

**Diagnosis**:
```bash
kubectl logs -n opencost -l app=opencost
```

**Solutions**:

1. **Prometheus Connection**:
   - Verify `PROMETHEUS_SERVER_ENDPOINT` in deployment
   - Test connectivity:
     ```bash
     kubectl run -it --rm debug --image=curlimages/curl --restart=Never -- \
       curl http://prometheus-kube-prometheus-prometheus.monitoring.svc.cluster.local:9090/api/v1/query?query=up
     ```

2. **Cloud Provider API Key**:
   - Default key is for demo only
   - Set proper key for production

### CLI Issues

#### CLI Cannot Connect to Prometheus

**Symptom**: `Error: failed to query Prometheus: connection refused`

**Solutions**:

1. **Port Forward Not Active**:
   ```bash
   # Ensure Prometheus is accessible
   kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090
   ```

2. **Wrong URL**:
   ```bash
   # Use correct URL
   ./cli/green-toolkit query --prometheus-url=http://localhost:9090
   ```

#### No Data Returned

**Symptom**: CLI runs but shows zero values

**Solutions**:

1. **Metrics Not Yet Available**:
   - Wait a few minutes after deployment
   - Prometheus scrape interval is 30s

2. **Wrong Namespace**:
   ```bash
   # Don't filter by namespace to see all data
   ./cli/green-toolkit query
   ```

3. **Query Metrics Directly**:
   ```bash
   # Visit Prometheus UI and run queries manually
   # http://localhost:9090
   ```

### Grafana Issues

#### Cannot Access Grafana

**Symptom**: http://localhost:3000 not accessible

**Solutions**:

1. **Check Service**:
   ```bash
   kubectl get svc -n monitoring | grep grafana
   ```

2. **Port Mapping**:
   - Verify kind config has port mappings
   - kind config should expose NodePort 30080 to host 3000

3. **Pod Status**:
   ```bash
   kubectl get pods -n monitoring -l app.kubernetes.io/name=grafana
   ```

#### Dashboards Not Loading

**Symptom**: Grafana UI works but dashboards show no data

**Solutions**:

1. **Check Data Source**:
   - Configuration > Data Sources
   - Verify Prometheus connection
   - Test & Save

2. **Check Prometheus Metrics**:
   - Visit Prometheus UI
   - Run sample queries

3. **Dashboard ConfigMap**:
   ```bash
   kubectl get configmap -n monitoring green-practitioner-dashboard
   ```

### Build/Lint Issues

#### Go Build Fails

**Symptom**: `go build` errors

**Solutions**:

1. **Dependencies**:
   ```bash
   cd cli
   go mod tidy
   ```

2. **Go Version**:
   ```bash
   go version  # Should be 1.21+
   ```

#### YAML Validation Fails

**Symptom**: Linting errors on YAML files

**Solutions**:

1. **Check Syntax**:
   ```bash
   python3 -c "import yaml; yaml.safe_load(open('file.yaml'))"
   ```

2. **Fix Indentation**:
   - YAML requires consistent spacing
   - Use 2 spaces for indentation

## Performance Issues

### High Memory Usage

**Symptom**: Pods being OOMKilled

**Solutions**:

1. **Increase Resource Limits**:
   ```yaml
   resources:
     limits:
       memory: 1Gi
   ```

2. **Reduce Scrape Intervals**:
   - Increase from 30s to 60s or more

3. **Limit Retention**:
   ```yaml
   prometheus:
     prometheusSpec:
       retention: 7d
   ```

### Slow Queries

**Symptom**: CLI or Grafana queries taking long time

**Solutions**:

1. **Reduce Time Range**:
   ```bash
   ./cli/green-toolkit query --range=1m
   ```

2. **Optimize PromQL**:
   - Use rate() instead of increase()
   - Add appropriate aggregation

## Getting Help

If issues persist:

1. **Check Logs**:
   ```bash
   # All pods
   kubectl logs -n <namespace> <pod-name>
   
   # Follow logs
   kubectl logs -f -n <namespace> <pod-name>
   ```

2. **Check Events**:
   ```bash
   kubectl get events -n <namespace> --sort-by='.lastTimestamp'
   ```

3. **Describe Resources**:
   ```bash
   kubectl describe pod <pod-name> -n <namespace>
   ```

4. **GitHub Issues**:
   - Search existing issues
   - Create new issue with logs and context

5. **Community Resources**:
   - [Kepler Slack](https://kubernetes.slack.com/messages/kepler)
   - [OpenCost Slack](https://slack.opencost.io/)
   - [CNCF Slack](https://slack.cncf.io/)

## Debug Mode

### Enable Verbose Logging

1. **Prometheus**:
   ```yaml
   prometheus:
     prometheusSpec:
       logLevel: debug
   ```

2. **OTel Collector**:
   ```yaml
   exporters:
     logging:
       loglevel: debug
   ```

3. **Kubectl**:
   ```bash
   kubectl --v=8 get pods
   ```

## Clean Slate

When all else fails:

```bash
# Delete everything and start fresh
make clean
docker system prune -a  # Optional: clean Docker
make demo
```
