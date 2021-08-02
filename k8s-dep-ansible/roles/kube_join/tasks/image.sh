#!/bin/bash
url=registry.cn-hangzhou.aliyuncs.com/google_containers
version=v1.21.2
images=(`kubeadm config images list --kubernetes-version=$version|awk -F '/' '{print $2}'`)
coredns=1.8.0
for imagename in ${images[@]} ; do
  if [ $imagename = "coredns" ] 
  then 
     docker pull $url/coredns:$coredns
     docker tag $url/coredns:$coredns k8s.gcr.io/coredns/coredns:v1.8.0
     docker tag $url/coredns:$coredns registry.aliyuncs.com/google_containers/coredns:v1.8.0
     
  else
     docker pull $url/$imagename
     docker tag $url/$imagename k8s.gcr.io/$imagename
     docker rmi -f $url/$imagename
fi

done
timedatectl set-timezone Asia/Shanghai
sed -i '/centos.pool.ntp.org/d' /etc/chrony.conf
echo "server cn.ntp.org.cn iburst" >> /etc/chrony.conf
systemctl restart chronyd

