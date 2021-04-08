#!/bin/bash

curl -X POST \
    -H "Content-Type: application/json" \
    -d '{"ClientToken": "15","TargetCapacity": 1,"ImageId": "ami-0742b4e673072066f","MinvCPU": 1,"MaxvCPU": 2,"KeyName":"ec2-tr","AllocationStrategy":"capacityOptimized"}' \
    https://cg71v7chi6.execute-api.us-east-1.amazonaws.com/v1/spotfleet
