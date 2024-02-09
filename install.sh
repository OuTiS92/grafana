#/bin/bash 
sleep 1 
clear 
echo "started ... "
sleep 1 
clear 



#colors
red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
blue='\033[0;34m'
purple='\033[0;35m'
cyan='\033[0;36m'
white='\033[0;37m'
rest='\033[0m'




root_access() {
    # Check if the script is running as root
    if [ "$EUID" -ne 0 ]; then
        echo "This script requires root access. please run as root."
        exit 1
    fi
}



detect_distribution() {
    # Detect the Linux distribution
    local supported_distributions=("ubuntu" "debian" "centos" "fedora")
    
    if [ -f /etc/os-release ]; then
        source /etc/os-release
        if [[ "${ID}" = "ubuntu" || "${ID}" = "debian" || "${ID}" = "centos" || "${ID}" = "fedora" ]]; then
            package_manager="apt-get"
            [ "${ID}" = "centos" ] && package_manager="yum"
            [ "${ID}" = "fedora" ] && package_manager="dnf"
        else
            echo "Unsupported distribution!"
            exit 1
        fi
    else
        echo "Unsupported distribution!"
        exit 1
    fi
}

check_dependencies() {
    detect_distribution

    local dependencies=("wget" "figlet" "lolcat" "unzip" "gcc" "git" "curl" "tar" "mysql-server" "influxdb" "influxdb-client" "telegraf" )
    
    for dep in "${dependencies[@]}"; do
        if ! command -v "${dep}" &> /dev/null; then
            echo "${dep} is not installed. Installing..."
            sudo "${package_manager}" install "${dep}" -y
        fi
    done
}




unistall_all(){
cd /etc/systemd/system
rm -rf prometheus.service
rm -rf prometheus.yml
rm -rf mysql_exporter.service
rm -rf influxd.service
sudo apt-get purge influxdb -y
sudo apt-get purge grafana -y
sudo apt-get remove --purge mysql-server 
sudo apt-get purge telegraf -y
rm -rf  /etc/grafana
rm -rf /etc/telegraf
rm -rf /etc/influxdb
sudo rm -rf /var/lib/mysql
sudo rm -rf /etc/mysql
sudo apt-get autoremove -y 
sudo apt-get autoclean -y
}

install_grafana() {
	get -q -O - https://packages.grafana.com/gpg.key | sudo apt-key add -
echo "deb https://packages.grafana.com/oss/deb stable main" | sudo tee /etc/apt/sources.list.d/grafana.list && sudo apt update && sudo apt install -y grafana

sudo systemctl unmask grafana-server.service
#sudo systemctl enable grafana-server.service
sudo systemctl start grafana-server
}




install_prometheus() {
	wget -qO- https://github.com/prometheus/prometheus/releases/download/v2.45.3/prometheus-2.45.3.linux-amd64.tar.gz | tar xz 
	cd prometheus-2.*
}

check_install_prometheus() {
	if [ -f "/etc/systemd/system/prometheus.service" ]; then
		echo "the service prometheus is already install"
		exit 1 
	fi
}


install_service_prometheus() {
	cd /etc/systemd/system
	cat <<EOL > prometheus.service
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
}



add_user_prometheus() {
	sudo groupadd --system prometheus
	sudo useradd -s /sbin/nologin --system -g prometheus prometheus
}

install_mysql_exported() {
	curl -s https://api.github.com/repos/prometheus/mysqld_exporter/releases/latest   | grep browser_download_url   | grep linux-amd64 | cut -d '"' -f 4   | wget -qi - && tar xvf mysqld_exporter*.tar.gz && sudo mv  mysqld_exporter-*.linux-amd64/mysqld_exporter /usr/local/bin/ && sudo chmod +x /usr/local/bin/mysqld_exporter
}

check_mysql_export_service() {
	if [ -f "/etc/systemd/system/mysql_exporter.service" ]; then
		echo "the service mysql_exporter is already install"
		exit 1
	fi
}



insert_mysql_query() {
	mysql -u root -proot << EOF
	CREATE USER 'mysqld_exporter'@'localhost' IDENTIFIED BY 'C@f@vb@zXMU2fm^8c';GRANT PROCESS, REPLICATION CLIENT, SELECT ON *.* TO 'mysqld_exporter'@'localhost';FLUSH PRIVILEGES;
EOF
}

install_service_mysql_export_cnf() {
	cat <<EOL > /etc/.mysqld_exporter.cnf
[client]
user=mysqld_exporter
password=StrongPassword
EOL
sudo chown root:prometheus /etc/.mysqld_exporter.cnf
}


install_service_mysql_export() {
	cd /etc/systemd/system
	cat <<EOL > mysql_exporter.service 
[Unit]
Description=Prometheus MySQL Exporter
After=network.target
User=prometheus
Group=prometheus

[Service]
Type=simple
Restart=always
ExecStart=/usr/local/bin/mysqld_exporter \
--config.my-cnf /etc/.mysqld_exporter.cnf \
--collect.global_status \
--collect.info_schema.innodb_metrics \
--collect.auto_increment.columns \
--collect.info_schema.processlist \
--collect.binlog_size \
--collect.info_schema.tablestats \
--collect.global_variables \
--collect.info_schema.query_response_time \
--collect.info_schema.userstats \
--collect.info_schema.tables \
--collect.perf_schema.tablelocks \
--collect.perf_schema.file_events \
--collect.perf_schema.eventswaits \
--collect.perf_schema.indexiowaits \
--collect.perf_schema.tableiowaits \
--collect.slave_status \
--web.listen-address=0.0.0.0:9104

[Install]
WantedBy=multi-user.target
EOL
sudo systemctl daemon-reload
sudo systemctl enable mysql_exporter
sudo systemctl start mysql_exporter
}



install_yamel_prometheus() {
	cat <<EOF >> prometheus.yml 
- job_name: "mysqld"

    # metrics_path defaults to '/metrics'
    # scheme defaults to 'http'.

    static_configs:
      - targets: ["localhost:9104"]"
EOF
sudo systemctl restart prometheus.service
}




check_installed_influx() {
	if [ -f "/etc/systemd/system/influxd.service" ]; then
		echo "the service influxd is already install"
		exit 1
	fi
}

install_selected_service() {
	read -p "select service install on server ??? [uptime/mysql] default:uptime " choice

	if [[ "$choice" == "mysql" ]]; then 
		install_mysql
	else
		install_uptime
	fi
}



influx_start_service() {
	systemctl unmask influxdb.service
	 systemctl start influxdb
	 systemctl enable influxdb 
 }


influx_service_active() {
	wget https://raw.githubusercontent.com/OuTiS92/grafana/main/telegraf.conf
	if systemctl is-active --quiet influxdb ; then
		influx  -execute "create database telegraf"
		influx -execute  "create user telegraf with password 'root'"
		touch /etc/telegraf/telegraf.conf
		#wget https://raw.githubusercontent.com/OuTiS92/grafana/main/telegraf.conf
		cat ./telegraf.conf > /etc/telegraf/telegraf.conf
	else
		echo -e "======================================="
		echo -e "  "
		echo -e "service influx not running !!!!!"
		exit 1
	fi
	
}
telegraf_service() {
	systemctl start telegraf
	systemctl enable telegraf
	if systemctl is-active --quiet telegraf ; then
		systemctl restart telegraf
	else
		clear
		echo -e "======================================="
		echo -e "  "
		echo -e "service telegraf not running !!!!!"
		exit 1
	fi
}
grafana_service() {
	systemctl start grafana-server
	if systemctl is-active --quiet grafana-server ; then
		systemctl enable grafana-server
		clear
		echo -e "fnished instation grafana (+ influxdb ) "
		echo  -e "    "
		information
	else 
		clear
		echo "======================================="
		echo "  "
		echo "service grafana not running !!!!!"
		exit 1
	fi
}



information() {

	echo "Grafana information :"
	echo "your address grafa : http://yourip:3000"
	echo "Password : admin  , Username : admin "
	echo   " informaton influxdb : telegraf  username and password : root " | lolcat -d -a -t -s
}



install_uptime() {

	root_access
	check_dependencies
#	check_installed_influx
#	figlet
	detect_distribution
	install_grafana
	influx_start_service
	influx_service_active
	telegraf_service
	grafana_service

}



unistall_influxdb() {
	if [ ! -f "/etc/systemd/system/influxd.service" ]; then 
		echo "influx-db not installed."
		return
	fi
	sudo systemctl  stop influxdb.service
	sudo systemctl  disable influxdb.service
	sudo rm -rf /etc/systemd/system/influxd.service

}


unistall_mysql() {
	if [ ! -f "/etc/systemd/system/mysql_exporter.service"]; then 
		echo "mysql exporter in not installed"
		return
	fi
	sudo systemctl  stop mysql_exporter.service
	sudo systemctl disable mysql_exporter.service
	sudo rm -rf /etc/systemd/system/mysql_exporter.service
}


install_mysql() {
	root_access
	detect_distribution
	check_dependencies
	install_grafana
	check_install_prometheus
	install_prometheus
	install_service_prometheus
	add_user_prometheus
	check_mysql_export_service
	install_mysql_exported
	insert_mysql_query
	install_service_mysql_export_cnf
	install_service_mysql_export
	install_yamel_prometheus
	sleep 1
	clear 

	echo "Fnish .... " | lolcat -d -a -t -s
}





clear
figlet "github OuTiS92" | lolcat -t -s -d
sleep 1
echo -e " "
echo -e " "
echo -e " ${purple}--------#- Grafana install -#--------${rest}"
echo -e " "
echo -e "${yellow}******************************${rest}"
echo -e "${green}1) Install mysql${rest}"
echo -e "${green}2) Install uptime${rest}"
echo -e "${red}3) unistall${rest}"
echo -e "${cyan}0) Exit ${rest}"
echo -e "${yellow}******************************${rest}"
echo -e ""
echo -e ""
echo -e "${purple} --------------${cyan}version 1.0.0 ${purple}--------------${rest}"
echo -e ""
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
		echo " Invalid choice. Please try again."
		;;

esac
