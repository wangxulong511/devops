#coding:utf-8   #强制使用utf-8编码格式
import cx_Oracle
from Channel import *
from email.header import Header
from email.mime.text import MIMEText
from email.utils import parseaddr, formataddr
import smtplib

def _format_addr(str):
    name, addr = parseaddr(str)
    return formataddr((Header(name, 'utf-8').encode(), addr))

'''加密发送文本邮件'''
def sendEmail(from_addr,password,to_addr,centext,smtp_server):
    ret = True
    try:
        msg = MIMEText(centext, 'html', 'utf-8') # 文本邮件
        msg['From'] = _format_addr('捷顺金科运维 <%s>' % from_addr)
        msg['To'] = _format_addr('收件人: <%s>' % to_addr)
        msg['Subject'] = Header('预付卡数据库用户密码过期警告', 'utf-8').encode()
        #server = smtplib.SMTP(smtp_server, 25)
        server = smtplib.SMTP_SSL(smtp_server, 465)
        #server.starttls() # 调用starttls()方法，就创建了安全连接
        # server.set_debuglevel(1) # 记录详细信息
        server.login(from_addr, password) # 登录邮箱服务器
        server.sendmail(from_addr, to_addr, msg.as_string()) # 发送信息
        server.quit()
        #print("加密后邮件发送成功！")
    except Exception as e:
        print("发送失败：" + e)
        ret = False
    return ret


def get_html_msg(centexts):
    head = """<head>
<META http-equiv="Content-Type" content="text/html; charset=UTF-8">
<title>Load Test Results</title>
<style type="text/css">
                body {
                    font:normal 68% verdana,arial,helvetica;
                    color:#000000;
                }                
                p {
                   font-weight: bold;
                   font-size: 160%;
                }
                table tr td, table tr th {
                    font-size: 68%;
                }
                table.details tr th{
                    color: #ffffff;
                    font-weight: bold;
                    text-align:center;
                    background:#2674a6;
                    white-space: nowrap;
                }
                table.details tr td{
                    background:#eeeee0;
                    white-space: nowrap;
                }
                h1 {
                    margin: 0px 0px 5px; font: 165% verdana,arial,helvetica
                }
                h2 {
                    margin-top: 1em; margin-bottom: 0.5em; font: bold 125% verdana,arial,helvetica
                }
                h3 {
                    margin-bottom: 0.5em; font: bold 115% verdana,arial,helvetica
                }
                .Failure {
                    font-weight:bold; color:red;
                }
                img
                {
                  border-width: 0px;
                }                         

            </style>

</head>"""
    p = """<h1>数据库账号过期监控</h1>
    <hr>
    """
    body = """<body>""" + p + """
<p> 请数据库管理员检查数据库用户密码状态以及在密码失效7天之前重置用户密码，避免应用系统无法连接到数据库，造成系统服务故障！！！</p>
<h2>#账号过期详情：</h2>
<table width="95%" cellspacing="2" cellpadding="5" border="0" class="details" align="center">
<tr valign="top">
    <th># 账号</th><th>账号状态</th><th>账号过期天数</th><th>账号失效日期</th>
</tr>
""" + centexts + """
</table>
</body>"""
    html = """<html>""" + head + body + """</html>"""
    return html

def isDatabaseUserExpiry ():
    connect = cx_Oracle.connect('acc/acc@10.10.151.39:1521/testdb ')
    cursor = connect.cursor()
    sqlSelect = "select t.username, t.ACCOUNT_STATUS, TRUNC(t.expiry_date - sysdate) expiry_day,t.expiry_date from dba_users t where TRUNC(t.expiry_date-sysdate) between 1 and 15"
    cursor.execute(sqlSelect)
    results = cursor.fetchall()
    list = []
    if results != [] :
        for row in results:
            databaseUser = DatabaseUser(row[0], row[1], row[2], row[3])
            list.append(databaseUser)
        cursor.close()
        connect.close()
        return list
    else:
        cursor.close()
        connect.close()
        return

if __name__ == '__main__':
    list = isDatabaseUserExpiry()
    from_addr = '123434@email.cn'   # 邮箱登录用户名
    password = '123456'              # 登录密码
    to_addr = ['123434@email.cn', '123423134@email.cn']

    contexts = ''
      # 发送对象地址，可以多个邮箱
    smtp_server = "smtp.exmail.qq.com"          # 服务器地址，默认端口号25
    if list != [] and list != None:
        for dsUser in list:
            context = "<tr> <th> %s </th><th> %s </th> <th>%d </th><th>%s</th></tr></tr>" %(dsUser.username, dsUser.account_status, dsUser.expiry_day, dsUser.expiry_date )
            contexts = contexts + context
        msg = get_html_msg(contexts)
        res = sendEmail(from_addr, password, to_addr, msg, smtp_server)
        if res:
            print '发送邮件成功！'
        else:
            print '发送邮件失败！'
    else:
        print "账号没有过期"
