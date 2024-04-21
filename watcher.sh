# #!/bin/bash

# # Define variables
# NAMESPACE="sre"
# DEPLOYMENT_NAME="swype-app"
# MAX_RESTARTS=3

# # Function: kubectl_retry
# # Executes a kubectl command with retries on failure.
# kubectl_retry() {
#   local retries=3
#   local count=0
#   local delay=10
#   until kubectl "$@"; do
#     count=$((count + 1))
#     if [ $count -ge $retries ]; then
#       echo "Command failed after $retries attempts: kubectl $*"
#       return 1
#     fi
#     sleep $delay
#   done
#   return 0
# }

# # Main monitoring loop
# while true; do
#   # Get the restart count of pods
#   raw_counts=$(kubectl_retry get pods --namespace="$NAMESPACE" -l app=$DEPLOYMENT_NAME -o jsonpath='{.items[*].status.containerStatuses[*].restartCount}')
#   POD_RESTART_COUNT=0

#   # Process each value in the raw_counts to ensure they are numeric
#   for count in $raw_counts; do
#     if [[ "$count" =~ ^[0-9]+$ ]]; then
#       POD_RESTART_COUNT=$((POD_RESTART_COUNT + count))
#     fi
#   done

#   echo "Current restart count for $DEPLOYMENT_NAME: $POD_RESTART_COUNT"
  
#   # Check if restart count exceeds maximum allowed restarts
#   if [[ "$POD_RESTART_COUNT" -gt "$MAX_RESTARTS" ]]; then
#     echo "Restart limit exceeded. Scaling down the deployment..."
#     if ! kubectl_retry scale deployment/$DEPLOYMENT_NAME --replicas=0 --namespace="$NAMESPACE"; then
#       echo "Error scaling down deployment, will retry..."
#       continue  # Continue the loop to retry the operation
#     fi
#     echo "Deployment scaled down due to excessive restarts."
#     break
#   else
#     echo "Restart count within limits. Checking again in 60 seconds..."
#   fi
  
#   sleep 60
# done

# echo "Script completed."

#!/bin/bash

# Define variables
NAMESPACE="sre"
DEPLOYMENT_NAME="swype-app"
MAX_RESTARTS=3

# Function: kubectl_retry
# Executes a kubectl command with retries on failure.
kubectl_retry() {
  local retries=3
  local count=0
  local delay=10
  until kubectl "$@"; do
    count=$(($count + 1))
    if [ $count -ge $retries ]; then
      echo "Command failed after $retries attempts: kubectl $*"
      return 1
    fi
    sleep $delay
  done
  return 0
}

# Main monitoring loop
while true; do
  # Get the restart count of pods
  POD_RESTART_COUNT=$(kubectl_retry get pods --namespace="$NAMESPACE" -l app=$DEPLOYMENT_NAME -o jsonpath='{.items[*].status.containerStatuses[*].restartCount}' | awk '{s+=$1} END {print s}')
  POD_RESTART_COUNT=${POD_RESTART_COUNT:-0}
  
  echo "Current restart count for $DEPLOYMENT_NAME: $POD_RESTART_COUNT"
  
  if [ "$POD_RESTART_COUNT" -gt "$MAX_RESTARTS" ]; then
    echo "Restart limit exceeded. Scaling down the deployment..."
    if ! kubectl_retry scale deployment/$DEPLOYMENT_NAME --replicas=0 --namespace="$NAMESPACE"; then
      echo "Error scaling down deployment, will retry..."
      continue  # Continue the loop to retry the operation
    fi
    
    echo "Deployment scaled down due to excessive restarts."
    break
  else
    echo "Restart count within limits. Checking again in 60 seconds..."
  fi
  
  sleep 60
done

echo "Script completed."

