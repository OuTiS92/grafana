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
sleep 1

if systemctl is-active --quiet fail2ban ; then
	echo "service infulxdb is running ..."
	echo "I was getting port alrady in use error ... " 
	sleep 2 
	clear 


else 
	echo " service influxdb not runnint !!!!!!"
	exit
fi



















