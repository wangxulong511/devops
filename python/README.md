#openfalcon-mongodb监控插件

https://blog.csdn.net/vbaspdelphi/article/details/52796411

https://github.com/wangxulong511/mongomon

Grafana 数据库监控平台
https://www.jianshu.com/p/20bdb7fbe350?from=timeline&isappinstalled=0

ES6
https://www.bilibili.com/video/av35882450?from=search&seid=13217966141035681599

 阿里云redis大key搜索工具 
```
find_bigkeys.py  
Redis提供了list、hash、zset等复杂类型的数据结构，业务在使用的时候可能由于key设计不合理导致某个key过大，由于redis简单的单线程模型，业务在获取或者删除大key的时候都会有一定的影响，另外在集群模式下由于大key的产生还很容易导致某个子节点的内存满，综上所述我们需要提供大key的搜索工具。

扫描脚本
遍历key
对于Redis主从版本可以通过scan命令进行扫描，对于集群版本提供了ISCAN命令进行扫描，命令规则如下, 其中节点个数node可以通过info命令来获取到


ISCAN idx cursor [MATCH pattern] [COUNT count]（idx为节点的id，从0开始，16到64gb的集群实例为8个节点故idx为0到7，128g 256gb的为16个节点）

扫描脚本
find_bigkeys.py 

执行命令
python find_bigkey host 6379 | tee -a redis_bigkeys.log

cat redis_bigkeys.log | sort -k 3r

可以通过python find_bigkey host 6379 来执行，支持阿里云Redis的主从版本和集群版本的大key查找，默认大key的阈值为10240，也就是对于string类型的value  大于10240的认为是大key，对于list的话如果list长度大于10240认为是大key，对于hash的话如果field的数目大于10240认为是大key。另外默认该脚本每次搜索1000 个key，对业务的影响比较低，不过最好在业务低峰期进行操作，避免scan命令对业务的影响。

时间： 2017-07-04
```

rdbtools

```
发现redis使用量突然暴增，于是紧急扩容redis，不能影响服务运行。扩容之后，赶紧查找原因，突破口就是寻找存在哪些大key。

1. 将redis的dump.rdb文件下载到本地（一般redis的持久化文件以rdb的方式存储，在redis配置文件可以找到dump.rdb的存储路径）。

2. 用rdbtools工具生产内存报告，命令是 rdb -c memory，例子：

sudo rdb -c memory  /redisfile/dump.rdb >test.csv
注意：rdb文件越大，生成时间越长。

Rdbtools是以python语言开发的。
GITHUP地址：https://github.com/sripathikrishnan/redis-rdb-tools/

分析redis key大小的几种方法
https://www.cnblogs.com/ExMan/p/11586751.html
```
