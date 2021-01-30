#!/bin/bash

# ----------------------备份数据库设置-----------------------------
mysql_user="root" #MySQL备份用户
mysql_password="123456" #MySQL备份用户的密码
mysql_host="172.17.0.3" #mysql在本机上的地址,如果在docker容器内填容器地址，
mysql_port="3306"
backup_db_arr=("sys" "mysql") #要备份的数据库名称,多个用空格分开隔开,如("db1" "db2" "db3")
mysql_charset="utf8" #MySQL编码
# ----------------------备份过期删除设置-----------------------------
expire_backup_delete="ON" #是否开启过期备份删除 ON为开启 OFF为关闭
expire_days=30 #过期时间天数 默认为三天，此项只有在expire_backup_delete开启时有效

# ----------------------备份位置设置-------------------------------
backup_location=/opt/mysql  #备份数据存放位置，末尾请不要带"/",此项可以保持默认，程序会自动创建文件夹
backup_time=`date +%Y%m%d%H%M`  #定义备份详细时间
backup_Ymd=`date +%Y-%m-%d` #定义备份目录中的年月日时间
backup_dir=$backup_location/$backup_Ymd  #备份文件夹全路径

# ----------------------日志配置-----------------------------------
log_file=$backup_dir/$backup_Ymd.log #日志文件
log_switch="ON" # 是否开启日志 ON为开启 OFF为关闭
log_console_switch="ON" # 是否开启终端显示日志 ON为开启 OFF为关闭 可用来测试是否可备份成功

# ----------------------辅助函数-----------------------------------
# 日志打印函数
function printLog(){
    if [ "$log_console_switch" == "ON" ];then echo $(date +"%Y-%m-%d %H:%M:%S") $1; fi
	if [ "$log_switch" == "ON" ];then
	   echo $(date +"%Y-%m-%d %H:%M:%S") $1 >> $log_file;
    fi
}
# ---------------------------------------------------------------

# 这里的-d 参数判断备份文件夹是否存在 
if [ ! -d "$backup_dir" ]; then 
    `mkdir -p $backup_dir`
fi 

# 这里的-f参数判断日志文件是否存在 
if [[ "$log_switch" == "ON" ]] && [[ ! -f "$log_file" ]];then 
    `touch $log_file`
fi

# 判断MYSQL是否启动,mysql没有启动则备份退出
mysql_ps=`ps -ef |grep mysql |wc -l`
mysql_listen=`netstat -an |grep LISTEN |grep $mysql_port|wc -l`
# 进程与端口检查
if [ [$mysql_ps == 0] -o [$mysql_listen == 0] ]; then
        printLog "ERROR:MySQL is not running! backup stop!"
        exit
else
        printLog "SUCCESS:Mysql is running. Start trying to backup!"
fi

# 连接到mysql数据库，无法连接则备份退出
mysql -h$mysql_host -P$mysql_port -u$mysql_user -p$mysql_password <<end
use mysql;
select host,user from user where user='root' and host='localhost';
exit
end

flag=`echo $?`
if [ $flag != "0" ]; then
        printLog "ERROR:Can't connect mysql server! backup stop!"
        exit
else
        printLog "MySQL connect ok! Please wait......"
        # 判断有没有定义备份的数据库，如果定义则开始备份，否则退出备份
        if [ "$backup_db_arr" != "" ];then
                # 循环备份数据库
                for dbname in ${backup_db_arr[@]}
                do
                        printLog "database $dbname backup start..."
                        `mysqldump -h$mysql_host -P$mysql_port -u$mysql_user -p$mysql_password $dbname --default-character-set=$mysql_charset | gzip > $backup_dir/$dbname-$backup_time.sql.gz`
                        flag=`echo $?`
                        if [ $flag == "0" ];then
                                printLog "database $dbname success backup to $backup_dir/$dbname-$backup_time.sql.gz"
                        else
                                printLog "database $dbname backup fail!"
                        fi
                        
                done
        else
                printLog "ERROR:No database needs to backup! backup stop"
                exit
        fi
        # 如果开启了删除过期备份，则进行删除操作
        if [ "$expire_backup_delete" == "ON" -a  "$backup_location" != "" ];then
                 #`find $backup_location/ -type d -o -type f -ctime +$expire_days -exec rm -rf {} \;`
                 `find $backup_location/ -type d -mtime +$expire_days | xargs rm -rf`
                 #echo "Expired backup data delete complete!"
        fi
        printLog "All database backup success! Thank you!"
        exit
fi 