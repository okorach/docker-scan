# docker scanning example

This repo shows how to perform a docker scan with SonarQube and how to complement with 3rd party analyzers
(Trivy and Checkov in the current case)

Prerequisites:
- SonarQube 2025 Release 1 or higher
- Python 3.9 or higher installed
- 3rd party analyzers installed:
  - Pylint (Python linter)
  - Shellcheck (Shell linter)
  - Checkov (Docker linter)
  - Trivy (Docker image analyzer)