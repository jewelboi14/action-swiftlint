#!/bin/bash

function stripPWD() {
    if [ -n "${WORKING_DIRECTORY}" ];
    then
        cd "${WORKING_DIRECTORY}" || exit 1
    fi
    sed -E "s/$(pwd|sed 's/\//\\\//g')\///"
}

function convertToGitHubActionsLoggingCommands() {
    sed -E 's/^(.*):([0-9]+):([0-9]+): (warning|error|[^:]+): (.*)/::\4 file=\1,line=\2,col=\3::\5/'
}

# Set safe.directory for git
git config --global --add safe.directory "$PWD"

# Fetch the base_ref from the remote and update the local branch
git fetch --prune --no-tags --depth=1 origin "+refs/heads/${BASE_REF}:refs/heads/${BASE_REF}"
git checkout "${BASE_REF}"

# Compare the base_ref with the current branch (HEAD) to get changed files
changedFiles=$(git --no-pager diff --name-only --relative "${BASE_REF}" HEAD)

if [ -z "$changedFiles" ]; then
    echo "No files changed"
    exit
fi

# Run SwiftLint on changed files
set -o pipefail && swiftlint "$@" -- $changedFiles | stripPWD | convertToGitHubActionsLoggingCommands
