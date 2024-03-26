#!/bin/bash
set -eux

kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.26.3/manifests/tigera-operator.yaml
curl https://raw.githubusercontent.com/projectcalico/calico/v3.26.3/manifests/custom-resources.yaml | sed -e 's#192.168.0.0/16#172.16.0.0/16#' | kubectl create -f -
