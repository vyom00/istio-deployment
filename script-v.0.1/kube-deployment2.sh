#!/bin/bash


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
