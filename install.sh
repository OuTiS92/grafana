#/bin/bash 
sleep 1 
clear 
echo "started ... "
sleep 1 
clear 
filetelegraf='/etc/telegraf/telegraf.conf'



#colors
red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
blue='\033[0;34m'
purple='\033[0;35m'
cyan='\033[0;36m'
white='\033[0;37m'
rest='\033[0m'




root_access(){
	#check if script is runnig as root 
	if ["$EUID" -ne 0 ]; then 
		echo "this script requires root access . please run as root."
		exit 1 
	fi
}



detect_distribution() {
	local supported_distributions=("ubuntu" "debian")

	if [ -f /etc/os-realease ]; then
		source /etc/os-release
		if [[ "${ID}" = "ubuntu" || "${ID}" = "debian" ]];then
			package_manager="apt-get"
		else
			echo "Unsupported distribution!!"
			exit 1
		fi
	else 
		echo "Unsupported distribution!!"
		exit 1
	fi
}



chek_dependecies() {
	detect_distribution

	local dependenxies=("wget" "unzip" "git" "curl" "tar" "lolcat" "figlet" "influxdb" "influxdb-client" "mysql-server"  )
	
	for dep in "${dependenxies[@]}"; do
		if ! command -v "${dep}" &> /dev/null; then
			echo "${dep} is not installed, installing ...."
			sudo "${package_manager}" install "${dep}" -y 
		fi
	done
}



check_install_mysql() {
	wget "https://github.com/prometheus/prometheus/releases/download/v2.45.3/prometheus-2.45.3.linux-amd64.tar.gz" -O tar xvfz prometheus-2.30.0.linux-amd64.tar.gz && cd prometheus-2.45.3.linux-amd64 
}

check_install_prometheus() {
	if [ -f "/etc/systemd/system/prometheus.service" ]; then
		echo "the service is already install"
		exit 1 
	fi
}


install_service_prometheus() {
	cd cd /etc/systemd/system
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
		echo "the service is already install"
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
	cd /etc/prometheus/
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
		echo "the service is already install"
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


install_uptime() {

	#apt update && apt install  lolcat  && apt install figlet >> /dev/null
	#clear 
	#sleep 1
	root_access
	check_dependencies
	check_installed_influx


	figlet github OuTiS92 | lolcat -t -s -d 

	sleep 3 
	apt install influxdb influxdb-client 
	systemctl unmask influxdb.service

	systemctl start influxdb
	systemctl enable influxdb

	if systemctl is-active --quiet influxdb ; then
		#echo "service infulxdb is running ..."
		#echo "I was getting port alrady in use error ... " 
		#sleep 2 
		influx  -execute "create database telegraf" 
		influx -execute  "create user telegraf with password 'root'"
		#exit
		apt install telegraf -y
		#mv /etc/telegraf/telegraf.conf /etc/telegraf/telegraf.conf.default
		touch /etc/telegraf/telegraf.conf
		cat ./telegraf.conf > /etc/telegraf/telegraf.conf
		systemctl start telegraf 
		systemctl enable telegraf
	if  systemctl is-active --quiet telegraf ; then 
		
		#mv /etc/telegraf/telegraf.conf /etc/telegraf/telegraf.conf.default
		#touch /etc/telegraf/telegraf.conf
		#cat ./telegraf.conf > /etc/telegraf/telegraf.conf
		systemctl restart telegraf 
		wget -q -O - https://packages.grafana.com/gpg.key | sudo apt-key add -
		#grep yes | sudo add-apt-repository "deb https://packages.grafana.com/oss/deb stable main" 
		apt update -y  && apt install grafana -y  
		systemctl start grafana-server
	if systemctl is-active --quiet grafana-server ; then 
			systemctl enable grafana-server
			clear
			sleep 2 
			echo "fnished instation grafana (+ influxdb ) "
			echo  "    "
			echo    "go to browser and enter  
				http://yourip:3000" | lolcat -d -a -t -s 	
			echo 	"Username : admin " | lolcat -d -a -t -s
			echo 	"Password : admin " | lolcat -d -a -t -s
			echo "  "
			echo    " informaton influxdb : telegraf  username and password : root" | lolcat -d -a -t -s   
			
	else 
			clear
			echo "======================================="
			echo "  "
			echo "service grafana not running !!!!!"
			exit
	fi
	else 
		clear
		echo "service influxdb not running !!!!!"
		exit
	fi
	else 
		clear
		echo " service influxdb not runnint !!!!!!"
		exit
	fi

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
	chek_dependecies
	check_install_mysql
	check_install_prometheus
	install_service_prometheus
	add_user_prometheus
	check_mysql_export_service
	install_mysql_exported
	insert_mysql_query
	install_service_mysql_export_cnf
	install_service_mysql_export
	install_yamel_prometheu





clear 

echo -e "${cyan}By --> outis92  * ${rest}"
echo -e "${yellow}******************************${rest}"
echo -e " ${purple}--------#- Grafana -#--------${rest}"
echo -e "${green}1) Install mysql${rest}"
echo -e "${green}1) Install uptime${rest}"
echo "0) Exit"
echo -e "${yellow} ----------------------------${rest}"
echo -e "${purple} --------------${cyan}version 1.0.0 ${purple}--------------${rest}"
read -p "Please choose: " choice

case $choice in 
	1)
		install_mysql
		;;
	2)
		install_uptime
		;;
	0)
		exit
		;;
	*)
		echo " Invalid choice. Please try again."
		;;

esac
