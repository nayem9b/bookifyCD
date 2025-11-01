# Contributing to Bookify DevSecOps Platform

## Table of Contents
1. [Getting Started](#getting-started)
2. [Development Workflow](#development-workflow)
3. [Code Standards](#code-standards)
4. [Testing Guidelines](#testing-guidelines)
5. [Pull Request Process](#pull-request-process)
6. [Community Guidelines](#community-guidelines)

## Getting Started

### Prerequisites
Before contributing to the Bookify DevSecOps platform, ensure you have:
- A GitHub account
- Git installed on your local machine
- Docker and Kubernetes tools (kubectl, kind, or minikube)
- ArgoCD CLI installed
- Access to development Kubernetes cluster (if applicable)

### Setting Up Your Environment
1. Fork the repository on GitHub
2. Clone your fork locally:
   ```bash
   git clone https://github.com/<your-username>/bookify-devsecops.git
   cd bookify-devsecops
   ```
3. Add the original repository as an upstream remote:
   ```bash
   git remote add upstream https://github.com/bookify/bookify-devsecops.git
   ```
4. Create a new branch for your changes:
   ```bash
   git checkout -b feature/your-feature-name
   ```

## Development Workflow

### Git Workflow
1. Update your local main branch:
   ```bash
   git checkout main
   git fetch upstream
   git merge upstream/main
   ```
2. Create a new feature branch:
   ```bash
   git checkout -b feature/your-feature-name
   ```
3. Make your changes and commit them:
   ```bash
   git add .
   git commit -m "feat: description of your changes"
   ```
4. Push to your fork:
   ```bash
   git push origin feature/your-feature-name
   ```
5. Create a pull request to the main repository

### Branch Naming Convention
- `feature/`: New features
- `bugfix/`: Bug fixes
- `hotfix/`: Urgent production fixes
- `docs/`: Documentation updates
- `refactor/`: Code refactoring
- `test/`: Testing improvements

### Commit Message Format
Use the following format for commit messages:
```
<type>(<scope>): <subject>

<body>

<footer>
```

Types:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (white-space, formatting, etc.)
- `refactor`: Code changes that don't fix bugs or add features
- `test`: Adding or updating tests
- `chore`: Other changes that don't modify src or test files

## Code Standards

### YAML/JSON Standards
- Use 2-space indentation
- Follow consistent naming conventions
- Include appropriate comments for complex configurations
- Validate syntax before committing

### Kubernetes Manifests
- Use appropriate resource limits and requests
- Include proper labels and annotations
- Follow security best practices (non-root users, read-only root filesystem, etc.)
- Use ConfigMaps and Secrets appropriately

### Documentation Standards
- Use Markdown for documentation files
- Include examples where applicable
- Follow consistent formatting
- Use clear and concise language

## Testing Guidelines

### Local Testing
Before submitting changes, ensure:
1. All Kubernetes manifests are valid and properly formatted
2. ArgoCD applications can be created and synced without errors
3. Updated configurations work in a local development environment

### Automated Tests
- Unit tests for scripts and utilities
- Validation of Kubernetes manifests
- Security scanning of container images
- Integration tests for deployment configurations

### Test Environment
- Test changes in a local Kubernetes cluster using kind or minikube
- Verify ArgoCD sync operations
- Check monitoring and logging functionality

## Pull Request Process

### Before Submitting
1. Update the README.md with details of changes if applicable
2. Ensure your code follows the standards outlined above
3. Test your changes in a local environment
4. Verify that all automated checks pass

### Creating the Pull Request
1. Push your changes to your fork
2. Navigate to the original repository on GitHub
3. Click "New Pull Request"
4. Select your branch from the right dropdown
5. Fill in the pull request template with:
   - Summary of changes
   - Issue references (if applicable)
   - Testing performed
   - Breaking changes (if any)

### Review Process
1. Wait for at least one review from maintainers
2. Address any feedback provided
3. Make requested changes
4. Request a new review after making changes

### Post-Merge
- Delete the feature branch after merging
- Update your local main branch

## Community Guidelines

### Code of Conduct
All contributors are expected to follow the project's code of conduct:
- Be respectful and considerate
- Provide constructive feedback
- Respect privacy and confidentiality
- Focus on the technical merit of contributions

### Getting Help
- Use GitHub issues for bug reports and feature requests
- Join the project's communication channels for questions
- Be patient with your questions and help others when possible

## Style Guides

### Documentation Style
- Use active voice
- Be concise and clear
- Provide examples when possible
- Follow inclusive language guidelines

### Comment Style
- Use comments to explain "why" rather than "what"
- Keep comments up-to-date with code changes
- Remove unnecessary comments

## Reporting Issues

### Bug Reports
When reporting bugs, please include:
- Clear description of the issue
- Steps to reproduce
- Expected vs. actual behavior
- Environment details (Kubernetes version, ArgoCD version, etc.)
- Screenshots or logs if applicable

### Feature Requests
For feature requests:
- Describe the problem the feature would solve
- Include use cases
- Suggest possible implementations
- Consider the impact on existing functionality

Thank you for contributing to the Bookify DevSecOps platform!