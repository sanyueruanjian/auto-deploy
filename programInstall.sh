#!/bin/bash

# docker安装
docker_ex=`docker --version | wc -l` 
if [ $docker_ex != 1 ];then
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
echo -e "{\n\t\"registry-mirrors\": [\"https://hv76hnc6.mirror.aliyuncs.com\"]\n}" > /etc/docker/daemon.json
systemctl start docker

# git安装
git_ex=`git --version | wc -l`
if [ $git_ex != '1' ];then
	sudo yum install git -y
fi

# expect安装 expect用于提供脚本和控制台交互功能
expect_ex=`yum list installed | grep expect | wc -l`
if [ $expect_ex != '1' ];then
	sudo yum install expect -y
fi



