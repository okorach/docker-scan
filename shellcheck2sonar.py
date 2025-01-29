#!/usr/bin/env python3
#
"""

    Converts shellcheck JSON format to Sonar external issues format

"""
import sys
import json

SHELLCHECK = "shellcheck"
MAPPING = {"INFO": "INFO", "LOW": "MINOR", "MEDIUM": "MAJOR", "HIGH": "CRITICAL", "BLOCKER": "BLOCKER"}


def main() -> None:
    """Main script entry point"""
    text = "".join(sys.stdin)

    rules_dict = {}
    issue_list = []

    for issue in json.loads(text):
        sonar_issue = {
            "ruleId": f"{SHELLCHECK}:{issue['code']}",
            "effortMinutes": 5,
            "primaryLocation": {
                "message": issue["message"],
                "filePath": issue["file"],
                "textRange": {
                    "startLine": issue["line"],
                    "endLine": issue["endLine"],
                    "startColumn": issue["column"] - 1,
                    "endColumn": max(issue["column"], issue["endColumn"] - 1),
                },
            },
        }
        issue_list.append(sonar_issue)
        if issue["level"] in ("info", "style"):
            sev_mqr = "LOW"
        elif issue["level"] == "warning":
            sev_mqr = "MEDIUM"
        else:
            sev_mqr = "HIGH"
        rules_dict[f"{SHELLCHECK}:{issue['code']}"] = {
            "id": f"{SHELLCHECK}:{issue['code']}",
            "name": f"{SHELLCHECK}:{issue['code']}",
            "engineId": SHELLCHECK,
            "type": "CODE_SMELL",
            "cleanCodeAttribute": "LOGICAL",
            "severity": MAPPING[sev_mqr],
            "impacts": [{"softwareQuality": "MAINTAINABILITY", "severity": sev_mqr}],
        }

    external_issues = {"rules": list(rules_dict.values()), "issues": issue_list}
    print(json.dumps(external_issues, indent=3, separators=(",", ": ")))


if __name__ == "__main__":
    main()
