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

############################################################## Deploying the sample app ##############################################################################
######################################################################################################################################################################

echo "######### Enable default side-car injection #################"
kubectl label namespace default istio-injection=enabled

echo "############# Deploy the services #########"
kubectl apply -f samples/bookinfo/platform/kube/bookinfo.yaml

echo "######## Verify the pods and services are running #######"
kubectl get svc,pod

echo "######## Deploy the ingress gateway #########"

kubectl apply -f samples/bookinfo/networking/bookinfo-gateway.yaml

echo "########## Now determine the ingress ip and port ############"
kubectl get svc istio-ingressgateway -n istio-system

echo "Set the ingress ip and port"
 export INGRESS_HOST=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
export INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="http2")].port}')
export SECURE_INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="https")].port}')

echo "gateway url"
export GATEWAY_URL=$INGRESS_HOST:$INGRESS_PORT

echo "verify the app is up and running"
curl -o /dev/null -s -w "%{http_code}\n" http://${GATEWAY_URL}/productpage

echo "Apply default destination rules"
kubectl apply -f samples/bookinfo/networking/destination-rule-all-mtls.yaml

echo "deploying User Based Testing / Request Routing"
#One aspect of traffic management is controlling traffic routing based on the HT#TP request, such as user agent strings, IP address or cookies.
#The example below will send all traffic for the user "jason" to the reviews:v2, #meaning they'll only see the black stars
kubectl apply -f samples/bookinfo/networking/virtual-service-reviews-test-v2.yaml

echo "deploying Traffic Shaping for Canary Releases"
#The ability to split traffic for testing and rolling out changes is important. #This allows for A/B variation testing or deploying canary releases.
#The rule below ensures that 50% of the traffic goes to reviews:v1 (no stars), o#reviews:v3 (red stars).

kubectl apply -f samples/bookinfo/networking/virtual-service-reviews-50-v3.yaml

kubectl get deployment -n istio-system > deploymets


