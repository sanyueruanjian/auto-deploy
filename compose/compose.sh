#!/bin/bash
#----------- 项目信息 不需要改--------------------------
# 项目名, 默认 marchsoft
PROJECT_NAME=marchsoft
# 构建过程中各个容器的数量
mysql=0
nginx=0
# node 版本管理工具
nvm=0
redis=0
# 后端API容器
marchsoft_api=0
# 消息队列
rabbitmq=0
# docker可视化管理工具
portainer=0
#----------------------------------------------------

#---------- 此脚本环境变量 ----------------------------
GLOBAL_PATH=`awk -F "=" '/GLOBAL_PATH/{print $2}' .env`
#---------------------------------------------------- 


# 每次启动脚本都需做的准备
prepare(){
    # 如果docker-compose不存在，则进行下载
    if [ ! -e "/usr/local/bin/docker-compose" ]; then
        echo "未安装docker-compose，正在进行安装..."
        curl -o /usr/local/bin/docker-compose  http://elltor-blog.oss-cn-hangzhou.aliyuncs.com/software/docker-compose
        chmod +x /usr/local/bin/docker-compose
        echo "docker-compose 安装完成"
    fi    
    
    # 创建公共业务网桥, 所有容器都使用这个网桥
    docker network ls | grep "marchsoft_biz_net" 2>/dev/null 1>&2
    if [ $? -ne 0 ]; then
        docker network create --driver=bridge --subnet="172.22.0.0/16" --attachable="true" --gateway="172.22.0.1" marchsoft_biz_net
        echo "未发现公共网桥，创建 network: marchsoft_biz_net"
    fi
    
    # mysql 容器配置
    #for ((i=1; i<=$mysql; i++)){
    #}
    
    # nginx 容器配置
    for ((i=1; i<=$nginx; i++)){
        if [ ! -e "$GLOBAL_PATH/${PROJECT_NAME}_nginx_${i}" ]; then
            mkdir -p "$GLOBAL_PATH/${PROJECT_NAME}_nginx_${i}"
            # 强制拷贝覆盖所有文件 ×
            #cp -rf $PWD/nginx/* "$GLOBAL_PATH/${PROJECT_NAME}_nginx_${i}"
            if [ ! -e "$GLOBAL_PATH/${PROJECT_NAME}_nginx_${i}/nginx.conf" ]; then
                cat $PWD/nginx/nginx.conf > "$GLOBAL_PATH/${PROJECT_NAME}_nginx_${i}/nginx.conf"
            fi

            if [ ! -e "$GLOBAL_PATH/${PROJECT_NAME}_nginx_${i}/conf.d" ]; then
                mkdir -p "$GLOBAL_PATH/${PROJECT_NAME}_nginx_${i}/conf.d"
                cp -rf $PWD/nginx/conf.d/* "$GLOBAL_PATH/${PROJECT_NAME}_nginx_${i}/conf.d"
            fi
        fi
        # 总是拷贝 ./nginx/conf.d 目录下的所有配置文件到 nginx 容器启动目录的 conf.d
        #cat $PWD/nginx/nginx.conf > "$GLOBAL_PATH/${PROJECT_NAME}_nginx_${i}/nginx.conf" 
        #cp -rf $PWD/nginx/conf.d/* "$GLOBAL_PATH/${PROJECT_NAME}_nginx_${i}/conf.d"
    }

    # nvm 容器配置
    #for ((i=1; i<=$nvm; i++)) {
    #}
    
    # redis 容器配置
    for ((i=1; i<=$redis; i++)){
        if [ ! -e "$GLOBAL_PATH/${PROJECT_NAME}_redis_${i}" ]; then
            mkdir -p "$GLOBAL_PATH/${PROJECT_NAME}_redis_${i}"
            cp -rf $PWD/redis/* "$GLOBAL_PATH/${PROJECT_NAME}_redis_${i}"
        fi  
    }

    # 后端api 容器配置
    #for ((i=1; i<=$marchsoft_api; i++)){
    #}

    # rabbitmq 容器配置
    #for ((i=1; i<=$rabbitmq; i++)){
    #}
    
    # portainer 部分配置
    #for ((i=1; i<=$portainer; i++)){ 
    #}      
}

# 打印帮助
print_help(){
    echo "usage: 这些命令只能能在这个目录使用，因为启动时自动读取当前目录下的配置文件和环境变量。格式如下："
    echo "  1) ./compose.sh <command> [options]"
    echo "  2) sh compose.sh <command> [options]"
    echo "commands:"
    echo "  env                   显示当前环境变量，该命令等价于 cat .env，若编辑修改使用 vi/vim"
    echo "  up [-d] [<服务名>..]   启动项目，后台运行加 -d 参数（这是默认执行此脚本的参数）"
    echo "  ps [<服务名>..]        显示容器运行情况，同 docker ps 命令"
    echo "  start [<服务名>..]     启动服务，exit -> up"
    echo "  restart [<服务名>..]   重启服务容器"
    echo "  stop [<服务名>..]      停止服务，up -> exit"
    echo "  exec <服务名> bash     进入服务容器，以 bash 交互"
    echo "  config                验证并输出完整 docker-compose.yml 配置"
    echo "  run [<服务名>..]       运行一个服务（容器），通常我们使用 up 命令启动"
    echo "  rm [<服务名>..]        移除停止的容器，删除容器"
    echo "  logs [<服务名>..]      显示服务日志"
    echo "  top [<服务名>..]       查看容器状态，内容：UID、PID、PPID、C、STIME、TTY、TIME、CMD"
    echo "  images                列出所有服务使用的镜像（进本方案）"
    echo "  help                  显示 compose.sh 帮助"
    echo "  --help                显示 docker-compose 帮助"
    echo "说明：'[]'选项代表可选参数，不加默认对所有服务生效；在方案中 服务名=容器名=容器内主机名（hostname），都代指一个容器"
}

# 调用预操作函数
prepare

# 根据参数的情况调用执行 docker-compose 命令
if [ $# -eq 0 ]; then
    docker-compose up -d
elif [ $1 = "help" ]; then
    print_help
elif [ $1 = "env" ]; then
    cat .env 
else
    docker-compose $@
fi

