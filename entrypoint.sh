#!/bin/bash

function stripPWD() {
    if ! ${WORKING_DIRECTORY+false};
    then
        cd - > /dev/null
    fi
    sed -E "s/$(pwd|sed 's/\//\\\//g')\///"
}

function convertToGitHubActionsAnnotations() {
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
    git fetch --prune --no-tags origin "+refs/heads/${GITHUB_BASE_REF}:refs/heads/${GITHUB_BASE_REF}"
    changedFiles=$(git diff --name-only $(git merge-base ${GITHUB_BASE_REF} ${GITHUB_HEAD_REF})..${GITHUB_HEAD_REF})
    echo "changed files $changedFiles"

    if [ -z "$changedFiles" ]
    then
        echo "No Swift file changed"
        exit
    fi
fi

# Lint the changed Swift files
set -o pipefail && swiftlint "$@" -- $changedFiles | stripPWD | convertToGitHubActionsAnnotations
