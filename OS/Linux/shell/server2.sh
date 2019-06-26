source /etc/profile
NAME=$2
BASE_DIR=$3
if [  -d "$BASE_DIR" ]; then
cd "$BASE_DIR"
fi
profile=bs
JAVA_OPT=" -Xms256m -Xmx256m -Xmn256m  -Xss512k  -XX:MetaspaceSize=256m -XX:MaxMetaspaceSize=256m -XX:+UseConcMarkSweepGC -XX:+CMSClassUnloadingEnabled -XX:+UseCMSInitiatingOccupancyOnly -XX:CMSInitiatingOccupancyFraction=80  -XX:+UseParNewGC "

function start() {
     stop
     echo "start server now , please waiting..."
     nohup java -jar $JAVA_OPT -Dspring.profiles.active="$profile" "$NAME" >nohup.out 2>&1 & 
     sleep 2
     ps aux|grep "$NAME" |grep -v "$0"|grep -v "grep"
echo "--------------------------- start finish------------------------------"            
}


function stop() {
     pid=`ps -ef |grep  "$NAME" |grep -v "$0"|grep -v "grep"|awk '{print $2}'`
     test "$pid" != '' && echo "server run in $pid" || echo "pid is null"
for i in "$pid"
do
     test "$i" != '' && kill -9 "$i"
     echo "kill-pid:------------$i"
done	  
  echo "-----------------------------killed-----------------------------------" 
}

function backup() {
    t=$(date +%Y%m%d%H%M%S)
if [ ! -d "backup" ]; then
  mkdir -p backup
fi

if [  -f "$NAME" ]; then 
     echo backup app  begin...
     cp  "$NAME" "backup/$NAME.$t"
	else
     echo
     echo backup app fail!!!
     #read -p 'jar file not find,please keypress Ctrl+C exit!'
fi
  echo "---------------------------bak finish----------------------------------" 
}


function status() {
                pid=`ps -ef |grep  "$NAME" |grep -v "$0"|grep -v "grep"|awk '{print $2}'`
                test "$pid" != '' && echo "$NAME is running, and the pid is $pid" || echo "can not detect the pid of $NAME !"      
}

function restart() {
        stop 
        start
}


case "$1" in
        start)
                start
        ;;
       start-log)
                 start
                 tail -f nohup.out
        ;;
        backup)
                 backup
        ;;
        stop)
                stop
        ;;
       stopbak)
                stop
                backup
        ;;

        status)
                status
        ;;
        restart)
                restart
        ;;
        * )
                echo "usage: $0 {start|stop|status|restart}"
                exit 1
        ;;
esac
