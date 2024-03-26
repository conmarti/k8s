#!/bin/bash
set -eux
kubectl apply -k .
kubectl -n ingress-nginx create secret tls default --key key.pem --cert cert.pem
