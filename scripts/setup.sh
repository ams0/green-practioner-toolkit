#!/bin/bash
# Quick setup script for GPTK

set -e

CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

echo -e "${CYAN}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║   Green Practitioner Toolkit - Quick Setup Script    ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check prerequisites
echo -e "${CYAN}Checking prerequisites...${NC}"

command -v docker >/dev/null 2>&1 || { 
    echo -e "${YELLOW}Docker not found. Please install Docker first.${NC}"; 
    exit 1; 
}
echo -e "${GREEN}✓ Docker found${NC}"

command -v kind >/dev/null 2>&1 || { 
    echo -e "${YELLOW}kind not found. Installing...${NC}"
    curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
    chmod +x ./kind
    sudo mv ./kind /usr/local/bin/kind
    echo -e "${GREEN}✓ kind installed${NC}"
}
echo -e "${GREEN}✓ kind found${NC}"

command -v kubectl >/dev/null 2>&1 || { 
    echo -e "${YELLOW}kubectl not found. Installing...${NC}"
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    chmod +x kubectl
    sudo mv kubectl /usr/local/bin/
    echo -e "${GREEN}✓ kubectl installed${NC}"
}
echo -e "${GREEN}✓ kubectl found${NC}"

command -v helm >/dev/null 2>&1 || { 
    echo -e "${YELLOW}helm not found. Installing...${NC}"
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
    echo -e "${GREEN}✓ helm installed${NC}"
}
echo -e "${GREEN}✓ helm found${NC}"

echo ""
echo -e "${CYAN}Starting GPTK demo environment...${NC}"
echo ""

# Run demo
make demo

echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║              Setup Complete! 🎉                       ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${CYAN}Next steps:${NC}"
echo "  1. Access Grafana:"
echo "     kubectl port-forward -n monitoring svc/grafana 3000:3000"
echo "     Open: http://localhost:3000 (admin/admin)"
echo ""
echo "  2. Build CLI:"
echo "     make build-cli"
echo ""
echo "  3. Query metrics:"
echo "     ./bin/gptk carbon --namespace demo-workloads"
echo ""
echo -e "${CYAN}Documentation:${NC}"
echo "  - Getting Started: docs/getting-started.md"
echo "  - Architecture: docs/architecture.md"
echo "  - How It Works: docs/how-it-works.md"
echo ""
