# Method for processing a .properties file and retrieving values by key.

# Received parameters:

# $1 - File Path;
# $2 - Property Key.

function getPropertyFromFile {
  set -e

  file_path=$1
  property_key=$2
  
  property_value=`cat "${file_path}" | grep "${property_key}" | cut -d'=' -f2`
  echo $property_value
}