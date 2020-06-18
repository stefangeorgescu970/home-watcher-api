#!/bin/bash

set -e

echo "LOG - Importing required constants from helper files."

. ./buildScripts/helpers/constants.sh

echo "LOG - Finished importing."

# Method for processing the branch name, available in the TRAVIS_BRANCH environment variable.
# Will return the version number from a branch named <BRANCH_TYPE>/<RELEASE_NUMBER>.
# The implementation is highly coupled with the branch naming chosen, hence it is provided in
# this file and not separately, as the other methods used.

function getBranchReleaseVersion {
  echo "${TRAVIS_BRANCH}" | cut -d'/' -f2
}

echo "LOG - Starting Artefact Upload"

version_number=$(getBranchReleaseVersion)

echo "LOG - Uploading release with version number ${version_number}"
aws s3 cp release ${s3_address}/${version_number} --recursive --quiet --profile ${staging_profile}