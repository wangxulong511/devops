源码地址：https://mp.weixin.qq.com/s/mZ6MkVE7aVIK_VKGJDAvjw

#!/bin/bash
# by Sharkz@fankun.com
# 2022-07-8
# Be sure to output table
# long_query_time = 5
# slow_query_log = on
# log_output = 'TABLE' 
# Deadlock log parameters
# innodb_print_all_deadlocks=ON
# performance_schema=ON  #此参数必须ON
# performance_schema_events_statements_history_long_size=1000000 #保留百万条 默认是1万条 根据自己内存来设定 先在测试库确定内存消耗量 类似ORACLE V$SQL
# performance_schema_digests_size=100000 #此参数类似ORACLE SQLAREA汇总的 设置10万不同SQL基本覆盖7天的量
# performance_schema_max_sql_text_length=255 #此参数是文本长度,默认值1024 注意它是TEXT_LENGTH X HISTORY_LONG_SIZ的乘积消耗内存,这里不需要看完整的SQL
# performance_schema_max_digest_length=255 #同上
#================================================DataSegment===============================================
TARGET_DB_IP=192.168.188.129
TARGET_DB_PROT=3339
TARGET_DB_USER=root
#TARGET_DB_PASS='Sharkz@AESYGO'
TARGET_DB_PASS='123456'
MYSQL_ERROR_LOG='/data/mysql/data/error.log'
SYS_DIR='/dev/mapper/centos-root'
DB_DIR='/usr/local/mysql'
BAK_DIR='/data/backup'
SCHEMA='test'
CHARTSET='utf8mb4'
CHART_COLLATION='utf8mb4_general_ci'
CHECK_RESULT_FILE="/root/CHECK_${SCHEMA}_MYSQL_${TARGET_DB_IP}_$(date +%Y%m%d-%H%M%S).html"
START_DATE='2022-09-12 00:00:00.000000'
END_DATE='2022-09-20 00:00:00.000000'

##下面参数没有起作用不用改
CURN_DATE=$(date "+%Y-%m-%d %H:%M:%S")
SEVEN_DATE=$(date -d"7 day ago" +%Y-%m-%d)
BEFORE_DAYS=7

#===============================================Fuction segments======================================================================
function Target_MysqlDB()
{
 mysql -h $TARGET_DB_IP -P $TARGET_DB_PROT -u$TARGET_DB_USER -p$TARGET_DB_PASS --html -t  -e "$*" >> ${CHECK_RESULT_FILE} 2>/dev/null
}


function SALVE_MysqlDB()
{
 mysql -h $TARGET_DB_IP -P $TARGET_DB_PROT -u$TARGET_DB_USER -p$TARGET_DB_PASS  -e "$*" 1>tmp_slave_status.txt   2>/dev/null
}

function OUTPUT_TITLE()
{
  echo -e "<h3 class="awr" >$1</h3>" >>${CHECK_RESULT_FILE} 2>/dev/null
}


CREATE_HTML_HEAD()
{
echo -e '<html>
<head>
<meta charset="UTF-8">
<style type="text/css">
    body        {font:12px Courier New,Helvetica,sansserif; color:black; background:White;}
    table       {font:12px Courier New,Helvetica,sansserif; color:Black; background:#FFFFCC; padding:0px 0px 0px 0px; margin:0px 0px 0px 0px;} 
    th.awrbg    {font:bold 12pt Arial,Helvetica,Geneva,sans-serif; color:White; background:#000000;padding-left:4px; padding-right:4px;padding-bottom:2px}
    td.awrc     {font:12pt Arial,Helvetica,Geneva,sans-serif;color:black;background:#FFFFCC; vertical-align:top;}
    td.awrnc    {font:12pt Arial,Helvetica,Geneva,sans-serif;color:black;background:White;vertical-align:top;}
    h1.awr   {font:bold 24pt Arial,Helvetica,Geneva,sans-serif;color:#336699;background-color:White; margin-bottom:0pt;padding:0px 0px 0px 0px;}
    h2.awr   {font:bold 20pt Arial,Helvetica,Geneva,sans-serif;color:#336699;background-color:White;border-bottom:1px solid #cccc99;margin-top:0pt; margin-bottom:0pt;padding:0px 0px 0px 0px;}
    h3.awr   {font:bold 18pt Arial,Helvetica,Geneva,sans-serif;color:#336699;background-color:White;margin-top:4pt; margin-bottom:0pt;}
    h4.awr   {font:bold 20pt Arial,Helvetica,Geneva,sans-serif;color:#336699;background-color:White;border-top:1px solid #cccc99;margin-top:0pt; margin-bottom:0pt;padding:0px 0px 0px 0px;}
    table tr:nth-child(even){            background-color: #fafad2;        }
    table tr:nth-child(odd){          background-color: #b2e1b2;        }
</style>
</head>
<body>' >>${CHECK_RESULT_FILE} 2>/dev/null

 echo -e " <h1 align="center" class="awr"> ${SCHEMA} Daily patrol inspection report </h1> ">>${CHECK_RESULT_FILE}
 echo -e "<br/>" >>${CHECK_RESULT_FILE}
 echo -e " <h2 align="center" class="awr"> Report:$(date +%Y-%m-%d)  </h2> ">>${CHECK_RESULT_FILE}
}



CREATE_HTML_END(){
  echo -e "</body></html>" >>${CHECK_RESULT_FILE} 2>/dev/null
}

OUT_PUT_TABLE_HEAD(){
  echo -e '<table width="" border="1" >' >>${CHECK_RESULT_FILE}
}


OUT_PUT_FILED() ##Field name of the table
{
    th_str=`echo $1|awk 'BEGIN {FS=" "}''{i=1; while(i<=NF) {print "<th class='awrbg' scope="col"> "$i"</th>";i++}}'`
}

OUT_PUT_TITEL() ##Field row of table
{
  OUT_PUT_FILED "$*"; echo -e "<tr>    $th_str  </tr>" >> ${CHECK_RESULT_FILE}
}


OUT_PUT_VAULES() ##Output the contents of the line
{
    th_str=`echo $1|awk 'BEGIN{FS=" "}''{i=1; while(i<=NF) {print "<td scope="row" class='awrc'> "$i"</td>";i++}}'`
}


OUT_PUT_LINES() ## 
{
  OUT_PUT_VAULES "$*";  echo -e "<tr>    $th_str  </tr>" >>${CHECK_RESULT_FILE}
}

OUT_PUT_NEW_LINE()
{
      echo -e " <br />">>${CHECK_RESULT_FILE}
}

OUT_PUT_TABLE_TAIL()
{
  echo -e "</table>" >>${CHECK_RESULT_FILE}
  OUT_PUT_NEW_LINE
}

OUT_PUT_LINES_LOG() ## 
{
     echo -e "<tr> <td scope="row" class='awrc'> $1</td></tr>" >>${CHECK_RESULT_FILE}
}



deadlock()
{
    ERROR_LOG=$1
    DEADLOCK_KEY='InnoDB: Transactions deadlock detected,'
    DEADLOCK_END_KEY='InnoDB: *** WE ROLL BACK TRANSACTION'
    IS_EXIST_DEADLOCK=$(cat ${ERROR_LOG} | grep -m 1 "InnoDB: Transactions deadlock detected,")
    FIND_DATE1=$(date -d"$2 day ago" +%Y-%m-%d)
    FIND_DATE=$(date -d "${FIND_DATE1}" +%s)

    #Match all line numbers and times of key

    START_LINE_VAR=$(cat ${ERROR_LOG} | grep -n  "InnoDB: Transactions deadlock detected," |awk -F ":"  '{printf($1);printf ";"}')
    START_TIME_VAR=$(cat ${ERROR_LOG} | grep -n  "InnoDB: Transactions deadlock detected," |awk -F ":"  '{printf($2);printf ";"}')
    START_KEY_LINE_LIST=(${START_LINE_VAR//;/ })
    START_KEY_TIME_LIST=(${START_TIME_VAR//;/ })

    #Last compliant_ Key all line numbers and times
    CLOSE_LINE_VAR=$(cat ${ERROR_LOG} | grep -n  "WE ROLL BACK TRANSACTION" |awk -F ":"  '{printf($1);printf ";"}')
    CLOSE_TIME_VAR=$(cat ${ERROR_LOG} | grep -n  "WE ROLL BACK TRANSACTION" |awk -F ":"  '{printf($2);printf ";"}')
    CLOSE_KEY_LINE_LIST=(${CLOSE_LINE_VAR//;/ })
    CLOSE_KEY_TIME_LIST=(${CLOSE_TIME_VAR//;/ })

    START_POS=0
    for (( i=0; i<${#START_KEY_TIME_LIST[*]}; i=i+1 ))
    do
        temp_time=${START_KEY_TIME_LIST[$i]}
        START_TIME=${temp_time:0:10}
        DIG_START_TIME=$(date -d "${START_TIME}" +%s)

        if [[ ${DIG_START_TIME} -ge ${FIND_DATE}  ]]; then
            START_POS=${i}
            break
        fi
    done

    END_POS=0
    for (( k=0; k<${#CLOSE_KEY_TIME_LIST[*]}; k=k+1 ))
    do
        temp_time=${CLOSE_KEY_TIME_LIST[$i]}
        CLOSE_TIME=${temp_time:0:10}
        DIG_CLOSE_TIME=$(date -d "${CLOSE_TIME}" +%s)    

 if [[ ${DIG_CLOSE_TIME} -ge ${FIND_DATE}  ]]; then
     #echo -e "${CLOSE_TIME} Lines=${CLOSE_KEY_LINE_LIST[$k]}"
     END_POS=${k}
     break
   fi

done

#echo -e "start :${START_POS};  close:${END_POS}"

for (( j=0; j<${#CLOSE_KEY_TIME_LIST[*]}; j=j+1 ))
do
  if [[ ${j} -ge ${START_POS} ]] ; then 

     CLOSE=${CLOSE_KEY_LINE_LIST[$j]}
     START=${START_KEY_LINE_LIST[$j]}
     DEADLOCK_STRINGS=$(sed -n "${START},${CLOSE}p" ${ERROR_LOG}) 
     OUT_PUT_LINES_LOG "${DEADLOCK_STRINGS}"

  fi

done

}

sar_cpu()
{
   TITL="DATE:         CPU     %user     %nice   %system   %iowait    %steal     %idle "
   OUT_PUT_TITEL $TITL 
   for file in `ls -tr /var/log/sa/sa* | grep -v sar`
   do    
    dat=`sar -f $file | head -n 1 | awk '{print $4}'`    
    INFO=$(echo -n $dat ;   sar -f $file  | grep -i Average | sed "s/Average://")
    OUT_PUT_LINES ${INFO}
  done

}


Parse_salve_txt()
{
MASTER_UUID=$(cat tmp_slave_status.txt           | grep -i "Master_UUID" |awk '{print $2}')
SLAVE_IO_STATE=$(cat tmp_slave_status.txt        | grep -i "Slave_IO_State" |awk -F " " '{for (i=2;i<=NF;i++)printf("%s ", $i);print ""}')
READ_MASTER_POST=$(cat tmp_slave_status.txt      | grep -i "Read_Master_Log_Pos"  |awk '{print $2}')
Relay_Master_Log_File=$(cat tmp_slave_status.txt | grep -i "Relay_Master_Log_File"|awk '{print $2}')
EXEC_MASTER_POST=$(cat tmp_slave_status.txt      | grep -i "Exec_Master_Log_Pos"  |awk '{print $2}')
BEHIND_SECONDS=$(cat tmp_slave_status.txt        | grep -i "Seconds_Behind_Master"|awk '{print $2}')
SLAVE_IO_RUNNING=$(cat tmp_slave_status.txt      | grep -i "Slave_IO_Running" |awk '{print $2}')
SLAVE_SQL_RUNNING=$(cat tmp_slave_status.txt     | grep -i "Slave_SQL_Running:" |awk '{print $2}')
REPLICATE_DO_DB=$(cat tmp_slave_status.txt       | grep -i "Replicate_Do_DB" |awk '{print $2}')
SQLDELAY=$(cat tmp_slave_status.txt              | grep -i "SQL_Delay"  |awk '{print $2}')
SALVE_SQL_RUN_STATE=$(cat tmp_slave_status.txt   | grep -i "Slave_SQL_Running_State"  |awk -F " " '{for (i=2;i<=NF;i++)printf("%s ", $i);print ""}')
LAST_SQL_ERROR=$(cat tmp_slave_status.txt        | grep -i "Last_IO_Errno"|awk '{print $2}')
LAST_IO_ERROR=$(cat tmp_slave_status.txt         | grep -i "Last_SQL_Errno"|awk '{print $2}')
RETRIEVED_GTID=$(cat tmp_slave_status.txt        | grep -i "retrieved_gtid_set" |awk -F " " '{for (i=2;i<=NF;i++)printf("%s ", $i);print ""}')
EXECUTED_GTID=$(cat tmp_slave_status.txt         | grep -i "${MASTER_UUID}:" |grep -vi "retrieved_gtid_set")
SALVE_SQL_RUN_STATE=${SALVE_SQL_RUN_STATE// /_}
SLAVE_IO_STATE=${SLAVE_IO_STATE// /_}
}

#================================================SQL Segments========================================================================

TOP_SCHEMA_SQL="select  table_schema,
ROUND(SUM(TABLE_ROWS),2) as ALLSIZE_ROWS,
ROUND(SUM(DATA_LENGTH+INDEX_LENGTH+DATA_FREE)/1024/1024,2) as ALLSIZE_MB,
ROUND(SUM(DATA_LENGTH)/1024/1024,2) AS DATASIZE_MB,
ROUND(SUM(INDEX_LENGTH)/1024/1024,2) AS INDEXSIZE_MB
from information_schema.TABLES
GROUP BY table_schema
order by ALLSIZE_ROWS desc
limit 10;
"

TOP_TABLE_SQL="select TABLE_NAME,ROUND(ALL_LENGTH/1024/1024,2) as ALLSIZE_MB,TABLE_ROWS,ROUND(DATA_LENGTH/1024/1024,2)  AS DATASIZE_MB,ROUND(INDEX_LENGTH/1024/1024,2)  AS INDEXSIZE_MB,frag_rate,avg_row_length
from
(
select  TABLE_NAME,TABLE_ROWS,DATA_LENGTH,INDEX_LENGTH,DATA_FREE, DATA_LENGTH+INDEX_LENGTH+DATA_FREE as ALL_LENGTH, RoUND(DATA_FREE/(DATA_LENGTH+INDEX_LENGTH+DATA_FREE)*100,2) AS  frag_rate,avg_row_length
from information_schema.TABLES
where table_schema='${SCHEMA}'
order by ALL_LENGTH desc
limit 20
) tmp;"

TO_FRAG_SQL="
select TABLE_NAME,ROUND(ALL_LENGTH/1024/1024,2) as ALLSIZE_MB,ROUND(DATA_LENGTH/1024/1024,2)  AS DATASIZE_MB,ROUND(INDEX_LENGTH/1024/1024,2)  AS INDEXSIZE_MB,frag_rate,TABLE_ROWS,avg_row_length
from
(
select  TABLE_NAME,TABLE_ROWS,DATA_LENGTH,INDEX_LENGTH,DATA_FREE, DATA_LENGTH+INDEX_LENGTH+DATA_FREE as ALL_LENGTH, RoUND(DATA_FREE/(DATA_LENGTH+INDEX_LENGTH+DATA_FREE)*100,2) AS  frag_rate,avg_row_length
from information_schema.TABLES
where table_schema='${SCHEMA}'
order by frag_rate desc
limit 10
) tmp
where frag_rate >10;"

##events_statements_history =10000 没法保留1周
GET_TPS_SQL=" 
 SELECT DATE_FORMAT(Per_Second,'%Y-%m-%d') as Per_DAY,SUM(TPS) AS TOTAL_TPS,AVG(TPS) AS AVG_TPS,MAX(TPS) AS MAX_TPS
 FROM
 (
    select DATE_FORMAT(START_TIME,'%Y-%m-%d %H:%i:%S') as Per_Second,count(DIGEST) AS TPS
    from
    (
    SELECT 
    FROM_UNIXTIME( (unix_timestamp(sysdate()) - (select variable_value  from performance_schema.global_status  where variable_name = 'Uptime')) + TIMER_START/1000000000000 ) AS START_TIME,
    FROM_UNIXTIME( (unix_timestamp(sysdate()) - (select variable_value  from performance_schema.global_status  where variable_name = 'Uptime')) + TIMER_END/1000000000000 ) AS END_TIME,
    DIGEST,DIGEST_TEXT,
    TIMER_WAIT/1000000000000  AS RUN_SECONDS,
    LOCK_TIME/1000000000000   AS LOCK_SECONDS,
    SQL_TEXT,EVENT_NAME
    FROM performance_schema.events_statements_history
    WHERE EVENT_NAME in ('statement/sql/update','statement/sql/insert','statement/sql/delete')
) base1 
 where START_TIME between '${START_DATE}' and '${END_DATE}'
 group by Per_Second,EVENT_NAME
) DAY1
GROUP BY  Per_DAY
order by Per_DAY asc;"

##events_statements_history =10000 没法保留1周
GET_QPS_SQL=" 
 SELECT DATE_FORMAT(Per_Second,'%Y-%m-%d') as Per_DAY,SUM(QPS) AS TOTAL_QPS,AVG(QPS) AS AVG_QPS,MAX(QPS) AS MAX_QPS
 FROM
 (
    select DATE_FORMAT(START_TIME,'%Y-%m-%d %H:%i:%S') as Per_Second,count(DIGEST) AS QPS
    from
    (
    SELECT 
    FROM_UNIXTIME( (unix_timestamp(sysdate()) - (select variable_value  from performance_schema.global_status  where variable_name = 'Uptime')) + TIMER_START/1000000000000 ) AS START_TIME,
    FROM_UNIXTIME( (unix_timestamp(sysdate()) - (select variable_value  from performance_schema.global_status  where variable_name = 'Uptime')) + TIMER_END/1000000000000 ) AS END_TIME,
    DIGEST,DIGEST_TEXT,
    TIMER_WAIT/1000000000000  AS RUN_SECONDS,
    LOCK_TIME/1000000000000   AS LOCK_SECONDS,
    SQL_TEXT,EVENT_NAME
    FROM performance_schema.events_statements_history
    WHERE EVENT_NAME in ('statement/sql/select','statement/sql/update','statement/sql/insert','statement/sql/delete')
) base1 
 where START_TIME between '${START_DATE}' and  '${END_DATE}'
 group by Per_Second,EVENT_NAME
) DAY1
GROUP BY  Per_DAY
order by Per_DAY asc;"



#查询到运行时间 最长的5%的语句。
GET_SYS_TOP95_LONG_SQL=" select
 query,
db,
full_scan,
exec_count,
err_count,
warn_count,
total_latency,
max_latency,
avg_latency,
rows_sent,
rows_sent_avg,
rows_examined,
rows_examined_avg,
first_seen,
last_seen
from sys.statements_with_runtimes_in_95th_percentile 
limit 10;"

#总计执行时间最长的SQL语句
GET_SYS_TOP_LONG_TIME_SQL="
SELECT SCHEMA_NAME,DIGEST_TEXT,
COUNT_STAR, 
sys.format_time(SUM_TIMER_WAIT) AS SUM_TIME,  
sys.format_time(MIN_TIMER_WAIT) AS MIN_TIME,  
sys.format_time(AVG_TIMER_WAIT) AS AVG_TIME,
sys.format_time(MAX_TIMER_WAIT) AS MAX_TIME,
sys.format_time(SUM_LOCK_TIME) AS SUM_LOCK_TIME,
SUM_ROWS_AFFECTED,SUM_ROWS_SENT,SUM_ROWS_EXAMINED
FROM performance_schema.events_statements_summary_by_digest
WHERE SCHEMA_NAME IS NOT NULL 
ORDER BY SUM_TIME DESC 
LIMIT 10;"

GET_SYS_TOP_LOCK_TIME_SQL="
SELECT SCHEMA_NAME,DIGEST_TEXT,
COUNT_STAR, 
sys.format_time(SUM_TIMER_WAIT) AS SUM_TIME,  
sys.format_time(MIN_TIMER_WAIT) AS MIN_TIME,  
sys.format_time(AVG_TIMER_WAIT) AS AVG_TIME,
sys.format_time(MAX_TIMER_WAIT) AS MAX_TIME,
sys.format_time(SUM_LOCK_TIME) AS SUM_LOCK_TIME,
SUM_ROWS_AFFECTED,SUM_ROWS_SENT,SUM_ROWS_EXAMINED
FROM performance_schema.events_statements_summary_by_digest
WHERE SCHEMA_NAME IS NOT NULL 
ORDER BY SUM_LOCK_TIME DESC 
LIMIT 10; "


GET_SYS_TOP_EXECUTE_COUNT_SQL="
SELECT SCHEMA_NAME,DIGEST_TEXT,
COUNT_STAR, 
sys.format_time(SUM_TIMER_WAIT) AS SUM_TIME,  
sys.format_time(MIN_TIMER_WAIT) AS MIN_TIME,  
sys.format_time(AVG_TIMER_WAIT) AS AVG_TIME,
sys.format_time(MAX_TIMER_WAIT) AS MAX_TIME,
sys.format_time(SUM_LOCK_TIME) AS SUM_LOCK_TIME,
SUM_ROWS_AFFECTED,SUM_ROWS_SENT,SUM_ROWS_EXAMINED
FROM performance_schema.events_statements_summary_by_digest
WHERE SCHEMA_NAME IS NOT NULL 
ORDER BY COUNT_STAR DESC 
LIMIT 10;" 


GET_SYS_TOP_WAIT_EVENT_SQL="
SELECT EVENT_NAME,COUNT_STAR,sys.format_time(sum_timer_wait),sys.format_time(avg_timer_wait),sys.format_time(max_timer_wait) 
FROM performance_schema.events_waits_summary_global_by_event_name
order by sum_timer_wait desc
LIMIT 25;"

##events_waits_history_long =10000 没法保留1周
GET_WEEK_SLOW_SQL="SELECT db,CAST(sql_text AS CHAR  ) as SQLTEXT,
count(thread_id)            as total_exec_times,
round(avg(query_time),3) as avg_exec_seconds,
round(max(query_time),3) as max_exec_seconds,
sum(rows_sent)           as total_sent_rows,
round(avg(rows_sent),0)  as avg_sent_rows,
max(rows_sent)           as max_sent_rows,
sum(rows_examined)       as total_examined,
round(avg(rows_examined),0) as avg_examined,
max(rows_examined)          as max_examined,
DATE_FORMAT(min(start_time),'%Y-%m-%d %H:%i:%S')            as first_exec_time,
DATE_FORMAT(max(start_time),'%Y-%m-%d %H:%i:%S')            as last_exec_time
FROM mysql.slow_log
where 1=1
and start_time >= '${START_DATE}'
and start_time < '${END_DATE}'
AND DB='${SCHEMA}'
group by db,sql_text
order by total_exec_times desc,avg_exec_seconds desc"



##events_waits_history_long =10000 没法保留1周 GET_WEEK_TOP_WAITEVENTS_SQL
GET_WEEK_TOP_WAIT_EVENTS_SQL="
SELECT V.EVENT_NAME,sys.format_time(V.WAIT_TIMES) AS WAIT_TIME,sys.format_bytes(V.SIZE) as SIZE,V.SPING_COUNT
FROM
(
    SELECT EVENT_NAME,
    SUM(TIMER_WAIT) AS WAIT_TIMES,
    SUM(NUMBER_OF_BYTES) AS SIZE,
    SUM(SPINS) AS SPING_COUNT
FROM
(
    SELECT EVENT_NAME, 
    FROM_UNIXTIME( (unix_timestamp(sysdate()) - (select variable_value  from performance_schema.global_status  where variable_name = 'Uptime')) + TIMER_START/1000000000000 )  AS START_TIME,
    TIMER_WAIT,
    SPINS,OBJECT_SCHEMA,OBJECT_NAME,INDEX_NAME,OBJECT_TYPE,OPERATION,NUMBER_OF_BYTES
    from performance_schema.events_waits_history_long 
) W
    WHERE    START_TIME  >= '${START_DATE}' AND START_TIME < '${END_DATE}'
    GROUP BY EVENT_NAME
    ORDER BY   WAIT_TIMES DESC
) V
LIMIT 10;"

##events_waits_history_long =10000 没法保留1周
GET_WEEK_TOP_WAITEVENTS_DETAIL_SQL="
SELECT  EVENT_NAME,OBJECT_SCHEMA,OBJECT_NAME,INDEX_NAME,OBJECT_TYPE,OPERATION,SPING_COUNT,
sys.format_time(V.WAIT_TIMES) AS WAIT_TIME,sys.format_bytes(V.SIZE) as SIZE
FROM 
(
 SELECT 
 EVENT_NAME,OBJECT_SCHEMA,OBJECT_NAME,INDEX_NAME,OBJECT_TYPE,OPERATION,
 SUM(TIMER_WAIT) AS WAIT_TIMES,SUM(NUMBER_OF_BYTES) AS SIZE,SUM(SPINS) AS SPING_COUNT
FROM
(
 SELECT EVENT_NAME, 
 FROM_UNIXTIME( (unix_timestamp(sysdate()) - (select variable_value  from performance_schema.global_status  where variable_name = 'Uptime')) + TIMER_START/1000000000000 )  AS START_TIME,
 TIMER_WAIT,
 SPINS,OBJECT_SCHEMA,OBJECT_NAME,INDEX_NAME,OBJECT_TYPE,OPERATION,NUMBER_OF_BYTES
 from performance_schema.events_waits_history_long   
) W
 WHERE    START_TIME >= '${START_DATE}' AND START_TIME < '${END_DATE}'
 GROUP BY EVENT_NAME,OBJECT_SCHEMA,OBJECT_NAME,INDEX_NAME,OBJECT_TYPE,OPERATION
 ORDER BY   WAIT_TIMES DESC
) V
LIMIT 100;"


##events_statements_summary_by_digest =10000 有可能没法保留1周
GET_WEEK_TOP_RUNTIME_SQL="
SELECT SCHEMA_NAME,DIGEST_TEXT,COUNT_STAR,
sys.format_time(SUM_TIMER_WAIT) AS TOTAL_RUN_SECONDS,
sys.format_time(MIN_TIMER_WAIT) AS MIN_RUN_SECONDS,
sys.format_time(AVG_TIMER_WAIT) AS AVG_RUN_SECONDS,
sys.format_time(MAX_TIMER_WAIT) AS MAX_RUN_SECONDS,
sys.format_time(SUM_LOCK_TIME)  AS LOCK_RUN_SECONDS
from performance_schema.events_statements_summary_by_digest
WHERE    1=1
AND LAST_SEEN >= '${START_DATE}'
AND SCHEMA_NAME='${SCHEMA}'
ORDER BY TOTAL_RUN_SECONDS DESC
LIMIT 10;"

##events_statements_summary_by_digest =10000 有可能没法保留1周
GET_WEEK_TOP_EXECUTE_COUNT_SQL="
SELECT SCHEMA_NAME,DIGEST_TEXT,COUNT_STAR,
sys.format_time(SUM_TIMER_WAIT) AS TOTAL_RUN_SECONDS,
sys.format_time(MIN_TIMER_WAIT) AS MIN_RUN_SECONDS,
sys.format_time(AVG_TIMER_WAIT) AS AVG_RUN_SECONDS,
sys.format_time(MAX_TIMER_WAIT) AS MAX_RUN_SECONDS,
sys.format_time(SUM_LOCK_TIME)  AS LOCK_RUN_SECONDS
from performance_schema.events_statements_summary_by_digest
WHERE    1=1
AND LAST_SEEN >= '${START_DATE}'
AND SCHEMA_NAME='${SCHEMA}'
ORDER BY COUNT_STAR DESC
LIMIT 10;"


#平均执行时间最长的语句
GET_WEEK_TOP_AVGTIME_SQL="
SELECT SCHEMA_NAME,DIGEST_TEXT,COUNT_STAR ,
sys.format_time(SUM_TIMER_WAIT) AS TOTAL_RUN_SECONDS,
sys.format_time(MIN_TIMER_WAIT) AS MIN_RUN_SECONDS,
sys.format_time(AVG_TIMER_WAIT) AS AVG_RUN_SECONDS,
sys.format_time(MAX_TIMER_WAIT) AS MAX_RUN_SECONDS,
sys.format_time(SUM_LOCK_TIME)  AS LOCK_RUN_SECONDS
from performance_schema.events_statements_summary_by_digest
WHERE    1=1
AND LAST_SEEN >= '${START_DATE}'
AND SCHEMA_NAME='${SCHEMA}'
ORDER BY AVG_RUN_SECONDS DESC
LIMIT 10;"  


#TOP 锁时间时间最长的语句
GET_WEEK_TOP_LOCKTIME_SQL="
SELECT SCHEMA_NAME,DIGEST_TEXT,COUNT_STAR,
sys.format_time(MIN_TIMER_WAIT) AS MIN_RUN_SECONDS,
sys.format_time(AVG_TIMER_WAIT) AS AVG_RUN_SECONDS,
sys.format_time(MAX_TIMER_WAIT) AS MAX_RUN_SECONDS,
sys.format_time(SUM_LOCK_TIME)  AS LOCK_RUN_SECONDS
from performance_schema.events_statements_summary_by_digest
WHERE    1=1
AND LAST_SEEN >= '${START_DATE}'
AND SCHEMA_NAME='${SCHEMA}'
ORDER BY LOCK_RUN_SECONDS DESC
LIMIT 10;"  


#top 5 出检查行数最多的SQL语句
GET_WEEK_TOP_EXAMINEDROW_SQL="
SELECT SCHEMA_NAME,DIGEST_TEXT,COUNT_STAR,SUM_ROWS_EXAMINED,
sys.format_time(MIN_TIMER_WAIT) AS MIN_RUN_SECONDS,
sys.format_time(AVG_TIMER_WAIT) AS AVG_RUN_SECONDS,
sys.format_time(MAX_TIMER_WAIT) AS MAX_RUN_SECONDS,
sys.format_time(SUM_LOCK_TIME)  AS LOCK_RUN_SECONDS
from performance_schema.events_statements_summary_by_digest
WHERE    1=1
AND LAST_SEEN >= '${START_DATE}'
AND SCHEMA_NAME='${SCHEMA}'
ORDER BY SUM_ROWS_EXAMINED DESC
LIMIT 10;"  

#--top 5 返回行数最多的SQL语句
GET_WEEK_TOP_SENTROW_SQL="
SELECT SCHEMA_NAME,DIGEST_TEXT,COUNT_STAR,SUM_ROWS_SENT,
sys.format_time(MIN_TIMER_WAIT) AS MIN_RUN_SECONDS,
sys.format_time(AVG_TIMER_WAIT) AS AVG_RUN_SECONDS,
sys.format_time(MAX_TIMER_WAIT) AS MAX_RUN_SECONDS,
sys.format_time(SUM_LOCK_TIME)  AS LOCK_RUN_SECONDS
from performance_schema.events_statements_summary_by_digest
WHERE    1=1
AND LAST_SEEN >= '${START_DATE}'
AND SCHEMA_NAME='${SCHEMA}'
ORDER BY SUM_ROWS_SENT DESC
LIMIT 10;" 

#--top 10排序行数最多的SQL语句
GET_WEEK_TOP_SORTROW_SQL="
SELECT SCHEMA_NAME,DIGEST_TEXT,COUNT_STAR,SUM_SORT_ROWS,
sys.format_time(MIN_TIMER_WAIT) AS MIN_RUN_SECONDS,
sys.format_time(AVG_TIMER_WAIT) AS AVG_RUN_SECONDS,
sys.format_time(MAX_TIMER_WAIT) AS MAX_RUN_SECONDS,
sys.format_time(SUM_LOCK_TIME)  AS LOCK_RUN_SECONDS
from performance_schema.events_statements_summary_by_digest
WHERE    1=1
AND LAST_SEEN >= '${START_DATE}'
AND SCHEMA_NAME='${SCHEMA}'
ORDER BY SUM_SORT_ROWS DESC
LIMIT 10;" 


#--top 10 更新行数最多的SQL语句
GET_WEEK_TOP_AFFECTED_SQL="
SELECT SCHEMA_NAME,DIGEST_TEXT,COUNT_STAR,SUM_ROWS_AFFECTED,
sys.format_time(MIN_TIMER_WAIT) AS MIN_RUN_SECONDS,
sys.format_time(AVG_TIMER_WAIT) AS AVG_RUN_SECONDS,
sys.format_time(MAX_TIMER_WAIT) AS MAX_RUN_SECONDS,
sys.format_time(SUM_LOCK_TIME)  AS LOCK_RUN_SECONDS
from performance_schema.events_statements_summary_by_digest
WHERE    1=1
AND LAST_SEEN >= '${START_DATE}'
AND SCHEMA_NAME='${SCHEMA}'
ORDER BY SUM_ROWS_AFFECTED DESC
LIMIT 10;" 


#--top 5 磁盘临时表数最多的SQL语句
GET_WEEK_TOP_DISKTMP_SQL="
SELECT SCHEMA_NAME,DIGEST_TEXT,COUNT_STAR,SUM_CREATED_TMP_DISK_TABLES,
sys.format_time(MIN_TIMER_WAIT) AS MIN_RUN_SECONDS,
sys.format_time(AVG_TIMER_WAIT) AS AVG_RUN_SECONDS,
sys.format_time(MAX_TIMER_WAIT) AS MAX_RUN_SECONDS,
sys.format_time(SUM_LOCK_TIME)  AS LOCK_RUN_SECONDS
from performance_schema.events_statements_summary_by_digest
WHERE    1=1
AND LAST_SEEN >= '${START_DATE}'
AND SCHEMA_NAME='${SCHEMA}'
ORDER BY SUM_CREATED_TMP_DISK_TABLES DESC
LIMIT 10;" 


#--top 5 未使用索引最多的SQL语句
GET_WEEK_TOP_NO_INDEX_SQL="
SELECT SCHEMA_NAME,DIGEST_TEXT,COUNT_STAR,SUM_NO_INDEX_USED,
sys.format_time(MIN_TIMER_WAIT) AS MIN_RUN_SECONDS,
sys.format_time(AVG_TIMER_WAIT) AS AVG_RUN_SECONDS,
sys.format_time(MAX_TIMER_WAIT) AS MAX_RUN_SECONDS,
sys.format_time(SUM_LOCK_TIME)  AS LOCK_RUN_SECONDS
from performance_schema.events_statements_summary_by_digest
WHERE    1=1
AND LAST_SEEN >= '${START_DATE}'
AND SCHEMA_NAME='${SCHEMA}'
ORDER BY SUM_NO_INDEX_USED DESC
LIMIT 10;" 



#--全局内存设置
GET_GOBAL_MEM_OPTION_SQL="
SELECT
ROUND(@@innodb_buffer_pool_size/1024/1024,2) as BUF_POOL ,
ROUND(@@innodb_log_buffer_size/1024/1024,2) as LOG_BUF,
ROUND(@@tmp_table_size/1024/1024,2) as TMP_TABLE,
ROUND(@@read_buffer_size/1024/1024,2) as READ_BUF,
ROUND(@@sort_buffer_size/1024/1024,2) as SORT_BUF,
ROUND(@@join_buffer_size/1024/1024,2) as JOIN_BUF,
ROUND(@@read_rnd_buffer_size/1024/1024,2) as READ_RND_BUF,
ROUND(@@binlog_cache_size/1024/1024,2) as BINLOG_CACHE,
ROUND(@@thread_stack/1024/1024,2) as THREAD_STACK,
(SELECT COUNT(host) FROM information_schema.processlist where command<>'Sleep') as active_connect;
"

#总内存使用
GET_TOTAL_MEMORY_SQL="
SELECT  
sys.format_bytes(sum(CURRENT_NUMBER_OF_BYTES_USED)) AS MEMORY_USED
FROM performance_schema.memory_summary_global_by_event_name"

#TOP 事件 内存使用
GET_EVENT_MEMORY_SQL="
SELECT event_name,
sys.format_bytes(CURRENT_NUMBER_OF_BYTES_USED) AS MEMORY
FROM performance_schema.memory_summary_global_by_event_name
ORDER BY CURRENT_NUMBER_OF_BYTES_USED DESC
LIMIT 10;"

#对象等待统计
GET_OBJECT_TOTAL_SQL="
SELECT  
OBJECT_SCHEMA,OBJECT_TYPE,OBJECT_NAME,COUNT_STAR,
sys.format_time(SUM_TIMER_WAIT) AS SUM_TIMER_WAIT,
sys.format_time(MIN_TIMER_WAIT) AS MIN_TIMER_WAIT,
sys.format_time(AVG_TIMER_WAIT) AS AVG_TIMER_WAIT,
sys.format_time(MAX_TIMER_WAIT) AS MAX_TIMER_WAIT
FROM performance_schema.objects_summary_global_by_type 
WHERE OBJECT_SCHEMA='${SCHEMA}'
order by sum_timer_wait desc
limit 250; "

#HOST INFO
GET_HOST_SUMMARY_SQL="select * sys.from host_summary ;"
GET_HOST_IO_SQL="SELECT * FROM sys.host_summary_by_file_io;"
GET_HOST_IO_TYPE_SQL="select * from sys.host_summary_by_file_io_type;"
GET_HOST_STAGES_SQL="select * from sys.host_summary_by_stages;"
GET_HOST_STATEMENT_SQL="select * from sys.host_summary_by_statement_latency ;"
GET_HOST_STATEMENT_TYPE_SQL="select * from sys.host_summary_by_statement_type;"

#USER INFO
GET_USER_SUMMARY_SQL="select * from sys.user_summary;"
GET_USER_IO_SQL="select * from sys.user_summary_by_file_io;"
GET_USER_IO_TYPE="select * from sys.user_summary_by_file_io_type;"
GET_USER_STAGES_SQL="select * from sys.user_summary_by_stages;"
GET_USER_STATEMENT_SQL="select * from sys.user_summary_by_statement_latency;"
GET_USE_STATEMENT_TYPE_SQL="select * from sys.user_summary_by_statement_type;"
GET_THREAD_IO_SQL="select * from sys.io_by_thread_by_latency;"

GET_FILE_IO_BYTES_SQL="select * from sys.io_global_by_file_by_bytes LIMIT 250;"
GET_FILE_IO_TIME_SQL="select * from sys.io_global_by_file_by_latency LIMIT 250;"
GET_FILE_IO_SUMMARY_BYTES_SQL="select * from sys.io_global_by_wait_by_bytes LIMIT 250;"
GET_FILE_IO_SUMMARY_TIME_SQL="select * from sys.io_global_by_wait_by_latency;"
GET_NEW_IO_SQL="select * from sys.latest_file_io ORDER BY LATENCY DESC LIMIT 250;"

GET_GOBAL_MEMORY_SQL="select * from sys.memory_global_total;"
GET_INNODB_BUF_SCHEMA_SQL="select * from sys.innodb_buffer_stats_by_schema;"
GET_INNODB_BUF_TABLE_SQL="select * from sys.innodb_buffer_stats_by_table;"
GET_HOST_MEMORY_BYTES_SQL="select * from sys.memory_by_host_by_current_bytes;"
GET_THREAD_MEMORY_BYTES_SQL="select * from sys.memory_by_thread_by_current_bytes;"
GET_USER_CURRENT_MEMORY_BYTES_SQL="select * from sys.memory_by_user_by_current_bytes;"
GET_EVENT_CURRENT_MEMEORY_BYTES_SQL="select * from sys.memory_global_by_current_bytes LIMIT 250;"
#Wait Event Info

GET_WAIT_EVENT_SQL="select * from sys.wait_classes_global_by_avg_latency;"
GET_HOST_WAIT_SQL="select * from sys.waits_by_host_by_latency;"
GET_USER_WAIT_SQL="select * from sys.waits_by_user_by_latency;"
GET_GLOBAL_WAIT_SQL="select * from sys.waits_global_by_latency;"
GET_LOCK_WAIT_SQL="select * from sys.innodb_lock_waits;"

GET_PROCESSLIST_SQL="select * from sys.processlist;"
GET_SESSION_SQL="select * from sys.session where 1=1 and conn_id!=connection_id();"
GET_CURRENT_TABLE_LOCK_WAIT_SQL="select * from sys.schema_table_lock_waits;"

GET_AUTO_INCREMENT_SQL="select * from sys.schema_auto_increment_columns where table_schema='${SCHEMA}';"
GET_INDEXS_STATIS_SQL="select * from sys.schema_index_statistics  where table_schema='${SCHEMA}';"
GET_REDUN_INDEX_SQL="select * from sys.schema_redundant_indexes  where table_schema='${SCHEMA}';"
GET_TABLE_STATIS_SQL="select * from sys.schema_table_statistics  where table_schema='${SCHEMA}';"
GET_BUF_HOT_TABLE_SQL="select * from sys.schema_table_statistics_with_buffer  where table_schema='${SCHEMA}';"
GET_UNUSED_INDEX_SQL="SELECT * FROM sys.schema_unused_indexes  where object_schema='${SCHEMA}';"

GET_FULL_TABLE_SCAN_SQL="select * from sys.schema_tables_with_full_table_scans  where object_schema='${SCHEMA}';"
GET_STATEMENT_ANLAYZ_SQL="select * from sys.statement_analysis  where db='${SCHEMA}';"
GET_FULL_SCAN_STATEMENT_SQL="select * from sys.statements_with_full_table_scans where db='${SCHEMA}';"
GET_FILESORT_STATEMENT_SQL="select * from sys.statements_with_sorting where db='${SCHEMA}';"
GET_TEMP_STATEMENT_SQL="select * from sys.statements_with_temp_tables where db='${SCHEMA}';"


#check sql
#----------------------------------------------------------------------------------------------
#1.太多逻辑读的SQL 平均每次大于2万行
GET_WEEK_TOP_LOGIC_READ_SQL="SELECT SCHEMA_NAME,
DIGEST AS digest,
DIGEST_TEXT,
COUNT_STAR,
AVG_TIMER_WAIT,
ROUND(SUM_ROWS_AFFECTED/COUNT_STAR, 0) AS rows_affected_avg,
ROUND(SUM_ROWS_SENT/COUNT_STAR, 0) AS rows_sent_avg,
ROUND(SUM_ROWS_EXAMINED/COUNT_STAR, 0) AS rows_examined_avg,
FIRST_SEEN,
LAST_SEEN 
FROM performance_schema.events_statements_summary_by_digest 
where  DIGEST_TEXT not like '%SHOW%' 
and DIGEST_TEXT not like 'desc%'
and SCHEMA_NAME='${SCHEMA}'
and ROUND(SUM_ROWS_EXAMINED/COUNT_STAR, 0) >20000
and COUNT_STAR >200
and last_seen > date_sub(curdate(),interval 7 day) 
order by  ROUND(SUM_ROWS_EXAMINED/COUNT_STAR, 0)  desc;"

#大事务影响行超过10万行
GET_WEEK_BIG_TRANS_SQL="SELECT SCHEMA_NAME,
DIGEST AS digest,
DIGEST_TEXT,
COUNT_STAR,
AVG_TIMER_WAIT,
ROUND(SUM_ROWS_AFFECTED/ COUNT_STAR, 0) AS rows_affected_avg,
ROUND(SUM_ROWS_SENT / COUNT_STAR, 0) AS rows_sent_avg,
ROUND(SUM_ROWS_EXAMINED / COUNT_STAR, 0) AS rows_examined_avg,
FIRST_SEEN,
LAST_SEEN 
FROM performance_schema.events_statements_summary_by_digest 
where  DIGEST_TEXT not like '%SHOW%' and  DIGEST_TEXT not like 'desc%'
and SCHEMA_NAME='${SCHEMA}'
and ROUND(SUM_ROWS_AFFECTED/ COUNT_STAR, 0) >100000
and COUNT_STAR >200
and last_seen > date_sub(curdate(),interval 8 day) 
order by ROUND(SUM_ROWS_AFFECTED/ COUNT_STAR, 0) desc;"

#查询语句返回太多行以及分页返回超过千行
GET_WEEK_RETRUN_ROWS_SQL="
SELECT SCHEMA_NAME,
DIGEST AS digest,
DIGEST_TEXT,
COUNT_STAR,
AVG_TIMER_WAIT,
ROUND(SUM_ROWS_AFFECTED/ COUNT_STAR, 0) AS rows_affected_avg,
ROUND(SUM_ROWS_SENT / COUNT_STAR, 0) AS rows_sent_avg,
ROUND(SUM_ROWS_EXAMINED / COUNT_STAR, 0) AS rows_examined_avg,
FIRST_SEEN,
LAST_SEEN 
FROM performance_schema.events_statements_summary_by_digest 
where  DIGEST_TEXT not like '%SHOW%' and  DIGEST_TEXT not like 'desc%'
and SCHEMA_NAME='${SCHEMA}'
and ROUND(SUM_ROWS_SENT / COUNT_STAR, 0)>1000
and COUNT_STAR >200
and last_seen > date_sub(curdate(),interval 10 day) 
order by ROUND(SUM_ROWS_SENT / COUNT_STAR, 0);"

#拥有不被推荐的数据类型
GET_NOT_RECOMMEND_TYPE_SQL="select TABLE_SCHEMA, TABLE_NAME,COLUMN_NAME,DATA_TYPE 
from information_schema.COLUMNS 
where DATA_TYPE in ('enum','set','bit','binary') 
and table_schema='${SCHEMA}'
order by table_name;"


#拥有超过5个索引的表
GET_FIVE_INDEX_TABLE_SQL="select table_schema,table_name,count(*) AS num_idx
from 
  (select distinct table_schema,table_name, INDEX_NAME 
   from information_schema.STATISTICS
   where  table_schema='${SCHEMA}'
   ) a 
group by table_schema,table_name 
having   num_idx>5 
order by table_schema,num_idx desc,table_name ;"

#有主键的表
GET_NO_PRIMARY_TABLE_SQL="select  t.table_name 
from information_schema.tables t
left join
 (select table_name from information_schema.STATISTICS
  where INDEX_NAME='PRIMARY'
  and  table_schema ='${SCHEMA}'
  group by   table_name 
 ) a
on  t.table_name=a.table_name
where t.table_schema ='${SCHEMA}'
and a.table_name is null
order by table_name;"

#组合索引超过5个字段的
GET_FIVE_INDEX_COL_SQL="select table_schema, table_name,index_name,count(index_name) num_col
from information_schema.STATISTICS 
where 
table_schema='${SCHEMA}'
and NON_UNIQUE=1
group by table_schema,table_name,index_name 
having   num_col>5  
order by  table_schema, num_col,table_name,index_name;"

#表注解为空的
GET_TAB_COMM_NULL_SQL="select TABLE_SCHEMA,TABLE_NAME from information_schema.TABLES 
where
table_schema='${SCHEMA}'
and TABLE_COMMENT=''
order by table_name;"

#列注解为空的
GET_COL_COM_NULL_SQL="select distinct TABLE_SCHEMA,TABLE_NAME,column_name 
from information_schema.COLUMNS 
where COLUMN_COMMENT='' 
and table_schema='${SCHEMA}'
order by table_name;"

#列注解包含值域的
GET_COL_COMM_VAULE_SQL="select distinct TABLE_SCHEMA,TABLE_NAME,column_name ,COLUMN_COMMENT
from information_schema.COLUMNS
where COLUMN_COMMENT regexp '[0-9]'
and table_schema='${SCHEMA}'
order by table_name;"

#数据库字符集
GET_SCHEMA_CHARSET_SQL="select schema_name,default_character_set_name,default_collation_name 
from information_schema.schemata 
where default_character_set_name != '${CHARTSET}'
and schema_name='${SCHEMA}';"

#表字符集
GET_TABLE_CHAR_SORT_SQL="select TABLE_SCHEMA, TABLE_NAME,TABLE_COLLATION
  from information_schema.tables
where TABLE_COLLATION !='${CHART_COLLATION}'
and table_schema='${SCHEMA}'
order by table_name;"

#列字符集
GET_COL_CHAR_SET_SQL="select TABLE_SCHEMA, TABLE_NAME,column_name, COLLATION_NAME
  from information_schema.columns
where 
   table_schema='${SCHEMA}'
   and CHARACTER_SET_NAME != '${CHARTSET}'
order by table_name;"


#拥有超过30个列的表
GET_TABLE_COL_OVER_SQL="select TABLE_SCHEMA, TABLE_NAME,count(COLUMN_NAME) num_col
from information_schema.COLUMNS 
where 
table_schema='${SCHEMA}'
group by TABLE_SCHEMA, TABLE_NAME 
having num_col>30
order by table_name;"

#主键拥有3个列以上的
GET_PRIMARY_THREE_COL_SQL="select table_schema, table_name,index_name,count(COLUMN_NAME) num_col
from information_schema.STATISTICS 
where INDEX_NAME='PRIMARY' 
and table_schema='${SCHEMA}'
group by table_schema,table_name
having   num_col>3  
order by  table_schema, num_col,table_name,index_name;"

#索引第一列不够多的选择值
GET_INDEX_FIRST_COL_SELECT_SQL="SELECT 
    first.TABLE_SCHEMA,
    first.TABLE_NAME,
    first.INDEX_NAME,
    first.COLUMN_NAME col1,
    first.CARDINALITY CARDINALITY1,
    second.COLUMN_NAME col2,
    second.CARDINALITY CARDINALITY2
FROM
    ((SELECT 
        TABLE_SCHEMA,
            TABLE_NAME,
            INDEX_SCHEMA,
            INDEX_NAME,
            COLUMN_NAME,
            SEQ_IN_INDEX,
            CARDINALITY
    FROM
        information_schema.STATISTICS
    WHERE
        table_schema = '${SCHEMA}'
            AND SEQ_IN_INDEX = 1) first, (SELECT 
        TABLE_SCHEMA,
            TABLE_NAME,
            INDEX_SCHEMA,
            INDEX_NAME,
            COLUMN_NAME,
            SEQ_IN_INDEX,
            CARDINALITY
    FROM
        information_schema.STATISTICS
    WHERE
        table_schema = '${SCHEMA}'
            AND SEQ_IN_INDEX = 2) second)
WHERE
    first.TABLE_SCHEMA = second.TABLE_SCHEMA
        AND first.TABLE_NAME = second.TABLE_NAME
        AND first.INDEX_NAME = second.INDEX_NAME
        AND second.CARDINALITY > first.CARDINALITY
ORDER BY first.TABLE_NAME;"



#拥有外键的表
GET_Foreign_KEY_TAB_SQL="select table_name,column_name,constraint_name,referenced_table_name,referenced_column_name 
from  information_schema.key_column_usage 
where referenced_table_name is not null 
and constraint_schema='${SCHEMA}'
order by TABLE_NAME;"

#使用rand函数来排序的
GET_RAND_SORT_SQL="select SCHEMA_NAME,DIGEST,DIGEST_TEXT 
from performance_schema.events_statements_summary_by_digest 
where DIGEST_TEXT like '%ORDER BY \`rand\`%' 
and SCHEMA_NAME='${SCHEMA}';"

#使用 select *
GET_SELECT_STAR_SQL="select count_star,SCHEMA_NAME, DIGEST,DIGEST_TEXT 
from performance_schema.events_statements_summary_by_digest 
where DIGEST_TEXT like '%select \*%' 
and SCHEMA_NAME='${SCHEMA}'
order by count_star desc;"

#使用 DISTINCT * 
GET_DISTINCT_STAR_SQL="select SCHEMA_NAME,DIGEST,DIGEST_TEXT 
from performance_schema.events_statements_summary_by_digest 
where DIGEST_TEXT like '%DISTINCTROW \*%'
and SCHEMA_NAME='${SCHEMA}';"

#表列名相同,大小类型不同
GET_TAB_COL_SIZE_TYPE_SQL="
select A.*
from
(
select  table_name,column_name,data_type,CHARACTER_MAXIMUM_LENGTH
from information_schema.columns IC
where IC.table_schema='${SCHEMA}'
AND COLUMN_NAME NOT IN ('status','create_time','update_time','id')
)A
INNER JOIN 
(
select  table_name,column_name,data_type,CHARACTER_MAXIMUM_LENGTH
from information_schema.columns IC
where IC.table_schema='${SCHEMA}'
AND COLUMN_NAME NOT IN ('status','create_time','update_time','id')
)B  ON A.COLUMN_NAME=B.COLUMN_NAME AND A.TABLE_NAME<>B.TABLE_NAME 
AND ( A.data_type<>B.data_type OR  A.CHARACTER_MAXIMUM_LENGTH<>B.CHARACTER_MAXIMUM_LENGTH)
ORDER BY A.COLUMN_NAME;"

#BUSINESS
#------------------------------------------------------------------------------------------------




GET_SLAVE_INFO_SQL="show slave status \G;"
#============================================================CODE SEGMETN===================================================================
if [[ ! -f  ${CHECK_RESULT_FILE} ]] ; then 
  touch ${CHECK_RESULT_FILE} 
fi

CREATE_HTML_HEAD
##SHELL OUT PUT
OUTPUT_TITLE "SYS SPACE"                    ##Print the title of the table
OUT_PUT_TABLE_HEAD                          ##Print table header
OUT_PUT_TITEL "$(df -h |head -1|awk '{ for (i=1; i<7; i++ ) printf("%s ",$i);print ""}')"           ##打印表格字段
OUT_PUT_LINES "$(df -h |grep ${SYS_DIR})"   ##Print each row of the table
OUT_PUT_TABLE_TAIL                          ##Print the tail of the table


OUTPUT_TITLE "MYSQL SPACE"
OUT_PUT_TABLE_HEAD
OUT_PUT_TITEL  "Size    Dir"                 ##Table fields (space delimited)
OUT_PUT_LINES "$(du -h ${DB_DIR} |tail -1 )"
OUT_PUT_TABLE_TAIL 

OUTPUT_TITLE "Database backupset space size"
OUT_PUT_TABLE_HEAD
OUT_PUT_TITEL  "Size    Dir"                 ##
OUT_PUT_LINES "$(du -h ${BAK_DIR} |tail -1 )"
OUT_PUT_TABLE_TAIL


OUTPUT_TITLE "MEM INFO"
OUT_PUT_TABLE_HEAD
OUT_PUT_TITEL  "TYPE TOTAL USED FREE SHARED BUFF AVAILABLE"
OUT_PUT_LINES "$(free -m |tail -2|grep Mem )"
OUT_PUT_LINES "$(free -m |tail -2|grep Swap)"
OUT_PUT_TABLE_TAIL


OUTPUT_TITLE "CPU INFO"
OUT_PUT_TABLE_HEAD
sar_cpu
OUT_PUT_TABLE_TAIL

OUTPUT_TITLE "SLAVE INFO:"
SALVE_MysqlDB $GET_SLAVE_INFO_SQL
Parse_salve_txt
OUT_PUT_TABLE_HEAD
OUT_PUT_TITEL "KEY   VAULE"
OUT_PUT_LINES "MASTER_UUID  ${MASTER_UUID}" 
OUT_PUT_LINES "SLAVE_IO_STATE  ${SLAVE_IO_STATE}" 
OUT_PUT_LINES "READ_MASTER_POST  ${READ_MASTER_POST}" 
OUT_PUT_LINES "Relay_Master_Log_File  ${Relay_Master_Log_File}" 
OUT_PUT_LINES "EXEC_MASTER_POST  ${EXEC_MASTER_POST}" 
OUT_PUT_LINES "BEHIND_SECONDS  ${BEHIND_SECONDS}" 
OUT_PUT_LINES "SLAVE_IO_RUNNING  ${SLAVE_IO_RUNNING}"
OUT_PUT_LINES "SLAVE_SQL_RUNNING  ${SLAVE_SQL_RUNNING}"
OUT_PUT_LINES "REPLICATE_DO_DB  ${REPLICATE_DO_DB}" 
OUT_PUT_LINES "SQLDELAY  ${SQLDELAY}" 
OUT_PUT_LINES "SALVE_SQL_RUN_STATE  ${SALVE_SQL_RUN_STATE}" 
OUT_PUT_LINES "LAST_SQL_ERROR  ${LAST_SQL_ERROR}" 
OUT_PUT_LINES "LAST_IO_ERROR  ${LAST_IO_ERROR}" 
OUT_PUT_LINES "RETRIEVED_GTID  ${RETRIEVED_GTID}" 
OUT_PUT_LINES "EXECUTED_GTID  ${EXECUTED_GTID}" 
OUT_PUT_TABLE_TAIL 

OUTPUT_TITLE "Deadlock Info:"                 
OUT_PUT_TABLE_HEAD                           
OUT_PUT_TITEL "DEAD_LOCK"                    
deadlock ${MYSQL_ERROR_LOG} ${BEFORE_DAYS} 
OUT_PUT_TABLE_TAIL 

##The following MySQL HTML output SQL contents (including field names):
OUTPUT_TITLE "TOP SCHEMA"
Target_MysqlDB $TOP_SCHEMA_SQL
OUT_PUT_NEW_LINE

OUTPUT_TITLE "TOP TABLES "
Target_MysqlDB $TOP_TABLE_SQL
OUT_PUT_NEW_LINE
#
#
OUTPUT_TITLE "TOP TABLE FRAG RATE >10%"
Target_MysqlDB $TO_FRAG_SQL
OUT_PUT_NEW_LINE


OUTPUT_TITLE "TPS"
Target_MysqlDB $GET_TPS_SQL
OUT_PUT_NEW_LINE

OUTPUT_TITLE "QPS"
Target_MysqlDB $GET_QPS_SQL
OUT_PUT_NEW_LINE

OUTPUT_TITLE "GET_SYS_TOP95_LONG_SQL"
Target_MysqlDB $GET_SYS_TOP95_LONG_SQL
OUT_PUT_NEW_LINE

OUTPUT_TITLE "GET_SYS_TOP_LONG_TIME_SQL"
Target_MysqlDB $GET_SYS_TOP_LONG_TIME_SQL
OUT_PUT_NEW_LINE

OUTPUT_TITLE "GET_SYS_TOP_LOCK_TIME_SQL"
Target_MysqlDB $GET_SYS_TOP_LOCK_TIME_SQL
OUT_PUT_NEW_LINE

OUTPUT_TITLE "GET_SYS_TOP_EXECUTE_COUNT_SQL"
Target_MysqlDB $GET_SYS_TOP_EXECUTE_COUNT_SQL
OUT_PUT_NEW_LINE

OUTPUT_TITLE "GET_SYS_TOP_WAIT_EVENT_SQL"
Target_MysqlDB $GET_SYS_TOP_WAIT_EVENT_SQL
OUT_PUT_NEW_LINE

OUTPUT_TITLE "GET_WEEK_SLOW_SQL"
Target_MysqlDB $GET_WEEK_SLOW_SQL
OUT_PUT_NEW_LINE


OUTPUT_TITLE "GET_WEEK_TOP_WAIT_EVENTS_SQL"
Target_MysqlDB $GET_WEEK_TOP_WAIT_EVENTS_SQL
OUT_PUT_NEW_LINE

OUTPUT_TITLE "GET_WEEK_TOP_WAITEVENTS_DETAIL_SQL"
Target_MysqlDB $GET_WEEK_TOP_WAITEVENTS_DETAIL_SQL
OUT_PUT_NEW_LINE

OUTPUT_TITLE "GET_WEEK_TOP_RUNTIME_SQL"
Target_MysqlDB $GET_WEEK_TOP_RUNTIME_SQL
OUT_PUT_NEW_LINE

OUTPUT_TITLE "GET_WEEK_TOP_EXECUTE_COUNT_SQL"
Target_MysqlDB $GET_WEEK_TOP_EXECUTE_COUNT_SQL
OUT_PUT_NEW_LINE

OUTPUT_TITLE "GET_WEEK_TOP_AVGTIME_SQL"
Target_MysqlDB $GET_WEEK_TOP_AVGTIME_SQL
OUT_PUT_NEW_LINE

OUTPUT_TITLE "GET_WEEK_TOP_LOCKTIME_SQL"
Target_MysqlDB $GET_WEEK_TOP_LOCKTIME_SQL
OUT_PUT_NEW_LINE

OUTPUT_TITLE "GET_WEEK_TOP_EXAMINEDROW_SQL"
Target_MysqlDB $GET_WEEK_TOP_EXAMINEDROW_SQL
OUT_PUT_NEW_LINE

OUTPUT_TITLE "GET_WEEK_TOP_SENTROW_SQL"
Target_MysqlDB $GET_WEEK_TOP_SENTROW_SQL
OUT_PUT_NEW_LINE

OUTPUT_TITLE "GET_WEEK_TOP_SORTROW_SQL"
Target_MysqlDB $GET_WEEK_TOP_SORTROW_SQL
OUT_PUT_NEW_LINE

OUTPUT_TITLE "GET_WEEK_TOP_AFFECTED_SQL"
Target_MysqlDB $GET_WEEK_TOP_AFFECTED_SQL
OUT_PUT_NEW_LINE

OUTPUT_TITLE "GET_WEEK_TOP_DISKTMP_SQL"
Target_MysqlDB $GET_WEEK_TOP_DISKTMP_SQL
OUT_PUT_NEW_LINE

OUTPUT_TITLE "GET_WEEK_TOP_NO_INDEX_SQL"
Target_MysqlDB $GET_WEEK_TOP_NO_INDEX_SQL
OUT_PUT_NEW_LINE




OUTPUT_TITLE "GET_GOBAL_MEM_OPTION_SQL"
Target_MysqlDB $GET_GOBAL_MEM_OPTION_SQL
OUT_PUT_NEW_LINE

OUTPUT_TITLE "GET_TOTAL_MEMORY_SQL"
Target_MysqlDB $GET_TOTAL_MEMORY_SQL
OUT_PUT_NEW_LINE

OUTPUT_TITLE "GET_EVENT_MEMORY_SQL"
Target_MysqlDB $GET_EVENT_MEMORY_SQL
OUT_PUT_NEW_LINE

OUTPUT_TITLE "GET_OBJECT_TOTAL_SQL"
Target_MysqlDB $GET_OBJECT_TOTAL_SQL
OUT_PUT_NEW_LINE






OUTPUT_TITLE "HOST INFO"
Target_MysqlDB "$GET_HOST_SUMMARY_SQL"
OUT_PUT_NEW_LINE
Target_MysqlDB "$GET_HOST_IO_SQL"
OUT_PUT_NEW_LINE
Target_MysqlDB "$GET_HOST_IO_TYPE_SQL"
OUT_PUT_NEW_LINE
Target_MysqlDB "$GET_HOST_STAGES_SQL"
OUT_PUT_NEW_LINE
Target_MysqlDB "$GET_HOST_STATEMENT_SQL"
OUT_PUT_NEW_LINE
Target_MysqlDB "$GET_HOST_STATEMENT_TYPE_SQL"
OUT_PUT_NEW_LINE

OUTPUT_TITLE "USER INFO"
Target_MysqlDB "$GET_USER_SUMMARY_SQL"
OUT_PUT_NEW_LINE
Target_MysqlDB "$GET_USER_IO_SQL"
OUT_PUT_NEW_LINE
Target_MysqlDB "$GET_USER_IO_TYPE"
OUT_PUT_NEW_LINE
Target_MysqlDB "$GET_USER_STAGES_SQL"
OUT_PUT_NEW_LINE
Target_MysqlDB "$GET_USER_STATEMENT_SQL"
OUT_PUT_NEW_LINE
Target_MysqlDB "$GET_USE_STATEMENT_TYPE_SQL"
OUT_PUT_NEW_LINE
Target_MysqlDB "$GET_THREAD_IO_SQL"
OUT_PUT_NEW_LINE

OUTPUT_TITLE "FILE IO INFO"
Target_MysqlDB "$GET_FILE_IO_BYTES_SQL"
OUT_PUT_NEW_LINE
Target_MysqlDB "$GET_FILE_IO_TIME_SQL"
OUT_PUT_NEW_LINE
Target_MysqlDB "$GET_FILE_IO_SUMMARY_BYTES_SQL"
OUT_PUT_NEW_LINE
Target_MysqlDB "$GET_FILE_IO_SUMMARY_TIME_SQL"
OUT_PUT_NEW_LINE
Target_MysqlDB "$GET_NEW_IO_SQL"
OUT_PUT_NEW_LINE

OUTPUT_TITLE "MEMORY INFO"
Target_MysqlDB "$GET_GOBAL_MEMORY_SQL"
OUT_PUT_NEW_LINE
Target_MysqlDB "$GET_INNODB_BUF_SCHEMA_SQL"
OUT_PUT_NEW_LINE
Target_MysqlDB "$GET_INNODB_BUF_TABLE_SQL"
OUT_PUT_NEW_LINE
Target_MysqlDB "$GET_HOST_MEMORY_BYTES_SQL"
OUT_PUT_NEW_LINE
Target_MysqlDB "$GET_THREAD_MEMORY_BYTES_SQL"
OUT_PUT_NEW_LINE
Target_MysqlDB "$GET_USER_CURRENT_MEMORY_BYTES_SQL"
OUT_PUT_NEW_LINE
Target_MysqlDB "$GET_EVENT_CURRENT_MEMEORY_BYTES_SQL"
OUT_PUT_NEW_LINE


#Wait Event Info
OUTPUT_TITLE "WAIT EVENT INFO"

Target_MysqlDB "$GET_WAIT_EVENT_SQL"
OUT_PUT_NEW_LINE
Target_MysqlDB "$GET_HOST_WAIT_SQL"
OUT_PUT_NEW_LINE
Target_MysqlDB "$GET_USER_WAIT_SQL"
OUT_PUT_NEW_LINE
Target_MysqlDB "$GET_GLOBAL_WAIT_SQL"
OUT_PUT_NEW_LINE
OUTPUT_TITLE "CURRENT LOCK WAIT INFO"
Target_MysqlDB "$GET_LOCK_WAIT_SQL"
OUT_PUT_NEW_LINE

OUTPUT_TITLE "CURRENT PROCESS INFO"
Target_MysqlDB "$GET_PROCESSLIST_SQL"
OUT_PUT_NEW_LINE
OUTPUT_TITLE "CURRENT SESSION INFO"
Target_MysqlDB "$GET_SESSION_SQL"
OUTPUT_TITLE "CURRENT TABLE LOCK WAIT INFO"
OUT_PUT_NEW_LINE
Target_MysqlDB "$GET_CURRENT_TABLE_LOCK_WAIT_SQL"
OUT_PUT_NEW_LINE


OUTPUT_TITLE "STATISTICS INFO"
OUTPUT_TITLE "AUTO INCREMENT"
Target_MysqlDB "$GET_AUTO_INCREMENT_SQL"
OUT_PUT_NEW_LINE
OUTPUT_TITLE " INDEXS STATISTICS:"
Target_MysqlDB "$GET_INDEXS_STATIS_SQL"
OUT_PUT_NEW_LINE
Target_MysqlDB "$GET_REDUN_INDEX_SQL"
OUT_PUT_NEW_LINE
OUTPUT_TITLE " TABLE STATISTICS:"
Target_MysqlDB "$GET_TABLE_STATIS_SQL"
OUT_PUT_NEW_LINE
OUTPUT_TITLE   "BUF HOT INFO:"
Target_MysqlDB "$GET_BUF_HOT_TABLE_SQL"
OUT_PUT_NEW_LINE
OUTPUT_TITLE "UNUSED INDEX:"
Target_MysqlDB "$GET_UNUSED_INDEX_SQL"
OUT_PUT_NEW_LINE

OUTPUT_TITLE "STATEMENT INFO"
OUTPUT_TITLE "FULL SCAN SQL:"
Target_MysqlDB "$GET_FULL_TABLE_SCAN_SQL"
OUT_PUT_NEW_LINE
OUTPUT_TITLE "ALL SQL:"
Target_MysqlDB "$GET_STATEMENT_ANLAYZ_SQL"
OUT_PUT_NEW_LINE
Target_MysqlDB "$GET_FULL_SCAN_STATEMENT_SQL"
OUT_PUT_NEW_LINE
OUTPUT_TITLE "FILE SORT SQL:"
Target_MysqlDB "$GET_FILESORT_STATEMENT_SQL"
OUT_PUT_NEW_LINE
OUTPUT_TITLE " TEMP SQL:"
Target_MysqlDB "$GET_TEMP_STATEMENT_SQL"
OUT_PUT_NEW_LINE



OUTPUT_TITLE "使用 DISTINCT STAR :"
Target_MysqlDB "$GET_DISTINCT_STAR_SQL"
OUT_PUT_NEW_LINE

OUTPUT_TITLE "使用 SELECT STAR :"
Target_MysqlDB "$GET_SELECT_STAR_SQL"
OUT_PUT_NEW_LINE

OUTPUT_TITLE "拥有外键的表 :"
Target_MysqlDB "$GET_Foreign_KEY_TAB_SQL"
OUT_PUT_NEW_LINE


OUTPUT_TITLE "索引第一列不够多的选择值 :"
Target_MysqlDB "$GET_INDEX_FIRST_COL_SELECT_SQL"
OUT_PUT_NEW_LINE


OUTPUT_TITLE "拥有超过30个列的表 :"
Target_MysqlDB "$GET_TABLE_COL_OVER_SQL"
OUT_PUT_NEW_LINE

OUTPUT_TITLE "列字符集 :"
Target_MysqlDB "$GET_COL_CHAR_SET_SQL"
OUT_PUT_NEW_LINE

OUTPUT_TITLE "表字符集 :"
Target_MysqlDB "$GET_TABLE_CHAR_SORT_SQL"
OUT_PUT_NEW_LINE

OUTPUT_TITLE "数据库字符集 :"
Target_MysqlDB "$GET_SCHEMA_CHARSET_SQL"
OUT_PUT_NEW_LINE

OUTPUT_TITLE "列注解包含值域的 :"
Target_MysqlDB "$GET_COL_COMM_VAULE_SQL"
OUT_PUT_NEW_LINE

OUTPUT_TITLE "列注解为空的 :"
Target_MysqlDB "$GET_COL_COM_NULL_SQL"
OUT_PUT_NEW_LINE


OUTPUT_TITLE "表注解为空的 :"
Target_MysqlDB "$GET_TAB_COMM_NULL_SQL"
OUT_PUT_NEW_LINE


OUTPUT_TITLE "组合索引超过5个字段的 :"
Target_MysqlDB "$GET_FIVE_INDEX_COL_SQL"
OUT_PUT_NEW_LINE


OUTPUT_TITLE "没有主键的表 :"
Target_MysqlDB "$GET_NO_PRIMARY_TABLE_SQL"
OUT_PUT_NEW_LINE

OUTPUT_TITLE "拥有超过5个索引的表 :"
Target_MysqlDB "$GET_FIVE_INDEX_TABLE_SQL"
OUT_PUT_NEW_LINE

OUTPUT_TITLE "拥有不被推荐的数据类型 :"
Target_MysqlDB "$GET_NOT_RECOMMEND_TYPE_SQL"
OUT_PUT_NEW_LINE

OUTPUT_TITLE "查询语句返回太多行:"
Target_MysqlDB "$GET_WEEK_RETRUN_ROWS_SQL"
OUT_PUT_NEW_LINE

OUTPUT_TITLE "大事务影响行超过10万行:"
Target_MysqlDB "$GET_WEEK_BIG_TRANS_SQL"
OUT_PUT_NEW_LINE

OUTPUT_TITLE "太多逻辑读的SQL 平均每次大于2万行:"
Target_MysqlDB "$GET_WEEK_TOP_LOGIC_READ_SQL"
OUT_PUT_NEW_LINE

OUTPUT_TITLE "表列名相同,大小类型不同:"
Target_MysqlDB "$GET_TAB_COL_SIZE_TYPE_SQL"
OUT_PUT_NEW_LINE

#============================Bussines Info==============================
#OUTPUT_TITLE "This Week Merchant Status"
#Target_MysqlDB $GET_MERCHANT_SQL
#OUT_PUT_NEW_LINE


#OUTPUT_TITLE "This Week Sk status"
#Target_MysqlDB $GET_SK_STATUS_SQL
#OUT_PUT_NEW_LINE




echo " <h4 align="center" class="awr">  COPY 2022-07-29 Author:InnerCodeDBA  fankun@sharkz.com.cn.earth  </h4> " >>${CHECK_RESULT_FILE}                       
CREATE_HTML_END


sed -i 's/<TH>/<TH class=awrbg scope="col">/g'  ${CHECK_RESULT_FILE}  ## Add background to SQL fields output by MySQL

