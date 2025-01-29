# docker scanning example

This repo demonstrates 2 different use cases:
- How to perform a docker scan with SonarQube and how to complement with 3rd party analyzers
(Trivy and Checkov in the current case)
- More generally speaking how to integrate results of multiple 3rd party analysers with SonarQube, with different situations:
  - A 3rd party analyzer whose custom output format is natively recognized by SonarQube because this is a very popular analyzer (pylint)
  - A 3rd party analyzer that generates a report in the nbormalized SARIF format natively recognized by SonarQube (checkov)
  - Two 3rd party analyzers that generate a report in a custom format not natively recognized by SonarQube and that therefore need conversion to the SonarQube [generic issue report format](https://docs.sonarsource.com/sonarqube-server/latest/analyzing-source-code/importing-external-issues/generic-issue-import-format/) (**trivy** and **shellcheck**).
  For those 2 a simple script converts the original tool format into the SonarQube format


Prerequisites:
- SonarQube Developer Edition or higher, and Scanner
- Docker runtime
- Python 3.9 or higher and `pip` installed
- 3rd party analyzers installed:
  - **Pylint** (Python linter) - Automatically installed at first scan if not already installed
  - **Shellcheck** (Shell linter) - Automatically installed (MacOS) at first scan if not already installed
    See https://github.com/koalaman/shellcheck?tab=readme-ov-file#installing in case of problems
  - **Checkov** (Docker linter) - Automatically installed at first scan if not already installed
    See https://www.checkov.io/2.Basics/Installing%20Checkov.html in case of problem
  - **Trivy** (Docker image analyzer):  - Automatically installed (MacOS) at first scan if not already installed
  See https://trivy.dev/v0.18.3/installation/ in case of problem

All prerequisites except SonarQube and Docker can be automatically installed by running `./install.sh`

Demo Scenario
- 