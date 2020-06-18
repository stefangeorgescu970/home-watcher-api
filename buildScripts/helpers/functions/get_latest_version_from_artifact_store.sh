# Method for parsing the subdirectories in the artifact store and retrieving the latest version.

# Received parameters:

# $1 - Artifact Bucket;
# $2 - Repository key in Arifact Bucket;
# $3 - Wheter we are during a hotfix build;
#           true - we are releasing a hotfix build;
#           false - we are releasing a normal build.


function getLatestVersionFromArtifactStore {
  artifact_bucket=$1
  repository_key=$2
  hotfix_release=$3

  versions=`aws s3api list-objects --bucket ${artifact_bucket} --prefix ${repository_key} --profile stg | jq --raw-output ".Contents | map(.Key) | flatten[]" | cut -d"/" -f2 | uniq | grep -v properties | sort -r `
  if [ "$hotfix_release" = "false" ]; then
    echo `echo $versions | tr " " "\n" | grep -v "_" | head -n 1`
  else
    echo `echo $versions | tr " " "\n" | grep "_" | head -n 1`
  fi
}