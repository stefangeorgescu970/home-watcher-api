#!/bin/bash

# Helper script for building the code. 
# This example is very simple but more complex builds could be encapsulated here.

echo "LOG - Importing required methods from helper files."

. ./buildScripts/helpers/functions/build_lambda.sh

echo "LOG - Finished importing."

buildLambda src

