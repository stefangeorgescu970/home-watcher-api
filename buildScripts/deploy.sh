#!/bin/bash

# Arguments received by script

# $1 - environment in which the Lambda Should be Deployed. Can be either dev or stg.

set -e

echo "LOG - Importing required methods from helper files."

. ./buildScripts/helpers/functions/deploy_lambda.sh
. ./buildScripts/helpers/constants.sh
. ./buildScripts/helpers/functions/get_property_from_file.sh

echo "LOG - Finished importing."

# Processing script variables.
deploy_env=$1
lambda_full_name="${lambda_base_name}-${deploy_env}"

# Setting aws_profile to the required values to be later used with the aws-cli.
if [ "${deploy_env}" == "dev" ]; then
  aws_profile="default"
else
  aws_profile=${staging_profile}
fi

echo "LOG - Preparing to deploy. Fetching deployment information."
aws s3 cp "${s3_address}/${deploy_property_file}" ${deploy_property_file} --quiet --profile ${staging_profile}

echo "LOG - Received the following deployment information from artifact storage:"
cat ${deploy_property_file}

hotfix_in_progress=$(getPropertyFromFile ${deploy_property_file} "HOTFIX_IN_PROGRESS")

if [ "$hotfix_in_progress" = "false" ]; then
  echo "LOG - Hotfix not in progress. Deploying normally."
  deployLambda release "${lambda_full_name}" "${lambda_base_name}" "${aws_profile}" eu-central-1

  if [[ $TRAVIS_BRANCH =~ ^hotfix\/.*$ ]]; then
    echo "LOG - Hotfix branch detected. Updating deployment information to S3 artefact storage."
    echo "HOTFIX_IN_PROGRESS=true" > $deploy_property_file
    aws s3 cp ${deploy_property_file} "${s3_address}/${deploy_property_file}" --quiet --profile ${staging_profile}
  else
    echo "LOG - Hotfix branch not detected. No further action required."
  fi
else
  echo "LOG - Hotfix in progress."
  if [[ $TRAVIS_BRANCH =~ (^hotfix\/.*$|^development$) ]]; then
    echo "LOG - Deploying since we are on development or on a hotfix branch, which are permitted."
    deployLambda release "${lambda_full_name}" "${lambda_base_name}" "${aws_profile}" eu-central-1
  else
    echo "LOG - Skipping deployment since we are on a release branch during a hotfix."
  fi
fi
