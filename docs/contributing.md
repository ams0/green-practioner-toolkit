# Contributing to Green Practitioner Toolkit

Thank you for your interest in contributing to GPTK! This document provides guidelines and instructions for contributing.

## Code of Conduct

We are committed to providing a welcoming and inclusive environment. Please be respectful and constructive in all interactions.

## Ways to Contribute

- 🐛 **Report bugs** via GitHub Issues
- 💡 **Suggest features** via GitHub Discussions
- 📝 **Improve documentation**
- 🔧 **Submit code changes** via Pull Requests
- 🧪 **Add tests** for better coverage
- 📊 **Create dashboards** for new use cases
- 🎨 **Design improvements** to CLI/UI

## Getting Started

### 1. Fork and Clone

```bash
# Fork the repository on GitHub, then:
git clone https://github.com/YOUR_USERNAME/green-practioner-toolkit.git
cd green-practioner-toolkit
```

### 2. Set Up Development Environment

```bash
# Install dependencies
make install-deps

# Create a development cluster
make create-cluster

# Deploy the stack
make deploy-all
```

### 3. Make Your Changes

Create a new branch:

```bash
git checkout -b feature/my-new-feature
```

### 4. Test Your Changes

```bash
# Run tests
make test

# Run linters
make lint

# Test in the cluster
make demo
```

### 5. Commit and Push

```bash
git add .
git commit -m "feat: add new feature"
git push origin feature/my-new-feature
```

### 6. Create a Pull Request

- Go to GitHub and create a PR from your branch
- Describe your changes clearly
- Link any related issues
- Wait for review

## Development Workflow

### Building the CLI

```bash
# Build locally
make build-cli

# Test the CLI
./bin/gptk --help
```

### Running Tests

```bash
# Run all tests
go test ./...

# Run with coverage
go test -cover ./...

# Run specific package tests
go test ./pkg/carbon/...
```

### Code Style

We follow standard Go conventions:

```bash
# Format code
go fmt ./...

# Run linters
go vet ./...

# If you have golangci-lint
golangci-lint run
```

### Adding New Features

#### Adding a New CLI Command

1. Add command in `cmd/gptk/main.go`
2. Implement logic in appropriate `pkg/` subdirectory
3. Add tests
4. Update documentation

Example:

```go
// cmd/gptk/main.go
optimizeCmd := &cobra.Command{
    Use:   "optimize",
    Short: "Get optimization recommendations",
    RunE:  runOptimizeCommand,
}
rootCmd.AddCommand(optimizeCmd)
```

#### Adding New Metrics

1. Create metric in OTel Collector config
2. Add dashboard panel in Grafana
3. Document in `docs/how-it-works.md`

#### Adding New Dashboards

1. Create JSON in `dashboards/`
2. Follow naming: `gptk-[purpose].json`
3. Include in ConfigMap deployment
4. Document panels and queries

### Testing Guidelines

#### Unit Tests

```go
// pkg/carbon/carbon_test.go
func TestCalculateCO2FromEnergy(t *testing.T) {
    tests := []struct {
        name            string
        energyKWh       float64
        carbonIntensity float64
        expected        float64
    }{
        {"default intensity", 1.0, 0, 475.0},
        {"custom intensity", 1.0, 300.0, 300.0},
        {"zero energy", 0.0, 475.0, 0.0},
    }
    
    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            result := CalculateCO2FromEnergy(tt.energyKWh, tt.carbonIntensity)
            if result != tt.expected {
                t.Errorf("expected %f, got %f", tt.expected, result)
            }
        })
    }
}
```

#### Integration Tests

```bash
# Test full deployment
make demo

# Verify components
make status

# Check metrics
kubectl port-forward -n kepler-system svc/prometheus-server 9090:80 &
curl http://localhost:9090/api/v1/query?query=up
```

## Project Structure

```
.
├── cmd/
│   └── gptk/              # CLI application
├── pkg/
│   ├── carbon/            # Carbon calculation logic
│   ├── cost/              # Cost calculation logic
│   └── metrics/           # Metrics collection
├── deploy/
│   ├── kind/              # kind cluster config
│   ├── helm/              # Helm values files
│   └── kustomize/         # Kustomize overlays
├── dashboards/            # Grafana dashboards
├── docs/                  # Documentation
├── examples/              # Example configurations
└── scripts/               # Helper scripts
```

## Commit Message Guidelines

We follow [Conventional Commits](https://www.conventionalcommits.org/):

### Format

```
<type>[optional scope]: <description>

[optional body]

[optional footer]
```

### Types

- **feat**: New feature
- **fix**: Bug fix
- **docs**: Documentation changes
- **style**: Code style changes (formatting, etc.)
- **refactor**: Code refactoring
- **test**: Adding or updating tests
- **chore**: Maintenance tasks

### Examples

```bash
feat: add carbon intensity per region

Add support for region-specific carbon intensity values.
Includes configuration for AWS, GCP, and Azure regions.

Closes #123

---

fix: correct CO2 calculation formula

The previous formula didn't account for proper unit conversion.

---

docs: update getting-started guide

Add troubleshooting section for common issues.

---

chore: update dependencies
```

## Pull Request Guidelines

### PR Title

Use the same format as commit messages:

```
feat: add real-time optimization recommendations
```

### PR Description Template

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Testing
Describe how you tested your changes

## Checklist
- [ ] Code follows project style
- [ ] Tests added/updated
- [ ] Documentation updated
- [ ] All tests pass
- [ ] Commits follow convention

## Related Issues
Closes #XXX
```

### Review Process

1. Automated checks must pass (CI/CD)
2. At least one approving review required
3. All comments must be resolved
4. No merge conflicts
5. Documentation updated if needed

## Documentation

### When to Update Docs

- Adding new features
- Changing CLI commands
- Modifying configuration
- Adding new metrics/dashboards
- Fixing significant bugs

### Documentation Files

- `README.md`: Overview and quick start
- `docs/architecture.md`: System design
- `docs/getting-started.md`: Detailed setup
- `docs/how-it-works.md`: Technical details
- `docs/contributing.md`: This file

### Documentation Style

- Use clear, concise language
- Include code examples
- Add screenshots for UI changes
- Update table of contents
- Test all commands/code snippets

## Adding Dependencies

### Go Dependencies

```bash
# Add a new dependency
go get github.com/example/package

# Update go.mod and go.sum
go mod tidy
```

### Helm Dependencies

Update `deploy/helm/*/values.yaml` with version:

```yaml
image:
  repository: new-repo
  tag: v1.2.3
```

### Principles

- Minimize dependencies
- Prefer well-maintained libraries
- Check for security issues
- Document why dependency is needed

## Release Process

Releases are managed by maintainers:

1. Update version in `cmd/gptk/main.go`
2. Update `CHANGELOG.md`
3. Create Git tag: `git tag v0.2.0`
4. Push tag: `git push origin v0.2.0`
5. GitHub Actions creates release
6. Update release notes

## Common Tasks

### Adding a New Helm Chart

1. Create directory: `deploy/helm/new-component/`
2. Add `values.yaml`
3. Update `Makefile` with deploy target
4. Document in README
5. Test deployment

### Adding a Dashboard

1. Create in Grafana UI
2. Export as JSON
3. Save to `dashboards/gptk-name.json`
4. Update ConfigMap reference
5. Document panels and queries

### Updating Kepler/OpenCost

1. Change version in Helm values
2. Test in dev cluster
3. Update documentation if API changes
4. Create PR with changes

## Getting Help

- **Questions**: [GitHub Discussions](https://github.com/ams0/green-practioner-toolkit/discussions)
- **Bugs**: [GitHub Issues](https://github.com/ams0/green-practioner-toolkit/issues)
- **Security**: Email maintainers directly

## Recognition

Contributors are recognized in:
- GitHub Contributors page
- Release notes
- Project README (for significant contributions)

## License

By contributing, you agree that your contributions will be licensed under the Apache License 2.0.

## Additional Resources

- [Kepler Contribution Guide](https://github.com/sustainable-computing-io/kepler/blob/main/CONTRIBUTING.md)
- [OpenCost Contribution Guide](https://github.com/opencost/opencost/blob/develop/CONTRIBUTING.md)
- [Go Code Review Comments](https://github.com/golang/go/wiki/CodeReviewComments)
- [Effective Go](https://golang.org/doc/effective_go)

## Thank You!

Your contributions make GPTK better for everyone. Thank you for taking the time to contribute! 🌱
