# Method for deploying Lambda Functions.
# Prerequisites:
# 1. Lambda Function code has been packaged in .zip files and placed in a single directory.

# Received parameters:

# $1 - Release files directory path compared to current working directory;
# $2 - Name of lambda function in AWS environment;
# $3 - The base name of the files containing the lambda function. The dependencies archive will have a -deps suffix;
# $3 - AWS profile to use with the aws cli;
# $4 - AWS region.

function deployLambda {
  set -e
  
  lambda_path=$1
  lambda_aws_name=$2
  lambda_file_name=$3
  aws_profile=$4
  aws_region=$5

  echo "LOG - Deploying Lambda ${lambda_aws_name} to AWS with profile ${aws_profile}"

  # Required environment variables for the aws-cli. Used export in this context for brevity of the aws lambda command later.
  export AWS_PROFILE=${aws_profile}
  export AWS_DEFAULT_REGION=${aws_region}

  cd "${lambda_path}"

  if [ -f "${lambda_file_name}-deps.zip" ]; then
    echo "LOG - Found Lambda dependencies. Creating Lambda Layer."

	# Publishing lambda layer and keeping the version ARN for updating the function.
    layer_version_arn=$(aws lambda publish-layer-version --layer-name "dependencies-${lambda_aws_name}" --zip-file fileb://./${lambda_file_name}-deps.zip --compatible-runtimes python3.8 | jq -r .LayerVersionArn)

	# Updating the function configuration to ue the latest published layer.
    aws lambda update-function-configuration --function-name "${lambda_aws_name}" --layers ${layer_version_arn}
  fi

  echo "LOG - Updating function code."
  aws lambda update-function-code --function-name "${lambda_aws_name}" --zip-file fileb://./${lambda_file_name}.zip
}