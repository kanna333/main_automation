#!/bin/bash

# ==============================
# Ready-to-run Docker & Kubernetes deploy script
# Usage: ./deploy.sh <app_name> <version>
# Example: ./deploy.sh my-app 1.0.0
# ==============================

# Check for parameters
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <app_name> <version>"
    exit 1
fi

# Parameters
APP_NAME=$1
DOCKER_IMAGE_TAG=$2

# Variables
GIT_REPO_URL="https://github.com/kanna333/main_automation.git"
REPO_NAME="main_automation"
DOCKER_IMAGE_NAME="73333/$APP_NAME"  # <-- Docker image name uses app_name
DEPLOYMENT_YAML_PATH="./deployment.yaml"
SERVICE_YAML_PATH="./service.yaml"
CONTAINER_NAME="$APP_NAME-container"

# Clone repo if not exists
if [ ! -d "$REPO_NAME" ]; then
    git clone $GIT_REPO_URL
else
    echo "Repo already exists, skipping clone."
fi

# Build Docker image
cd $REPO_NAME || { echo "Repo directory not found"; exit 1; }
docker build -t $DOCKER_IMAGE_NAME:$DOCKER_IMAGE_TAG .
docker push $DOCKER_IMAGE_NAME:$DOCKER_IMAGE_TAG
cd ..

# Update deployment.yaml image
if [ -f "$DEPLOYMENT_YAML_PATH" ]; then
    sed -i.bak "/name: $CONTAINER_NAME/{n;s|image:.*|image: $DOCKER_IMAGE_NAME:$DOCKER_IMAGE_TAG|}" $DEPLOYMENT_YAML_PATH
else
    echo "Error: $DEPLOYMENT_YAML_PATH not found!"
    exit 1
fi

# Apply Deployment
kubectl apply -f $DEPLOYMENT_YAML_PATH

# Apply Service
if [ -f "$SERVICE_YAML_PATH" ]; then
    kubectl apply -f $SERVICE_YAML_PATH
fi

echo "Deployment of $APP_NAME:$DOCKER_IMAGE_TAG completed successfully!"
