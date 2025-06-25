#!/bin/bash

COLLECTOR_VERSION="v0.2"

# Disclaimer
echo "DISCLAIMER:"
echo "This script will capture the following information from your Kubernetes cluster:"
echo "- Pod logs (including previous container logs)"
echo "- Kubernetes events"
echo "- Detailed pod statuses"
echo "- Helm deployments and their values"
echo "- Simple 'kubectl get pods' output for each namespace"
echo ""
echo "IMPORTANT: The captured data may contain sensitive information, including credentials."
echo "It is your responsibility to review and obfuscate any sensitive data before sharing these logs."
echo ""
read -p "Do you understand and agree to proceed? (yes/no): " agreement

if [[ ! $agreement =~ ^[Yy][Ee][Ss]$ ]]; then
    echo "Script execution cancelled."
    exit 1
fi

# Ask if user wants to skip kube-* namespaces
read -p "Do you want to skip kube-* namespaces? (yes/no): " skip_kube

# Create a directory with current timestamp
timestamp=$(date +"%Y%m%d_%H%M%S")
log_dir="kubernetes_logs_and_events_$timestamp"
mkdir "$log_dir"

# Get all namespaces
if [[ $skip_kube =~ ^[Yy][Ee][Ss]$ ]]; then
    namespaces=$(kubectl get namespaces -o jsonpath='{.items[*].metadata.name}' | tr ' ' '\n' | grep -v '^kube-')
else
    namespaces=$(kubectl get namespaces -o jsonpath='{.items[*].metadata.name}')
fi

# Initialize counters for summary
total_pods=0
total_containers=0
total_initContainers=0
total_helm_releases=0

# Function to extract events for a namespace
extract_events() {
  local namespace=$1
  kubectl get events -n "$namespace" -o json > "$log_dir/$namespace/events.json"
}

# Function to extract Helm deployments and values
extract_helm_info() {
  local namespace=$1

  # Get Helm releases in the namespace
  helm_releases=$(helm list -n "$namespace" -o json | jq -r '.[].name')

  for release in $helm_releases; do
    # Create a directory for the release
    mkdir -p "$log_dir/$namespace/helm/$release"

    # Get release history
    helm history "$release" -n "$namespace" -o json > "$log_dir/$namespace/helm/$release/history.json"

    # Get release values
    helm get values "$release" -n "$namespace" -a -o yaml > "$log_dir/$namespace/helm/$release/values.yaml"

    ((total_helm_releases++))
  done
}

for namespace in $namespaces; do
  # Create a subdirectory for each namespace
  mkdir -p "$log_dir/$namespace"

  # Extract events for the namespace
  extract_events "$namespace"

  # Extract Helm information for the namespace
  extract_helm_info "$namespace"

  # Get simple pod list
  kubectl get pods -n "$namespace" > "$log_dir/$namespace/pods_list.txt"

  # Get all pods in the namespace
  pods=$(kubectl get pods -n "$namespace" -o jsonpath='{.items[*].metadata.name}')

  for pod in $pods; do
    # Get detailed pod status
    kubectl get pod "$pod" -n "$namespace" -o json > "$log_dir/$namespace/${pod}_status.json"

    # Get containers in the pod
    containers=$(kubectl get pod "$pod" -n "$namespace" -o jsonpath='{.spec.containers[*].name}')

    for container in $containers; do
      # Get current logs
      kubectl logs "$pod" -c "$container" -n "$namespace" > "$log_dir/$namespace/${pod}_${container}.log"

      # Get previous logs (if any)
      kubectl logs "$pod" -c "$container" -n "$namespace" -p > "$log_dir/$namespace/${pod}_${container}_previous.log" 2>/dev/null

      ((total_containers++))
    done

    # Get containers in the pod
    initContainers=$(kubectl get pod "$pod" -n "$namespace" -o jsonpath='{.spec.initContainers[*].name}')

    for initContainer in $initContainers; do
      # Get current logs
      kubectl logs "$pod" -c "$initContainer" -n "$namespace" > "$log_dir/$namespace/${pod}_${initContainer}_initContainer.log"

      # Get previous logs (if any)
      kubectl logs "$pod" -c "$initContainer" -n "$namespace" -p > "$log_dir/$namespace/${pod}_${initContainer}_initContainer_previous.log" 2>/dev/null

      ((total_initContainers++))
    done

    ((total_pods++))
  done
done

# Extract cluster-wide events
kubectl get events --all-namespaces -o json > "$log_dir/cluster_events.json"

# Generate summary
echo "Summary:" > "$log_dir/summary.txt"
echo "Collector version: $COLLECTOR_VERSION" > "$log_dir/summary.txt"
echo "Total namespaces processed: $(echo "$namespaces" | wc -w)" >> "$log_dir/summary.txt"
echo "Total pods: $total_pods" >> "$log_dir/summary.txt"
echo "Total containers: $total_containers" >> "$log_dir/summary.txt"
echo "Total initContainers: $total_initContainers" >> "$log_dir/summary.txt"
echo "Total Helm releases: $total_helm_releases" >> "$log_dir/summary.txt"
if [[ $skip_kube =~ ^[Yy][Ee][Ss]$ ]]; then
    echo "Note: kube-* namespaces were skipped" >> "$log_dir/summary.txt"
fi

echo "Logs, events, and Helm information extracted to $log_dir"
echo "REMINDER: Please review and obfuscate any sensitive information before sharing these logs."
echo "Summary:"
cat "$log_dir/summary.txt"