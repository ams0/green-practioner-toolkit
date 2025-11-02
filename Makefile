.PHONY: help
help: ## Display this help message
	@echo "Green Practitioner Toolkit - Makefile commands:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'

.PHONY: deps
deps: ## Check dependencies
	@echo "Checking dependencies..."
	@command -v kind >/dev/null 2>&1 || { echo "kind is required but not installed. Visit https://kind.sigs.k8s.io/"; exit 1; }
	@command -v kubectl >/dev/null 2>&1 || { echo "kubectl is required but not installed."; exit 1; }
	@command -v helm >/dev/null 2>&1 || { echo "helm is required but not installed."; exit 1; }
	@command -v go >/dev/null 2>&1 || { echo "go is required but not installed."; exit 1; }
	@echo "All dependencies found!"

.PHONY: cluster-create
cluster-create: deps ## Create kind cluster
	@echo "Creating kind cluster..."
	kind create cluster --config deploy/kind/cluster-config.yaml --wait 5m

.PHONY: cluster-delete
cluster-delete: ## Delete kind cluster
	@echo "Deleting kind cluster..."
	kind delete cluster --name green-practitioner-toolkit

.PHONY: deploy-prometheus
deploy-prometheus: ## Deploy Prometheus using Helm
	@echo "Adding Prometheus Helm repository..."
	helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
	helm repo update
	@echo "Installing Prometheus..."
	kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -
	helm upgrade --install prometheus prometheus-community/kube-prometheus-stack \
		--namespace monitoring \
		--set prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues=false \
		--set prometheus.service.type=NodePort \
		--set prometheus.service.nodePort=30090 \
		--wait --timeout 10m

.PHONY: deploy-kepler
deploy-kepler: ## Deploy Kepler for energy monitoring
	@echo "Deploying Kepler..."
	kubectl apply -k deploy/kepler

.PHONY: deploy-opencost
deploy-opencost: ## Deploy OpenCost for cost monitoring
	@echo "Deploying OpenCost..."
	kubectl apply -k deploy/opencost

.PHONY: deploy-otel
deploy-otel: ## Deploy OpenTelemetry Collector
	@echo "Deploying OpenTelemetry Collector..."
	kubectl apply -k deploy/otel-collector

.PHONY: deploy-grafana
deploy-grafana: ## Deploy Grafana dashboards
	@echo "Grafana is already deployed with Prometheus stack"
	@echo "Applying custom dashboards..."
	kubectl apply -f deploy/grafana/dashboards.yaml

.PHONY: deploy-sample
deploy-sample: ## Deploy sample workload
	@echo "Deploying sample workload..."
	kubectl apply -k deploy/sample-workload

.PHONY: deploy-all
deploy-all: deploy-prometheus deploy-kepler deploy-opencost deploy-otel deploy-grafana deploy-sample ## Deploy all components
	@echo "All components deployed!"
	@echo ""
	@echo "Access points:"
	@echo "  Grafana:    http://localhost:3000 (admin/prom-operator)"
	@echo "  Prometheus: http://localhost:9090"
	@echo ""
	@echo "Run 'make cli-build' to build the CLI tool"

.PHONY: demo
demo: cluster-create deploy-all ## Full demo setup
	@echo "Demo environment is ready!"
	@echo "Run 'make cli-query' to query metrics"

.PHONY: cli-build
cli-build: ## Build the CLI tool
	@echo "Building CLI tool..."
	cd cli && go build -o green-toolkit .
	@echo "CLI built: cli/green-toolkit"

.PHONY: cli-query
cli-query: cli-build ## Query metrics using CLI
	@echo "Querying metrics..."
	./cli/green-toolkit query

.PHONY: clean
clean: cluster-delete ## Clean up everything
	@echo "Cleanup complete!"

.PHONY: lint
lint: ## Run linters
	@echo "Running Go linters..."
	cd cli && go fmt ./...
	cd cli && go vet ./...
	@echo "Running YAML linters..."
	@command -v yamllint >/dev/null 2>&1 && find deploy -name "*.yaml" -exec yamllint {} \; || echo "yamllint not installed, skipping YAML validation"

.PHONY: test
test: ## Run tests
	@echo "Running Go tests..."
	cd cli && go test -v ./...
