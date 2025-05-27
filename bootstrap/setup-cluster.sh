#!/bin/bash

check_pods_ready() {
  local namespace=$1
  local timeout=$2
  local retries=$3
  local interval=$4
  local attempt=1

  echo "⌛ Prüfe, ob Pods im Namespace '$namespace' bereit sind..."

  while [ $attempt -le $retries ]; do
    echo "🟡 Versuch $attempt von $retries..."

    # Prüfe, ob alle Pods im Namespace bereit sind
    ready_pods=$(kubectl get pods -n $namespace --no-headers | grep -c "Running")
    total_pods=$(kubectl get pods -n $namespace --no-headers | wc -l)

    if [ "$ready_pods" -eq "$total_pods" ] && [ "$total_pods" -gt 0 ]; then
      echo "✅ Alle Pods im Namespace '$namespace' sind bereit."
      return 0
    fi

    echo "❌ Pods sind noch nicht bereit. Warte $interval Sekunden..."
    attempt=$((attempt + 1))
    sleep $interval
  done

  echo "❌ Fehler: Nicht alle Pods im Namespace '$namespace' sind nach $retries Versuchen bereit."
  exit 1
}


echo "==========================================="
echo "🔧 1. Create KIND Cluster..."
echo "==========================================="

#kind create cluster --name dev --config ./kind-config/kind-hacp.yaml # use for 3CP + 4 Worker Nodes and HA
kind create cluster --name dev --config ./kind-config/kind-simple.yaml # use for 1 CP and 3 Worker Nodes

echo "==========================================="
echo "🔧 2. Installing MetalLB..."
echo "==========================================="
helm repo add metallb https://metallb.github.io/metallb
helm repo update
helm install metallb metallb/metallb --create-namespace --namespace metallb-system

echo "✅ MetalLB Installation gestartet."
check_pods_ready "metallb-system" 120 24 5

echo "📂 Anwenden der IPAddressPool und L2Advertisement Konfigurationen..."
kubectl apply -f ./metallb/ipaddresspool.yaml
kubectl apply -f ./metallb/l2advertisement.yaml
echo "✅ IPAddressPool und L2Advertisement erfolgreich angewendet."


echo "==========================================="
echo "🔧 3. Installing NGINX Ingress Controller..."
echo "==========================================="
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm install nginx-ingress ingress-nginx/ingress-nginx --create-namespace --namespace ingress-nginx

echo "✅ NGINX Ingress Controller Installation gestartet."
check_pods_ready "ingress-nginx" 120 24 5


echo "==========================================="
echo "🔧 4. Installing Cert-Manager + Cluster-Issuer"
echo "==========================================="
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/latest/download/cert-manager.yaml

echo "✅ Cert-Manager Installation gestartet."
check_pods_ready "cert-manager" 120 24 5

echo "Create CA Secret"
kubectl create secret tls ca-key-pair --cert=CA/ca.crt --key=CA/ca.key -n cert-manager
echo "✅ CA Secret erfolgreich erstellt."

echo "20 Sekunden Warten vor Cluster Issuer..."
sleep 20
kubectl apply -f ./cert-manager/cluster-issuer.yaml

