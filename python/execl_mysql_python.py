#!/usr/bin/env python
#coding:utf-8

import xlwt
import pymysql
import datetime
import time

import sys
import os
import smtplib
from email.header import Header
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from email.utils import parseaddr, formataddr

class SendEmail(object):
    def __init__(self, sender, sendto, subject, record_path, filename):
        self.sender = sender
        self.sendto = sendto
        self.subject = subject
        self.filename = filename
        self.smtpserver = 'smtp.exmail.qq.com'
        self.username = self.sender
        self.record_path = record_path
        self.password = '123456'
        self._init()

    def _init(self):
        if not os.path.exists(os.path.join(self.record_path, self.filename)):
            print('{0} is not exist, program exiting.....')
            sys.exit()

    def _format_addr(str):
        name, addr = parseaddr(str)
        return formataddr((Header(name, 'utf-8').encode(), addr))

    def readContent(self):
        file_name = os.path.join(self.record_path, self.filename)
        with open(file_name, 'rb') as fd:
            return fd.read()

    def buildHeader(self):
        self.msg = MIMEMultipart()
        self.msg['from'] = self.sender
        self.msg['to'] = ','.join(self.sendto) # 构建头部信息，跟上面一样，值必须为字符串
        self.msg['subject'] = self.subject
        mailbody = self.readContent()  # 读取测试报告的内容
        # html附件    下面是将测试报告放在附件中发送
        atta = MIMEText(mailbody, 'base64', 'utf-8')
        atta["Content-Type"] = 'application/octet-stream'
        atta["Content-Disposition"] = "attachment; filename=" + self.filename  # 这里的filename可以任意写，写什么名字，附件的名字就是什么
        self.msg.attach(atta)

    def send(self):
        self.buildHeader()
        try:
            sm = smtplib.SMTP_SSL()
            sm.connect(self.smtpserver, 465)
            sm.login(self.username, self.password)
            sm.sendmail(self.sender, self.sendto, self.msg.as_string())
            print("邮件发送成功")
        except Exception as e:
            raise e
            print("Error: 无法发送邮件.%s"%e)
        finally:
            sm.quit()

class MySQL:
    def __init__(self,host, port, user, password, db_name):
        self.connection = pymysql.connect(host=host,
                                    port=port, user=user, passwd=password, db=db_name,charset='utf8')

    def get_connection(self):
        return self.connection

    #定义一个执行SQL的函数
    def execude_sql(self, sql='', close_conn=True):
        conn = self.get_connection()
        cursor = conn.cursor()
        cursor.execute(sql)  # args即要传入SQL的参数
        result = cursor.fetchall()
        return result

    def close(self):
        if self.connection:
            self.connection.close()
            self.connection = None
    #通过SQL得到该表有多少行，如果想取出指定的数据，只需要在后面加where条件即可。

    def wite_to_excel(self, record_path, file_name, sql=''):
        name = os.path.join(record_path, file_name)
        wbk = xlwt.Workbook(encoding='utf-8', style_compression=0)
        sheet = wbk.add_sheet('sheet1', cell_overwrite_ok=True)
        # 设置写excel的样式
        # 设置写excel的样式
        alignment = xlwt.Alignment()
        style = xlwt.XFStyle()
        font = xlwt.Font()
        font.name = 'Times New Roman'
        # 0x0190设置字体为20，默认为0x00C8 字体为10 ，0x00C8为十六进制的数字
        # font.height = 0x0190
        style.font = font

        style.num_format_str = 'yyyy-m-dd hh:mm:ss' #
        alignment.horz = xlwt.Alignment.HORZ_LEFT  # 可取值: HORZ_GENERAL, HORZ_LEFT, HORZ_CENTER, HORZ_RIGHT, HORZ_FILLED, HORZ_JUSTIFIED, HORZ_CENTER_ACROSS_SEL, HORZ_DISTRIBUTED
        alignment.vert = xlwt.Alignment.VERT_CENTER
        style.alignment = alignment

        # 查询得到该表有多少列
        result = self.execude_sql(sql)

        # 定义所有的列名，共7列
        fields = ['执行开始时间', '数据库用户', '数据库名', 'SQL语句', '执行总次数', '执行总时长(秒)', '平均执行时长(秒)', '扫描总行数', '返回总行数']
        # 将列名插入表格，共7列
        for i in range(len(fields)):
            sheet.col(i).width = 5000
            sheet.write(0, i, fields[i], style)

        # 通过循环取出每一行数据，写入excel
        # for i in range(1, count_cols - 1):
        #     data = list(cursor.fetchone())
        #     for j in range(0, len(fileds)):
        #         sheet.write(i, j, data[j], style)
        for row in range(1, len(result) + 1):

            for col in range(len(fields)):
                if col == 0:
                    sheet.write(row, col, result[row - 1][0], style)
                else:
                    sheet.write(row, col, result[row - 1][col])
        wbk.save(name)

if __name__ == '__main__':
    record_path = 'E:\\'
    report_name = 'prod_slow_sql_report'
    # 格式化时间输出，用于给Excel起名时使用。
    sheet_time = datetime.datetime.now()
    excel_time = sheet_time.strftime('%Y%m%d')
    print(excel_time)

    business_name = {'pay': '10.101.10.100:3306'}

    addr_list = {
        'pay':['2341134@email.cn', '2341134@email.cn']        
        }


    time_start = (sheet_time - datetime.timedelta(days=1)).strftime('%Y-%m-%d')
    print(time_start)
    sender = 'jsjkops@jieshunpay.cn'
    mysql = MySQL(host='10.10.10.60', port=3306, user='test', password='test', db_name='test')

    for i in business_name:
        print('=======开始生成慢SQL数据表======[' + i + ']:'+ time.strftime("%Y-%m-%d %H:%M:%S"))

        sql = "SELECT  ts_min, user_max, db_max ,sample,ts_cnt,query_time_sum,query_time_pct_95, rows_examined_sum,rows_sent_sum " \
              "from mysql_slow_query_review_history where ts_min > '%s' and query_time_pct_95 > 1 and hostname_max='%s';" %(time_start, business_name[i])
        file_name = report_name + '_' + i + '_' + excel_time + '.xls'
        mysql.wite_to_excel(record_path, file_name, sql)

        print('=======完成慢SQL数据表======[' + i + ']:' + time.strftime("%Y-%m-%d %H:%M:%S"))
        sendto = addr_list[i]
        sendto = ['123414g@email.cn']
        subject = '[PROD] <' + excel_time + '> slow sql summry for account ' + i
        sendEmail = SendEmail(sender, sendto, subject, record_path, file_name)
        sendEmail.send()
    # 关闭数据库连接
    mysql.close()
