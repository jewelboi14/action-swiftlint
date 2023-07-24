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
    git fetch --prune --no-tags origin "+refs/heads/${{ github.base_ref }}:refs/heads/${{ github.base_ref }}"
    changedFiles=$(git diff --name-only $(git merge-base ${GITHUB_BASE_REF} ${GITHUB_HEAD_REF})..${GITHUB_HEAD_REF})
    echo "changed files $changedFiles"

    if [ -z "$changedFiles" ]
    then
        echo "No Swift file changed"
        exit
    fi
fi
set -o pipefail && swiftlint "$@" -- $changedFiles | stripPWD | convertToGitHubActionsLoggingCommands
