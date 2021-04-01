#!/bin/bash

#echo 'Installing dependencies...'
#pip install package-name -t "/project-dir"

echo 'Zipping Lambda Function...'
zip dist.zip RequestSpotFleet.py 

echo 'Put on S3...'
aws s3api put-object \
  --bucket rafaelsilvestri.github.com-private-us-east-1 \
  --key functions/RequestSpotFleetFunction \
  --region us-east-1 \
  --body ./dist.zip