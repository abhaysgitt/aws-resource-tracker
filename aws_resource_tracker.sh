#!/bin/bash

#############################################
# AWS Resource Tracker
# Author: Abhay
# Version: 1.0
#############################################

LOG_FILE="tracker.log"
REPORT_FILE="aws_report_$(date +%F_%H-%M-%S).txt"

log() {
    echo "$(date '+%F %T') - $1" >> "$LOG_FILE"
}

echo "=========================================="
echo " AWS RESOURCE TRACKER & FREE TIER MONITOR "
echo "=========================================="

# Check AWS CLI
if ! command -v aws &> /dev/null
then
    echo "AWS CLI is not installed."
    exit 1
fi

# Check AWS Credentials
if ! aws sts get-caller-identity &>/dev/null
then
    echo "AWS credentials not configured."
    exit 1
fi

REGION=$(aws configure get region)

echo
echo "Region : $REGION"

echo
echo "Collecting AWS resources..."
echo

# Resource Counts

S3_COUNT=$(aws s3 ls 2>/dev/null | wc -l)

EC2_COUNT=$(aws ec2 describe-instances \
--query 'Reservations[*].Instances[*].InstanceId' \
--output text 2>/dev/null | wc -w)

LAMBDA_COUNT=$(aws lambda list-functions \
--query 'Functions[*].FunctionName' \
--output text 2>/dev/null | wc -w)

IAM_COUNT=$(aws iam list-users \
--query 'Users[*].UserName' \
--output text 2>/dev/null | wc -w)

EBS_COUNT=$(aws ec2 describe-volumes \
--query 'Volumes[*].VolumeId' \
--output text 2>/dev/null | wc -w)

VPC_COUNT=$(aws ec2 describe-vpcs \
--query 'Vpcs[*].VpcId' \
--output text 2>/dev/null | wc -w)

SG_COUNT=$(aws ec2 describe-security-groups \
--query 'SecurityGroups[*].GroupId' \
--output text 2>/dev/null | wc -w)

EIP_COUNT=$(aws ec2 describe-addresses \
--query 'Addresses[*].PublicIp' \
--output text 2>/dev/null | wc -w)

echo "============== SUMMARY =============="
echo "S3 Buckets        : $S3_COUNT"
echo "EC2 Instances     : $EC2_COUNT"
echo "Lambda Functions  : $LAMBDA_COUNT"
echo "IAM Users         : $IAM_COUNT"
echo "EBS Volumes       : $EBS_COUNT"
echo "VPCs              : $VPC_COUNT"
echo "Security Groups   : $SG_COUNT"
echo "Elastic IPs       : $EIP_COUNT"
echo "====================================="

echo
echo "EC2 DETAILS"
echo "====================================="

aws ec2 describe-instances \
--query 'Reservations[*].Instances[*].[InstanceId,State.Name,InstanceType]' \
--output table

echo
echo "FREE TIER / COST WARNINGS"
echo "====================================="

RUNNING_EC2=$(aws ec2 describe-instances \
--filters Name=instance-state-name,Values=running \
--query 'Reservations[*].Instances[*].InstanceId' \
--output text 2>/dev/null)

if [ -n "$RUNNING_EC2" ]
then
    echo "WARNING: Running EC2 instance detected."
fi

if [ "$EIP_COUNT" -gt 0 ]
then
    echo "WARNING: Elastic IP allocated."
fi

echo "====================================="

{
echo "AWS REPORT"
echo "Generated: $(date)"
echo
echo "Region: $REGION"
echo
echo "S3 Buckets: $S3_COUNT"
echo "EC2 Instances: $EC2_COUNT"
echo "Lambda Functions: $LAMBDA_COUNT"
echo "IAM Users: $IAM_COUNT"
echo "EBS Volumes: $EBS_COUNT"
echo "VPCs: $VPC_COUNT"
echo "Security Groups: $SG_COUNT"
echo "Elastic IPs: $EIP_COUNT"
} > "$REPORT_FILE"

echo
echo "Report Saved: $REPORT_FILE"

log "AWS resource scan completed successfully."
