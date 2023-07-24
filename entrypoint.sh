#!/bin/bash

# convert swiftlint's output into GitHub Actions Logging commands
# https://help.github.com/en/github/automating-your-workflow-with-github-actions/development-tools-for-github-actions#logging-commands

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

# Fetch the base_ref from the remote and update the local branch
git fetch --prune --no-tags --depth=1 origin +refs/heads/${{ github.base_ref }}:refs/heads/${{ github.base_ref }}
git checkout ${{ github.base_ref }}

# Compare the base_ref with the current branch (HEAD) to get changed files
changedFiles=$(git --no-pager diff --name-only --relative ${{ github.base_ref }} HEAD)

if [ -z "$changedFiles" ]; then
    echo "No files changed"
    exit
fi

set -o pipefail && swiftlint "$@" -- $changedFiles | stripPWD | convertToGitHubActionsLoggingCommands
