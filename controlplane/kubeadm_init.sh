#!/bin/bash
set -x

IPADDR="10.103.68.139"
NODENAME=$(hostname -s)
POD_CIDR="172.16.0.0/16"
SVC_CIDR="172.17.0.0/16"
grep -q $(hostname -s) /etc/hosts || echo -e "${IPADDR}\t$(hostname -s)" >>/etc/hosts
kubeadm init --apiserver-advertise-address=$IPADDR  --apiserver-cert-extra-sans=$IPADDR  --pod-network-cidr=$POD_CIDR --node-name $NODENAME --service-cidr=$SVC_CIDR --kubernetes-version stable-1.28
