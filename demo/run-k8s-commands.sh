#!/bin/bash

# A script to run the necessary kubectl commands for steps 3, 4, and 5.
# Make sure you have created the 'k8s-deployment.yaml' file first
# and that your Docker Desktop Kubernetes cluster is running.

echo "--- Step 3: Applying the Kubernetes Deployment ---"
# This command sends your YAML configuration to the Kubernetes cluster.
kubectl apply -f k8s-deployment.yaml

echo ""
echo "--- Step 4: Verifying the Application is Running ---"
echo "Waiting for the pod to be created... (this might take a minute)"
# Wait for the deployment to complete
kubectl wait --for=condition=available --timeout=120s deployment/demo-spring-boot-deployment

echo "Checking the status of the Pod:"
# This command shows you the running container (Pod). Look for a STATUS of 'Running'.
kubectl get pods

echo ""
echo "Checking the status of the Deployment:"
# This command shows the overall state of your deployment. Look for '1/1' in the READY column.
kubectl get deployment

echo ""
echo "--- Step 5: Exposing and Accessing Your Application ---"
# This command creates a Service to make your application accessible from your local machine.
kubectl expose deployment demo-spring-boot-deployment --type=NodePort --port=8081

echo ""
echo "Fetching the service details to find the access port..."
# This command shows the port mapping.
kubectl get service demo-spring-boot-deployment

echo ""
echo "--- How to Access Your App ---"
echo "Look at the 'PORT(S)' column from the command above."
echo "You will see something like '8081:XXXXX/TCP'."
echo "To access your application's health check, open a browser or use curl with 'http://localhost:XXXXX/actuator/health', replacing XXXXX with that port number."
echo "For example: curl http://localhost:32178/actuator/health"
