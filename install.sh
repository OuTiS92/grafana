#!/bin/bash
sleep 1
clear
echo -e "${green}started ...${rest}"
sleep 1
clear

# colors
red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
blue='\033[0;34m'
purple='\033[0;35m'
cyan='\033[0;36m'
white='\033[0;37m'
rest='\033[0m'

root_access() {
    if [ "$EUID" -ne 0 ]; then
        echo -e "${red}This script requires root access. Please run as root.${rest}"
        exit 1
    fi
}

detect_distribution() {
    if [ -f /etc/os-release ]; then
        source /etc/os-release
        case "${ID}" in
            ubuntu|debian) package_manager="apt-get" ;;
            centos) package_manager="yum" ;;
            fedora) package_manager="dnf" ;;
            *) echo -e "${red}Unsupported distribution!${rest}"; exit 1 ;;
        esac
    else
        echo -e "${red}Unsupported distribution!${rest}"
        exit 1
    fi
}

check_dependencies() {
    detect_distribution
    local dependencies=("wget" "figlet" "lolcat" "unzip" "gcc" "git" "curl" "tar" "mysql-server" "influxdb" "influxdb-client" "telegraf")
    
    for dep in "${dependencies[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            echo -e "${yellow}$dep is not installed. Installing...${rest}"
            sudo "$package_manager" install "$dep" -y
        fi
    done
}

unistall_all() {
    cd /etc/systemd/system
    rm -rf prometheus.service prometheus.yml mysql_exporter.service influxd.service
    sudo apt-get purge influxdb grafana mysql-server telegraf -y
    sudo apt-get autoremove -y
    sudo apt-get autoclean -y
    rm -rf /etc/grafana /etc/telegraf /etc/influxdb /var/lib/mysql /etc/mysql
    echo -e "${green}All services uninstalled successfully.${rest}"
}

install_grafana() {
    wget -q -O - https://packages.grafana.com/gpg.key | sudo apt-key add -
    echo "deb https://packages.grafana.com/oss/deb stable main" | sudo tee /etc/apt/sources.list.d/grafana.list
    sudo apt update
    sudo apt install -y grafana
    sudo systemctl unmask grafana-server.service
    sudo systemctl start grafana-server
    echo -e "${green}Grafana installed and started.${rest}"
}

install_prometheus() {
    wget -qO- https://github.com/prometheus/prometheus/releases/download/v2.45.3/prometheus-2.45.3.linux-amd64.tar.gz | tar xz
    cd prometheus-2.*
}

check_install_prometheus() {
    if [ -f "/etc/systemd/system/prometheus.service" ]; then
        echo -e "${yellow}The service Prometheus is already installed${rest}"
        exit 1
    fi
}

install_service_prometheus() {
    cat <<EOL > /etc/systemd/system/prometheus.service
[Unit]
Description=Prometheus
Wants=network-online.target
After=network-online.target

[Service]
ExecStart=/path/to/prometheus --config.file=/path/to/prometheus.yml
Restart=always
 
[Install]
WantedBy=default.target
EOL
    sudo systemctl daemon-reload
    sudo systemctl enable prometheus.service
    sudo systemctl start prometheus.service
    echo -e "${green}Prometheus service installed and started.${rest}"
}

add_user_prometheus() {
    sudo groupadd --system prometheus
    sudo useradd -s /sbin/nologin --system -g prometheus prometheus
    echo -e "${green}Prometheus user added.${rest}"
}

install_mysql_exported() {
    curl -s https://api.github.com/repos/prometheus/mysqld_exporter/releases/latest | grep browser_download_url | grep linux-amd64 | cut -d '"' -f 4 | wget -qi -
    tar xvf mysqld_exporter*.tar.gz
    sudo mv mysqld_exporter-*.linux-amd64/mysqld_exporter /usr/local/bin/
    sudo chmod +x /usr/local/bin/mysqld_exporter
    echo -e "${green}MySQL exporter installed.${rest}"
}

check_mysql_export_service() {
    if [ -f "/etc/systemd/system/mysql_exporter.service" ]; then
        echo -e "${yellow}The service MySQL exporter is already installed${rest}"
        exit 1
    fi
}

install_service_mysql_export_cnf() {
    cat <<EOL > /etc/.mysqld_exporter.cnf
[client]
user=mysqld_exporter
password=StrongPassword
EOL
    sudo chown root:prometheus /etc/.mysqld_exporter.cnf
    echo -e "${green}MySQL exporter config file created.${rest}"
}

install_service_mysql_export() {
    cat <<EOL > /etc/systemd/system/mysql_exporter.service 
[Unit]
Description=Prometheus MySQL Exporter
After=network.target
User=prometheus
Group=prometheus

[Service]
Type=simple
Restart=always
ExecStart=/usr/local/bin/mysqld_exporter --config.my-cnf /etc/.mysqld_exporter.cnf --collect.global_status --collect.info_schema.innodb_metrics --collect.auto_increment.columns --collect.info_schema.processlist --collect.binlog_size --collect.info_schema.tablestats --collect.global_variables --collect.info_schema.query_response_time --collect.info_schema.userstats --collect.info_schema.tables --collect.perf_schema.tablelocks --collect.perf_schema.file_events --collect.perf_schema.eventswaits --collect.perf_schema.indexiowaits --collect.perf_schema.tableiowaits --collect.slave_status --web.listen-address=0.0.0.0:9104

[Install]
WantedBy=multi-user.target
EOL
    sudo systemctl daemon-reload
    sudo systemctl enable mysql_exporter
    sudo systemctl start mysql_exporter
    echo -e "${green}MySQL exporter service installed and started.${rest}"
}

install_yamel_prometheus() {
    cat <<EOF >> prometheus.yml
- job_name: "mysqld"
  static_configs:
    - targets: ["localhost:9104"]
EOF
    sudo systemctl restart prometheus.service
    echo -e "${green}Prometheus configuration updated.${rest}"
}

influx_start_service() {
    sudo systemctl unmask influxdb.service
    sudo systemctl start influxdb
    sudo systemctl enable influxdb
    echo -e "${green}InfluxDB service started.${rest}"
}

install_uptime() {
    root_access
    check_dependencies
    detect_distribution
    install_grafana
    influx_start_service
    telegraf_service
    grafana_service
}

unistall_mysql() {
    if [ ! -f "/etc/systemd/system/mysql_exporter.service" ]; then
        echo -e "${yellow}MySQL exporter is not installed${rest}"
        return
    fi
    sudo systemctl stop mysql_exporter.service
    sudo systemctl disable mysql_exporter.service
    sudo rm -rf /etc/systemd/system/mysql_exporter.service
    echo -e "${green}MySQL exporter service uninstalled.${rest}"
}

clear
figlet "github OuTiS92" | lolcat -a -s 100
sleep 1
echo -e " "
echo -e " "
echo -e "${purple}--------#- Grafana install -#--------${rest}"
echo -e " "
echo -e "${yellow}******************************${rest}"
echo -e "${green}1) Install MySQL${rest}"
echo -e "${green}2) Install Uptime${rest}"
echo -e "${red}3) Uninstall All${rest}"
echo -e "${cyan}0) Exit${rest}"
echo -e "${yellow}******************************${rest}"
echo -e ""
echo -e "${purple} --------------${cyan}Version 1.0.0 ${purple}--------------${rest}"
echo -e ""
read -p "Please choose: " choice
echo -e ""

case $choice in
    1)
        install_mysql
        ;;
    2)
        install_uptime
        ;;
    3)
        unistall_all
        ;;
    0)
        exit
        ;;
    *)
        echo -e "${red}Invalid choice. Please try again.${rest}"
        ;;
esac
