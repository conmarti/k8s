#!/bin/bash
set -eux

kubectl apply -f https://raw.githubusercontent.com/longhorn/longhorn/v1.5.3/deploy/longhorn.yaml
kubectl patch storageclass longhorn -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"false"}}}'

kubectl apply -f - <<EOF
allowVolumeExpansion: true
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  annotations:
    storageclass.kubernetes.io/is-default-class: "true"
  name: longhorn-1-replica
parameters:
  dataLocality: disabled
  fromBackup: ""
  fsType: ext4
  numberOfReplicas: "1"
  staleReplicaTimeout: "30"
provisioner: driver.longhorn.io
reclaimPolicy: Delete
volumeBindingMode: Immediate
EOF

kubectl patch settings.longhorn.io storage-reserved-percentage-for-default-disk -n longhorn-system --type='json' -p='[{"op": "replace", "path": "/value", "value": "0"}]'

echo "======================================================================"
echo "kubectl -n longhorn-system edit nodes.longhorn.io wmstk-k8s-w1"
echo "storageReserved anpassen"
