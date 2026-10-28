#!/usr/bin/env bash
#	Runs a CFHarness suite on a running server and reports the outcome as an exit code.
#
#	Usage: run-suite.sh <run.cfm URL> [TestName]
#	  e.g. run-suite.sh https://localhost:8282/test/run.cfm RestServiceTest
#
#	Prints each failed assertion and a summary line. Exits 0 when every assertion passes, 1 when
#	any fails and 2 when the suite could not run or ran no assertions.

set -uo pipefail

if [[ $# -lt 1 ]]; then
	echo 'Usage: run-suite.sh <run.cfm URL> [TestName]' >&2
	exit 2
fi

suite_url="$1"
test_name="${2:-}"

report="$(mktemp)"
trap 'rm -f "$report"' EXIT

#	Test servers use self-signed certificates, hence --insecure.
status="$(curl --silent --insecure --max-time 600 \
	--header 'Accept: text/plain' \
	--output "$report" --write-out '%{http_code}' \
	"${suite_url}${test_name:+/$test_name}")"

summary="$(tail -n 1 "$report")"
summary_pattern='^([0-9]+) assertions, [0-9]+ passed, ([0-9]+) failed$'

if [[ "$status" != 200 || ! "$summary" =~ $summary_pattern ]]; then
	echo "The suite did not return results (HTTP $status). Start of the response:" >&2
	head -c 2000 "$report" >&2
	echo >&2
	exit 2
fi

cat "$report"
echo

if (( BASH_REMATCH[1] == 0 )); then
	echo 'No assertions ran.' >&2
	exit 2
fi

(( BASH_REMATCH[2] == 0 ))
