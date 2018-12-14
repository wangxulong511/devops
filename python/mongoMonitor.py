#!/usr/bin/env python
# -*- coding:utf-8 -*-

from pymongo import MongoClient
import mongoServer
conn = MongoClient('10.101.130.130', 27017)
db = conn.admin  #连接mydb数据库，没有则自动创建
my_set = db.test#使用test_set集合，没有则自动创建$

def main():
    print mongoServer.mongodbMonitor().serverStatus(conn)

if __name__ == '__main__':
    main()
