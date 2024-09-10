#!/bin/bash
# 检查是否为root用户
if [[ $EUID -ne 0 ]]; then
    echo "请以 root 用户身份运行此脚本。"
    exit 1
fi

while true; do
    echo "
+-------------------------------------------------------------------------+
|                       系统工具 V1.0                                     |
+-------------------------------------------------------------------------+
|               1. 关闭防火墙和安全组                                     |
|               2. 删除当前YUM源                                          |
|               3. 配置YUM源                                              |
|               4. 配置静态IP                                             |
|               5. 安装常用软件                                           |
|               6. 一键安装Docker                                         |
|               7. 一键安装Nginx                                          |
|               8. 退出                                                   |
+-------------------------------------------------------------------------+
"

    read -p "请选择你想使用的功能(1-8):" num

    case $num in
        1)
            systemctl stop firewalld
            systemctl disable firewalld
            setenforce 0
            sed -i 's/^SELINUX=.*/SELINUX=disabled/' /etc/selinux/config
            systemctl is-enabled firewalld &>/dev/null && systemctl disable firewalld
            systemctl status firewalld &>/dev/null
            if [ $? -ne 0 ]; then
                echo "你已成功关闭防火墙和安全组"
            else
                echo "关闭失败，请重新关闭"
            fi
            ;;
        2)
            read -p "确定要删除所有YUM源吗? (y/n)" yn
            if [ "$yn" == "y" ]; then
                rm -rf /etc/yum.repos.d/*repo
                echo "YUM源已被删除"
            else
                echo "操作取消"
            fi
            ;;
        3)
            curl -o /etc/yum.repos.d/CentOS-Base.repo https://mirrors.aliyun.com/repo/Centos-7.repo
            curl -o /etc/yum.repos.d/epel.repo https://mirrors.aliyun.com/repo/epel-7.repo
            echo "YUM源已配置完成"
            ;;
        4)
            read -p "请输入网络接口名称 (如 ens33): " interface
            if ! ip link show $interface &> /dev/null; then
                echo "网络接口 $interface 不存在。"
                continue
            fi
            read -p "请输入静态 IP 地址 (如 192.168.1.10): " ip_address
            read -p "请输入子网掩码 (如 255.255.255.0): " netmask
            read -p "请输入默认网关 (如 192.168.1.1): " gateway
            read -p "请输入备用 DNS 服务器地址 (如 114.114.114.114): " dns1

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
EOF
            systemctl restart network.service
            ip addr show $interface
            echo "静态 IP 地址已成功配置。"
            ;;
        5)
            echo "1. 一键安装常用软件"
            read -p "你确定要安装吗？(1确定/2退出）" a
            if [ "$a" -eq 1 ]; then
                echo "正在安装"
                yum install -y wget vim git lrzsz vfstpd
                if [ $? -eq 0 ]; then
                    echo "你已成功安装wget, vim, git, lrzsz 和 vfstpd"
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
            wget -O /etc/yum.repos.d/docker-ce.repo https://mirrors.huaweicloud.com/docker-ce/linux/centos/docker-ce.repo
            sed -i 's+download.docker.com+mirrors.huaweicloud.com/docker-ce+' /etc/yum.repos.d/docker-ce.repo
            sudo yum makecache fast -y
            sudo yum install docker-ce -y
            docker --version
            systemctl restart docker
            ;;
        7)
            echo "7. 一键安装Nginx"  
            read -p "你确定要安装Nginx吗？(1确定/2退出）" a  
            if [ "$a" -eq 1 ]; then  
                echo "正在安装Nginx"  
                yum install -y nginx  
                if [ $? -eq 0 ]; then  
                    echo "Nginx已安装，正在启动Nginx服务..."  
                    systemctl start nginx  
                    systemctl enable nginx  
                    echo "Nginx已安装并启动"  
                else  
                    echo "Nginx安装失败，请重新安装"  
                fi  
            elif [ "$a" -eq 2 ]; then  
                echo "程序退出"  
            fi  
            ;;
        8)
            echo "退出脚本。"
            exit
            ;;
        *)
            echo "输入有误,请重新输入选项:"
            ;;
    esac
done
