#-*- coding:utf8 -*-
import pymssql #引入pymssql模块
import sys

def conn():
    connect = pymssql.connect(host='10.101.200.32',user='sa',password='123456', database='test') #服务器名,账户,密码,数据库名
    if connect:
        return connect

def query():
    connect = conn()
    cur = connect.cursor()
    cur.execute(
        'SELECT    count(*)  FROM sys.[dm_exec_requests] AS der   CROSS APPLY   sys.[dm_exec_sql_text](der.[sql_handle]) AS dest   WHERE  1=1  and DATEDIFF(minute, der.start_time, GETDATE())>5  ')
    row = cur.fetchone()
    res = row[0]
    cur.close()
    connect.close()
    return res

def transaction():
    connect = conn()
    cur = connect.cursor()
    cur.execute("SELECT  COUNT(*) FROM    sys.dm_tran_session_transactions AS ST  INNER JOIN sys.dm_tran_active_transactions AS AT ON ST.transaction_id = AT.transaction_id  INNER JOIN sys.dm_tran_database_transactions AS DT ON ST.transaction_id = DT.transaction_id  WHERE DATEDIFF(minute, AT.transaction_begin_time, GETDATE())>5 ")
    row = cur.fetchone()
    res = row[0]
    cur.close()
    connect.close()
    return res

if __name__ == '__main__':
    #print(sys.argv[1])
    args = sys.argv[1]
    count = 0
    if args == 'query':
        count = query()
        print(count)
    if args == 'transaction':
        count = transaction()
        print(count)