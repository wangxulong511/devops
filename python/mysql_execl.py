# -*- coding: UTF-8 -*-
import pymysql
import uuid
import datetime
import xlrd


class SysPartnerODS:
    def __init__(self):
        self.HEADERS = {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 ''(KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.36'}
        self.CONNECTION = pymysql.connect(host='10.10.100.7', user='test', password='test',
                                          db='partner',
                                          charset='utf8',
                                          cursorclass=pymysql.cursors.DictCursor)

    def read_excel(self):
        # 打开文件
        workbook = xlrd.open_workbook(
            r'新版通讯录88888.xlsx')
        sheet2 = workbook.sheet_by_index(0)  # sheet索引从0开始
        list = []
        for i in range(1, sheet2.nrows):
            # 将excel里面的值放入list
            dict = {}
            dict['serverName'] = sheet2.cell(i, 2).value.strip()
            dict['sapId'] = str(sheet2.cell(i, 3).value).split('.')[0]
            list.append(dict)
        return list

    def handle_data(self, list):
        listNotHandle = []
        for dict in list:
            serverName = dict['serverName']
            sapId = dict['sapId']
            # 根据服务商名称查询服务商信息
            sql = "SELECT a.target_agency,a.dealer_id,b.id as pid,b.city,b.county,c.id,c.tel,c.company_name \
                    FROM  t_partner_service_provider a inner JOIN t_partner_area_fare b ON a.id = b.service_id inner JOIN t_partner_info c ON c.area_id = b.id \
                    where a.open_name='%s'" % (serverName)
            try:
                with self.CONNECTION.cursor() as cursor:
                    cursor.execute(sql)
                    self.CONNECTION.commit()
                    result = cursor.fetchall()
            except Exception as e:
                print(repr(e))
            if cursor.rowcount == 0:
                print('result is None')
                listNotHandle.append(serverName)
                continue
            # 处理
            for item in result:
                print(item)
                if item['pid'] is None:
                    partner_ods1 = {}
                    partner_ods1['dealer_name'] = item['target_agency']
                    partner_ods1['dealer_no'] = sapId
                    update_sql = "update t_jst_partner_service_provider set dealer_id ='%s'  where target_agency='%s'" % (
                        partner_ods1['dealer_no'], partner_ods1['dealer_name'])
                    try:
                        with self.CONNECTION.cursor() as cursor:
                            cursor.execute(update_sql)
                            self.CONNECTION.commit()
                    except Exception as e:
                        print(item['target_agency'])
                        print(repr(e))
                        # 发生错误时回滚
                        self.CONNECTION.rollback()
                    continue
                partner_ods = {}
                partner_ods['id'] = str(uuid.uuid1())[0:32]
                partner_ods['partner_id'] = item['pid']
                partner_ods['customer_name'] = item['company_name']
                partner_ods['phone'] = item['tel']
                partner_ods['city'] = item['city'] + item['county']
                partner_ods['dealer_no'] = sapId
                partner_ods['dealer_name'] = item['target_agency']
                partner_ods['state'] = 0
                partner_ods['create_time'] = datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')
                print('partner_ods:' + str(partner_ods))
                insert_sql = "INSERT INTO t_partner_ods(id, partner_id, customer_name, phone, city, dealer_no,dealer_name,state, create_time) \
                               VALUES ('%s', '%s', '%s', '%s','%s','%s','%s','%d','%s')" % \
                             (partner_ods['id'], partner_ods['partner_id'], partner_ods['customer_name'],
                              partner_ods['phone'], partner_ods['city'],
                              partner_ods['dealer_no'], partner_ods['dealer_name'], partner_ods['state'],
                              partner_ods['create_time'])
                try:
                    with self.CONNECTION.cursor() as cursor:
                        cursor.execute(insert_sql)
                        self.CONNECTION.commit()
                except Exception as e:
                    print(item['target_agency'])
                    print(repr(e))
                    # 发生错误时回滚
                    self.CONNECTION.rollback()
        print(listNotHandle)


if __name__ == '__main__':
    sysPartnerODS = SysPartnerODS()
    list = sysPartnerODS.read_excel()
    # list = [{'sapId':'123123123','serverName':'小番茄2312222'},{'sapId':'1231231443','serverName':'维生素AB'}]
    print(list)
    sysPartnerODS.handle_data(list)
