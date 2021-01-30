#!/bin/bash
#注意:第一次编译执行时，要先执行pull命令，否则没有maven打的jar不行start。

# docker 容器名字或者jar名字，这里都命名为这个（必填项）
SERVER_NAME=api_system-0.0.1.jar

#这里的JAR_PATH为jar包所在位置（必填项）
JAR_PATH=./api_system/target/api_system-0.0.1.jar

# ------------ 分隔线，以下用户无需更改 --------------------------------------
profile=$2
port=$3

usage(){
    echo "简介：这是后端服务使用的脚本，通过该shell脚本可以轻松管理后端服务。"
    echo "使用格式："
    echo "  sh 此脚本 [命令] [参数..]"
    echo "命令："
    echo "  pull        拉取远程仓库的代码并运行项目"
    echo "  start       启动后端项目"
    echo "  restart     重启后端项目，等价于使用两个 stop、start"
    echo "  stop        停止项目运行"
    echo "  status      查看项目运行的状态"
    echo "  usage       查看帮助手册"
    echo "使用示例："
    echo "  1) sh 此脚本 start test 8000   # 启动项目，以test配置文件启动，启动服务端口8000"
    echo "  2) sh 此脚本 pull              # 拉取远程仓库代码，并重新启动项目，（这是常用操作）"
}

#检查程序是否在运行
is_exist(){
    pid=`ps -ef|grep "$JAR_PATH"|awk 'NR==1 {print $2}'`
    #如果不存在返回 1，存在返回 0
    if [ -z "${pid}" ]; then
        return 1
    else
        return 0
    fi
}

#启动方法
start(){
    is_exist
    if [ $? -eq 1 ]; then
        echo "-------- Starting application ---------"
        nohup java -server  -XX:-DisableExplicitGC -XX:+UseParNewGC -XX:+UseConcMarkSweepGC -jar $JAR_PATH --spring.profiles.active="${profile:-prod}" --server.port="${port:-8000}" > start.log 2>&1 &
        echo "-------------- Started! ---------------"
    else
        echo "${SERVER_NAME} is already running. pid=${pid} ."
    fi
}

#停止方法
stop(){
    is_exist
    if [ $? -eq 1 ]; then
        echo "${JAR_PATH} is not running"
    else
        kill -9 $pid
        echo "-----------Application Stopped------------"
    fi
}

#输出运行状态
status(){
    is_exist
    if [ $? -eq 1 ]; then
        echo "${JAR_PATH} is NOT running."
    else
        echo "${JAR_PATH} is running. Pid is ${pid}"
    fi
}

#重启
restart(){
    stop
    start
}

#mvn
pull(){
    echo "-------------------- git：find status ----------------------"
    git status
    echo "------------------- git：pull new coads --------------------"
    git pull origin develop
    if [ $? -ne 0 ]; then
        exit
    fi
    echo "--------- mvn clean package -Dmaven.test.skip=true ---------"
    mvn clean package -Dmaven.test.skip=true
    if [ $? -ne 0 ]; then
        exit
    fi
    echo "------------- Preparing start application -----------------"
    is_exist
    if [ $? -eq 0 ]; then
        restart
    else
        start
    fi
}

#根据输入参数，选择执行对应方法，不输入则执行使用说明
case "$1" in
    "start")
        start
    ;;
    "stop")
        stop
    ;;
    "status")
        status
    ;;
    "restart")
        restart
    ;;
    "pull")
        pull
    ;;
    *)
        usage
    ;;
esac
