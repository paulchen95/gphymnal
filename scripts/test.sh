#!/bin/bash
#
# Run the A2N Hymnal unit tests on an iOS simulator.
#
#   scripts/test.sh                                   # every test
#   scripts/test.sh HymnDataTests                     # one test class
#   scripts/test.sh HymnDataTests/testHymnsAreSorted  # one test
#   scripts/test.sh HymnParsingTests HymnDataTests    # several
#
# Environment:
#   SIMULATOR   simulator to run on (default: first available iPhone)
#   XCODEBUILD_ARGS   extra flags passed through to xcodebuild
#
set -euo pipefail

cd "$(dirname "$0")/.."

PROJECT="A2N Hymnal.xcodeproj"
SCHEME="A2N Hymnal"
TEST_TARGET="A2N HymnalTests"
LOG="${TMPDIR:-/tmp}"; LOG="${LOG%/}/a2n-hymnal-test.log"

# Xcode needs a concrete device, and the stock simulator set changes with every
# Xcode release, so resolve one instead of hardcoding a name.
if [[ -z "${SIMULATOR:-}" ]]; then
    SIMULATOR=$(xcrun simctl list devices available \
        | sed -n 's/^ *\(iPhone [^(]*\) (.*/\1/p' \
        | sed 's/ *$//' \
        | head -1)
fi
if [[ -z "$SIMULATOR" ]]; then
    echo "error: no iPhone simulator available. Install one in Xcode > Settings > Components," >&2
    echo "       or set SIMULATOR to a device from 'xcrun simctl list devices available'." >&2
    exit 1
fi

# Bare class or class/method names are qualified with the test target.
only_testing=()
for test in "$@"; do
    [[ "$test" == "$TEST_TARGET/"* ]] || test="$TEST_TARGET/$test"
    only_testing+=("-only-testing:$test")
done

echo "==> Testing on $SIMULATOR${1:+ (${*})}"

set +e
xcodebuild test \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -destination "platform=iOS Simulator,name=$SIMULATOR" \
    ${only_testing[@]+"${only_testing[@]}"} \
    ${XCODEBUILD_ARGS:-} 2>&1 \
    | tee "$LOG" \
    | grep -E "error:|warning:|failed \(|Executed .* tests|\*\* (TEST|BUILD)"
status=${PIPESTATUS[0]}
set -e

if [[ $status -ne 0 ]]; then
    echo
    echo "Tests failed. Full log: $LOG"
fi
exit $status
