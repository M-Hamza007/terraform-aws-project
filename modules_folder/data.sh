#!/bin/bash
sudo apt-get update
sudo apt-get install httpd
sudo apt-get install nginx -y
sudo echo "Hello, from terraform!!" >/var/www/html/index.nginx-debian.html
sudo service httpd start
chkconfig httpd on