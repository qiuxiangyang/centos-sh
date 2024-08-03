#!/bin/bash
echo "1.关闭防火墙和安全组"
echo "2.删除当前yum源"
echo "3.配置yum源"
echo "4.配置静态IP"
echo "5.安装常用软件"
echo "6.一键安装docker"
echo "7.一键安装zabbix"
read -p "请选择你想使用的功能(1/2/3/4/5/6/7):" num

case $num in

1)
	systemctl stop firewalld
        systemctl disable firewalld
	setenforce  0
	sed  -i  "/^SELINUX/s/enforcing/disabled/"  /etc/selinux/config
	systemctl status firewalld >>/dev/null
	 if [ $? -ne 0 ]; then
            echo "你已成功关闭防火墙和安全组"
        else
            echo "关闭失败，请重新关闭"
        fi
;;
2)
	rm -rf /etc/yum.repos.d/*
;;
3)
	curl -o /etc/yum.repos.d/CentOS-Base.repo https://mirrors.aliyun.com/repo/Centos-7.repo
	curl -o /etc/yum.repos.d/epel.repo https://mirrors.aliyun.com/repo/epel-7.repo
;;
4)
	# 检查是否以 root 用户运行
  if [[ $EUID -ne 0 ]]; then
   	echo "请以 root 用户身份运行此脚本。"
  	 exit 1
  fi
	#检查网络接口是否存在
  	read -p "请输入网络接口名称 (如 ens33): " interface
  if ! ip link show $interface &> /dev/null; then
        echo "网络接口 $interface 不存在。"
        exit 1
  fi
	read -p "请输入静态 IP 地址 (如 192.168.1.10): " ip_address
	read -p "请输入子网掩码 (如 255.255.255.0): " netmask
	read -p "请输入默认网关 (如 192.168.1.1): " gateway
	read -p "请输入首选 DNS 服务器地址 (如 8.8.8.8): " dns1
	read -p "请输入备用 DNS 服务器地址 (如 114.114.114.114): " dns2

cat > "/etc/sysconfig/network-scripts/ifcfg-$interface" << EOF
TYPE=Ethernet
BOOTPROTO=static
DEFROUTE=yes
IPV4_FAILURE_FATAL=no
NAME=$interface
UUID=$(uuidgen)
DEVICE=$interface
ONBOOT=yes
IPADDR=$ip_address
NETMASK=$netmask
GATEWAY=$gateway
DNS1=$dns1
DNS2=$dns2
EOF
	systemctl restart network.service
	ip addr show $interface
	echo "静态 IP 地址已成功配置。"
;;
5)
echo "1.一键安装常用软件"
    read -p "你确定要安装吗？(1确定/2退出）" a
    if [ "$a" -eq 1 ]; then
        echo "正在安装"
        yum install -y wget vim git lrzsz vfstpd 
        if [ $? -eq 0 ]; then
            echo "你已成功安装wget,vim,git,lrzsz和vfstpd"
        else
            echo "安装失败，请重新安装"
        fi
    elif [ "$a" -eq 2 ]; then
        echo "程序退出"
    fi
;;
6)
        sudo yum remove docker docker-common docker-selinux docker-engine
        sudo yum install -y yum-utils device-mapper-persistent-data lvm2
        wget -O /etc/yum.repos.d/docker-ce.repo https://mirrors.huaweicloud.com/docker-ce/linux/cen
tos/docker-ce.repo
        sudo sed -i 's+download.docker.com+mirrors.huaweicloud.com/docker-ce+' /etc/yum.repos.d/doc
ker-ce.repo
        sudo yum makecache fast -y
        sudo yum install docker-ce -y
        docker --version
        systemctl restart docker
;;i
7)

;;	
*)
 exit
;;
esac
