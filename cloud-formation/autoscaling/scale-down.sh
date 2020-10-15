#!/bin/bash

set -x
# set -ex

# Deploys the ASG
# Usage: scale-down.sh <cf-stack-name> |tee /dev/fd/3 
 
CFN_STACK_NAME="$1"

# Delete CFN Stack
echo "Deleling Stack"
aws cloudformation delete-stack --stack-name $CFN_STACK_NAME 
    
# wait until the command is complete
aws cloudformation wait stack-delete-complete --stack-name $CFN_STACK_NAME
