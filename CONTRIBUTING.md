# Contributing to LiteRAG

Thank you for your interest in contributing to LiteRAG! This document provides guidelines and information for contributors.

## Table of Contents

- [Community Guidelines](#community-guidelines)
- [Getting Started](#getting-started)
- [Development Setup](#development-setup)
- [Making Changes](#making-changes)
- [Pull Request Process](#pull-request-process)
- [Coding Standards](#coding-standards)
- [Testing](#testing)
- [Reporting Issues](#reporting-issues)

## Community Guidelines

We welcome contributions from everyone. Please be respectful and constructive in all interactions.

## Getting Started

1. **Fork the repository** on GitHub
2. **Clone your fork** locally:
   ```bash
   git clone https://github.com/your-username/local-rag-system.git
   cd local-rag-system
   ```
3. **Set up the development environment** (see [Development Setup](#development-setup))

## Development Setup

### Prerequisites

- Python 3.11+
- Docker and Docker Compose
- Poetry (for local development)

### Quick Setup

```bash
# Install Poetry if not already installed
curl -sSL https://install.python-poetry.org | python3 -

# Run the setup script
./setup-dev.sh

# Or manually install dependencies
./dev-commands.sh install
```

### Development Workflow

1. **Start the development environment**:
   ```bash
   # Option 1: Docker (recommended for testing)
   docker-compose up -d
   
   # Option 2: Local development
   ./dev-commands.sh start-local
   ```

2. **Run the test suite**:
   ```bash
   ./dev-commands.sh test
   ```

3. **Format and lint your code**:
   ```bash
   ./dev-commands.sh format
   ./dev-commands.sh lint
   ./dev-commands.sh typecheck
   ```

## Making Changes

### Branch Naming

Use descriptive branch names:
- `feature/add-authentication`
- `fix/memory-leak-in-embeddings`
- `docs/update-api-documentation`
- `refactor/improve-error-handling`

### Commit Messages

Follow the [Conventional Commits](https://www.conventionalcommits.org/) format:

```
type(scope): description

[optional body]

[optional footer]
```

Examples:
- `feat(api): add batch document ingestion endpoint`
- `fix(embedding): resolve memory leak in model loading`
- `docs(readme): update installation instructions`
- `test(api): add integration tests for query endpoint`

### Making Changes

1. **Create a new branch**:
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make your changes** following the [coding standards](#coding-standards)

3. **Test your changes**:
   ```bash
   # Install dependencies and run integration tests
   poetry install
   poetry run python tests/test_rag.py
   
   # Run service-specific tests and linting
   ./dev-commands.sh test
   ./dev-commands.sh lint
   ```

4. **Commit your changes**:
   ```bash
   git add .
   git commit -m "feat(api): add your feature description"
   ```

5. **Push to your fork**:
   ```bash
   git push origin feature/your-feature-name
   ```

## Pull Request Process

1. **Ensure your PR**:
   - [ ] Follows the coding standards
   - [ ] Includes tests for new functionality
   - [ ] Updates documentation if needed
   - [ ] Passes all CI checks

2. **Fill out the PR template** with:
   - Clear description of changes
   - Related issue numbers
   - Testing instructions
   - Screenshots (if applicable)

3. **Request review** from maintainers

4. **Address feedback** promptly and respectfully

## Coding Standards

### Python Code Style

- **Formatting**: Use Black with 88-character line length
- **Import sorting**: Use isort with Black profile
- **Linting**: Code must pass Flake8 checks
- **Type hints**: Use type hints for all functions (mypy compliance)

### Code Organization

- **Services**: Keep RAG API and Embedding Service concerns separate
- **Error handling**: Use appropriate HTTP status codes and error messages
- **Logging**: Use structured logging with appropriate levels
- **Configuration**: Use environment variables for configuration

### Docker

- **Multi-stage builds**: Use when appropriate to reduce image size
- **Security**: Run containers as non-root users when possible
- **Efficiency**: Optimize layer caching and build times

## Testing

### Test Structure

```
tests/
├── unit/           # Unit tests for individual components
├── integration/    # Integration tests for API endpoints
└── e2e/           # End-to-end tests for complete workflows
```

### Running Tests

```bash
# Install root dependencies first
poetry install

# Run integration tests
poetry run python tests/test_rag.py

# Run service-specific tests
cd rag-api && poetry run pytest
cd embedding-service && poetry run pytest

# Run with coverage
cd rag-api && poetry run pytest --cov=.
cd embedding-service && poetry run pytest --cov=.
```

### Test Guidelines

- **Unit tests**: Test individual functions and classes
- **Integration tests**: Test API endpoints and service interactions
- **Mocking**: Mock external dependencies (Qdrant, embedding models)
- **Fixtures**: Use pytest fixtures for test data and setup

## Reporting Issues

### Bug Reports

Use the bug report template and include:

- **Environment**: OS, Python version, Docker version
- **Steps to reproduce**: Clear, numbered steps
- **Expected behavior**: What should happen
- **Actual behavior**: What actually happens
- **Logs**: Relevant error messages or logs
- **Configuration**: docker-compose.yml modifications, environment variables

### Feature Requests

Use the feature request template and include:

- **Problem**: What problem does this solve?
- **Solution**: Proposed solution or approach
- **Alternatives**: Other solutions considered
- **Additional context**: Screenshots, examples, references

## Development Tips

### Debugging

- **Logs**: Use `docker-compose logs -f service-name` to view logs
- **Debugging**: Attach debugger to running containers
- **Database**: Use Qdrant dashboard at http://localhost:6333/dashboard

### Performance

- **Profiling**: Use cProfile for Python performance analysis
- **Memory**: Monitor memory usage, especially for embedding models
- **Caching**: Consider caching strategies for expensive operations

### Documentation

- **API changes**: Update API.md for endpoint changes
- **Configuration**: Update README.md for new environment variables
- **Architecture**: Update CLAUDE.md for structural changes

## Questions?

- **GitHub Discussions**: For general questions and ideas
- **Issues**: For bug reports and feature requests
- **Email**: For security-related concerns (see SECURITY.md)

Thank you for contributing to LiteRAG! 🚀