#!/bin/bash

function stripPWD() {
    if ! ${WORKING_DIRECTORY+false};
    then
        cd - > /dev/null
    fi
    sed -E "s/$(pwd|sed 's/\//\\\//g')\///"
}
function convertToGitHubActionsLoggingCommands() {
    sed -E 's/^(.*):([0-9]+):([0-9]+): (warning|error|[^:]+): (.*)/::\4 file=\1,line=\2,col=\3::\5/'
}
sh -c "git config --global --add safe.directory $PWD"
if ! ${WORKING_DIRECTORY+false};
then
	cd ${WORKING_DIRECTORY}
fi

if ! ${DIFF_BASE+false};
then
    # Find all Swift files in the repository
    changedFiles=$(git --no-pager diff --name-only --relative $(git merge-base ${GITHUB_BASE_REF} ${GITHUB_SHA})..${GITHUB_SHA} -- `git ls-files '*.swift'`)

    if [ -z "$changedFiles" ]
    then
        echo "No Swift file changed"
        exit
    fi
fi
set -o pipefail && swiftlint "$@" -- $changedFiles | stripPWD | convertToGitHubActionsLoggingCommands
