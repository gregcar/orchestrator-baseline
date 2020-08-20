#!/usr/bin/env bash

# az login --only-show-errors

# Verify selected subscription
# az account show -o table

# Set correct subscription (if needed)
# az account set --subscription <SUBSCRIPTION_ID>

# deploy full solution
deployResults = "$(az deployment sub create --location westus2 --template-file "./deploy/arm/azuredeploy.json" --parameters $1 --verbose -o json) | \
                tr -d '{}' |\
                cut '-d''' -f4 )"

clusterName="${deployResults}.clusterName"
resourceGroupName="${deployResults}.resourceGroupName"
ingressNamespace=ingress

# Public IP address for cluster ingress
nodeRGName=$(az aks show --resource-group $resourceGroupName --name $clusterName --query nodeResourceGroup -o tsv)
clusterIP01=$(az network public-ip create --resource-group $nodeRGName --name "$clusterName-IP01" --sku Basic --allocation-method static --query publicIp.ipAddress -o tsv)

az aks get-credentials --name $clusterName --resource-group $resourceGroupName --overwrite-existing

# Create a namespace for your ingress resources
kubectl create namespace $ingressNamespace

# Use Helm to deploy an NGINX ingress controller
helm install nginx-ingress stable/nginx-ingress \
    --namespace $ingressNamespace \
    --set controller.replicaCount=2 \
    --set controller.nodeSelector."beta\.kubernetes\.io/os"=linux \
    --set defaultBackend.nodeSelector."beta\.kubernetes\.io/os"=linux \
    --set controller.service.loadBalancerIP=$clusterIP01

# Install the CustomResourceDefinition resources separately
kubectl apply --validate=false -f https://raw.githubusercontent.com/jetstack/cert-manager/release-0.13/deploy/manifests/00-crds.yaml

# Label the ingress-basic namespace to disable resource validation
kubectl label namespace ingress-basic cert-manager.io/disable-validation=true

# Add the Jetstack Helm repository
helm repo add jetstack https://charts.jetstack.io

# Update your local Helm chart repository cache
helm repo update

# Install the cert-manager Helm chart
helm install \
  cert-manager \
  --namespace ingress-basic \
  --version v0.13.0 \
  jetstack/cert-manager

# Create a CA cluster issuer
kubectl apply -f letsencrypt-clusterissuer-staging.yaml --namespace $ingressNamespace
# kubectl apply -f letsencrypt-clusterissuer-prod.yaml --namespace $Namespace