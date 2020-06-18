# Method for building Lambda Functions.
# Prerequisites:
# 1. Code must be given as a single python file called lambda.py. This is highly coupled with the definition 
# of the Lambda Function. See the README.md for a link to the repository containing infrastructure setup.
# 2. If the code has any external dedpendencies, they must be placed in a requirements.txt file within the same directory.

# This method first zips the lambda.py file and then checks if dependencies are present. If they are present, it installs
# and packages those as well.

# Received parameters:
# $1 - Path to Lambda directory from the current working directory.

function buildLambda {
  set -e

  lambda_path=$1

  cd "${lambda_path}"

  echo "LOG - Beginning Lambda Packaging."

  req_file="requirements.txt"
  current_dir=$(pwd)

  echo "LOG - Zipping lambda code."
  zip -rq lambda.zip lambda.py

  # Checking if the requirements file is present and not empty.
  if [ -f $req_file -a -s $req_file ]; then
    echo "LOG - ${req_file} file exists and is not empty within ${current_dir}. Installing dependencies."

    pkg_dir="python"

    rm -rf ${pkg_dir} && mkdir -p ${pkg_dir}

	# Running pip install within a docker image simulating the AWS Lambda Environment. 
	# Highly recommended in order to avoid dependency issues when invoking the Lambda Function.
    docker run -rm -v $(pwd):/foo lambci/lambda:build-python3.8
    \
    pip install -r ${req_file} -t ${pkg_dir}

    echo "LOG - Installation complete. Zipping."
    mkdir -p dependencies
    zip -rq dependencies/lambda_layer_deps.zip ${pkg_dir}
    rm -rf ${pkg_dir}
  else
    echo "LOG - Skipping dependency packaging since ${req_file} file does not exist or is empty within ${current_dir}"
  fi
}