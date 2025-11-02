.PHONY: help demo clean build-cli test lint install-deps \
        create-cluster delete-cluster deploy-all deploy-kepler \
        deploy-opencost deploy-otel deploy-grafana deploy-workload \
        port-forward-grafana logs status

.DEFAULT_GOAL := help

# Configuration
CLUSTER_NAME ?= gptk-demo
KIND_CONFIG := deploy/kind/kind-config.yaml
KUBECTL := kubectl
HELM := helm

# Colors for output
CYAN := \033[0;36m
GREEN := \033[0;32m
YELLOW := \033[0;33m
RED := \033[0;31m
NC := \033[0m # No Color

help: ## Show this help message
	@echo "$(CYAN)Green Practitioner Toolkit - Makefile Commands$(NC)"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "$(GREEN)%-25s$(NC) %s\n", $$1, $$2}'

install-deps: ## Install required dependencies (kind, kubectl, helm)
	@echo "$(CYAN)Installing dependencies...$(NC)"
	@command -v kind >/dev/null 2>&1 || { echo "$(YELLOW)Installing kind...$(NC)"; \
		curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64 && \
		chmod +x ./kind && sudo mv ./kind /usr/local/bin/kind; }
	@command -v kubectl >/dev/null 2>&1 || { echo "$(YELLOW)Installing kubectl...$(NC)"; \
		curl -LO "https://dl.k8s.io/release/$$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" && \
		chmod +x kubectl && sudo mv kubectl /usr/local/bin/; }
	@command -v helm >/dev/null 2>&1 || { echo "$(YELLOW)Installing helm...$(NC)"; \
		curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash; }
	@echo "$(GREEN)✓ Dependencies installed$(NC)"

create-cluster: ## Create a kind cluster
	@echo "$(CYAN)Creating kind cluster: $(CLUSTER_NAME)...$(NC)"
	@kind create cluster --name $(CLUSTER_NAME) --config $(KIND_CONFIG) || true
	@$(KUBECTL) cluster-info --context kind-$(CLUSTER_NAME)
	@echo "$(GREEN)✓ Cluster created$(NC)"

delete-cluster: ## Delete the kind cluster
	@echo "$(CYAN)Deleting kind cluster: $(CLUSTER_NAME)...$(NC)"
	@kind delete cluster --name $(CLUSTER_NAME)
	@echo "$(GREEN)✓ Cluster deleted$(NC)"

deploy-kepler: ## Deploy Kepler for power monitoring
	@echo "$(CYAN)Deploying Kepler...$(NC)"
	@$(KUBECTL) create namespace kepler-system --dry-run=client -o yaml | $(KUBECTL) apply -f -
	@$(HELM) repo add kepler https://sustainable-computing-io.github.io/kepler-helm-chart || true
	@$(HELM) repo update
	@$(HELM) upgrade --install kepler kepler/kepler \
		--namespace kepler-system \
		--values deploy/helm/kepler/values.yaml \
		--wait
	@echo "$(GREEN)✓ Kepler deployed$(NC)"

deploy-opencost: ## Deploy OpenCost for cost visibility
	@echo "$(CYAN)Deploying OpenCost...$(NC)"
	@$(KUBECTL) create namespace opencost --dry-run=client -o yaml | $(KUBECTL) apply -f -
	@$(HELM) repo add opencost https://opencost.github.io/opencost-helm-chart || true
	@$(HELM) repo update
	@$(HELM) upgrade --install opencost opencost/opencost \
		--namespace opencost \
		--values deploy/helm/opencost/values.yaml \
		--wait
	@echo "$(GREEN)✓ OpenCost deployed$(NC)"

deploy-otel: ## Deploy OpenTelemetry Collector
	@echo "$(CYAN)Deploying OpenTelemetry Collector...$(NC)"
	@$(KUBECTL) create namespace otel-system --dry-run=client -o yaml | $(KUBECTL) apply -f -
	@$(HELM) repo add open-telemetry https://open-telemetry.github.io/opentelemetry-helm-charts || true
	@$(HELM) repo update
	@$(HELM) upgrade --install otel-collector open-telemetry/opentelemetry-collector \
		--namespace otel-system \
		--values deploy/helm/otel-collector/values.yaml \
		--wait
	@echo "$(GREEN)✓ OpenTelemetry Collector deployed$(NC)"

deploy-grafana: ## Deploy Grafana with dashboards
	@echo "$(CYAN)Deploying Grafana...$(NC)"
	@$(KUBECTL) create namespace monitoring --dry-run=client -o yaml | $(KUBECTL) apply -f -
	@$(KUBECTL) create configmap grafana-dashboards \
		--from-file=dashboards/ \
		--namespace monitoring \
		--dry-run=client -o yaml | $(KUBECTL) apply -f -
	@$(HELM) repo add grafana https://grafana.github.io/helm-charts || true
	@$(HELM) repo update
	@$(HELM) upgrade --install grafana grafana/grafana \
		--namespace monitoring \
		--values deploy/helm/grafana/values.yaml \
		--wait
	@echo "$(GREEN)✓ Grafana deployed$(NC)"
	@echo "$(YELLOW)Get Grafana password: kubectl get secret --namespace monitoring grafana -o jsonpath='{.data.admin-password}' | base64 --decode$(NC)"

deploy-workload: ## Deploy example demo workload
	@echo "$(CYAN)Deploying demo workload...$(NC)"
	@$(KUBECTL) apply -f deploy/helm/demo-workload/deployment.yaml
	@echo "$(GREEN)✓ Demo workload deployed$(NC)"

deploy-all: deploy-kepler deploy-opencost deploy-otel deploy-grafana deploy-workload ## Deploy all components

demo: install-deps create-cluster deploy-all ## Run complete demo environment
	@echo ""
	@echo "$(GREEN)╔═══════════════════════════════════════════════════════════╗$(NC)"
	@echo "$(GREEN)║        🌱 Green Practitioner Toolkit Demo Ready!        ║$(NC)"
	@echo "$(GREEN)╚═══════════════════════════════════════════════════════════╝$(NC)"
	@echo ""
	@echo "$(CYAN)Access Grafana:$(NC)"
	@echo "  kubectl port-forward -n monitoring svc/grafana 3000:3000"
	@echo "  URL: http://localhost:3000"
	@echo "  User: admin"
	@echo "  Password: run 'make get-grafana-password'"
	@echo ""
	@echo "$(CYAN)Access OpenCost:$(NC)"
	@echo "  kubectl port-forward -n opencost svc/opencost 9003:9003"
	@echo "  URL: http://localhost:9003"
	@echo ""
	@echo "$(CYAN)Check Kepler metrics:$(NC)"
	@echo "  kubectl port-forward -n kepler-system svc/kepler-exporter 9102:9102"
	@echo "  Metrics: http://localhost:9102/metrics"
	@echo ""
	@echo "$(CYAN)Next steps:$(NC)"
	@echo "  1. Run: make port-forward-grafana"
	@echo "  2. Open Grafana and explore dashboards"
	@echo "  3. Build CLI: make build-cli"
	@echo "  4. Query metrics: ./bin/gptk --help"
	@echo ""

port-forward-grafana: ## Port-forward Grafana to localhost:3000
	@echo "$(CYAN)Port-forwarding Grafana...$(NC)"
	@echo "$(YELLOW)Access Grafana at: http://localhost:3000$(NC)"
	@$(KUBECTL) port-forward -n monitoring svc/grafana 3000:3000

get-grafana-password: ## Get Grafana admin password
	@$(KUBECTL) get secret --namespace monitoring grafana -o jsonpath='{.data.admin-password}' | base64 --decode
	@echo ""

build-cli: ## Build the gptk CLI tool
	@echo "$(CYAN)Building gptk CLI...$(NC)"
	@cd cmd/gptk && go build -o ../../bin/gptk .
	@echo "$(GREEN)✓ CLI built: ./bin/gptk$(NC)"

test: ## Run tests
	@echo "$(CYAN)Running tests...$(NC)"
	@go test -v ./...

lint: ## Run linters
	@echo "$(CYAN)Running linters...$(NC)"
	@go vet ./...
	@gofmt -s -l .

status: ## Show cluster status
	@echo "$(CYAN)Cluster Status:$(NC)"
	@$(KUBECTL) get nodes
	@echo ""
	@echo "$(CYAN)Deployed Components:$(NC)"
	@$(KUBECTL) get pods -A | grep -E "kepler|opencost|otel|grafana|demo" || echo "No components deployed"

logs: ## Show logs from all components
	@echo "$(CYAN)Kepler logs:$(NC)"
	@$(KUBECTL) logs -n kepler-system -l app.kubernetes.io/name=kepler --tail=20 || true
	@echo ""
	@echo "$(CYAN)OpenCost logs:$(NC)"
	@$(KUBECTL) logs -n opencost -l app.kubernetes.io/name=opencost --tail=20 || true
	@echo ""
	@echo "$(CYAN)OTel Collector logs:$(NC)"
	@$(KUBECTL) logs -n otel-system -l app.kubernetes.io/name=opentelemetry-collector --tail=20 || true

clean: delete-cluster ## Clean up everything (delete cluster)
	@echo "$(GREEN)✓ Cleanup complete$(NC)"

.PHONY: all
all: demo build-cli ## Build everything and run demo
