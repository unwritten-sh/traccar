#!/usr/bin/env bash
# The project's own test command (./gradlew test) on the base commit, with the JDK the harness found
# (tools/harness/java-home.sh). Gradle prints no test summary: counts come from the JUnit XML reports.
# DIFF=<file> applies a diff first (the control arm).
set -u
repo="$PWD/repo"; d="$PWD/own-tree"
git -C "$repo" worktree remove --force "$d" 2>/dev/null; rm -rf "$d"
git -C "$repo" worktree add -q --detach "$d" "$(jq -r .base_sha meta.json)"
[ -n "${DIFF:-}" ] && git -C "$d" apply "$DIFF" && echo "applied $DIFF"
export JAVA_HOME="$("$repo/tools/harness/java-home.sh")" CI=1
cd "$d"; echo "JAVA_HOME=$JAVA_HOME"; start=$(date +%s)
./gradlew --console=plain test --rerun > gradle.log 2>&1; code=$?
tail -5 gradle.log
python3 - <<'PY'
import glob, xml.etree.ElementTree as ET
t=s=f=0
for p in glob.glob('build/test-results/test/*.xml'):
    r=ET.parse(p).getroot(); t+=int(r.get('tests',0)); s+=int(r.get('skipped',0)); f+=int(r.get('failures',0))+int(r.get('errors',0))
print(f"xml: ran {t} skipped {s} failed {f}")
PY
echo "exit $code seconds $(( $(date +%s) - start ))"
cd ..; git -C "$repo" worktree remove --force "$d"
