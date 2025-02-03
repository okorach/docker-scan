#!/bin/bash

ROOTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
BUILDDIR="$ROOTDIR/build"
YELLOW=$(tput setaf 3)
GREEN=$(tput setaf 2)
RESET=$(tput setaf 7)

function log {
    echo -e "${GREEN}$*${RESET}"
}
function logcmd {
    echo -e "${YELLOW}$*${RESET}"
}

[ ! -d "$BUILDDIR" ] && mkdir "$BUILDDIR"
rm -rf -- ${BUILDDIR:?"."}/* */__pycache__ */*.pyc

if [[ ! "$(which python3)" =~ ^.*venv/bin/python3$ ]]; then
    # Activate python virtual env
    . venv/bin/activate
fi

log "\n======= BUILDING PYTHON PACKAGE ========="
logcmd python3 -m build "\n"
python3 -m build >/dev/null

log "\n======= BUILDING DOCKER IMAGE WITH PYTHON PACKAGE ========="
logcmd docker build -t "$DOCKER_USER/hello-world:1.0-snapshot" -t $DOCKER_USER/hello-world:latest -f "$ROOTDIR/Dockerfile" "$ROOTDIR" --load "\n"
docker build -t "$DOCKER_USER/hello-world:1.0-snapshot" -t "$DOCKER_USER/hello-world:latest" -f "$ROOTDIR/Dockerfile" "$ROOTDIR" --load

log "\n======= Running pylint ======="
pylintReport="$BUILDDIR/pylint-report.out"
logcmd pylint --rcfile "$ROOTDIR"/pylintrc "$ROOTDIR"/*.py "$ROOTDIR"/*/*.py -r n --msg-template="{path}:{line}: [{msg_id}({symbol}), {obj}] {msg}" \> "$pylintReport" "\n"

pylint --rcfile "$ROOTDIR"/pylintrc "$ROOTDIR"/*.py "$ROOTDIR"/*/*.py -r n --msg-template="{path}:{line}: [{msg_id}({symbol}), {obj}] {msg}" > "$pylintReport"
re=$?
if [ "$re" == "32" ]; then
    >&2 echo "ERROR: pylint execution failed, errcode $re, aborting..."
    exit $re
fi

log "\n======= Running shellcheck and converting to SonarQube generic format on-the-fly ======"

shellcheckReport="$BUILDDIR/generic-shellcheck.json"
logcmd shellcheck "$ROOTDIR"/\*.sh -s bash -f json \| "$ROOTDIR"/shellcheck2sonar.py \> "$shellcheckReport" "\n"
shellcheck "$ROOTDIR"/*.sh -s bash -f json | "$ROOTDIR"/shellcheck2sonar.py >"$shellcheckReport"

log "\n=======  Running checkov ======="

logcmd checkov -d . --framework dockerfile -o sarif --output-file-path "$BUILDDIR" "\n"
checkov -d . --framework dockerfile -o sarif --output-file-path "$BUILDDIR" >/dev/null

log "\n======= Running trivy ======="

trivyReport="$BUILDDIR/generic-trivy.json"
logcmd "trivy image -f json -o "$BUILDDIR"/trivy_results.json olivierkorach/hello-world:latest\n"
trivy image -f json -o "$BUILDDIR"/trivy_results.json olivierkorach/hello-world:latest

log "\n======= Converting trivy report to SonarQube generic format ======="
logcmd python "$ROOTDIR"/trivy2sonar.py \< "$BUILDDIR"/trivy_results.json \> "$trivyReport" "\n"
python "$ROOTDIR"/trivy2sonar.py < "$BUILDDIR"/trivy_results.json > "$trivyReport"
