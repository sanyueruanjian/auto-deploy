#!/bin/bash

# docker安装
if [ `docker --version | wc -l` != 1 ];then
	sudo yum -y update &&\
	sudo yum install -y yum-utils device-mapper-persistent-data lvm2 &&\
	sudo yum-config-manager --add-repo http://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo &&\
	sudo yum install docker-ce -y
fi
# docker修改镜像后启动
if [ ! -d "/etc/docker" ];then
	`mkdir -d /etc/docker`
  	`touch /etc/docker/daemon.json`
fi
echo -e "{\n\t\"registry-mirrors\": [\"https://6prwwss1.mirror.aliyuncs.com\"]\n}" > /etc/docker/daemon.json
sudo systemctl daemon-reload
sudo systemctl restart docker

# git安装

if [ `git --version | wc -l` != '1' ];then sudo yum install git -y;fi

# expect安装 expect用于提供脚本和控制台交互功能
if [ `yum list installed | grep expect | wc -l` != '1' ];then sudo yum install expect -y;fi
