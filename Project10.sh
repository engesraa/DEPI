#!/bin/bash

# Variables
VPC_ID="vpc-09ffd3dddcdc78775"
PEER_VPC_ID="vpc-0b96f7b7ee43a6707"
ROUTE_TABLE_ID_1="rtb-048fbb68f0289207e"
ROUTE_TABLE_ID_2="rtb-03a8a34851c54b5f5"
LOG_GROUP_NAME="ShareVPCFlowLogs"
DELIVER_LOGS_PERMISSION_ARN="arn:aws:iam::848017974037:role/Vpc-flow-logs-Role"
FLOW_LOG_ID="fl-03a720d4d9c45bf55"
PEERING_CONNECTION_ID="pcx-09569d6c65f6fce60"
DESTINATION_CIDR_BLOCK_1="10.5.0.0/16"
DESTINATION_CIDR_BLOCK_2="10.0.0.0/16"
LOG_STREAM_NAME="eni-088ea5d11cf1e4c07-all"

# Create a VPC Peering Connection
aws ec2 create-vpc-peering-connection \
    --vpc-id $VPC_ID \
    --peer-vpc-id $PEER_VPC_ID \
    --tag-specifications 'ResourceType=vpc-peering-connection,Tags=[{Key=Name,Value=Lab-Peer}]'

# Accept the VPC Peering Connection
aws ec2 accept-vpc-peering-connection \
    --vpc-peering-connection-id $PEERING_CONNECTION_ID

# Create Routes for VPC Peering
aws ec2 create-route \
    --route-table-id $ROUTE_TABLE_ID_1 \
    --destination-cidr-block $DESTINATION_CIDR_BLOCK_1 \
    --vpc-peering-connection-id $PEERING_CONNECTION_ID

aws ec2 create-route \
    --route-table-id $ROUTE_TABLE_ID_2 \
    --destination-cidr-block $DESTINATION_CIDR_BLOCK_2 \
    --vpc-peering-connection-id $PEERING_CONNECTION_ID

# Create Flow Logs
aws ec2 create-flow-logs \
    --resource-type VPC \
    --resource-id $PEER_VPC_ID \
    --traffic-type ALL \
    --log-destination-type cloud-watch-logs \
    --log-group-name $LOG_GROUP_NAME \
    --deliver-logs-permission-arn $DELIVER_LOGS_PERMISSION_ARN \
    --max-aggregation-interval 60

# Tag Flow Logs
aws ec2 create-tags \
    --resources $FLOW_LOG_ID \
    --tags Key=Name,Value=SharedVPCLogs

# Describe Log Streams
aws logs describe-log-streams \
    --log-group-name $LOG_GROUP_NAME \
    --log-stream-name-prefix eni- \
    --limit 5

# Get Log Events
aws logs get-log-events \
    --log-group-name $LOG_GROUP_NAME \
    --log-stream-name $LOG_STREAM_NAME \
    --limit 100

# Filter Log Events
aws logs filter-log-events \
    --log-group-name $LOG_GROUP_NAME \
    --log-stream-names $LOG_STREAM_NAME \
    --filter-pattern "ACCEPT"

# End of script
