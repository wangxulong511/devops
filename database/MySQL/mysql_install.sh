#!/bin/bash
# author:yanwei.wei 
# Email:yanwei.wei@flaginfo.com.cn
#date 20171123
#version 0.0.2
#set system 
#$1 mysql server PORT
#$2 mysql DATADIR
#$3 databasename
if [ $# -ne 3 ];then
   echo "Usage:bash $0 PORT DATADIR"
   echo -e "eg: bash $0 3306 data databasename"
   exit 1
fi

if [ $UID -ne 0 ];then
   echo "Must be use ROOT"
   exit 2
fi

echo -e "####Install mysql require"
yum -y install gcc gcc-c++ openssl openssl-devel zlib zlib-devel libaio wget lsof vim-enhanced sysstat ntpdate numactl.x86_64 bc

echo -e "#### 检查系统版本###"
VSER_NUM=`cat /etc/redhat-release |grep 'release 6'|wc -l`
if [ $VSER_NUM -ne 1  ]; then
    echo "this system is Centos 7"
    sed -i 's@1024@20480@g' /etc/security/limits.d/20-nproc.conf
    IP_LAST=` ip add|grep eth0|grep inet|awk -F '/' '{print $1}'|awk -F ' ' '{print $2}'|awk -F . '{print $4}'`
else 
    echo "this system is Centos 6"
    sed -i 's@1024@20480@g' /etc/security/limits.d/90-nproc.conf
    IP_LAST=`/sbin/ifconfig eth0 | awk -F ':' '/inet addr/{print $2}' | sed 's/[a-zA-Z ]//g'|awk -F . '{print $4}'`
fi
#关闭Linux透明透明大页功能
cat >>/etc/rc.local <<EOF
echo never >/sys/kernel/mm/transparent_hugepage/defrag
echo never >/sys/kernel/mm/transparent_hugepage/enabled
EOF
. /etc/rc.local
#修改cpu调度策略
echo "deadline" >/sys/block/sda/queue/scheduler
echo "echo \"deadline\" >/sys/block/sda/queue/scheduler" >>/etc/rc.local

PORT=$1
DATADIR=$2
DATANAMES=$3
MEM=`free -m|grep Mem|awk -F " " '{print $2}'`
PER=0.7
I=$(echo "$MEM * $PER" | bc)
INNODB_BUFFER=`printf "%1.f\n" $I`
TARFILE="mysql-5.7.20-linux-glibc2.12-x86_64.tar.gz"
TARFILEDIR="${TARFILE%.tar.gz*}"
REALPATH=$(readlink -f "$0")
REALDIR=$(dirname "$REALPATH")

echo -e "######Set selinux#####"
sed -i '/SELINUX/s/enforcing/disabled/' /etc/selinux/config
setenforce 0
 
#ntpdate 0.pool.ntp.org
#timedatectl set-timezone "Asia/Shanghai"
echo -e "#####ADD USER mysql#######"
MYSQL_USER=$(id mysql)
if [ -z "$MYSQL_USER" ]
then
    groupadd mysql
    useradd -r -g mysql -s /sbin/nologin mysql
    echo "create user mysql by this script" 
else
    echo "user mysql has been created before run this script" 
fi

cd "${REALDIR}"
#wget https://cdn.mysql.com//Downloads/MySQL-5.7/${tarfile}
if [ ! -d ${TARFILEDIR} ];then
   tar xf $TARFILE -C /usr/local/src
   ln -s /usr/local/src/${TARFILEDIR} /usr/local/mysql
fi
#创建数据库目录
mkdir /${DATADIR}/mysql/mysql${PORT}/{data,logs,tmp} -p
#授权目录mysql权限
chown mysql.mysql /usr/local/src/${TARFILEDIR}  /usr/local/mysql /${DATADIR}/mysql -R

echo "add my.cnf"

cat > /etc/my.cnf << EOF
[client]
port = ${PORT}
socket = /tmp/mysql${PORT}.sock
default-character-set=utf8mb4
[mysql]
prompt="\\u@\\h [\\d]>" 
no-auto-rehash
 
[mysqld]
user = mysql
basedir = /usr/local/mysql
datadir = /${DATADIR}/mysql/mysql${PORT}/data
port = ${PORT}
socket = /tmp/mysql${PORT}.sock
event_scheduler = 0
explicit-defaults-for-timestamp=on
tmpdir = /${DATADIR}/mysql/mysql${PORT}/tmp
skip-name-resolve 
######timeout settings######
interactive_timeout = 2880000
wait_timeout = 2880000
character-set-server = utf8mb4
########connection settings########
default-time-zone = '+8:00'
lower_case_table_names=1
open_files_limit = 65535
max_connections = 2000
max_user_connections= 1998
max_connect_errors = 100000
########log settings########
log-output=file
slow_query_log = 1
slow_query_log_file = /${DATADIR}/mysql/mysql${PORT}/logs/slow.log
log-error = error.log
log_error_verbosity=2
pid-file = mysql.pid
long_query_time = 1
log-slow-slave-statements = 1
 
#####binlog settings#######
auto_increment_increment = 1
auto_increment_offset = 1
binlog_format = row
server-id = ${PORT}${IP_LAST}
log-bin = /${DATADIR}/mysql/mysql${PORT}/logs/mysql-bin
binlog_cache_size = 4M
max_binlog_size = 1G
max_binlog_cache_size = 2G
sync_binlog = 1
expire_logs_days = 7
#procedure 
log_bin_trust_function_creators=1
 
####GTID settings########
gtid-mode=on
binlog_gtid_simple_recovery = 1
enforce_gtid_consistency = 1
log_slave_updates
 
####relay log settings#####
skip_slave_start = 1
max_relay_log_size = 128M
relay_log_purge = 1
relay_log_recovery = 1
relay-log=/${DATADIR}/mysql/mysql3306/logs/relay-bin
relay-log-index=/${DATADIR}/mysql/mysql3306/logs/relay-bin.index
#skip-grant-tables
 
####buffers & cache settings########
table_open_cache = 2048
table_definition_cache = 2048
table_open_cache = 2048
max_heap_table_size = 96M
sort_buffer_size = 16M
join_buffer_size = 16M
thread_cache_size = 3000
query_cache_size = 0
query_cache_type = 0
query_cache_limit = 256K
query_cache_min_res_unit = 512
thread_stack = 192K
tmp_table_size = 96M
key_buffer_size = 8M
read_buffer_size = 2M
read_rnd_buffer_size = 16M
bulk_insert_buffer_size = 32M
 
#######myisam sttings#####
myisam_sort_buffer_size = 128M
myisam_max_sort_file_size = 10G
myisam_repair_threads = 1
 
#####innodb settings######
innodb_buffer_pool_size = ${INNODB_BUFFER}M
innodb_buffer_pool_instances = 8
innodb_data_file_path = ibdata1:1G:autoextend
innodb_flush_log_at_trx_commit = 1
innodb_log_buffer_size = 1G
innodb_log_file_size = 100M
innodb_log_files_in_group = 3
innodb_max_dirty_pages_pct = 50
innodb_file_per_table = 1
innodb_rollback_on_timeout
innodb_status_file = 1
innodb_buffer_pool_load_at_startup = 1
innodb_buffer_pool_dump_at_shutdown = 1
transaction_isolation = READ-COMMITTED
innodb_flush_method = O_DIRECT
innodb_lock_wait_timeout = 10
innodb_rollback_on_timeout = 1
innodb_print_all_deadlocks = 1
innodb_file_per_table = 1
innodb_online_alter_log_max_size = 1G
internal_tmp_disk_storage_engine = InnoDB
innodb_stats_on_metadata = 0
######io settings############
innodb_io_capacity = 4000
innodb_io_capacity_max = 8000
innodb_flush_neighbors = 0
innodb_write_io_threads = 8
innodb_read_io_threads = 8
innodb_purge_threads = 4
innodb_page_cleaners = 4
#performance_schema
performance_schema = 1
performance_schema_instrument = '%=on'
######innodb monitor settings#####
innodb_monitor_enable="module_innodb"
innodb_monitor_enable="module_server"
innodb_monitor_enable="module_dml"
innodb_monitor_enable="module_ddl"
innodb_monitor_enable="module_trx"
innodb_monitor_enable="module_os"
innodb_monitor_enable="module_purge"
innodb_monitor_enable="module_log"
innodb_monitor_enable="module_lock"
innodb_monitor_enable="module_buffer"
innodb_monitor_enable="module_index"
innodb_monitor_enable="module_ibuf_system"
innodb_monitor_enable="module_buffer_page"
innodb_monitor_enable="module_adaptive_hash"
EOF

echo -e "######initialize  mysql##############" 
cd /usr/local/mysql 
./bin/mysqld --initialize-insecure 
cp support-files/mysql.server /etc/init.d/mysqld

echo -e "########start mysql###########"
/etc/init.d/mysqld start 
echo -e "########Set mysql PATH########"
echo 'export PATH=/usr/local/mysql/bin:$PATH' >>/etc/profile
source /etc/profile
/usr/local/mysql/bin/mysql -uroot -e "set password=password('test')"
echo -e "MySQL root password is test"

echo -e "################Test mysql#####################"

TEST=`mysql -u root -ptest -e "show databases;"|grep sys|wc -l`
if [ $TEST -ne 1 ];then
   echo -e "mysql install is flase"
   exit 100
else
   echo -e "mysql is install successfull"
fi

echo -e "################Create database js_${DATANAMES} and user js_${DATANAMES} #############################"
mysql -u root -ptest -e "create database js_$DATANAMES default character set utf8"
mysql -u root -ptest -e "grant all privileges  on js_${DATANAMES}.* to 'js_${DATANAMES}'@'%' identified by 'js_${DATANAMES}#123!'"
mysql -u root -ptest -e "flush privileges"

        echo "DataBaseName: js_$DATANAMES"
        echo "DataUser: js_$DATANAMES"
        echo "DataPassword: js_${DATANAMES}#123!"
        echo "DataUser: js_$DATANAMES DataPassword: js_$DATANAMES#123!" >>/root/Mysql_Data_List.txt  
