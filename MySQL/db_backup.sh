#!/bin/bash
source /etc/profile
cd /data/backup
MAXIMUM_BACKUP_FILES=10              #最大备份文件数
BACKUP_FOLDERNAME="testyldb_full"        #数据库备份文件的主目录
DB_HOSTNAME="localhost"              #mysql所在主机的主机名
DB_USERNAME="root"                   #mysql登录用户名
DB_PASSWORD="root"              #mysql登录密码
DB_NAME="archery"
BACKUP_DB_NAME="archery"
backuptool=/usr/bin/innobackupex
mycnf=/etc/my.cnf
#========= 添加备份文件信息
BEGIN_TIME=$(date +"%Y-%m-%d %H:%M:%S") #备份开始时间
BACKUP_TYPE="physical"  # innobackupex 为物理备份，mysqldump为逻辑备份
BACKUP_DATE=$(date +"%Y%m%d") # 备份时间
INSTANCE_NAME="压力测试3306" #备份实例名
INSTANCE_ID="yltest3306" #备份实例ID
#FINISH_TIME   #备份完成时间
#BACK_FILENAME  # 备份文件名
#=========
echo "Bash Database Backup Tool"
#CURRENT_DATE=$(date +%F)
CURRENT_DATE=$(date +"%Y%m%d%H%M%S")              #定义当前日期为变量
BACKUP_FOLDER="${BACKUP_FOLDERNAME}_${CURRENT_DATE}" #存放数据库备份文件的目录
mkdir -p $BACKUP_FOLDER #创建数据库备份文件目录

echo -n "   Began:  ";echo $(date)
if $($backuptool --defaults-file=$mycnf --host=${DB_HOSTNAME} --user=${DB_USERNAME} --password=${DB_PASSWORD} --port=3306 --no-timestamp ${BACKUP_FOLDER} >log 2>&1);then
    echo "  Dumped successfully!"
else
    echo "  Failed dumping this database!"
fi
    echo -n "   Finished: ";echo $(date)
echo
echo "[+] Packaging and compressing the backup folder..."
#tar -cv ${BACKUP_FOLDER} | gzip  ${BACKUP_FOLDER}.tar.gz  && rm -rf $BACKUP_FOLDER
tar -cvf ${BACKUP_FOLDER}.tar  ${BACKUP_FOLDER}  && rm -rf $BACKUP_FOLDER
# 添加备份信息到备份记录表中
BACK_FILENAME=${BACKUP_FOLDER}.tar   # 备份文件名
BACK_FILESIZE=$(du -k ${BACKUP_FOLDER}.tar|cut -f1)
echo ${BACK_FILESIZE}
INSERT_SQL="INSERT INTO database_backup (file_name, type, backup_id, stat, create_time, finish_time, creator, size, backup_date,instance_id,instance_name) VALUES ('${BACK_FILENAME}', '${BACKUP_TYPE}', 103586904, '0','${BEGIN_TIME}', NOW(), 'SYSTEM', ${BACK_FILESIZE}, ${BACKUP_DATE},${INSTANCE_ID},${INSTANCE_NAME})"
echo ${INSERT_SQL}
mysql -h${DB_HOSTNAME} -u${DB_USERNAME} -p${DB_PASSWORD} -D ${DB_NAME} -e "${INSERT_SQL}"

BACKUP_FILES_MADE=$(ls -l ${BACKUP_FOLDERNAME}*.tar | wc -l)
BACKUP_FILES_MADE=$(( $BACKUP_FILES_MADE - 0 ))
#把已经完成的备份文件数的结果转换成整数数字

echo
echo "[+] There are ${BACKUP_FILES_MADE} backup files actually."
#判断如果已经完成的备份文件数比最大备份文件数要大，那么用已经备份的文件数减去最大备份文件数,打印要删除旧的备份文件
if [ $BACKUP_FILES_MADE -gt $MAXIMUM_BACKUP_FILES ];then
    REMOVE_FILES=$(( $BACKUP_FILES_MADE - $MAXIMUM_BACKUP_FILES ))
echo "[+] Remove ${REMOVE_FILES} old backup files."
#统计所有备份文件，把最新备份的文件存放在一个临时文件里，然后删除旧的文件，循环出临时文件的备份文件从临时目录里移到当前目录
    ALL_BACKUP_FILES=($(ls -t ${BACKUP_FOLDERNAME}*.tar))
    SAFE_BACKUP_FILES=("${ALL_BACKUP_FILES[@]:0:${MAXIMUM_BACKUP_FILES}}")
echo "[+] Safeting the newest backup files and removing old files..."
    FOLDER_SAFETY="_safety"
if [ ! -d $FOLDER_SAFETY ]
then mkdir $FOLDER_SAFETY

fi
for FILE in ${SAFE_BACKUP_FILES[@]};do

    mv -i  ${FILE}  ${FOLDER_SAFETY}
done
    rm -rf ${BACKUP_FOLDERNAME}*.tar
    mv  -i ${FOLDER_SAFETY}/* ./
    rm -rf ${FOLDER_SAFETY}
#以下显示备份的数据文件删除进度，一般脚本都是放在crontab里，所以我这里只是为了显示效果，可以不选择这个效果。

CHAR=''
for ((i=0;$i<=100;i+=2))
do  printf "Removing:[%-50s]%d%%\r" $CHAR $i
        sleep 0.1
CHAR=#$CHAR
done
    echo
fi

