#/bin/bash 
sleep 1 
clear 
echo "started ... "
sleep 1 
clear 
filetelegraf='/etc/telegraf/telegraf.conf'





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

install_service_mysql_export() {
	cat <<EOL > /etc/.mysqld_exporter.cnf
[client]
user=mysqld_exporter
password=StrongPassword
EOL
sudo chown root:prometheus /etc/.mysqld_exporter.cnf
}






check_installed_influx() {
	if[ -f "/etc/systemd/system/influxd.service" ]; then

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


install_mysql() {















