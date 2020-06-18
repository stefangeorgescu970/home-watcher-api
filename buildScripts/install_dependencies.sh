#!/bin/bash

set -e

echo "LOG - Installing deploy dependencies."

pip install --upgrade pip
pip install awscli
sudo apt-get install jq

echo "LOG - Deploy dependencies installed."