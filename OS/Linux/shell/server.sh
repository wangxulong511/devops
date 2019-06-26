#!/usr/bin/env bash

JST_HOME="/home/jst"
APPLICATION_HOME="$JST_HOME/tomcat"


function start() {
cd $APPLICATION_HOME/jst-server/xxljob_19880/bin/
$APPLICATION_HOME/jst-server/xxljob_19880/bin/startup.sh
cd -
echo "-------------------- xxljob 启动 ----------------"
for application_name in `cat $APPLICATION_HOME/conf/application-list`
do
	$APPLICATION_HOME/sh/server2.sh start ${application_name}.jar $APPLICATION_HOME/jst-server/$application_name
	echo "------------- $application_name 启动 -------------"
	sleep 30
done
cd $APPLICATION_HOME/jst-server/mgr_30001/bin/
$APPLICATION_HOME/jst-server/mgr_30001/bin/startup.sh
cd -
echo "-------------------- mgr 启动 ----------------"
}


function stop() {
for application_name in `cat $APPLICATION_HOME/conf/application-list`
do
	$APPLICATION_HOME/sh/server2.sh stop ${application_name}.jar $APPLICATION_HOME/jst-server/$application_name
	echo "------------- $application_name 停止 -------------"
	sleep 30
done
cd $APPLICATION_HOME/jst-server/mgr_30001/bin/
$APPLICATION_HOME/jst-server/mgr_30001/bin/shutdown.sh
cd -
echo "-------------------- mgr 停止 ----------------"
cd $APPLICATION_HOME/jst-server/xxljob_19880/bin/
$APPLICATION_HOME/jst-server/xxljob_19880/bin/shutdown.sh
cd -
echo "-------------------- xxljob 停止 ----------------"
}


function restart() {
cd $APPLICATION_HOME/jst-server/xxljob_19880/bin/
$APPLICATION_HOME/jst-server/xxljob_19880/bin/shutdown.sh
echo "-------------------- xxljob 停止 ----------------"
$APPLICATION_HOME/jst-server/xxljob_19880/bin/startup.sh
echo "-------------------- xxljob 启动 ----------------"
cd -
for application_name in `cat $APPLICATION_HOME/conf/application-list`
do
	$APPLICATION_HOME/sh/server2.sh restart ${application_name}.jar $APPLICATION_HOME/jst-server/$application_name
	echo "------------- $application_name 重启 -------------"
	sleep 30
done
cd $APPLICATION_HOME/jst-server/mgr_30001/bin/
$APPLICATION_HOME/jst-server/mgr_30001/bin/shutdown.sh
echo "-------------------- mgr 停止 ----------------"
$APPLICATION_HOME/jst-server/mgr_30001/bin/startup.sh
echo "-------------------- mgr 启动 ----------------"
cd -
}

case "$1" in
        start)
		start
        ;;
        stop)
		stop
        ;;

        restart)
		restart
        ;;
        * )
                echo "usage: $0 {start|stop|restart}"
        ;;
esac
