import re
from os import listdir
import os.path
import random
import string
import json

my_dir = 'C:\\Users\\rakesh.pattanaik\\Desktop\\JSON\\'
# print(listdir(my_dir))
my_files = [my_dir + "\\" + f for f in listdir(my_dir) if os.path.isfile(os.path.join(my_dir, f))]


def get_col_tab(js_data):
    vnew = ''
    cols = []
    all_cols = []
    tab = []
    for key, value in js_data.items():
        for i in value:
            for k, v in i.items():
                if k == 'COLUMN_NAME':
                    cols.append(v)
                    all_cols.append(v)
                elif k == 'TABLE_NAME':
                    tab.append(str(v))
                elif k == 'DATA_TYPE':
                    if v == 'VARCHAR2':
                        cols.append(":StringType,")
                    elif v.lower() == "number":
                        cols.append(":DecimalType,")
                    elif v.lower() == "char":
                        cols.append(":StringType,")
                    elif v.lower() == "long":
                        cols.append(":StringType,")
                    elif v.lower() == "date":
                        cols.append(":DateType,")
                    else:
                        cols.append(v)
                # elif k == 'DATA_LENGTH':
                #     vnew = '(' + str(v) + ')'
                #     cols.append(vnew)
    table_name = (list(set(tab)))[0]
    return table_name, cols, all_cols


def query_create(table_name, db_query):
    # silentremove(filename)
    qry_file = "C:\\Users\\rakesh.pattanaik\\Desktop\\JSON\\out\\case_class" + "_" + table_name +".scala"
    # print(qry_file)
    f = open(qry_file, "w")
    f.write(db_query + "\n")
    f.close()
    rep_str(qry_file)
    # logger(True, "Query File Created")


def rep_str(qry_file):
    regex = r",  \n  \)"
    subst = ")  \n "
    with open(qry_file, 'r') as file:
        filedata = file.read()
        content_new = re.sub(regex, subst, filedata, 2)
        #print("str_rep called")
        #print(content_new)
        with open(qry_file, 'w') as file:
            file.write(content_new)
            file.close()


def randomStringDigits(stringLength=6):
    """Generate a random string of letters and digits """
    lettersAndDigits = string.ascii_letters + string.digits
    return ''.join(random.choice(lettersAndDigits) for i in range(stringLength))


def col_format():
    table_name,cols,all_cols = get_col_tab(js_data)
    col_list = [cols[x:x+2] for x in range(0, len(cols), 2)]
    fnl_col = []
    fnl_col_list = [cols for x in range(0, len(all_cols), 3)]
    for i in col_list:
        if 'NVarChar' in i:
            fnl_col.append((" ".join(i)+ ' COLLATE Latin1_General_100_BIN2_UTF8, '))
        else:
            fnl_col.append((" ".join(i) + ' '))
    return fnl_col, all_cols


def read(table, **kwargs):
    """ Generates case class statement matching the kwargs passed. """
    fnl_col_list, all_cols = col_format()
    a = ("".join([i for i in fnl_col_list if i]))
    c = (",  ".join([i for i in all_cols if i]))
    sql = list()
    sql.append("case class")
    sql.append(" %s (" % table)
    sql.append(a)
    sql.append(" ) ")
    if kwargs:
        sql.append("WHERE " + " AND ".join("%s = '%s'" % (k, v) for k, v in kwargs.iteritems()))
    sql.append("")
    return " \n ".join(sql)


if __name__ == '__main__':
    for file_var in my_files:
        with open(file_var, encoding='utf-8') as data_file:
            js_data = json.loads(data_file.read())
        table_name, cols, all_cols = get_col_tab(js_data)
        db_query = read(table_name)
        query_create(table_name, db_query)
    print(" \n Case Class Files Created Successfully")
