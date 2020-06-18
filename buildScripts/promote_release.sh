#!/bin/bash

set -e

echo "LOG - Importing required methods and constants from helper files."

. ./buildScripts/helpers/functions/deploy_lambda.sh
. ./buildScripts/helpers/functions/get_property_from_file.sh
. ./buildScripts/helpers/constants.sh
. ./buildScripts/helpers/functions/get_latest_version_from_artifact_store.sh

echo "LOG - Finished importing."

echo "LOG - Preparing to deploy to production. Fetching deployment information."
aws s3 cp "${s3_address}/${deploy_property_file}" ${deploy_property_file} --quiet --profile ${staging_profile}

echo "LOG - Received the following deployment information from artifact storage:"
cat ${deploy_property_file}

hotfix_release=$(getPropertyFromFile ${deploy_property_file} "HOTFIX_IN_PROGRESS")
version_to_release=$(getLatestVersionFromArtifactStore ${artifact_bucket} ${repository_key} ${hotfix_release})

# Added check for Travis run, to prevent git config being overwritten in case this script is run locally.
if [ "$TRAVIS" == "true" ]; then
  echo "LOG - Configuring local git for release tagging."
  git config --local user.name "travis-builder"
  git config --local user.email "contact@stefangeorgescu.com"
fi

# Tagging is required for the release deploy provider.
echo "LOG - Tagging commit for realse with number ${version_to_release}"
git tag ${version_to_release}

echo "LOG - Fetching artifacts for release."
mkdir -p release
aws s3 cp "${s3_address}/${version_to_release}" release --recursive --quiet --profile ${staging_profile}

if [ "$hotfix_release" = "false" ]; then
  # If this was not a hotfix release, simply promote to prod. Nothing else needs to be done.

  deployLambda release "${lambda_base_name}-prod" "${lambda_base_name}" prod eu-central-1
else
  # Otherwise, deploy to production the hotfix.
 
  deployLambda release "${lambda_base_name}-prod" "${lambda_base_name}" prod eu-central-1

  # Fetch the latest released version from the artifact store.
  latest_version_for_release=$(getLatestVersionFromArtifactStore ${artifact_bucket} ${repository_key} "false")

  # Retrieve the latest package for deployment.
  rm -rf release
  echo "LOG - Fetching artefacts from release version ${latest_version_for_release} to reconstruct staging environment."
  mkdir -p release
  aws s3 cp "${s3_address}/${latest_version_for_release}" release --recursive --quiet --profile ${staging_profile}

  # Deploy latest release to the staging environment.
  deployLambda release "${lambda_base_name}-stg" "${lambda_base_name}" stg eu-central-1

  # Set the HOTFIX_IN_PROGRESS flag to false in the repository metadata.
  echo "HOTFIX_IN_PROGRESS=false" > $deploy_property_file
  aws s3 cp ${deploy_property_file} "${s3_address}/${deploy_property_file}" --quiet --profile ${staging_profile}
fi