# docker scanning example

## Purpose
This repository demonstrates 2 different use cases:
- How to perform a docker scan with SonarQube and how to complement with 3rd party analyzers
(Trivy and Checkov in the current case)
- More generally speaking how to integrate results of multiple 3rd party analysers with SonarQube, with 3 different situations:
  - A 3rd party analyzer whose custom output format is natively recognized by SonarQube because this is a very popular analyzer (pylint)
  - A 3rd party analyzer that generates a report in the normalized SARIF format natively recognized by SonarQube (checkov)
  - Two 3rd party analyzers that generate a report in a custom format not natively recognized by SonarQube and that therefore need conversion to the SonarQube [generic issue report format](https://docs.sonarsource.com/sonarqube-server/latest/analyzing-source-code/importing-external-issues/generic-issue-import-format/) (**trivy** and **shellcheck**).
  For those 2 a simple script converts the original tool format into the SonarQube format


## Prerequisites:
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

## Set up / Initial installation
After cloning the repository, all prerequisites except SonarQube and Docker can be automatically installed by running `./install.sh`.
To be done once for all on each machine where the demo may need to be run

## Demo Scenario
- make sure your **$SONAR_URL_URL** and **$SONAR_TOKEN** environment variables are pointing to the SonarQube instance you want to use for the demo
- Run `./lint.sh`
  This should:
  - Build an `hello-world` python package
  - Build an `hello-world` docker image wrapping the python package
  - Run all 3rd party analyzers: `pylint`, `shellcheck`, `trivy`, `checkov`

- You may show the output reports of all the linters in the `build` directory

- Run `sonar-scanner`:
  This will run the SonarQube scan, and combine the sonar-scanner results with the 3rd party analyzers results.
  You may show that the `sonar-project.properties` file is pointing at the 3rd party analyzer results in the `build` directory
```
# Pylint issue report, pylint native format supported by SonarQube
sonar.python.pylint.reportPaths=build/pylint-report.out

# Checkov issues, SARIF format supported by SonarQube
sonar.sarifReportPaths=build/results_sarif.sarif

# Shellcheck and Trivy issues, original reports converted to SonarQube generic issue format
sonar.externalIssuesReportPaths=build/generic-shellcheck.json, build/generic-trivy.json
```

- Browse your SonarQube instance and to the the **Docker Hello World** project
- Show the found issues (on overall code to not miss any)
  There are issues in the python code (irrelevant for the docker demo, just to show that everything is scanned in one go)
  and issues in Docker (you may filter by the `docker` language in the left pane)
- The docker issues are coming from several sources:
  - SonarQube native scan
  - Trivy (have a **TRIVY** tag on the issue)
  - Checkov (have a **CHECKOV** tag on the issue)

- If you want to go beyond and show how you fix the issues:
  - You may change to the `docker-fixes` repository branch that has all the fixes
  - Run `.lint.sh` then `sonar-scanner -Dsonar.branch.name=docker-fixes` again
```
git checkout docker-fixes
./lint.sh
sonar-scanner -Dsonar.branch.name=docker-fixes
```
  - Browse to SonarQube and show the `docker-fixes` branch with an almost spotless `Dockerfile`.
    There is 1 docker maintability issue, that is better not fix for the demo, otherwise all vulnerabilities have been solved