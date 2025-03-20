#!/bin/bash

# 检查是否为root用户
if [[ $EUID -ne 0 ]]; then
    echo "请以 root 用户身份运行此脚本。"
    exit 1
fi

while true; do
    echo "
+-------------------------------------------------------------------------+
|               你好，欢迎使用百依百顺的Linux工具 V1.3                    |
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
|               10. 一键安装Mysql5.7                                      |
|               11. 退出                                                  |
+-------------------------------------------------------------------------+
"

    read -p "请选择你想使用的功能(1-11):" num

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
        "https://mirror.aliyuncs.com",
        "https://docker.mirrors.ustc.edu.cn",
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
        "https://docker.m.daocloud.io",
        "https://docker.nju.edu.cn",
        "https://docker.mirrors.sjtug.sjtu.edu.cn",
        "https://docker.mirrors.ustc.edu.cn",
        "https://mirror.iscas.ac.cn",
        "https://docker.rainbond.cc",
        "https://docker.211678.top",
        "https://docker.1panel.live",
        "https://hub.rat.dev",
        "https://docker.m.daocloud.io",
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
            # 定义颜色输出
            RED='\033[31m'
            GREEN='\033[32m'
            YELLOW='\033[33m'
            BLUE='\033[34m'
            RESET='\033[0m'

            # 创建日志目录
            LOG_DIR="/var/log/system_maintenance"
            mkdir -p $LOG_DIR
            LOG_FILE="$LOG_DIR/maintenance_$(date +%Y%m%d_%H%M%S).log"

            # 检查root权限
            if [ "$(id -u)" != "0" ]; then
              echo -e "${RED}错误：必须使用root权限运行本脚本${RESET}" | tee -a $LOG_FILE
              exit 1
            fi

            # 系统基础信息检查
            echo -e "\n${BLUE}====== 系统基础信息 ======${RESET}" | tee -a $LOG_FILE
            {
              echo -e "${GREEN}主机名: $HOSTNAME${RESET}"
              echo "系统时间: $(date)"
              echo "运行时间: $(uptime)"
              echo "系统版本: $(cat /etc/redhat-release 2>/dev/null || cat /etc/issue)"
              echo "内核版本: $(uname -r)"
              echo "CPU使用率: $(top -bn1 | grep 'Cpu(s)' | sed 's/.*, *$[0-9.]*$%* id.*/\1/' | awk '{print 100 - $1}')%"
              echo "内存使用: $(free -m | awk '/Mem/{printf "%.2f%", $3/$2*100}')"
              echo "磁盘使用:"
              df -h | grep -vE 'tmpfs|devtmpfs' | sed 's/^/  /'
            } | tee -a $LOG_FILE

            # 内核参数检查
            echo -e "\n${BLUE}====== 内核参数检查 ======${RESET}" | tee -a $LOG_FILE
            {
              echo -e "${YELLOW}当前生效参数:${RESET}"
              sysctl -a | grep -E 'net.ipv4.ip_forward|fs.file-max|net.core.somaxconn'
              echo -e "\n${YELLOW}配置文件差异检查:${RESET}"
              grep -E '^net.ipv4.ip_forward|^fs.file-max|^net.core.somaxconn' /etc/sysctl.conf
            } | tee -a $LOG_FILE

            # 防火墙检查
            echo -e "\n${BLUE}====== 防火墙状态 ======${RESET}" | tee -a $LOG_FILE
            {
              firewall-cmd --state 2>&1
              echo -e "\n${YELLOW}开放端口:${RESET}"
              firewall-cmd --list-ports
              echo -e "\n${YELLOW}开放服务:${RESET}"
              firewall-cmd --list-services
            } | tee -a $LOG_FILE

            # 网络信息检查
            echo -e "\n${BLUE}====== 网络状态检查 ======${RESET}" | tee -a $LOG_FILE
            {
              echo -e "${YELLOW}IP地址信息:${RESET}"
              ip addr show | grep 'inet ' | grep -v '127.0.0.1'
              echo -e "\n${YELLOW}路由表:${RESET}"
              ip route
              echo -e "\n${YELLOW}监听端口:${RESET}"
              ss -tulnp | grep -vE '127.0.0.1|::1'
            } | tee -a $LOG_FILE

            # 服务状态检查
            echo -e "\n${BLUE}====== 服务状态检查 ======${RESET}" | tee -a $LOG_FILE
            {
              echo -e "${YELLOW}关键服务状态:${RESET}"
              systemctl list-units --type=service --state=running | grep -E 'sshd|nginx|httpd|mysql|mariadb|postgresql'
              echo -e "\n${YELLOW}失败服务检测:${RESET}"
              systemctl --failed
            } | tee -a $LOG_FILE

            # 软件包检查
            echo -e "\n${BLUE}====== 软件包检查 ======${RESET}" | tee -a $LOG_FILE
            {
              echo -e "${YELLOW}可用更新:${RESET}"
              yum check-update | grep -v '^$'
              echo -e "\n${YELLOW}最近安装的软件包:${RESET}"
              rpm -qa --last | head -20
            } | tee -a $LOG_FILE

            # 安全审计
            echo -e "\n${BLUE}====== 安全审计 ======${RESET}" | tee -a $LOG_FILE
            {
              echo -e "${YELLOW}SSH登录记录:${RESET}"
              grep 'sshd' /var/log/secure | tail -10
              echo -e "\n${YELLOW}sudo使用记录:${RESET}"
              grep 'sudo:' /var/log/secure | tail -5
            } | tee -a $LOG_FILE

            echo -e "\n${GREEN}检查完成，完整日志请查看：$LOG_FILE${RESET}"
            ;;
        10)
        #!/bin/bash

# 脚本开始提示
echo "开始一键部署MySQL 5.7..."

# 配置MySQL的YUM源
cat <<EOF > /etc/yum.repos.d/mysql-community.repo
[mysql56-community]
name=MySQL 5.6 Community Server
baseurl=http://repo.mysql.com/yum/mysql-5.6-community/el/7/\$basearch/
enabled=0
gpgcheck=0

[mysql57-community]
name=MySQL 5.7 Community Server
baseurl=http://repo.mysql.com/yum/mysql-5.7-community/el/7/\$basearch/
enabled=1
gpgcheck=0

[mysql80-community]
name=MySQL 8.0 Community Server
baseurl=http://repo.mysql.com/yum/mysql-8.0-community/el/7/\$basearch/
enabled=0
gpgcheck=0

[mysql-connectors-community]
name=MySQL Connectors Community
baseurl=http://repo.mysql.com/yum/mysql-connectors-community/el/7/\$basearch/
enabled=0
gpgcheck=0
EOF

echo "已配置MySQL YUM源"

# 安装MySQL社区版服务器
echo "正在安装MySQL社区版服务器..."
yum install -y mysql-community-server

if [ $? -eq 0 ]; then
    echo "MySQL安装成功！"
else
    echo "MySQL安装失败，请检查网络连接或源配置。"
    exit 1
fi

# 启动MySQL服务并设置开机自启
systemctl start mysqld
systemctl enable mysqld

echo "MySQL服务已启动，并设置为开机自启"

# 尝试查找临时密码
temp_pass=$(grep 'temporary password' /var/log/mysqld.log | awk '{print $NF}')

if [ -n "$temp_pass" ]; then
    echo "找到临时密码：$temp_pass"
else
    # 如果没有找到临时密码，尝试重置
    echo "未找到临时密码，正在进行修复..."
    systemctl stop mysqld
    rm -rf /var/lib/mysql/* && rm -rf /var/log/mysqld.log
    systemctl start mysqld
    
    temp_pass=$(grep 'temporary password' /var/log/mysqld.log | awk '{print $NF}')
    
    if [ -n "$temp_pass" ]; then
        echo "修复后找到的新临时密码：$temp_pass"
    else
        echo "未能生成临时密码，请手动检查。"
        exit 1
    fi
fi

# 提示用户下一步操作
echo "请使用以下临时密码登录MySQL，并尽快修改密码：$temp_pass"
echo "例如：mysql -u root -p'$temp_pass'"
echo "然后运行 'mysql_secure_installation' 进行安全设置。"
echo "或者执行 'mysqladmin -u root -p'$temp_pass' password '新密码''"

# 脚本结束提示
echo "MySQL 5.7一键部署完成！"
        # 脚本结束
        ;;
        11)
            echo "退出中..."
            break
            ;;
        *)
            echo "无效输入，请输入数字 1-10 中的一个。"
            ;;
    esac
done