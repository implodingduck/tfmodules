#! /bin/bash
sudo apt update
sudo apt install -y nginx 
sudo systemctl status nginx
sudo ufw allow 'Nginx Full'
sudo systemctl enable nginx