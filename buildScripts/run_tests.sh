#!/bin/bash

set -e 

echo "LOG - Performing tests."

# Here, tests is the name of the subdirectory in which the test classes are provided.
python -m unittest discover tests -v

echo "LOG - All tests successful."