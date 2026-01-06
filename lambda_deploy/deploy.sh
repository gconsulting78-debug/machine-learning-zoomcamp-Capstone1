#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# --- 1. Configuration Variables ---

# ECR Repository name and Local Image name (must match)
IMAGE_NAME="teacher-churn-prediction-lambda" 
AWS_REGION="ap-southeast-2"
LAMBDA_FUNCTION_NAME="teacher-churn-prediction-docker"

# !!! IMPORTANT: REPLACE THIS WITH YOUR ACTUAL IAM ROLE NAME !!!
# (Your role name found was 'teacher-churn-prediction-role-me7tbz9s')
IAM_ROLE_NAME="teacher-churn-prediction-role-me7tbz9s" 


# --- 2. Dynamic Tag Generation & URI Construction ---

# Retrieve the AWS Account ID securely
AWS_ACCOUNT_ID=$(aws sts get-caller-identity | jq -r ".Account")

# Get a unique, traceable tag (Commit SHA and Timestamp)
COMMIT_SHA=$(git rev-parse --short HEAD 2>/dev/null || echo "manual") 
DATETIME=$(date +"%Y%m%d-%H%M%S")
IMAGE_TAG="${COMMIT_SHA}-${DATETIME}"

# Construct the full ECR Registry URI and the final Image URI
ECR_URI="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
IMAGE_URI="${ECR_URI}/${IMAGE_NAME}:${IMAGE_TAG}"

echo "Starting deployment for function: ${LAMBDA_FUNCTION_NAME}"
echo "Image URI: ${IMAGE_URI}"
echo "--------------------------------------------------------"


# --- 3. ECR Authentication ---
echo "--- Step 1/4: Authenticating Docker to ECR ---"
aws ecr get-login-password \
  --region ${AWS_REGION} \
| docker login \
  --username AWS \
  --password-stdin ${ECR_URI}


# --- 4. Build and Push Image ---
echo "--- Step 2/4: Building Docker Image Locally ---"
# Builds the image using your Dockerfile and local code
docker build -t ${IMAGE_NAME}:${IMAGE_TAG} .

echo "--- Step 3/4: Tagging and Pushing to ECR ---"
# Tags the local image with the full ECR destination path
docker tag ${IMAGE_NAME}:${IMAGE_TAG} ${IMAGE_URI}

# Pushes the image to your ECR repository
docker push ${IMAGE_URI}


# --- 5. Create Lambda Function (FIRST TIME DEPLOYMENT) ---
echo "--- Step 4/4: Creating Lambda Function: ${LAMBDA_FUNCTION_NAME} ---"
# The full ARN for the IAM role
IAM_ROLE_ARN="arn:aws:iam::${AWS_ACCOUNT_ID}:role/service-role/${IAM_ROLE_NAME}"

# CREATE the function using the image URI just pushed to ECR
aws lambda create-function \
  --function-name ${LAMBDA_FUNCTION_NAME} \
  --code ImageUri=${IMAGE_URI} \
  --package-type Image \
  --role ${IAM_ROLE_ARN} \
  --timeout 30 \
  --memory-size 256 \
  --region ${AWS_REGION}

echo "--------------------------------------------------------"
echo "✅ Initial Deployment SUCCESSFUL!"
echo "Function ${LAMBDA_FUNCTION_NAME} created using image: ${IMAGE_URI}."