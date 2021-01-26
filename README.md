# auto-deploy

服务器自动化部署方案。

## 项目简介（Introduction）

基于 docker、docker-compose、shell 的自动化构建和编排容器。使用时仅需一点 linux 基础即可轻松构建多个容器。

**项目状态:** 基本功能已经完成，正在完善细节。

## 主要特性（ Characteristic）

* 多构建方案生成，一次生成多台服务器构建
* 构建方案独立，生成的构建方案可以跟随项目
* 操作简单，交互式操作，仅需输入少量参数就可以生成完整构建容器方案

## 项目结构（Project Structure）

```
- common                           服务器通用脚本
    - container-script             仅容器使用的脚本
    - server-script                服务器脚本
- compose                          compose 的 yml 配置文件的依赖
    - header-config.yml            
    - footer-config.yml
    - docker-compose.env
    - docker-compose.yml           完成 compose 配置文件
    - compose.sh                   方案启动脚本
- service                          放置独立的 docker-compose 服务
    - marchsoft-api                运行后端服务容器
    - mysql
    - nginx
    - nvm 
    - portainer
    - rabbitmq
    - redis
    - shell-template.sh 
- target                           放置生成容器构建方案
- build.sh                         启动构建入口
```



## 使用指南（Usage ）

#### 1. 使用前准备

1.1 使用前置技能

* Linux基础，熟悉常用命令：cd、ls、cp、cat、mv、vi/vim、sh、yum、rm
* docker基础，熟悉docker常用命令：run、exec、ps、rm、build

1.2 安装 docker，安装完后强烈推荐配置 docker 镜像加速，这样构建过程会更顺畅。



#### 2. 使用步骤

2.1 下载项目代码

```
git clone -b main https://github.com/shiwei-Ren/auto-deploy.git
```

2.2 编辑项目下 `build.sh` 里的配置清单

使用 `vi/vim` 命令编辑 `build.sh` 修改如下信息：

```
#------ 构建 docker-compose.yml 需填的信息-------------
# 项目名，这是必填项
PROJECT_NAME=marchsoft

# 设置构建容器的数量, 值为非负数, 如果不构建填：0
mysql=1
nginx=1
nvm=0
redis=0
marchsoft_api=2
rabbitmq=0
portainer=0
#----------------------------------------------------
```

`marchsoft` 指明了我们构建方案的名称。构建方案文件夹名称、容器名称、主机名称等都与此相关。以上配置信息生成的容器构建方案会生成在 `./target/marchsoft` 下，启动该构建方案会启动一个mysql容器、一个nginx容器和两个后端api容器。

为了方便介绍我们用了一些 “专用词”，了解它们能够解决你脑海中的一点疑惑。

* 配置清单：指生成构建方案所需填写的信息，需填写的内容有项目名称（PROJECT_NAME）和需要启动各个容器的数量
* 构建方案、构建的项目：它们是 `target` 目录下生成的一个目录，这个目录中包含了构建容器所需的配置文件和shell脚本，以项目名 `PROJECT_NAME` 命名
* 服务、容器配置：指一个启动一个容器的yml配置，在 `docker-compose` 中把一个容器看做一个服务（service）
* 构建脚本：指项目路径下的 `build.sh` 脚本
* 项目启动脚本、构建方案启动脚本：指在 `target` 目录下生成的以项目名（`PROJECT_NAME`）命名的文件夹里的 shell 脚本。在使用指南中演示的指 `compose.sh` 脚本



2.3 运行 `build.sh` 脚本进行构建

```bash
# 可以使用的命令
sh build.sh
bash build.sh
```

运行过程中部分容器需要输入端口号，如果使用默认端口号可以直接回车确认。按照 2.2 的配置清单，这里只输入 mysql 容器的端口即可，其他不需要指明端口服务配置直接生成。

```bash
sh build.sh 
# 下面是输出和打印内容
不存在, 创建文件夹
第 1 个 | 请输入与mysql容器3306映射的端口(默认 3306): 
marchsoft_mysql_1 配置文件已生成 OK
marchsoft_nginx_1 配置文件已生成 OK
marchsoft_api_1 配置文件已生成 OK
marchsoft_api_2 配置文件已生成 OK
构建脚本(build.sh)执行完成
```

可以前往 `./target` 目录下查看构建出的方案，方案名称为指定的项目名

```bash
cd target
ls
# 以下是ls打印内容
marchsoft #按照 2.2 配置生成的方案文件夹名称
```



2.4 启动 & 构建容器

2.4.1 前往并查看方案内容

```bash
cd marchsoft
ll
# 以下是打印内容
total 16
-rw-r--r-- 1 root root 4508 Jan 18 20:50 docker-compose.yml
-rw-r--r-- 1 root root  790 Jan 18 20:50 Dockerfile-api
-rwxr-xr-x 1 root root 2359 Jan 18 20:50 compose.sh # 启动shell
drwxr-xr-x 3 root root   38 Jan 18 20:50 nginx
```

2.4.2 运行构建启动命令

```bash
cd marchsoft
# 启动方式
sh compose.sh # 通过sh命令启动
./compose.sh # 直接运行脚本
```

启动项目，启动打印日志如下：

```bash
./compose.sh 
# 以下是打印内容
Creating marchsoft_api_1   ... done
Creating marchsoft_mysql_1 ... done
Creating marchsoft_api_2   ... done
Creating marchsoft_nginx_1 ... done
marchsoft.sh 启动脚本执行完成
```

如果是第一次构建方案，以下是会发生的（新手略）：

* 若未安装 `docker-compose` 则进行安装
* 创建容器公共网桥（network）
* 通过 `Dockerfile` 构建 docker 镜像，docker 拉取远程仓库的镜像


2.4.3 运行 `compose.sh` 脚本使用命令

```
usage: 这些命令这能在这个目录使用，启动时自动读取当前目录下的配置文件和环境变量。格式如下：
  1) ./compose.sh <command> [options]
  2) sh compose.sh <command> [options]
commands:
  env                   显示当前环境变量，该命令等价于 cat .env，若编辑修改使用 vi/vim
  up [-d] [<服务名>..]   启动项目，后台运行加 -d 参数（这是默认执行此脚本的参数）
  ps [<服务名>..]        显示容器运行情况，同 docker ps 命令
  start [<服务名>..]     启动服务，exit -> up
  restart [<服务名>..]   重启服务容器
  stop [<服务名>..]      停止服务，up -> exit
  exec <服务名> bash     进入服务容器，以 bash 交互
  config                验证并输出完整 docker-compose.yml 配置
  run [<服务名>..]       运行一个服务（容器），通常我们使用 up 命令启动
  rm [<服务名>..]        移除停止的容器，删除容器
  logs [<服务名>..]      显示服务日志
  top [<服务名>..]       查看容器状态，内容：UID、PID、PPID、C、STIME、TTY、TIME、CMD
  images                列出所有服务使用的镜像（进本方案）
  help                  显示 compose.sh 帮助
  --help                显示 docker-compose 帮助
说明：'[]'选项代表可选参数，不加默认对所有服务生效；在方案中 服务名=容器名=容器内主机名（hostname），都代指一个容器
```

2.5 查看启动的容器

```bash
# 1.使用docker命令
docker ps -a

# 2.使用 compose.sh 命令, 同3
./compose.sh ps

# 3.使用docker-compose命令，注意此命令只能在构建方案文件夹下执行
 docker-compose ps
# 打印信息如下
         Name                        Command               State                           Ports                         
-------------------------------------------------------------------------------------------------------------------------
marchsoft_api_1     /bin/bash                        Up                         
marchsoft_api_2     /bin/bash                        Up                         
marchsoft_mysql_1   docker-entrypoint.sh --cha ...   Up      0.0.0.0:3306->3306/tcp, 33060/tcp                     
marchsoft_nginx_1   /docker-entrypoint.sh ngin ...   Up      0.0.0.0:443->443/tcp, 0.0.0.0:80->80/tcp,             
                                                             0.0.0.0:8000->8000/tcp, 0.0.0.0:8001->8001/tcp,   
```

容器状态显示为 `UP` 说明启动成功。



#### 3. 进行一些定制和修改

如果需要修改或自定义一些内容，如全局路径、容器启动默认配置，可以通过修改项目方案下的 `.env` 文件里的环境变量或 `docker-compose.yml` 来实现。

操作方法

```shell
# 修改 .env 文件
vi .env
# 修改 docker-compose.yml 文件
vi docker-compose.yml
```

.env 环境变量部分内容

```
# 全局部署路径
GLOBAL_PATH=/root

# mysql默认密码
MYSQL_ROOT_PASSWORD=123456

# redis 默认密码
REDIS_DEFAULT_PASS=123456

# rabbitmq 默认虚拟机和用户账号
RABBITMQ_DEFAULT_VHOST=/
RABBITMQ_DEFAULT_USER=root
RABBITMQ_DEFAULT_PASS=123456

# 容器镜像版本
MYSQL_IMAGE=mysql:8.0.22
REDIS_IMAGE=redis:6.0.10
RABBITMQ_IMAGE=rabbitmq:management
NGINX_IMAGE=nginx:1.18.0
# docker可视化工具
PORTAINER_IMAGE=portainer/portainer
```



docker-compose.yml 配置文件部分内容

```
  # 后端 api 项目容器（推荐以项目名命名）------------------------------------
  marchsoft_api_1:
    container_name: marchsoft_api_1
    hostname: marchsoft_api_1
    # 部署启动策略
    deploy:
      restart_policy:
        condition: on-failure
        max_attempts: 3
    image: centos7_mvn_git_java8:2.0
    # 构建相关
    build: 
      # 指定镜像构建目录
      context: .
      # 指定 Dockerfile 文件名称
      dockerfile: Dockerfile-api
    # 设置网络，这里配置的是公共网桥 marchsoft_biz_net
    networks:
      - marchsoft_biz_net
    # 映射卷
    volumes:
      - "${GLOBAL_PATH}/project:/project"
    environment:
      - TZ=Asia/Shanghai
    # 配置容器的依赖、启动先后。一般在构建时我们不使用，除非我们已运行下面的容器
    #depends_on:
      #- mysql
      #- redis
      #- rabbitmq
      #- nginx
    # 没有进程运行，容器启动后会自动停止，使用tty阻塞容器
    tty: true
```



## 学习网站推荐（Learn & Study）

* 官方 docker-compose : https://docs.docker.com/compose
* 官方 compose file 3 : https://docs.docker.com/compose/compose-file/compose-file-v3
* 官方 docker : https://docs.docker.com/engine
* bilibili docker & docker-compose 教程 : https://www.bilibili.com/video/BV1ZT4y1K75K
* docker 中文教程 1 : http://www.dockerinfo.net/document
* docker 中文教程 2 : https://docker_practice.gitee.io/zh-cn



## 贡献（Contribute）

欢迎任何人为项目添砖加瓦、反馈问题（issue）。

参与贡献可以先联系开发者，我们会给与一些指导。


## 开发者、技术支持（Develop & Support）

* [@renshiwei](https://github.com/shiwei-Ren) 

* [@liuqichun](https://github.com/elltor)

* 技术支持 : [三月软件](http://marchsoft.cn)

