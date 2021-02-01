#!/bin/sh
#此脚本用在后端服务和 nginx 配置管理
#使用说明：
#  1) 以下几个信息在使用脚本前须根据项目补全
#  2) nginx的配置文件必须放在和这个脚本同级的目录

# git 拉取的分支，开发用 develop，线上用 master
GIT_PULL_BRANCH=develop

# docker 容器名字或者jar名字，这里都命名为这个（必填项）
API_CONTAINER_NAME=marchsoft_api_1

# 后端项目名，例如：scrch-api
API_PROJECT_NAME=scrch-api

# 从当前目录下 jar 包的相对路径，注意：不要以 ./ 开头！！ 示例：API_JAR_PATH=api_system/target/api_system-0.0.1.jar   #其中api_system为系统核心(API)模块 
API_JAR_PATH=api_system/target/api_system-0.0.1.jar

# nginx 容器名，关于nginx只需要填这一个参数，.conf在当前目录文件自动搜索
NGINX_CONTAINER_NAME=global_nginx_1

# ------------ 分隔线，以下用户无需更改 --------------------------------------
# 前端 - 前台项目名
PORTAL_PROJECT_NAME=scrch-mobile
# 前端 - 后台项目名
ADMIND_PROJECT_NAME=scrch-admin
# nvm 容器名
NVM_CONTAINER_NAME=global_nvm_1

# 待办 
# 使用 npm 编译 vue 项目 × 因为nvm软件原因暂时未实现容器外操作

# /project/scrch-manage
PROJECT_PATH=`pwd | grep -Eo "/project/.*" | grep -Eo "/project/.*/" | sed 's/.$//'`
#echo 'PROJECT_PATH:'$PROJECT_PATH

if [ -z $PROJECT_PATH ]; then
    # /project/scrch-manage/scrch-api
    PROJECT_PATH=`pwd|grep -Eo "/project/.*"`
fi

# /project/scrch-manage/scrch-api
API_PROJECT_PATH="$PROJECT_PATH/$API_PROJECT_NAME"


echo 'API_PROJECT_PATH:'$API_PROJECT_PATH

# /project/scrch-manage/scrch-api/api_system/target/api_system-0.0.1.jar
API_CONTAINER_JAR_PATH="$API_PROJECT_PATH/$API_JAR_PATH"
echo 'API_CONTAINER_JAR_PATH:'$API_CONTAINER_JAR_PATH

#----------------------------
# 容器内部署脚本文件夹路径
DEPLOY_PATH=`pwd | grep -Eo "/project/.*"`

# 项目nginx配置文件名称，如：scrch-manage.conf
NGINX_CONF_NAME=`find . -type f -name "*.conf"| awk 'NR==1'|sed 's/^..//'`

#echo 'NGINX_CONF_NAME:'"$DEPLOY_PATH/$NGINX_CONF_NAME"


usage(){
    echo "简介：这是后端服务使用的脚本，通过该shell脚本可以轻松管理后端服务。"
    echo "使用格式："
    echo "  sh 此脚本 <容器> [命令] [参数..]"
    echo "命令："
    echo "  start       启动命令，启动容器或服务"
    echo "  stop        停止运行服务或容器"
    echo "  restart     重启，等价于使用两个 stop、start"
    echo "  status      查看项目运行的状态"
    echo "  pull        拉取远程仓库的代码并运行项目"
    echo "  usage       查看帮助手册"
    echo "使用示例："
    echo "  1) sh deploy.sh api start test 8000   # 启动项目，以test配置文件启动，启动服务端口8000"
    echo "  2) sh deploy.sh api pull              # 拉取远程仓库代码，并重新启动项目，（这是常用操作）"
    echo "  3) sh deploy.sh api log [关键字]       # 查看启动日志，可以通过关键字过滤"
    echo "  4) sh deploy.sh nginx test            # 测试 nginx 配置文件"
    echo "  5) sh deploy.sh nginx restart         # 重启 nginx"
}

#检查程序是否在运行
is_api_execute(){
    # PID 容器内后端java程序的线程号
    PID=`docker exec $API_CONTAINER_NAME ps -aux | grep "$API_JAR_PATH" | awk 'NR==1 {print $2}'`
    #如果不存在返回 1，存在返回 0
    if [ -z "${PID}" ]; then
        return 1
    else
        return 0
    fi
}

# 判断 nginx 是否运行
is_nginx_execute(){
    docker ps -a |grep "global_nginx_1" | grep -o "Up"
    if [ $? -eq 0 ]; then
        docker exec $NGINX_CONTAINER_NAME nginx -h 2>/dev/null
        if [ $? -eq 0 ]; then
            return 0
        else
            return 1
        fi
    else
        return 2
    fi
}

is_linked_nginx_conf(){
    docker exec $NGINX_CONTAINER_NAME ls /etc/nginx/conf.d|grep $NGINX_CONF_NAME 2>/dev/null
    if [ $? -eq 0 ]; then
        return 0
    else
        return 1
    fi
}

link_nginx_conf(){
    docker exec $NGINX_CONTAINER_NAME ln -s $DEPLOY_PATH/$NGINX_CONF_NAME /etc/nginx/conf.d/$NGINX_CONF_NAME
    if [ $? -eq 0 ]; then
        echo "项目中的 nginx 配置文件（$NGINX_CONF_NAME）已经链接到nginx容器 /etc/nginx/conf.d"
    else
        echo "nginx 配置文件链接失败，请检查是否有误"
        exit 1
    fi
}

#启动方法
start_api(){
    profile=$1
    port=$2
    is_api_execute
    if [ $? -eq "1" ]; then
        echo "-------- Starting application ---------"
        nohup docker exec $API_CONTAINER_NAME java -server  -XX:-DisableExplicitGC -XX:+UseParNewGC -XX:+UseConcMarkSweepGC -jar $API_CONTAINER_JAR_PATH --spring.profiles.active="${profile:-prod}" --server.port="${port:-8000}" > start.log 2>&1 &
        sleep 1s
        echo "-------------- Started! ---------------"
    else
        echo "${API_CONTAINER_NAME} is already running. PID=${PID} ."
    fi
}

start_nginx(){
    is_nginx_execute
    NGINX_STATE=$?
    if [ $NGINX_STATE -eq 0 ]; then
        echo "$NGINX_CONTAINER_NAME 已经运行。"
    elif [  $NGINX_STATE -eq 1 ]; then
        docker exec -d  $NGINX_CONTAINER_NAME nginx
    elif [  $NGINX_STATE -eq 2 ]; then
        docker start $NGINX_CONTAINER_NAME
    fi
}

#停止方法
stop_api(){
    is_api_execute
    NGINX_STATE=$?
    if [ $NGINX_STATE -eq 0 ]; then
        docker exec $API_CONTAINER_NAME kill -9 $PID
        echo "-----------Application Stopped------------"
    else
        echo "${API_JAR_PATH} is not running"
    fi
}

stop_nginx(){
    is_nginx_execute
    NGINX_STATE=$?
    if [ $NGINX_STATE -eq 0 ]; then
        docker exec $NGINX_CONTAINER_NAME nginx -s stop
        echo "nginx 已停止"
    else
        echo "nginx 已停止"
    fi
}


#输出运行状态
status_api(){
    is_api_execute
    if [ $? -eq 0 ]; then
        echo "${API_JAR_PATH} is running. PID is ${PID}"
    else
        echo "${API_JAR_PATH} is NOT running."
    fi
}

status_nginx(){
    is_nginx_execute
    NGINX_STATE=$?
    if [ $NGINX_STATE -eq 0 ]; then
        echo "nginx 正在运行"
    elif [ $NGINX_STATE -eq 1 ]; then
        echo "nginx 已停止运行"
    elif [ $NGINX_STATE -eq 2 ]; then
        echo "nginx 容器停止运行了！！"
    fi
}

#重启
restart_api(){
    stop_api
    sleep 1s
    start_api $@
}

restart_nginx(){
    stop_nginx
    sleep 1s
    start_nginx
}


pull_api(){
    echo "-------------------- git：find status ----------------------"
    git status
    echo "------------------- git：pull new coads --------------------"
    git pull origin $GIT_PULL_BRANCH
    if [ $? -ne 0 ]; then
        exit 1
    fi
    echo "--------- mvn clean package -Dmaven.test.skip=true ---------"
    docker exec $API_CONTAINER_NAME mvn clean package -f "$API_PROJECT_PATH/pom.xml" -Dmaven.test.skip=true
    if [ $? -ne 0 ]; then
        exit 1
    fi
    echo "------------- Preparing start application -----------------"
    is_api_execute
    if [ $? -eq 0 ]; then
        restart_api $@
    else
        start_api $@
    fi
}

log_api(){
    arg=$1
    if [ -n "${arg:-''}" ]; then
        cat start.log | grep $arg
    else
        cat start.log
    fi    
}

test_nginx(){
    is_nginx_execute
    if [ $? -eq 0 ]; then
        docker exec $NGINX_CONTAINER_NAME nginx -t
    else
        echo "nginx 停止，请启动后重新尝试"
    fi
}

select_api(){
    case $1 in
        "start")
            start_api $2 $3 $4 $5 $6 $7 $8 $9
        ;;
        "stop")
            stop_api
        ;;
        "restart")
            restart_api $2 $3 $4 $5 $6 $7 $8 $9
        ;;
        "status")
            status_api
        ;;
        "pull")
            pull_api $2 $3 $4 $5 $6 $7 $8 $9
        ;;
        "log")
            log_api $2 $3 $4 $5 $6 $7 $8 $9
        ;;
        *)
            echo "API 容器命令格式错误，请查看操作指令说明。"
            usage
        ;;
    esac
}

select_nginx(){
    case $1 in
        "link-conf")
            is_linked_nginx_conf
            if [ $? -eq 0 ]; then
                echo "配置文件( $NGINX_CONF_NAME )已链接到nginx配置目录，无需重复链接"
            else
                link_nginx_conf
            fi
        ;;
        "test")
            test_nginx
        ;;
        "start")
            start_nginx
        ;;
        "stop")
            stop_nginx
        ;;
        "restart")
            restart_nginx
        ;;
        "status")
            status_nginx
        ;;
        *)
            echo "你输入的命令有误，请重新尝试，或查看以下命令。"
            usage
        ;;
    esac
}

#根据输入参数，选择执行对应方法，不输入则执行使用说明
select_container(){
    case $1 in
        "init")
            echo "全局初始化"
        ;;
        "api")
            select_api $2 $3 $4 $5 $6 $7 $8 $9
        ;;
        "nginx")
            select_nginx $2 $3 $4 $5 $6 $7 $8 $9
        ;;
        *)
            usage
        ;;
    esac
}

main(){
    select_container $@
}

# 执行全局方法
main $@
