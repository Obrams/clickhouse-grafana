#!/bin/bash
set -e

echo "=== Kubernetes Cluster Status ==="

# Проверка подключения к кластеру
if ! kubectl cluster-info &> /dev/null; then
    echo "Error: Not connected to Kubernetes cluster"
    echo "Run ./start-cluster.sh first"
    exit 1
fi

echo ""
echo "Cluster Info:"
kubectl cluster-info --context kind-grafana-demo

echo ""
echo "Grafana Operator:"
kubectl get pods -n grafana-operator-system

echo ""
echo "Grafana System:"
kubectl get pods -n grafana-system

echo ""
echo "Grafana Instance:"
kubectl get grafana -n grafana-system

echo ""
echo "Grafana Datasources:"
kubectl get grafanadatasource -n grafana-system

echo ""
echo "Grafana Dashboards:"
kubectl get grafanadashboard -n grafana-system

echo ""
echo "Services:"
kubectl get svc -n grafana-system

echo ""
echo "Access Grafana at: http://localhost:3001"
echo "Login: admin / admin123"

