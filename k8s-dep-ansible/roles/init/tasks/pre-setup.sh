#!/bin/bash
#关闭防火墙
systemctl disable firewalld
systemctl stop firewalld
#关闭selinux
setenforce 0
#永久关闭
sed -i "s/SELINUX=enforcing/SELINUX=disabled/" /etc/sysconfig/selinux
sed -i "s/SELINUX=enforcing/SELINUX=disabled/g" /etc/selinux/config
#禁用swap
swapoff -a
#永久禁用
sed -i "s/.*swap.*/#&/" /etc/fstab
#修改内核参数
cat <<EOF >  /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.tcp_tw_recycle=0
vm.swappiness=0
vm.overcommit_memory=1
vm.panic_on_oom=0
fs.inotify.max_user_instances=8192
fs.inotify.max_user_watches=1048576
fs.file-max=52706963
fs.nr_open=52706963
net.ipv6.conf.all.disable_ipv6=1
net.netfilter.nf_conntrack_max=2310720
EOF
#重新加载配置文件
sysctl --system
ipvs_modules="ip_vs ip_vs_lc ip_vs_wlc ip_vs_rr ip_vs_wrr ip_vs_lblc ip_vs_lblcr ip_vs_dh ip_vs_sh ip_vs_fo ip_vs_nq ip_vs_sed ip_vs_ftp nf_conntrack"
for kernel_module in ${ipvs_modules}; do
  /sbin/modinfo -F filename ${kernel_module} > /dev/null 2>&1
  if [ $? -eq 0 ]; then
    /sbin/modprobe ${kernel_module}
  fi
done
#配置阿里k8s yum源
cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64/
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg https://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
EOF
#更新缓存
yum clean all -y && yum makecache -y && yum repolist -y
yum install -y chrony conntrack ntpdate ntp ipvsadm ipset jq iptables curl sysstat libseccomp wget vim net-tools git iproute lrzsz bash-completion tree bridge-utils unzip bind-utils gcc yum-utils   device-mapper-persistent-data  lvm2
timedatectl set-timezone Asia/Shanghai
timedatectl set-local-rtc 0
mkdir -p /etc/docker/
cat <<EOF > /etc/docker/daemon.json
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "registry-mirrors": ["https://fl791z1h.mirror.aliyuncs.com"]
}
EOF
curl -fsSL https://get.docker.com | bash -s docker --mirror Aliyun
systemctl daemon-reload
systemctl restart docker
systemctl enable docker
sed -i '/centos.pool.ntp.org/d' /etc/chrony.conf
echo "server cn.ntp.org.cn iburst" >> /etc/chrony.conf
systemctl restart chronyd

