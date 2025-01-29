#!/bin/bash

ROOTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
BUILDDIR="$ROOTDIR/build"
[ ! -d "$BUILDDIR" ] && mkdir "$BUILDDIR"
rm -rf -- ${BUILDDIR:?"."}/* */__pycache__ */*.pyc

echo "======= BUILDING PYTHON PACKAGE ========="
pip3 install -r requirements-to-build.txt
python3 "$ROOTDIR/setup.py" bdist_wheel >/dev/null

echo "======= BUILDING DOCKER IMAGE WITH PYTHON PACKAGE ========="
docker build -t "olivierkorach/hello-world:1.0-snapshot" -t olivierkorach/hello-world:latest -f "$ROOTDIR/Dockerfile" "$ROOTDIR" --load

echo "===> Running pylint"
pylintReport="$BUILDDIR/pylint-report.out"
pylint --rcfile "$ROOTDIR"/pylintrc "$ROOTDIR"/*.py "$ROOTDIR"/*/*.py -r n --msg-template="{path}:{line}: [{msg_id}({symbol}), {obj}] {msg}" > "$pylintReport"
re=$?
if [ "$re" == "32" ]; then
    >&2 echo "ERROR: pylint execution failed, errcode $re, aborting..."
    exit $re
fi

# If Shellcheck is not installed, try to install on the fly

if [ ! which shellcheck >/dev/null ]; then
    echo "===> Installing shellcheck"
    brew install shellcheck
fi

echo "===> Running shellcheck"
shellcheckReport="$BUILDDIR/external-issues-shellcheck.json"
shellcheck "$ROOTDIR"/*.sh -s bash -f json | "$ROOTDIR"/shellcheck2sonar.py >"$shellcheckReport"

# Checkov is installed in the build python package step
echo "===> Running checkov"
checkov -d . --framework dockerfile -o sarif --output-file-path "$BUILDDIR"

# If Trivy is not installed, try to install on the fly
if [ ! which trivy >/dev/null ]; then
    echo "===> Installing trivy"
    brew install aquasecurity/trivy/trivy
fi

echo "===> Running trivy"
trivyReport="$BUILDDIR/external-issues-trivy.json"
trivy image -f json -o "$BUILDDIR"/trivy_results.json olivierkorach/hello-world:latest
python3 "$ROOTDIR"/trivy2sonar.py < "$BUILDDIR"/trivy_results.json > "$trivyReport"
