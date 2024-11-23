#!/bin/bash

# Set default region
REGION="us-east-1"

# Create a VPC
VPC_ID=$(aws ec2 create-vpc --cidr-block 10.0.0.0/16 --region $REGION --query 'Vpc.VpcId' --output text)
echo "Created VPC: $VPC_ID"

# Tag the VPC
aws ec2 create-tags --resources $VPC_ID --tags Key=Name,Value='Lab VPC' --region $REGION

# Enable DNS support and hostnames for the VPC
aws ec2 modify-vpc-attribute --vpc-id $VPC_ID --enable-dns-hostnames --region $REGION

# Create Public Subnet
PUBLIC_SUBNET_ID=$(aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block 10.0.0.0/24 --availability-zone ${REGION}a --region $REGION --query 'Subnet.SubnetId' --output text)
echo "Created Public Subnet: $PUBLIC_SUBNET_ID"

# Tag the Public Subnet
aws ec2 create-tags --resources $PUBLIC_SUBNET_ID --tags Key=Name,Value='Public Subnet' --region $REGION

# Enable public IP assignment on Public Subnet
aws ec2 modify-subnet-attribute --subnet-id $PUBLIC_SUBNET_ID --map-public-ip-on-launch --region $REGION

# Create Private Subnet
PRIVATE_SUBNET_ID=$(aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block 10.0.2.0/23 --availability-zone ${REGION}a --region $REGION --query 'Subnet.SubnetId' --output text)
echo "Created Private Subnet: $PRIVATE_SUBNET_ID"

# Tag the Private Subnet
aws ec2 create-tags --resources $PRIVATE_SUBNET_ID --tags Key=Name,Value='Private Subnet' --region $REGION

# Create Internet Gateway
IGW_ID=$(aws ec2 create-internet-gateway --region $REGION --query 'InternetGateway.InternetGatewayId' --output text)
echo "Created Internet Gateway: $IGW_ID"

# Tag the Internet Gateway
aws ec2 create-tags --resources $IGW_ID --tags Key=Name,Value='Lab IGW' --region $REGION

# Attach Internet Gateway to VPC
aws ec2 attach-internet-gateway --vpc-id $VPC_ID --internet-gateway-id $IGW_ID --region $REGION

# Tag the Private Route Table
aws ec2 create-tags --resources $PUBLIC_ROUTE_TABLE_ID --tags Key=Name,Value='Private Route Table' --region $REGION

# Create Public Route Table
PUBLIC_ROUTE_TABLE_ID=$(aws ec2 create-route-table --vpc-id $VPC_ID --region $REGION --query 'RouteTable.RouteTableId' --output text)
echo "Created Public Route Table: $PUBLIC_ROUTE_TABLE_ID"

# Tag the Public Route Table
aws ec2 create-tags --resources $PUBLIC_ROUTE_TABLE_ID --tags Key=Name,Value='Public Route Table' --region $REGION

# Create Route for Public Access
aws ec2 create-route --route-table-id $PUBLIC_ROUTE_TABLE_ID --destination-cidr-block 0.0.0.0/0 --gateway-id $IGW_ID --region $REGION

# Associate the Public Route Table with the Public Subnet
aws ec2 associate-route-table --route-table-id $PUBLIC_ROUTE_TABLE_ID --subnet-id $PUBLIC_SUBNET_ID --region $REGION

# Create a Security Group
SECURITY_GROUP_ID=$(aws ec2 create-security-group --group-name App-SG --description "Allow HTTP Traffic" --vpc-id $VPC_ID --region $REGION --query 'GroupId' --output text)
echo "Created Security Group: $SECURITY_GROUP_ID"

# Tag the Security Group
aws ec2 create-tags --resources $SECURITY_GROUP_ID --tags Key=Name,Value='App-SG' --region $REGION

# Authorize inbound HTTP traffic
aws ec2 authorize-security-group-ingress --group-id $SECURITY_GROUP_ID --ip-permissions 'IpProtocol=tcp,FromPort=80,ToPort=80,IpRanges=[{CidrIp=0.0.0.0/0,Description="Allow Web Access"}]' --region $REGION

# Launch EC2 instance
INSTANCE_ID=$(aws ec2 run-instances --image-id ami-0fff1b9a61dec8a5f --count 1 --instance-type t2.micro --key-name vockey --subnet-id $PUBLIC_SUBNET_ID --security-group-ids $SECURITY_GROUP_ID --iam-instance-profile Name=Inventory-App-Role --user-data file:/path/to/your/my_script.txt --region $REGION --query 'Instances[0].InstanceId' --output text)
echo "Launched EC2 Instance: $INSTANCE_ID"

# Tag the EC2 instance
aws ec2 create-tags --resources $INSTANCE_ID --tags Key=Name,Value='App Server' --region $REGION


# End of script
