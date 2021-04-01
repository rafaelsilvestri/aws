#!/bin/bash

CFN_STACK_NAME=RequestSpotFleetApi
CFN_FILE_NAME=cfn-spotfleet-template.yaml

#aws cloudformation validate-template --template-body file://$CFN_FILE_NAME

aws cloudformation deploy \
    --stack-name $CFN_STACK_NAME \
    --template-file $CFN_FILE_NAME \
    --capabilities CAPABILITY_IAM

# Display Output
echo "Outputs:"
aws cloudformation describe-stacks --stack-name $CFN_STACK_NAME --query 'Stacks[0].Outputs'
