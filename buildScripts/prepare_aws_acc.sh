#!/bin/bash

set -e

# Environment variables encrypted within Travis configuration.

# AWS_KEY_ID - id of the access key
# AWS_SECRET_KEY - secret key
# AWS_STG_ACCOUNT_ID - account id of the staging account.
# AWS_PROD_ACCOUNT_ID - account id of the production account.

echo "LOG - Importing required constants from helper files."

. ./buildScripts/helpers/constants.sh

echo "LOG - Finished importing."

# If statement added in case of accidental execution on local environment.
if [ "$TRAVIS" == "true" ]; then
  echo "LOG - Configuring AWS accounts."

  rm -f ~/.aws/config
  rm -f ~/.aws/credentials

  mkdir -p ~/.aws

  touch ~/.aws/config
  touch ~/.aws/credentials

  echo "[default]" >> ~/.aws/credentials
  echo "aws_access_key_id = ${AWS_KEY_ID}" >> ~/.aws/credentials
  echo "aws_secret_access_key = ${AWS_SECRET_KEY}" >> ~/.aws/credentials

  echo "[profile ${staging_profile}]" >> ~/.aws/config
  echo "role_arn = arn:aws:iam::$AWS_STG_ACCOUNT_ID:role/StagingEnvironmentAdminRole" >> ~/.aws/config
  echo "source_profile = default" >> ~/.aws/config

  echo "[profile ${prod_profile}]" >> ~/.aws/config
  echo "role_arn = arn:aws:iam::$AWS_PROD_ACCOUNT_ID:role/ProductionEnvironmentAdminRole" >> ~/.aws/config
  echo "source_profile = default" >> ~/.aws/config
fi
