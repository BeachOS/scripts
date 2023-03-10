#!/bin/bash
#
# SPDX-FileCopyrightText: 2017, 2020-2022 The LineageOS Project
# SPDX-FileCopyrightText: 2021-2022 The Beach Institute
#
# SPDX-License-Identifier: Apache-2.0
#

usage() {
    echo "Usage ${0} -n <newtag> -b <upstream-branch> --lineage"
}

# Verify argument count
if [ "${#}" -eq 0 ]; then
    usage
    exit 1
fi

LINEAGE=false

while [ "${#}" -gt 0 ]; do
    case "${1}" in
        -n | --new-tag )
                NEWTAG="${2}"; shift
                ;;
        -b | --upstream-branch )
                UPSTREAMBRANCH="${2}"; shift
                ;;
        -l | --lineage )
                LINEAGE=true; shift
                ;;
        * )
                usage
                exit 1
                ;;
    esac
    shift
done

### CONSTANTS ###
readonly script_path="$(cd "$(dirname "$0")";pwd -P)"
readonly vars_path="${script_path}/../vars"

source "${vars_path}/common"

TOP="${script_path}/../../.."

# Source build environment (needed for beachremote)
source "${TOP}/build/envsetup.sh"

# List of merged repos
PROJECTPATHS=$(cat ${MERGEDREPOS} | grep -w merge | awk '{printf "%s\n", $2}')

read -p "Press enter to begin pushing upstream branch."

# Make sure manifest and forked repos are in a consistent state
echo "#### Verifying there are no uncommitted changes on forked AOSP projects ####"
for PROJECTPATH in ${PROJECTPATHS} .repo/manifests; do
    cd "${TOP}/${PROJECTPATH}"
    if [[ -n "$(git status --porcelain)" ]]; then
        echo "Path ${PROJECTPATH} has uncommitted changes. Please fix."
        exit 1
    fi
done
echo "#### Verification complete - no uncommitted changes found ####"

# Iterate over each forked project
for PROJECTPATH in ${PROJECTPATHS}; do
    cd "${TOP}/${PROJECTPATH}"
    if [ "${LINEAGE}" = true ]; then
        if grep -q "${lineageos_branch}" .gitupstream-lineage; then
            UPSTREAMBRANCH="$(cat .gitupstream-lineage | cut -d ' ' -f 2)"
        else
            UPSTREAMBRANCH="${lineageos_branch}"
        fi
    fi
    echo "#### Pushing upstream branch ${UPSTREAMBRANCH} for ${PROJECTPATH} ####"
    beachremote | grep -v "Remote 'beach' created"
    if [ "${LINEAGE}" = true ]; then
        git push beach lineage/${UPSTREAMBRANCH}:refs/heads/upstream/${UPSTREAMBRANCH}
    else
        git push beach ${NEWTAG}^{commit}:refs/heads/upstream/${UPSTREAMBRANCH}
    fi
done
