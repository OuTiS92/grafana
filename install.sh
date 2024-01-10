#/bin/bash 
sleep 1 
clear 
echo "started ... "
sleep 1 
clear 

apt update && apt install  lolcat  && apt install figlet >> /dev/null
clear 
sleep 1
figlet github OuTiS92 | lolcat -t -s -d 

sleep 3 
apt install influxdb influxdb-client 
systemctl unmask influxdb.service

systemctl start influxdb
systemctl enable influxdb
sleep 1

if systemctl is-active --quiet influxdb ; then
	#echo "service infulxdb is running ..."
	#echo "I was getting port alrady in use error ... " 
	#sleep 2 
	influx  -execute "create database telegraf" 
	influx -execute  "create user telegraf with password 'root'"
	#exit
	apt install telegraf 
	systemctl start telegraf 
	systemctl enable telegraf
	if  systemctl is-active --quiet telegraf; then 
		
		mv /etc/telegraf/telegraf.conf /etc/telegraf/telegraf.conf.default
		cat ./telegraf.conf > /etc/telegraf/telegraf.conf
		systemctl restart telegraf 
		wget -q -O - https://packages.grafana.com/gpg.key | sudo apt-key add -
		#grep yes | sudo add-apt-repository "deb https://packages.grafana.com/oss/deb stable main" 
		apt update && apt install grafana 
		systemctl start grafana-server
		if systemctl is-active --quiet grafana; then 
			systemctl enable grafana-server
			sleep 2 
			echo "fnished instation grafana (+ influxdb ) "
			echo  "    "
			echo    "go to browser and enter   http://yourip:3000"	
			echo 	"Username : admin "
			echo 	"Password : admin "
			echo    " username database influxdb : telegraf  and password : root"  
			
		else 
			echo "service grafana not running !!!!!"
			exit
		fi
	else 
		echo "service influxdb not running !!!!!"
		exit
	fi


else 
	echo " service influxdb not runnint !!!!!!"
	exit
fi



















