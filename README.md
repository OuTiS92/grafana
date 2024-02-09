# grafana
Install Grafana and Import Dashboards (mini)

Please Run  sudo Installer  =>  ( sudo ./install.sh )

## Install 

```
 bash <(curl -fsSL https://raw.githubusercontent.com/OuTiS92/grafana/main/install.sh) 
```

1 . 

Now to to Grafana and click on “Home → Administration → Data Source”
Select “Prometheus” as data source and give IP of prometheus along with server




![Screenshot_20240209_180826](https://github.com/OuTiS92/grafana/assets/33751897/92681401-3071-4c28-a772-d025d0aa0db9)



Scroll down and click on “Save & Test” button if you see successful message that means your data source added successfully


Now Click on “+” icon in right top corner

and select “Import Dashboard” option and Give “7362” number for MySQL dashboard if you want customize your dashboard you can or also find more dashboard on Dashboards | Grafana Labs and click on “Load”

![Screenshot_20240209_181134](https://github.com/OuTiS92/grafana/assets/33751897/6b639f85-876a-4db1-bedd-637064545cfd)



Select Data source “Prometheus” as we configure and click on “Import”


![Screenshot_20240209_181236](https://github.com/OuTiS92/grafana/assets/33751897/41af0767-d7fe-41b5-a565-64f63685bdb4)

Here you can see full metrics of your MySQL

![screencapture-grafana-outiss-ir-d-MQWgroiiz-mysql-overview-testi-2024-02-09-18_13_39](https://github.com/OuTiS92/grafana/assets/33751897/65b5d81d-a7fc-44e6-9e39-d717c8db55d0)






2 .  

Preview :

![preview](https://github.com/OuTiS92/grafana/assets/33751897/0bccea7f-91bc-4331-bc7c-93f6d28813d1)

after install grafana . install influx in GUI grafana and edit username and password :


![influxdb](https://github.com/OuTiS92/grafana/assets/33751897/57f7d4ac-234f-4a76-85b0-221c0f9fada9)



and import json file in directory grafana Dashboard :


![import](https://github.com/OuTiS92/grafana/assets/33751897/6cb8cc6a-1a02-4dab-bd44-ffb2df099978)





![json](https://github.com/OuTiS92/grafana/assets/33751897/93a6696a-1f50-4318-9d73-8d23af89c660)






