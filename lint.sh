#!/bin/bash

ROOTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
BUILDDIR="$ROOTDIR/build"
[ ! -d "$BUILDDIR" ] && mkdir "$BUILDDIR"
rm -rf -- ${BUILDDIR:?"."}/* */__pycache__ */*.pyc

echo "======= BUILDING PYTHON PACKAGE ========="
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

echo "===> Running shellcheck and converting to SonarQube generic format on-the-fly"
shellcheckReport="$BUILDDIR/external-issues-shellcheck.json"
shellcheck "$ROOTDIR"/*.sh -s bash -f json | "$ROOTDIR"/shellcheck2sonar.py >"$shellcheckReport"

echo "===> Running checkov"
checkov -d . --framework dockerfile -o sarif --output-file-path "$BUILDDIR"

echo "===> Running trivy"
trivyReport="$BUILDDIR/external-issues-trivy.json"
trivy image -f json -o "$BUILDDIR"/trivy_results.json olivierkorach/hello-world:latest
echo "===> Converting trivy report to SonarQube generic format"
python3 "$ROOTDIR"/trivy2sonar.py < "$BUILDDIR"/trivy_results.json > "$trivyReport"
