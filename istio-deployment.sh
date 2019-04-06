#!/bin/bash

ISTIO_VERSION=1.0.4

echo downloading the istio-$ISTIO_VERSION

curl -sL "https://github.com/istio/istio/releases/download/$ISTIO_VERSION/istio-$ISTIO_VERSION-linux.tar.gz" | tar xz

if [ $? -eq 0 ]; then
        echo "istio-$ISTIO_VERSION downloaded"
        else echo "downlaod failed"
fi

cd istio-$ISTIO_VERSION

echo "createing name space istio-system"

kubectl create namespace istio-system

if [ $? -eq 0 ]; then
 echo "namespace istio-system is created"
 echo echo "namespace not created"
fi

echo "installing CRDs"

helm template install/kubernetes/helm/istio --name istio --namespace istio-system | kubectl apply -f -

if [ $? -eq 0 ]; then
 echo "CRD's installed"
  else echo "Error-CRDs installation"
fi
echo "Verifying that all 53 Istio CRDs were committed to the Kubernetes api-server"

kubectl get crds | grep 'istio.io\|certmanager.k8s.io' | wc -l

if [ $? -eq 0 ]; then
        echo "all Istio CRDs are commited"
        else echo" Error-CRDs not commited"
fi


echo "deploying istio"
helm template install/kubernetes/helm/istio --name istio --namespace istio-system | kubectl apply -f -

if [ $? -eq 0 ]; then
 echo "istio deployed sucssesfully"
   else echo "error"
 fi
