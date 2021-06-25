
import re
import pymysql
import requests
db_dict= {"host":"47.115.30.167",
        "port":3306,
        "user":"root",
        "password":"123456",
        "db":"pro_db",
    }
url_dict = {
    "host01": "http://10.10.203.192:8280/_cat/indices?v"

}

# 获取每行的数据
def get_line_list(line: str) -> list:
    re_sub = re.sub("( )+", "*", line)
    line_list = re_sub.split("*")
    return line_list


def get_connection():
    conn = pymysql.connect(
       **db_dict
    )
    return  conn

def update_db(conn: pymysql.Connection, line_list: list, es_host: str):
    cursor = conn.cursor()
    sql = "INSERT into  elasticsearch_tb(es_host,es_health,es_status,es_index,es_uuid,es_pri,es_rep,docs_count,docs_deleted,store_size,pri_store_size) value(%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s);"
    row=cursor.execute(sql,(es_host,line_list[0],line_list[1],line_list[2],line_list[3],line_list[4],line_list[5],line_list[6],line_list[7],line_list[8],line_list[9]))
    conn.commit()

def run():
    conn = get_connection()  # 获取连接
    # 循环字典
    for key,value in url_dict.items():
        # 每请求一次，获取对应es的信息并且按行切割
        re_list = get_elasticsearch_msg(value).split("\n")
        for re_line in re_list[1:-1] : # z
            # 把每一行的相关信息分割成列表，并且更新到数据库
            line_list = get_line_list(re_line)
            print(key+":",line_list)
            update_db(conn,line_list,key)
    conn.close()

def get_elasticsearch_msg(url):
    res = requests.request("GET", url, headers={}, data={}).text
    return res


if __name__ == '__main__':
    run()
