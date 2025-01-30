#!/bin/bash

echo "======= Installing prerequisites ========="

# Setting up local python virtual environment
if [ ! -d ./venv ]; then
    # Create python virtual env venv
    python3 -m venv venv
fi
if [[ ! "$(which python3)" =~ ^.*venv/bin/python3$ ]]; then
    # Create python virtual env venv
    . venv/bin/activate
fi

# Install pylint, checkov in the python virtual env
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
