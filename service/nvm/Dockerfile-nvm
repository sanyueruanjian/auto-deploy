# 依赖centos环境
FROM centos:latest
# 指定工作目录（进入容器的默认目录）
WORKDIR /project
#安装vim和git环境
COPY ./nvm/nvm-install.sh /root
RUN yum -y update \
    && yum -y install vim \
	&& yum -y install git \
	&& git --version \
	&& cd ~/ \
	&& sh nvm-install.sh 



