#!/bin/bash

# 检查是否为root用户
if [[ $EUID -ne 0 ]]; then
    echo "请以 root 用户身份运行此脚本。"
    exit 1
fi

while true; do
    clear
    echo "
+-------------------------------------------------------------------------+
|                     阳哥的百依百顺工具 V1.2                             |
+-------------------------------------------------------------------------+
|               1. 关闭防火墙和安全组                                     |
|               2. 删除当前YUM源                                          |
|               3. 配置YUM源                                              |
|               4. 配置静态IP                                             |
|               5. 安装常用软件                                           |
|               6. 一键安装Docker                                         |
|               7. 一键配置docker加速器                                   |
|               8. 一键安装Nginx                                          |
|               9. 系统监控                                               |
|               10. 退出                                                  |
+-------------------------------------------------------------------------+
"

    read -p "请选择你想使用的功能(1-10):" num

    case $num in
        1)
            systemctl stop firewalld
            systemctl disable firewalld &>/dev/null
            setenforce 0 &>/dev/null
            sed -i 's/^SELINUX=.*/SELINUX=disabled/' /etc/selinux/config
            if ! systemctl is-active --quiet firewalld; then
                echo "你已成功关闭防火墙和安全组"
            else
                echo "关闭失败，请重新关闭"
            fi
            ;;
        2)
            read -p "确定要删除所有YUM源吗? (y/n)" yn
            if [ "$yn" == "y" ]; then
                rm -rf /etc/yum.repos.d/*.repo
                echo "YUM源已被删除"
            else
                echo "操作取消"
            fi
            ;;
        3)
            curl -o /etc/yum.repos.d/CentOS-Base.repo https://mirrors.aliyun.com/repo/Centos-7.repo
            curl -o /etc/yum.repos.d/epel.repo https://mirrors.aliyun.com/repo/epel-7.repo
            yum makecache fast
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
            echo "正在安装常用软件..."
            yum install -y wget vim git lrzsz vsftpd
            if [ $? -eq 0 ]; then
                echo "你已成功安装 wget, vim, git, lrzsz 和 vsftpd"
            else
                echo "安装失败，请重新安装"
            fi
            ;;
        6)
            echo "正在安装 Docker..."
            sudo yum remove -y docker docker-common docker-selinux docker-engine &>/dev/null
            sudo yum install -y yum-utils device-mapper-persistent-data lvm2
            wget -O /etc/yum.repos.d/docker-ce.repo https://mirrors.huaweicloud.com/docker-ce/linux/centos/docker-ce.repo
            sed -i 's+download.docker.com+mirrors.huaweicloud.com/docker-ce+' /etc/yum.repos.d/docker-ce.repo
            sudo yum makecache fast -y
            sudo yum install -y docker-ce
            docker --version
            systemctl start docker
            systemctl enable docker
            echo "Docker 已成功安装并启动。"
            ;;
        7)
            echo "正在配置 Docker 加速器..."
            sudo mkdir -p /etc/docker
            sudo tee /etc/docker/daemon.json <<-'EOF'
{
    "registry-mirrors": [
        "https://2a6bf1988cb6428c877f723ec7530dbc.mirror.swr.myhuaweicloud.com",
        "https://docker.m.daocloud.io",
        "https://hub-mirror.c.163.com",
        "https://mirror.baidubce.com",
        "https://dockerhub.icu",
        "https://docker.registry.cyou",
        "https://docker-cf.registry.cyou",
        "https://dockercf.jsdelivr.fyi",
        "https://docker.jsdelivr.fyi",
        "https://dockertest.jsdelivr.fyi",
        "https://mirror.aliyuncs.com",
        "https://dockerproxy.com",
        "https://mirror.baidubce.com",
        "https://docker.nju.edu.cn",
        "https://docker.mirrors.sjtug.sjtu.edu.cn",
        "https://docker.mirrors.ustc.edu.cn",
        "https://mirror.iscas.ac.cn",
        "https://docker.rainbond.cc",
        "https://docker.211678.top",
        "https://docker.1panel.live",
        "https://hub.rat.dev",
        "https://do.nark.eu.org",
        "https://dockerpull.com",
        "https://dockerproxy.cn",
        "https://docker.awsl9527.cn"
    ]
}
EOF
            systemctl daemon-reload
            systemctl restart docker
            echo "Docker 加速器已配置完成。"
            ;;
        8)
            echo "正在安装 Nginx..."
            read -p "你确定要安装 Nginx 吗？(1确定/2退出)" a
            if [ "$a" -eq 1 ]; then
                yum install -y nginx
                if [ $? -eq 0 ]; then
                    echo "Nginx 已安装，正在启动 Nginx 服务..."
                    systemctl start nginx
                    systemctl enable nginx
                    echo "Nginx 已安装并启动"
                else
                    echo "Nginx 安装失败，请重新安装"
                fi
            elif [ "$a" -eq 2 ]; then
                echo "程序退出"
            fi
            ;;
        9)
            watch --color -n 5 '
echo -e "\033[1;36m=== 系统监控 ===\033[0m"

# 智能CPU检测
cores=$(lscpu 2>/dev/null | awk "/^CPU(s):/ {print \$2}" || nproc 2>/dev/null || grep -c ^processor /proc/cpuinfo)
loadavg=$(awk "{printf \"%.2f/%.2f/%.2f\", \$1,\$2,\$3}" /proc/loadavg 2>/dev/null)
echo "CPU负载:\t${loadavg:-N/A} (核心数: ${cores:-未知})"

# 自适应内存单位
if free -b &>/dev/null; then
    free -b | awk "
        /^Mem:/ {
            if (\$2 == 0) exit 1;
            used = \$3 + \$6;
            total = \$2;
            unit=\"GB\"; divisor=1073741824;
            printf \"内存使用:\t%.2f%s / %.2f%s (%.1f%%)\n\", used/divisor, unit, total/divisor, unit, (used/total)*100;
        }
    "
else
    echo "内存数据不可用"
fi

# 存储空间检测
df -hT / 2>/dev/null | awk "
NR==2 {
    if (NF >= 6) {
        used_col=\$5; total_col=\$3;
    } else {
        used_col=\$3; total_col=\$2;
    }
    gsub(/%/, \"\", used_col);
    printf \"存储空间:\t%s 已用 / %s 总量 (%.1f%%)\n\", \$4, total_col, used_col;
}
"

# TCP连接数检测
ss -s 2>/dev/null | awk "
/TCP/ {
    if (/v6/) ver=6; else ver=4;
    sub(/$|$/, \"\", \$2);
    print \"TCPv\" ver \"连接数:\t\" \$2;
    exit;
}
"
'
            ;;
        10)
            echo "退出脚本。"
            exit
            ;;
        *)
            echo "输入有误,请重新输入选项:"
            ;;
    esac
done
