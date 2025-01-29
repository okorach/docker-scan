#!/bin/bash
#
# sonar-tools
# Copyright (C) 2019-2025 Olivier Korach
# mailto:olivier.korach AT gmail DOT com
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 3 of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public License
# along with this program; if not, write to the Free Software Foundation,
# Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#

# ME="$( basename "${BASH_SOURCE[0]}" )"
ROOTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
buildDir="$ROOTDIR/build"
[ ! -d "$buildDir" ] && mkdir "$buildDir"
rm -rf -- ${buildDir:?"."}/* */__pycache__ */*.pyc

echo "======= BUILDING PYTHON PACKAGE ========="
python3 "$ROOTDIR/setup.py" bdist_wheel >/dev/null

echo "======= BUILDING DOCKER IMAGE WITH PYTHON PACKAGE ========="
docker build -t "olivierkorach/hello-world:1.0-snapshot" -t olivierkorach/hello-world:latest -f "$ROOTDIR/Dockerfile" "$ROOTDIR" --load

echo "===> Running pylint"
pylintReport="$buildDir/pylint-report.out"
pylint --rcfile "$ROOTDIR"/pylintrc "$ROOTDIR"/*.py "$ROOTDIR"/*/*.py -r n --msg-template="{path}:{line}: [{msg_id}({symbol}), {obj}] {msg}" > "$pylintReport"
re=$?
if [ "$re" == "32" ]; then
    >&2 echo "ERROR: pylint execution failed, errcode $re, aborting..."
    exit $re
fi

echo "===> Running shellcheck"
shellcheckReport="$buildDir/external-issues-shellcheck.json"
shellcheck "$ROOTDIR"/*.sh -s bash -f json | "$ROOTDIR"/shellcheck2sonar.py >"$shellcheckReport"

echo "===> Running checkov"
checkov -d . --framework dockerfile -o sarif --output-file-path "$buildDir"

echo "===> Running trivy"
trivyReport="$buildDir/external-issues-trivy.json"
trivy image -f json -o "$buildDir"/trivy_results.json olivierkorach/hello-world:latest
python3 "$ROOTDIR"/trivy2sonar.py < "$buildDir"/trivy_results.json > "$trivyReport"
