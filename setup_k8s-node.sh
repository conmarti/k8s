#!/bin/bash
set -eux
export http_proxy=http://itsm-con.telekom.de:80
export https_proxy=http://itsm-con.telekom.de:80
export no_proxy=.telekom.de,10.103.64.130
zypper ref
zypper install -y curl ebtables socat conntrack-tools iptables vim open-iscsi git nfs-client ethtool

#install containerd
test -e /usr/local/bin/containerd || curl -skL https://github.com/containerd/containerd/releases/download/v1.7.8/containerd-1.7.8-linux-amd64.tar.gz | tar -C /usr/local -xvzf -
curl -skL https://raw.githubusercontent.com/containerd/containerd/main/containerd.service | sed -e 's/local-fs.target/local-fs.target var-lib-containerd.mount/' >/etc/systemd/system/containerd.service
#install runc
test -e /usr/local/sbin/runc || ( curl -skL -o /usr/local/sbin/runc https://github.com/opencontainers/runc/releases/download/v1.1.10/runc.amd64; chmod 755 /usr/local/sbin/runc )
#install cni plugins
test -e /opt/cni/bin/ipvlan || ( mkdir -p /opt/cni/bin;curl -skL https://github.com/containernetworking/plugins/releases/download/v1.3.0/cni-plugins-linux-amd64-v1.3.0.tgz | tar -C /opt/cni/bin -xvzf - )
#create standard config for containerd
test -e /etc/containerd/config.toml || (mkdir -p /etc/containerd;containerd config default > /etc/containerd/config.toml)
#use systemd cgroup driver
perl -pi -e 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
#configure proxy
mkdir -p /etc/systemd/system/containerd.service.d
cat <<EOF >/etc/systemd/system/containerd.service.d/http-proxy.conf
[Service]
Environment="HTTP_PROXY=http://itsm-con.telekom.de:80"
Environment="HTTPS_PROXY=http://itsm-con.telekom.de:80"
Environment="NO_PROXY=172.0.0.0/8,.telekom.de"
EOF
#configure certificate
#cat <<EOF >/usr/local/share/ca-certificates/proxy_ca.crt
#-----BEGIN CERTIFICATE-----
#MIIF+DCCA+CgAwIBAgIUS8Rq8jI+M38thGq/8utbixJ8d68wDQYJKoZIhvcNAQEL
#BQAwgZMxCzAJBgNVBAYTAk5MMRYwFAYDVQQIDA1Ob29yZCBIb2xsYW5kMRIwEAYD
#VQQHDAlBbXN0ZXJkYW0xCzAJBgNVBAoMAk1FMQswCQYDVQQLDAJJVDE+MDwGA1UE
#Aww1RG9ja2VyTWlycm9yQm94IENBIFJvb3QgYTk1YTFhYWNjYTYzIDIwMjMuMTEu
#MjIgMTc6MjcwHhcNMjMxMTIyMTcyNzUwWhcNMjcwNjE0MTcyNzUwWjCBkzELMAkG
#A1UEBhMCTkwxFjAUBgNVBAgMDU5vb3JkIEhvbGxhbmQxEjAQBgNVBAcMCUFtc3Rl
#cmRhbTELMAkGA1UECgwCTUUxCzAJBgNVBAsMAklUMT4wPAYDVQQDDDVEb2NrZXJN
#aXJyb3JCb3ggQ0EgUm9vdCBhOTVhMWFhY2NhNjMgMjAyMy4xMS4yMiAxNzoyNzCC
#AiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBAL58Ekh6GQgEnJ31K0SwDAFK
#tPhE6pHlpG7Bn0LRkfegt8q2MWh6X/+XTV9zbuWEAFlX/rLcWEe+NtOqEYwR7G5P
#JnJICdWVt0lVLmXGwtRuM7k7GPWmvJILSuyMGKEPPgnqsCWaADyKcKPofG28IC23
#Qlp+IqnXD7MYOsN/xH7AtGnvbwloS0AnZyGGDn+H/MNToCIjakrDLrmWAyA5CxzE
#V4vH/DcIG+dzEPHjsb6n8BUGSWJreysRCg3Fu0pAljQ9uFfiU9u3xS/C4EVUJwZQ
#XyUvrN3eMei1dkyNjeF91cEpv1ui8GvzM7oZE+QZkR3vZQ6GoBNH7CHeGCPC/hsu
#+juJbol20iBKEjyAgwTPgiClC08z+untGhaT6r1POZdvdygtn0ep9dGFjf9js3Jk
#TR9ew+RoLH7GydMbrgMjZ/1HstYv7Z00C6wICDKttBv3uDJKfcQ3/xRit+sPyqdV
#jVfPrv6Ig/1KUDUK3rpt/xYAmmOaigWSz2oO8RjuDTPQv5aZkvwzjaimDBzy3Tqh
#l3b+ID+g07YiNFAqXZh5sHgd+it9srzRUW+L0+HWQxLGQDDH+adT3rh40F2Tzd1L
#OHKOUzeeiWLPHM/a6G7zdsLahZFqgQ+eTyYlwpDg7LMdZ75/yquaPuLm+YL+iaJO
#zyWPsl4TrZlibTJTK1yzAgMBAAGjQjBAMA8GA1UdEwEB/wQFMAMBAf8wDgYDVR0P
#AQH/BAQDAgGGMB0GA1UdDgQWBBTFX1fpBriELjt39hlSh6wrccFLzzANBgkqhkiG
#9w0BAQsFAAOCAgEAWj7ghLFodWJevYJZlFuY+XV7vY/+CQZEgr3KempY9Kip6c/b
#JkcKGM1ceVckNWoGOVH1FGctDz+xIkZjyUyKMzTXqT+x77lkEBnh3m4UVaoICYKI
#k+eZcHwnU/hKJ5mVHePQAx7goHOax32KTmLBHm5qf+k1/eafVwzWqLcP4DQveAC8
#iCYNcYT8UDa1z/oCcXp8l/TJrrjxvJo44iG+kEQHCSylqvgAc88/WHaRKbPfxg6Z
#lmPgpseifTBexHQi0CP7KIhDsc0alE9SwvQ1kuueF8B/71l4Saiu3wqyJMmDB1+k
#q7BZGZ6WTFtkD60ncPLGVkKBOKJjaDQAk39y+t9caOMp+IKThFpygwubaV0EB7iQ
#V08d5yZDrIxMI00J56wjHyccwSlM6x5vviCpRbz7tYefUbEE/6ijsNSfGQJnEGmN
#AgdYGWQMBI2yOfj4iy4kb11kL9kLv9gv+1CXDYoUuPm+AkDKlMf90rctLNreYUsQ
#0YtpziJXBiydz9oXmF6+Al/mFbtodXxbnWbDhdvxI9G8l1v9ZbwMQ8cxJv9z6uB8
#41O2VxgYxV4SDKWtD7FBpJIB7Ca++O2MoXH2teX5t9kp+NAh3K7IUm4o6lqLclqq
#6Y4iaRJMJ2XWHMgufNHfAMGWnfoZ5fm8tKyzwtoHmQF6qEbfY1ppjWTIgKw=
#-----END CERTIFICATE-----
#EOF
#update-ca-certificates
# start/enable containerd
systemctl daemon-reload
systemctl enable --now containerd
# configure os settings
cat <<EOF > /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

cat <<EOF >/etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
net.ipv4.conf.all.arp_ignore        = 0
vm.max_map_count                    = 262144
EOF
sed -i -e '/ip_forward/d' -e '/arp_ignore/d' /etc/sysctl.conf
sysctl --system
#disable swap
sed -e '/swap/ s/^#*/#/' -i /etc/fstab
swapoff -a
# create missing dir
mkdir -p /etc/kubernetes/manifests
#download tools
k8s_version=$(curl -L -s https://dl.k8s.io/release/stable.txt)
k8s_version=v1.28.7
test -e /usr/local/bin/kubectl || ( curl -skLo /usr/local/bin/kubectl "https://dl.k8s.io/release/$k8s_version/bin/linux/amd64/kubectl";chmod 755 /usr/local/bin/kubectl)
test -e /usr/local/bin/kubeadm || ( curl -skLo /usr/local/bin/kubeadm "https://dl.k8s.io/release/$k8s_version/bin/linux/amd64/kubeadm";chmod 755 /usr/local/bin/kubeadm)
test -e /usr/local/bin/kubelet || ( curl -skLo /usr/local/bin/kubelet "https://dl.k8s.io/release/$k8s_version/bin/linux/amd64/kubelet";chmod 755 /usr/local/bin/kubelet)
test -e /usr/local/bin/crictl || (curl -L "https://github.com/kubernetes-sigs/cri-tools/releases/download/v1.28.0/crictl-v1.28.0-linux-amd64.tar.gz" | sudo tar -C /usr/local/bin -xzvf -)
test -e /usr/local/bin/nerdctl || curl -L "https://github.com/containerd/nerdctl/releases/download/v1.7.0/nerdctl-1.7.0-linux-amd64.tar.gz" | tar -C /usr/local/bin -xzvf -
#configure kubelet systemd service
RELEASE_VERSION="v0.16.2"
curl -sSL "https://raw.githubusercontent.com/kubernetes/release/${RELEASE_VERSION}/cmd/krel/templates/latest/kubelet/kubelet.service" | sed "s:/usr/bin:/usr/local/bin:g" >/etc/systemd/system/kubelet.service
sudo mkdir -p /etc/systemd/system/kubelet.service.d
curl -sSL "https://raw.githubusercontent.com/kubernetes/release/${RELEASE_VERSION}/cmd/krel/templates/latest/kubeadm/10-kubeadm.conf" | sed "s:/usr/bin:/usr/local/bin:g" >/etc/systemd/system/kubelet.service.d/10-kubeadm.conf
systemctl enable --now kubelet
#configure kernel for running als images
#sed -ie 's/GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT="quiet vsyscall=emulate"/' /etc/default/grub
#SUM1=$(md5sum /boot/grub/grub.cfg)
#update-grub
#SUM2=$(md5sum /boot/grub/grub.cfg)
#if [[ "$SUM1" != "$SUM2" ]]; then
#    echo "reboot probably needed"
#fi
