#!/usr/bin/env python
# -*- coding: utf-8 -*-

import redis
import datetime

'''
删除redis bigkey，只能删除大key
日期：2020-07-13 
auth：wxl
'''



# 参考函数
# hash大key删除方式
def del_big_hash(redis_conn, hash_key):
    # 每次 SCAN 和删除 field 的数量，可以根据实际调高以提高效率
    COUNT = 500
    cursor = '0'
    while cursor != 0:
        pl = redis_conn.pipeline()
        cursor, data =  redis_conn.hscan(hash_key, cursor=cursor, count=COUNT)

        for item in data.items():
            pl.hdel(hash_key, item[0])
        pl.execute()


def del_big_list(redis_conn, list_key):

    long_llen = redis_conn.llen(list_key);
    counter = 0;
    left = 1000;

    while (counter < llen) :
        # //每次从左侧截掉100个
        redis_conn.ltrim(list_key, left, llen);
        counter += left;

    # //最终删除key
    # redis_conn.delete(list_key);

#
def del_big_set(redis_conn, set_key):
    # 每次 SCAN 和删除 field 的数量，可以根据实际调高以提高效率
    COUNT = 500
    cursor = '0'

    while cursor != 0:
        pl = redis_conn.pipeline()
        cursor, data = redis_conn.sscan(set_key, cursor=cursor, count=COUNT)

        for item in data:
            pl.srem(set_key, item)
        pl.execute()

def del_big_zset(redis_conn, zset_key):
    # 每次 SCAN 和删除 field 的数量，可以根据实际调高以提高效率
    COUNT = 500
    cursor = '0'

    while cursor != 0:
        pl = redis_conn.pipeline()
        cursor, data = redis_conn.zscan(zset_key, cursor=cursor, count=COUNT)
        print(data)
        for item in data:
            print(item[0])
            pl.zrem(zset_key, item[0])
        pl.execute()

    # //最终删除key
    #redis_conn.delete(zset_key);

def main():
    # Redis 连接
    conn = redis.StrictRedis(host='127.0.0.1', port=6379)

    # 要删除的 Key 的名字
    key_to_be_deleted = 'myzset'
    key_type = conn.type(key_to_be_deleted)

    print(key_type)
    if key_type == b'hash':
        del_big_hash(conn, key_to_be_deleted)
    elif key_type == b'list':
        del_big_list(conn, key_to_be_deleted)
    elif key_type == b'set':
        del_big_set(conn, key_to_be_deleted)
    elif key_type == b'zset':
        del_big_zset(conn, key_to_be_deleted)
    else:
        print("不是")
if __name__ == '__main__':
    print(datetime.datetime.now())
    main()
    print(datetime.datetime.now())
