#!/bin/bash

echo "======= Installing prerequisites ========="

# Install pylint, checkov
pip3 install --upgrade pip
pip3 install -r requirements-to-build.txt

echo "===> Installing shellcheck (Assuming MacOS)"
if ! which shellcheck >/dev/null; then
    brew install shellcheck
fi

echo "===> Installing trivy (Assuming MacOS)"
if ! which trivy >/dev/null; then
    brew install aquasecurity/trivy/trivy
fi
