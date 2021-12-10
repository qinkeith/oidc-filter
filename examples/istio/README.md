# Istio Example Deployment

This directory contains a full, working example of how to use oidc-filter together with [Istio](https://istio.io) and [Keycloak](https://keycloak.org).

## Requirements

You will need:

- kind 0.11.1
- kubectl
- istioctl (tested with version 1.11.5)

## How to run the example

You can deploy the example by running (in this directory):

```bash
./deploy.sh
```

Then, when everything is up, you need to setup port-forwarding for the ingress-gateway:

```bash
kubectl port-forward -n istio-system svc/istio-ingressgateway 8080:80 &
```

Now, go to http://localhost:8080/headers - it should forward you to keycloak (listening on http://localhost:8080/auth), where you can login using username `admin` and password `admin`. Keycloak will then forward you back to httpbin, which should show you the headers of your request - check out the cookie `oidcToken`- this is the token that oidc-filter will write into the `Authorization` header.

