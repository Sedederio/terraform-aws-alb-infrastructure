#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

ENVIRONMENT=$1

if [ -z "$ENVIRONMENT" ]; then
    echo "Usage: $0 <environment>"
    echo "Available environments: dev, staging, prod"
    exit 1
fi

if [[ ! "$ENVIRONMENT" =~ ^(dev|staging|prod)$ ]]; then
    echo "Error: Invalid environment. Must be dev, staging, or prod"
    exit 1
fi

ENV_DIR="${PROJECT_ROOT}/environments/${ENVIRONMENT}"

if [ ! -d "$ENV_DIR" ]; then
    echo "Error: Environment directory not found: $ENV_DIR"
    exit 1
fi

echo "========================================"
echo "Infrastructure Validation Script"
echo "Environment: $ENVIRONMENT"
echo "Timestamp: $(date)"
echo "========================================"
echo ""

cd "$ENV_DIR"

echo "Step 1: Checking Terraform state..."
if ! terraform show &> /dev/null; then
    echo "Error: No Terraform state found. Has the infrastructure been deployed?"
    exit 1
fi
echo "Terraform state found"
echo ""

echo "Step 2: Retrieving infrastructure outputs..."
ALB_DNS=$(terraform output -raw alb_dns_name 2>/dev/null || echo "")
VPC_ID=$(terraform output -raw vpc_id 2>/dev/null || echo "")
ASG_NAME=$(terraform output -raw asg_name 2>/dev/null || echo "")

if [ -z "$ALB_DNS" ]; then
    echo "Warning: Could not retrieve ALB DNS name"
else
    echo "ALB DNS Name: $ALB_DNS"
fi

if [ -z "$VPC_ID" ]; then
    echo "Warning: Could not retrieve VPC ID"
else
    echo "VPC ID: $VPC_ID"
fi

if [ -z "$ASG_NAME" ]; then
    echo "Warning: Could not retrieve ASG name"
else
    echo "ASG Name: $ASG_NAME"
fi
echo ""

echo "Step 3: Checking ALB health..."
if [ -n "$ALB_DNS" ]; then
    if command -v curl &> /dev/null; then
        echo "Testing ALB endpoint..."
        HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "http://${ALB_DNS}" --max-time 10 || echo "000")
        if [ "$HTTP_CODE" == "200" ] || [ "$HTTP_CODE" == "301" ] || [ "$HTTP_CODE" == "302" ]; then
            echo "ALB is responding (HTTP $HTTP_CODE)"
        else
            echo "Warning: ALB returned HTTP $HTTP_CODE"
        fi
    else
        echo "curl not installed, skipping ALB health check"
    fi
fi
echo ""

echo "Step 4: Checking Auto Scaling Group..."
if [ -n "$ASG_NAME" ]; then
    if command -v aws &> /dev/null; then
        ASG_INFO=$(aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names "$ASG_NAME" 2>/dev/null || echo "")
        if [ -n "$ASG_INFO" ]; then
            DESIRED=$(echo "$ASG_INFO" | jq -r '.AutoScalingGroups[0].DesiredCapacity')
            CURRENT=$(echo "$ASG_INFO" | jq -r '.AutoScalingGroups[0].Instances | length')
            HEALTHY=$(echo "$ASG_INFO" | jq -r '[.AutoScalingGroups[0].Instances[] | select(.HealthStatus=="Healthy")] | length')
            
            echo "ASG Desired Capacity: $DESIRED"
            echo "ASG Current Instances: $CURRENT"
            echo "ASG Healthy Instances: $HEALTHY"
            
            if [ "$HEALTHY" -ge "$DESIRED" ]; then
                echo "ASG is healthy"
            else
                echo "Warning: Not all instances are healthy"
            fi
        else
            echo "Warning: Could not retrieve ASG information"
        fi
    else
        echo "AWS CLI not installed, skipping ASG check"
    fi
fi
echo ""

echo "Step 5: Checking target group health..."
if command -v aws &> /dev/null; then
    TG_ARN=$(terraform output -raw target_group_arn 2>/dev/null || echo "")
    if [ -n "$TG_ARN" ]; then
        TG_HEALTH=$(aws elbv2 describe-target-health --target-group-arn "$TG_ARN" 2>/dev/null || echo "")
        if [ -n "$TG_HEALTH" ]; then
            HEALTHY_TARGETS=$(echo "$TG_HEALTH" | jq -r '[.TargetHealthDescriptions[] | select(.TargetHealth.State=="healthy")] | length')
            TOTAL_TARGETS=$(echo "$TG_HEALTH" | jq -r '.TargetHealthDescriptions | length')
            
            echo "Target Group Healthy Targets: $HEALTHY_TARGETS / $TOTAL_TARGETS"
            
            if [ "$HEALTHY_TARGETS" -gt 0 ]; then
                echo "Target group has healthy targets"
            else
                echo "Warning: No healthy targets in target group"
            fi
        fi
    fi
fi
echo ""

echo "========================================"
echo "Validation completed"
echo "========================================"

exit 0
