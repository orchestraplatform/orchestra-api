# Orchestra API Development Tasks

# Default API configuration
api_host := "0.0.0.0"
api_port := "8000"
api_url := "http://localhost:" + api_port

# List available commands
default:
    @just --list

# === Development Setup ===

# Install dependencies
install-deps:
    uv sync

# Install development dependencies
install-dev:
    uv sync --group dev

# Sync lock file
sync:
    uv sync --frozen

# === Running the API ===

# Run API server locally
run host=api_host port=api_port:
    uvicorn main:app --reload --host {{host}} --port {{port}}

# Run API server in background
run-bg host=api_host port=api_port:
    uvicorn main:app --host {{host}} --port {{port}} &

# Run API in development mode with hot reload
dev:
    uvicorn main:app --reload --host {{api_host}} --port {{api_port}}

# Run API in production mode
prod:
    uvicorn main:app --host {{api_host}} --port {{api_port}} --workers 4

# === Testing ===

# Run all tests
test:
    pytest tests/ -v

# Run tests with coverage
test-cov:
    pytest tests/ --cov=api --cov-report=html --cov-report=term

# Run specific test file
test-file file:
    pytest {{file}} -v

# Run tests in watch mode
test-watch:
    pytest-watch

# === Code Quality ===

# Format code with black
format:
    black .

# Sort imports with isort
sort-imports:
    isort .

# Lint code with ruff
lint:
    ruff check .

# Fix linting issues
lint-fix:
    ruff check . --fix

# Run all code quality checks
quality: format sort-imports lint

# === API Testing ===

# Check API health
health url=api_url:
    curl "{{url}}/health/" | jq

# Check API readiness
ready url=api_url:
    curl "{{url}}/health/ready" | jq

# List all workshops
list-workshops url=api_url:
    curl "{{url}}/api/v1/workshops/" | jq

# Get specific workshop
get-workshop name url=api_url:
    curl "{{url}}/api/v1/workshops/{{name}}" | jq

# Get workshop status
workshop-status name url=api_url:
    curl "{{url}}/api/v1/workshops/{{name}}/status" | jq

# Create workshop from example file
create-example url=api_url:
    curl -X POST "{{url}}/api/v1/workshops/" \
      -H "Content-Type: application/json" \
      -d @examples/workshop-api-example.json | jq

# Create a simple test workshop
create-test-workshop name="test-workshop" url=api_url:
    curl -X POST "{{url}}/api/v1/workshops/" \
      -H "Content-Type: application/json" \
      -d '{"name":"{{name}}","duration":"2h","image":"rocker/rstudio:latest","resources":{"cpu":"1","memory":"2Gi"}}' | jq

# Delete a workshop
delete-workshop name url=api_url:
    curl -X DELETE "{{url}}/api/v1/workshops/{{name}}"

# === Documentation ===

# Open API documentation in browser
docs url=api_url:
    open "{{url}}/docs"

# Open ReDoc documentation
redoc url=api_url:
    open "{{url}}/redoc"

# Generate OpenAPI spec file
openapi-spec url=api_url:
    curl "{{url}}/openapi.json" | jq > openapi.json

# === Kubernetes Integration ===

# Port-forward to operator for local development
port-forward-operator:
    kubectl port-forward -n orchestra-system svc/orchestra-operator-metrics 8080:8080

# Check operator logs
operator-logs:
    kubectl logs -n orchestra-system -l app=orchestra-operator --tail=50

# Watch workshops in Kubernetes
watch-workshops:
    kubectl get workshops -w

# List workshop pods
workshop-pods:
    kubectl get pods -l workshop

# === Environment Management ===

# Clean virtual environment
clean-venv:
    rm -rf .venv
    uv sync

# Update dependencies
update-deps:
    uv sync --upgrade

# Show dependency tree
deps-tree:
    uv tree

# === Docker ===

# Build API Docker image
build-image tag="orchestra-api:latest":
    docker build -t {{tag}} .

# Run API in Docker container
run-docker tag="orchestra-api:latest" port=api_port:
    docker run -p {{port}}:8000 {{tag}}

# === Load Testing ===

# Run basic load test (requires apache bench)
load-test url=api_url requests="100" concurrency="10":
    ab -n {{requests}} -c {{concurrency}} "{{url}}/health/"

# === Database/State ===

# Clear all workshops (use with caution!)
clear-workshops:
    kubectl delete workshops --all

# === Development Workflow ===

# Complete development setup
setup: install-deps
    echo "Orchestra API development environment ready!"
    echo "Run 'just dev' to start the API server"
    echo "Run 'just docs' to open API documentation"

# Full test suite and quality checks
ci: quality test
    echo "All checks passed!"

# Quick development cycle: format, lint, test
check: format lint test

# Reset everything for clean start
reset: clean-venv clear-workshops setup

# === Monitoring ===

# Show API metrics (if available)
metrics url=api_url:
    curl "{{url}}/metrics" || echo "Metrics endpoint not available"

# Tail API logs (assumes you're running with systemd or similar)
logs:
    journalctl -f -u orchestra-api || echo "Not running as a service"
