#!/usr/bin/env bash
#	Runs CFHarness's own suite in its Lucee 6 container.
#
#	Usage: ./run-tests.sh [TestName] [--down]
#	  TestName  run one test component, e.g. MockServiceTest; omit to run them all
#	  --down    stop the container afterwards; by default it keeps running so reruns are quick
#
#	Exit codes are those of run-suite.sh.

set -uo pipefail

cd "$(dirname "$0")"

test_name=''
stop_after=false
for arg in "$@"; do
	case "$arg" in
		--down) stop_after=true ;;
		*) test_name="$arg" ;;
	esac
done

export CFHARNESS_PORT="${CFHARNESS_PORT:-8181}"

if ! docker compose up --detach --build --wait; then
	echo 'The test container did not start.' >&2
	exit 2
fi

if $stop_after; then
	trap 'docker compose down' EXIT
fi

bash ./run-suite.sh "https://localhost:${CFHARNESS_PORT}/_test/run.cfm" "$test_name"
