#!/bin/bash

CLIENTSECRET=$1

kind create cluster || echo cluster already exists
istioctl manifest apply -y

kubectl create -f https://raw.githubusercontent.com/keycloak/keycloak-quickstarts/latest/kubernetes-examples/keycloak.yaml
kubectl rollout status deployment/keycloak

set -eux

kubectl port-forward svc/keycloak 8080:8080 &
port_forward_pid=$!

sleep 2

export TKN=$(curl -X POST 'http://localhost:8080/auth/realms/master/protocol/openid-connect/token' \
 -H "Content-Type: application/x-www-form-urlencoded" \
 -d "username=admin" \
 -d 'password=admin' \
 -d 'grant_type=password' \
 -d 'client_id=admin-cli' | jq -r '.access_token')

curl -X POST 'http://localhost:8080/auth/admin/realms/master/clients' \
 -H "authorization: Bearer ${TKN}" \
 -H "Content-Type: application/json" \
 --data \
 "{
    \"id\": \"test\",
    \"name\": \"test\",
    \"secret\": \"${CLIENTSECRET}\",
    \"redirectUris\": [\"*\"]
 }" 

kill -9 $port_forward_pid

kubectl label namespace default istio-injection=enabled || true

kubectl apply -f httpbin.yaml
kubectl apply -f httpbin-gateway.yaml
kubectl rollout status deployment/httpbin

HTTPBIN_POD=$(kubectl get pods -lapp=httpbin -o jsonpath='{.items[0].metadata.name}')
kubectl cp ../../oidc.wasm  ${HTTPBIN_POD}:/var/local/lib/wasm-filters/oidc.wasm --container istio-proxy

kubectl apply -f istio-auth.yaml
sed -e "s/INSERT_CLIENT_SECRET_HERE/${CLIENTSECRET}/" envoyfilter.yaml | kubectl apply -f -
