###############################################################################################################
LANG=C
#error log
log_error=`cat /etc/my.cnf|grep "log_error"`
log_error=`echo ${log_error#*=}`
#date
date=`mysql -e "select curdate();"`
date=`echo $date|awk '{print $2}'`
date2=`mysql -e "select date_sub(curdate(),interval 1 day);"`
date2=`echo $date2|awk '{print $4}'`
#check mysql server connect
ping=`mysqladmin ping`
#base dir
base=`cat /etc/my.cnf|grep basedir`
base=`echo ${base#*=}`
#data dir
data=`cat /etc/my.cnf | grep datadir`
data=`echo ${data#*=}`
#data free filesystem used
used=`df -h $data`
filesys=`echo $used|awk '{print $8}'`
free=`echo $used|awk '{print $11}'`
used=`echo $used|awk '{print $12}'`
#database uptime
uptime=`mysql -e"SHOW STATUS LIKE '%uptime%'"|awk '/ptime/{ calc = $NF / 3600;print $(NF-1), calc"Hour" }'` 
uptime=`echo $uptime|awk '{print $2}'`
#database threads
threads=`mysql -BNe "select count(host) from processlist;" information_schema`
#mysql max_used_connection
max_connect=`mysql -e "show status like '%max_used_connections%';"`
max_connect=`echo $max_connect|awk '{print $4}'`
#mysql aborted_clients
aborted_clients=`mysql -e "show status like '%aborted_clients%';"`
aborted_clients=`echo $aborted_clients|awk '{print $4}'`
#mysql aborted_connects
aborted_connects=`mysql -e "show status like '%aborted_connects%';"`
aborted_connects=`echo $aborted_connects|awk '{print $4}'`
#mysql server id
id=`mysql -e "show variables like 'server_id';"`
id=`echo $id|awk '{print $4}'`
#mysql read_only
reads=`mysql -e "show variables like 'read_only';"`
reads=`echo $reads|awk '{print $4}'`
#mysql max_connections
maxc=`mysql -e "show variables like 'max_connections';"`
maxc=`echo $maxc|awk '{print $4}'`
#mysql max_connect_errors
maxce=`mysql -e "show variables like 'max_connect_errors';"`
maxce=`echo $maxce|awk '{print $4}'`
#mysql wait_timeout
wt=`mysql -e "show variables like 'wait_timeout';"`
wt=`echo $wt|awk '{print $4}'`
s='s'
#mysql skip_name_resolve
snr=`mysql -e "show variables like 'skip_name_resolve';"`
snr=`echo $snr|awk '{print $4}'`
#mysql sync_binlog
sb=`mysql -e "show variables like 'sync_binlog';"`
sb=`echo $sb|awk '{print $4}'`
#mysql expire_logs_days
eld=`mysql -e "show variables like 'expire_logs_days';"`
eld=`echo $eld|awk '{print $4}'`
day='day'
#mysql table_open_cache
toc=`mysql -e "show variables like 'table_open_cache';"`
toc=`echo $toc|awk '{print $4}'`
#mysql query_cache_size
qcs=`mysql -e "show variables like 'query_cache_size';"`
qcs=`echo $qcs|awk '{print $4}'`
let qcs=$qcs/1024/1024
m='M'
#mysql sort_buffer_size
sbs=`mysql -e "show variables like 'sort_buffer_size';"`
sbs=`echo $sbs|awk '{print $4}'`
let sbs=$sbs/1024/1024
m='M'
#mysql read_buffer_size
rbs=`mysql -e "show variables like 'read_buffer_size';"`
rbs=`echo $rbs|awk '{print $4}'`
let rbs=$rbs/1024/1024
m='M'
#mysql join_buffer_size
jbs=`mysql -e "show variables like 'join_buffer_size';"`
jbs=`echo $jbs|awk '{print $4}'`
let jbs=$jbs/1024/1024
m='M'
#mysql tmp_table_size
tts=`mysql -e "show variables like 'tmp_table_size';"`
tts=`echo $tts|awk '{print $4}'`
let tts=$tts/1024/1024
m='M'
#mysql innodb_thread_concurrency
itc=`mysql -e "show variables like 'innodb_thread_concurrency';"`
itc=`echo $itc|awk '{print $4}'`
#mysql innodb_flush_method
ifm=`mysql -e "show variables like 'innodb_flush_method';"`
ifm=`echo $ifm|awk '{print $4}'`
#mysql innodb_file_per_table
ifpt=`mysql -e "show variables like 'innodb_file_per_table';"`
ifpt=`echo $ifpt|awk '{print $4}'`
#mysql innodb_flush_log_at_trx_commit
iflatc=`mysql -e "show variables like 'innodb_flush_log_at_trx_commit';"`
iflatc=`echo $iflatc|awk '{print $4}'`
#mysql innodb_lock_wait_timeout
ilwt=`mysql -e "show variables like 'innodb_lock_wait_timeout';"`
ilwt=`echo $ilwt|awk '{print $4}'`
s='s'
#mysql innodb_open_files
iof=`mysql -e "show variables like 'innodb_open_files';"`
iof=`echo $iof|awk '{print $4}'`
#mysql lower_case_table_names
lctn=`mysql -e "show variables like 'lower_case_table_names';"`
lctn=`echo $lctn|awk '{print $4}'`
#mysql innodb_buffer_pool_size
buffer=`mysql -e "show variables like 'innodb_buffer_pool_size';"`
buffer=`echo $buffer|awk '{print $4}'`
let buffer=$buffer/1024/1024
m="M"
#log_bin_basename
basename1=`mysql -e "show variables like 'log_bin_basename';"`
basename1=`echo $basename1|awk '{print $4}'`
#log_bin_index
index=`mysql -e "show variables like 'log_bin_index';"`
index=`echo $index|awk '{print $4}'`
#mysql binlog
binlog=`mysql -e "show variables like 'log_bin';"`
binlog=`echo $binlog|awk '{print $4}'`
#mysql binlog_format
format=`mysql -e "show variables like 'binlog_format';"`
format=`echo $format|awk '{print $4}'`
#mysql binlog_row_image
image=`mysql -e "show variables like 'binlog_row_image';"`
image=`echo $image|awk '{print $4}'`
#binlog file
file=`mysql -e "show master status;"`
file=`echo $file|awk '{print $6}'`
#binlog Position
pos=`mysql -e "show master status;"`
pos=`echo $pos|awk '{print $7}'`
#mysql slowlog
slow=`mysql -e "show variables like 'slow_query_log';"`
slow=`echo $slow|awk '{print $4}'`
#mysql slow_query_log_file
slowfile=`mysql -e "show variables like 'slow_query_log_file';"`
slowfile=`echo $slowfile|awk '{print $4}'`
#mysql error log
error=`mysql -e "show variables like 'log_error';"`
error=`echo $error|awk '{print $4}'`
#mysql log_timestamps
timestamps=`mysql -e "show variables like 'log_timestamps';"`
timestamps=`echo $timestamps|awk '{print $4}'`
#MySQL Master / Slave
ms=`mysql -e "show slave status\G"`
if [ -z "$ms" ];then
ms="Master"
else
ms="Slave"
fi
#Seconds Behind Master
seconds=`mysql -e "show slave status \G;"|awk '/Seconds_Behind_Master:/{print $2}'`
seconds=`echo $seconds|awk '{print $1}'`
#Slave_IO_Running
io=`mysql -e "show slave status \G;"|awk '/Running:/{print $2}'`
io=`echo $io|awk '{print $1}'`
#Slave_SQL_Running
sql=`mysql -e "show slave status \G;"|awk '/Running:/{print $2}'`
sql=`echo $sql|awk '{print $2}'`
#Master Log File
mlf=`mysql -e "show slave status \G;"|awk '/Master_Log_File:/{print $2}'`
mlf=`echo $mlf|awk '{print $1}'`
#Relay Master Log File
rmlf=`mysql -e "show slave status \G;"|awk '/Relay_Master_Log_File:/{print $2}'`
rmlf=`echo $rmlf|awk '{print $1}'`
#Read Master Log Pos
rmlp=`mysql -e "show slave status \G;"|awk '/Read_Master_Log_Pos:/{print $2}'`
rmlp=`echo $rmlp|awk '{print $1}'`
#Exec Master Log Pos:
emlp=`mysql -e "show slave status \G;"|awk '/Exec_Master_Log_Pos:/{print $2}'`
emlp=`echo $emlp|awk '{print $1}'`
#Qcache_hits
hits=`mysql -e "SHOW STATUS LIKE 'Qcache_hits';"`
hits=`echo $hits|awk '{print $4}'`
#Qcache_inserts
inserts=`mysql -e "SHOW STATUS LIKE 'Qcache_inserts';"`
inserts=`echo $inserts|awk '{print $4}'`
if [ $hits -ne 0 ];then
let x1=$hits-$inserts
let x2=$x1/$hits
qmzl=`echo "scale=1;$x2*100"|bc`
qmzl=`echo ${qmzl%.*}"%"`
else
qmzl=0
qmzl=`echo $qmzl"%"`
fi
#table Com_select
b1=`mysql -e "show global status like 'Handler_read_rnd_next';"`
b2=`echo $b1|awk '{print $4}'`
b3=`mysql -e "show global status like 'com_select';"`
b4=`echo $b3|awk '{print $4}'`
let bsml=$b2/$b4
#innodb read 
requests=`mysql -e "SHOW STATUS LIKE 'Innodb_buffer_pool_read_requests';"`
requests=`echo $requests|awk '{print $4}'`
reads=`mysql -e "SHOW STATUS LIKE 'Innodb_buffer_pool_reads';"`
reads=`echo $reads|awk '{print $4}'`
if [ $requests -ne 0 ];then
let i1=$requests-$reads
let i2=$i1/$requests
i2=`echo "scale=2;$i1/$requests"|bc`
imzl=`echo "scale=1;$i2*100"|bc`
imzl=`echo ${imzl%.*}"%"`
else
imzl=0
imzl=`echo $imzl"%`
fi

###############################################################################################################

echo "<H2><b>OS&nbsp;�ļ�ϵͳ<a name=\"OS�ļ�ϵͳ\"></b></H2>"
echo "<p><font size=4><i>"
echo "<pre>`df -h`</pre>"
echo "</i></font></p><br><a href=\"#top\">����ҳ��</a>"
echo "<hr size=2 width=100% color=\"#ff0000\">"

echo "<H2><b>MySQL&nbsp;���ݿ�汾<a name=\"���ݿ�汾\"></b></H2>"
echo "<p><font size=4><i>"
echo "<pre>`mysqladmin version`</pre>"
echo "</i></font></p><br><a href=\"#top\">����ҳ��</a>"
echo "<hr size=2 width=100% color=\"#ff0000\">"

echo "<H2><b>MySQL&nbsp;���ݿ����״̬��Ϣ<a name=\"���ݿ����״̬��Ϣ\"></b></H2>"
echo "<p><font size=4><i>"
echo "<pre>`echo "���ݿ�����״̬��             $ping"`</pre>"
echo "<pre>`echo "���ݿ�����ʱ�䣺             $uptime"`</pre>"
echo "<pre>`echo "���ݿ⵱ǰ��������           $threads"`</pre>"
echo "<pre>`echo "���ݿ�ʹ�õ�������������   $max_connect"`</pre>"
echo "<pre>`echo "���ݿ���������Ӹ�����       $aborted_clients"`</pre>"
echo "<pre>`echo "���ݿⳢ������ʧ�ܴ�����     $aborted_connects"`</pre>"
echo "<pre>`echo "���ݿ����Ŀ¼��             $base"`</pre>"
echo "<pre>`echo "����Ŀ¼��                   $data"`</pre>"
echo "<pre>`echo "ʹ�õ��ļ�ϵͳ��             $filesys"`</pre>"
echo "<pre>`echo "�ļ�ϵͳʹ���ʣ�             $used"`</pre>"
echo "<pre>`echo "ʣ��ռ䣺                   $free"`</pre>"
echo "</i></font></p><br><a href=\"#top\">����ҳ��</a>"
echo "<hr size=2 width=100% color=\"#ff0000\">"

echo "<H2><b>MySQL&nbsp;���ݿ���Ҫ����<a name=\"���ݿ���Ҫ����\"></b></H2>"
echo "<p><font size=4><i>"
echo "<pre>`echo "Server_Id:                           $id"`</pre>"
echo "<pre>`echo "Read_Only:                           $reads"`</pre>"
echo "<pre>`echo "Max_Connections:                     $maxc"`</pre>"
echo "<pre>`echo "Max_Connect_Errors:                  $maxce"`</pre>"
echo "<pre>`echo "Wait_Timeout:                        $wt$s"`</pre>"
echo "<pre>`echo "Skip_Name_Resolve:                   $snr"`</pre>"
echo "<pre>`echo "Sync_Binlog:                         $sb"`</pre>"
echo "<pre>`echo "Expire_Logs_Days:                    $eld$day"`</pre>"
echo "<pre>`echo "Table_Open_Cache:                    $toc"`</pre>"
echo "<pre>`echo "Query_Cache_Size:                    $qcs$m"`</pre>"
echo "<pre>`echo "Sort_Buffer_Size:                    $sbs$m"`</pre>"
echo "<pre>`echo "Read_Buffer_Size:                    $rbs$m"`</pre>"
echo "<pre>`echo "Join_Buffer_Size:                    $jbs$m"`</pre>"
echo "<pre>`echo "Tmp_Table_Size:                      $tts$m"`</pre>"
echo "<pre>`echo "Lower_Case_Table_Names:              $lctn"`</pre>"
echo "<pre>`echo "Innodb_Buffer_Pool_Size:             $buffer$m"`</pre>"
echo "<pre>`echo "Innodb_Thread_Concurrency:           $itc"`</pre>"
echo "<pre>`echo "Innodb_Flush_Method:                 $ifm"`</pre>"
echo "<pre>`echo "Innodb_File_Per_Table:               $ifpt"`</pre>"
echo "<pre>`echo "Innodb_Flush_Log_At_Trx_Commit:      $iflatc"`</pre>"
echo "<pre>`echo "Innodb_Lock_Wait_Timeout:            $ilwt$s"`</pre>"
echo "<pre>`echo "Innodb_Open_Files:                   $iof"`</pre>"
echo "<pre>`echo "Log_Bin:                             $binlog"`</pre>"
echo "<pre>`echo "Log_Bin_Basename:                    $basename1"`</pre>"
echo "<pre>`echo "Log_Bin_Index:                       $index"`</pre>"
echo "<pre>`echo "Binlog_Format:                       $format"`</pre>"
echo "<pre>`echo "Binlog_Row_Image:                    $image"`</pre>"
echo "<pre>`echo "Binlog File:                         $file"`</pre>"
echo "<pre>`echo "Binlog Position:                     $pos"`</pre>"
echo "<pre>`echo "Log_Timestamps:                      $timestamps"`</pre>"
echo "<pre>`echo "Slow_Query_Log:                      $slow"`</pre>"
echo "<pre>`echo "Slow_Query_Log_File:                 $slowfile"`</pre>"
echo "<pre>`echo "Log_Error:                           $error"`</pre>"
echo "</i></font></p><br><a href=\"#top\">����ҳ��</a>"
echo "<hr size=2 width=100% color=\"#ff0000\">"

echo "<H2><b>MySQL&nbsp;���ݿ�����״̬<a name=\"���ݿ�����״̬\"></b></H2>"
echo "<p><font size=4><i>"
echo "<pre>`echo "Master / Slave:           $ms"`</pre>"
echo "<pre>`echo "Slave IO Running:         $io"`</pre>"
echo "<pre>`echo "Slave SQL Running:        $sql"`</pre>"
echo "<pre>`echo "Master Log File:          $mlf"`</pre>"
echo "<pre>`echo "Relay Master Log File:    $rmlf"`</pre>"
echo "<pre>`echo "Read Master Log Pos:      $rmlp"`</pre>"
echo "<pre>`echo "Exec Master Log Pos:      $emlp"`</pre>"
echo "<pre>`echo "Seconds Behind Master:    $seconds"`</pre>"
echo "</i></font></p><br><a href=\"#top\">����ҳ��</a>"
echo "<hr size=2 width=100% color=\"#ff0000\">"

echo "<H2><b>MySQL&nbsp;���ݿ��С<a name=\"���ݿ��С\"></b></H2>"
echo "<p><font size=4><i>"
echo "<pre>`mysql -e 'select table_schema,round(sum(data_length+index_length)/1024/1024,2) as "Size(M)" from information_schema.tables group by table_schema order by round(sum(data_length+index_length)/1024/1024,2) desc\G'`</pre>"
echo "</i></font></p><br><a href=\"#top\">����ҳ��</a>"
echo "<hr size=2 width=100% color=\"#ff0000\">"

echo "<H2><b>MySQL&nbsp;���ݿ��еĴ��TOP 10��<a name=\"���ݿ��еĴ��\"></b></H2>"
echo "<p><font size=4><i>"
echo "<pre>`mysql -e 'select table_schema,table_name,round((sum(DATA_LENGTH)+sum(INDEX_LENGTH))/1024/1024,2) "Size(M)" from information_schema.tables group by table_schema,table_name order by round((sum(DATA_LENGTH)+sum(INDEX_LENGTH))/1024/1024,2) desc limit 10\G'`</pre>"
echo "</i></font></p><br><a href=\"#top\">����ҳ��</a>"
echo "<hr size=2 width=100% color=\"#ff0000\">"

echo "<H2><b>MySQL&nbsp;���ݿ�δ�����������ı�<a name=\"���ݿ�δ�����������ı�\"></b></H2>"
echo "<p><font size=4><i>"
echo "<pre>`mysql -e "SELECT distinct table_name,table_schema FROM information_schema.columns WHERE table_schema not in ('sys','information_schema','performance_schema','mysql') AND table_name not in (select distinct table_name from information_schema.columns where column_key='PRI')\G"`</pre>"
echo "</i></font></p><br><a href=\"#top\">����ҳ��</a>"
echo "<hr size=2 width=100% color=\"#ff0000\">"

echo "<H2><b>MySQL&nbsp;���ݿ��δʹ�ù�������<a name=\"���ݿ��δʹ�ù�������\"></b></H2>"
echo "<p><font size=4><i>"
echo "<pre>`mysql -e "select * from sys.schema_unused_indexes\G"`</pre>"
echo "</i></font></p><br><a href=\"#top\">����ҳ��</a>"
echo "<hr size=2 width=100% color=\"#ff0000\">"

echo "<H2><b>MySQL&nbsp;���ݿ���ͳ��<a name=\"���ݿ���ͳ��\"></b></H2>"
echo "<p><font size=4><i>"
echo "<pre>`mysql -e "show status like 'table_locks_%'\G"`</pre>"
echo "</i></font></p><br><a href=\"#top\">����ҳ��</a>"
echo "<hr size=2 width=100% color=\"#ff0000\">"

echo "<H2><b>MySQL&nbsp;���ݿ⻺��������<a name=\"���ݿ⻺��������\"></b></H2>"
echo "<p><font size=4><i>"
echo "<pre>`mysql -e "SHOW STATUS LIKE 'Qcache%'\G"`</pre>"
echo "<pre>`echo "��ѯ���������ʴ�ԼΪ:          $qmzl"`</pre>"
echo "</i></font></p><br><a href=\"#top\">����ҳ��</a>"
echo "<hr size=2 width=100% color=\"#ff0000\">"

echo "<H2><b>MySQL&nbsp;���ݿ�Innodb��Read������<a name=\"���ݿ�innodb��read������\"></b></H2>"
echo "<p><font size=4><i>"
echo "<pre>`mysql -e "show status like 'Innodb_buffer_pool_%'\G"`</pre>"
echo "<pre>`echo "Innodb�����ʴ�ԼΪ:          $imzl"`</pre>"
echo "</i></font></p><br><a href=\"#top\">����ҳ��</a>"
echo "<hr size=2 width=100% color=\"#ff0000\">"

echo "<H2><b>MySQL&nbsp;���ݿ���ʱ��<a name=\"���ݿ���ʱ��\"></b></H2>"
echo "<p><font size=4><i>"
echo "<pre>`mysql -e "Show status like '%tmp%'\G"`</pre>"
echo "</i></font></p><br><a href=\"#top\">����ҳ��</a>"
echo "<hr size=2 width=100% color=\"#ff0000\">"

echo "<H2><b>MySQL&nbsp;���ݿ�ȫ��ɨ�����<a name=\"���ݿ�ȫ��ɨ�����\"></b></H2>"
echo "<p><font size=4><i>"
echo "<pre>`mysql -e "show global status like 'handler_read%'\G"`</pre>"
echo "</i></font></p><br><a href=\"#top\">����ҳ��</a>"
echo "<hr size=2 width=100% color=\"#ff0000\">"

echo "<H2><b>MySQL&nbsp;���ݿⱸ��<a name=\"���ݿⱸ��\"></b></H2>"
echo "<p><font size=4><i>"
echo "<pre>`find /mysql/myback/* -mtime -2`</pre>"
echo "</i></font></p><br><a href=\"#top\">����ҳ��</a>"
echo "<hr size=2 width=100% color=\"#ff0000\">"

echo "<H2><b>MySQL&nbsp;���ݿ���־�������<a name=\"���ݿ���־�������\"></b></H2>"
echo "<p><font size=4><i>"
echo "<pre>`cat $log_error|grep $date2|grep 'ERROR'`</pre>"
echo "<pre>`cat $log_error|grep $date|grep 'ERROR'`</pre>"
echo "</i></font></p><br><a href=\"#top\">����ҳ��</a>"
echo "<hr size=2 width=100% color=\"#ff0000\">"

echo "<H2><b>MySQL&nbsp;���ݿ�error��־<a name=\"���ݿ�error��־\"></b></H2>"
echo "<p><font size=4><i>"
echo "<pre>`cat $log_error|grep $date2`</pre>"
echo "<pre>`cat $log_error|grep $date`</pre>"
echo "</i></font></p><br><a href=\"#top\">����ҳ��</a>"
echo "<hr size=2 width=100% color=\"#ff0000\">"