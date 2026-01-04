#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

ENVIRONMENT=$1
LOG_FILE="${PROJECT_ROOT}/deploy-${ENVIRONMENT}-$(date +%Y%m%d-%H%M%S).log"

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

echo "========================================" | tee -a "$LOG_FILE"
echo "Terraform Deployment Script" | tee -a "$LOG_FILE"
echo "Environment: $ENVIRONMENT" | tee -a "$LOG_FILE"
echo "Timestamp: $(date)" | tee -a "$LOG_FILE"
echo "========================================" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

echo "Step 1: Checking prerequisites..." | tee -a "$LOG_FILE"

if ! command -v terraform &> /dev/null; then
    echo "Error: Terraform is not installed" | tee -a "$LOG_FILE"
    exit 1
fi

if ! command -v aws &> /dev/null; then
    echo "Error: AWS CLI is not installed" | tee -a "$LOG_FILE"
    exit 1
fi

if ! command -v jq &> /dev/null; then
    echo "Warning: jq is not installed. Some features may not work" | tee -a "$LOG_FILE"
fi

TERRAFORM_VERSION=$(terraform version -json | jq -r '.terraform_version')
echo "Terraform version: $TERRAFORM_VERSION" | tee -a "$LOG_FILE"

echo "Checking AWS credentials..." | tee -a "$LOG_FILE"
if ! aws sts get-caller-identity &> /dev/null; then
    echo "Error: AWS credentials not configured or invalid" | tee -a "$LOG_FILE"
    exit 1
fi

AWS_ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
AWS_USER=$(aws sts get-caller-identity --query Arn --output text)
echo "AWS Account: $AWS_ACCOUNT" | tee -a "$LOG_FILE"
echo "AWS User: $AWS_USER" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

if [ ! -f "${ENV_DIR}/terraform.tfvars" ]; then
    echo "Error: terraform.tfvars not found in ${ENV_DIR}" | tee -a "$LOG_FILE"
    echo "Please copy terraform.tfvars.example to terraform.tfvars and configure it" | tee -a "$LOG_FILE"
    exit 1
fi

echo "Step 2: Initializing Terraform..." | tee -a "$LOG_FILE"
cd "$ENV_DIR"
if ! terraform init -upgrade 2>&1 | tee -a "$LOG_FILE"; then
    echo "Error: Terraform initialization failed" | tee -a "$LOG_FILE"
    exit 1
fi
echo "" | tee -a "$LOG_FILE"

echo "Step 3: Validating Terraform configuration..." | tee -a "$LOG_FILE"
if ! terraform validate 2>&1 | tee -a "$LOG_FILE"; then
    echo "Error: Terraform validation failed" | tee -a "$LOG_FILE"
    exit 1
fi
echo "" | tee -a "$LOG_FILE"

echo "Step 4: Creating Terraform plan..." | tee -a "$LOG_FILE"
PLAN_FILE="${ENV_DIR}/tfplan-$(date +%Y%m%d-%H%M%S)"
if ! terraform plan -out="$PLAN_FILE" 2>&1 | tee -a "$LOG_FILE"; then
    echo "Error: Terraform plan failed" | tee -a "$LOG_FILE"
    exit 1
fi
echo "" | tee -a "$LOG_FILE"

echo "Plan saved to: $PLAN_FILE" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

if [ "$ENVIRONMENT" == "prod" ]; then
    echo "WARNING: You are about to deploy to PRODUCTION" | tee -a "$LOG_FILE"
    echo "Please review the plan carefully before proceeding" | tee -a "$LOG_FILE"
    read -p "Type 'yes' to continue: " CONFIRM
    if [ "$CONFIRM" != "yes" ]; then
        echo "Deployment cancelled" | tee -a "$LOG_FILE"
        exit 0
    fi
fi

echo "Step 5: Applying Terraform plan..." | tee -a "$LOG_FILE"
if ! terraform apply "$PLAN_FILE" 2>&1 | tee -a "$LOG_FILE"; then
    echo "Error: Terraform apply failed" | tee -a "$LOG_FILE"
    exit 1
fi
echo "" | tee -a "$LOG_FILE"

echo "Step 6: Retrieving outputs..." | tee -a "$LOG_FILE"
terraform output 2>&1 | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

echo "========================================" | tee -a "$LOG_FILE"
echo "Deployment completed successfully!" | tee -a "$LOG_FILE"
echo "Environment: $ENVIRONMENT" | tee -a "$LOG_FILE"
echo "Log file: $LOG_FILE" | tee -a "$LOG_FILE"
echo "========================================" | tee -a "$LOG_FILE"

rm -f "$PLAN_FILE"

exit 0
