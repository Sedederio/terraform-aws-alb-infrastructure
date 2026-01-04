#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

ENVIRONMENT=$1
LOG_FILE="${PROJECT_ROOT}/destroy-${ENVIRONMENT}-$(date +%Y%m%d-%H%M%S).log"

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
echo "Terraform Destroy Script" | tee -a "$LOG_FILE"
echo "Environment: $ENVIRONMENT" | tee -a "$LOG_FILE"
echo "Timestamp: $(date)" | tee -a "$LOG_FILE"
echo "========================================" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

echo "WARNING: This will destroy all resources in the $ENVIRONMENT environment" | tee -a "$LOG_FILE"
echo "This action cannot be undone!" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

if [ "$ENVIRONMENT" == "prod" ]; then
    echo "CRITICAL WARNING: You are about to destroy PRODUCTION infrastructure" | tee -a "$LOG_FILE"
    echo "This will result in downtime and data loss" | tee -a "$LOG_FILE"
    echo "" | tee -a "$LOG_FILE"
    read -p "Type 'destroy-production' to continue: " CONFIRM
    if [ "$CONFIRM" != "destroy-production" ]; then
        echo "Destroy cancelled" | tee -a "$LOG_FILE"
        exit 0
    fi
else
    read -p "Type 'yes' to continue: " CONFIRM
    if [ "$CONFIRM" != "yes" ]; then
        echo "Destroy cancelled" | tee -a "$LOG_FILE"
        exit 0
    fi
fi

echo "" | tee -a "$LOG_FILE"
echo "Step 1: Initializing Terraform..." | tee -a "$LOG_FILE"
cd "$ENV_DIR"
if ! terraform init 2>&1 | tee -a "$LOG_FILE"; then
    echo "Error: Terraform initialization failed" | tee -a "$LOG_FILE"
    exit 1
fi
echo "" | tee -a "$LOG_FILE"

echo "Step 2: Creating destroy plan..." | tee -a "$LOG_FILE"
if ! terraform plan -destroy 2>&1 | tee -a "$LOG_FILE"; then
    echo "Error: Terraform plan failed" | tee -a "$LOG_FILE"
    exit 1
fi
echo "" | tee -a "$LOG_FILE"

echo "Step 3: Destroying infrastructure..." | tee -a "$LOG_FILE"
if ! terraform destroy -auto-approve 2>&1 | tee -a "$LOG_FILE"; then
    echo "Error: Terraform destroy failed" | tee -a "$LOG_FILE"
    exit 1
fi
echo "" | tee -a "$LOG_FILE"

echo "========================================" | tee -a "$LOG_FILE"
echo "Infrastructure destroyed successfully" | tee -a "$LOG_FILE"
echo "Environment: $ENVIRONMENT" | tee -a "$LOG_FILE"
echo "Log file: $LOG_FILE" | tee -a "$LOG_FILE"
echo "========================================" | tee -a "$LOG_FILE"

exit 0
