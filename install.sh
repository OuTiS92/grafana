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

	local dependenxies=("wget" "unzip" "git" "curl" "tar" "lolcat" "figlet" "influxdb" "influxdb-client")
	
	for dep in "${dependenxies[@]}"; do
		if ! command -v "${dep}" &> /dev/null; then
			echo "${dep} is not installed, installing ...."
			sudo "${package_manager}" install "${dep}" -y 
		fi
	done
}

#apt update && apt install  lolcat  && apt install figlet >> /dev/null
#clear 
#sleep 1



check_install_influxd() {
	if [ -f "/etc/systemd/system/influxd.service"]; then 
		echo "the service is already installed."
		exit 1
	fi
}












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



















