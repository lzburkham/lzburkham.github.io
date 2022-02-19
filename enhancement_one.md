# Logan Burkham ePortfolio 
###### [Portfolio Home](./README.md) | [Code Review](./code_review.md) | [Narratives & Enhancements](./narratives_and_enhancements_lander.md) | [Contact](./contact_me.md)
#### [Portfolio Home](./README.md) > [Enhancement One Narrative](./enhancement_narrative_one.md) > [Enhancement One](./Enhancement_one.md)

## Enhancement One (Software Design and Engineering)

```python

#!/usr/app/Ebsco/bin/python3
import os
import cx_Oracle
import pandas as pd
import datetime
import subprocess
from csv import DictReader
from loguru import logger as log
from dotenv import load_dotenv
from platform import system

#Written by lzb20a ACU - Enterprise Applications 2021

#Loads .env into OS
load_dotenv()

PASSWORD = os.getenv('PASSWORD')
DB_URL = os.getenv('DB_URL')
DB_USER = os.getenv('DB_USER')
DB_PORT = os.getenv('DB_PORT')
DB_SERVICE_NAME = os.getenv('DB_SERVICE_NAME')

# Open Banner connection
def get_cnx():
    try:
        log.info("Establishing Banner Connection")
        dsn = cx_Oracle.makedsn(DB_URL, DB_PORT, sid=DB_SERVICE_NAME)
        cnx = cx_Oracle.connect(
            user=DB_USER,
            password=PASSWORD,
            dsn=dsn)
        log.info("Connected to Banner DB -" + str(DB_SERVICE_NAME))
        return cnx
    except cx_Oracle.DatabaseError as e:
        log.info("There is a problem with the Banner connection:", e)

# Close Banner connection
def close_cnx(c):
    if c:
        try:
            log.info("Closing Banner connection")
            c.close()
            log.info("Connection to Banner closed")
        except cx_Oracle.DatabaseError as e:
            log.info("There is a problem closing the Banner connection:", e)
    else:
        log.info("Connection to Banner closed")

def instant_client_set():
    #Sets the Oracle instantclient to .include directory if on Windows
    os_name = system()
    if os_name == 'Windows':
        cx_Oracle.init_oracle_client(lib_dir=r".\include\instantclient_19_12_Windows")

def get_logs():
    #run ./ebsco_access_log.sh
    subprocess.call("./ebsco_access_log.sh")

def make_temp_table():
#Create Temp table for access data
    try:
        log.info("Creating Temp Banner Table ACU.ACU_EBSCOHOST_SSO_TEMP")
        try:
            sql_file = open('./create.txt', 'r')
            create = sql_file.read()
            sql_file.close()
            c = get_cnx()
            crsr = c.cursor()
            crsr.execute(create)
            c.commit()
            crsr.close()
        except cx_Oracle.DatabaseError as e:
            log.info("There was a problem creating ACU.ACU_EBSCOHOST_SSO_TEMP: ", e)
            close_cnx(c)
    except:
        log.info("Unable to attempt to Create Temp Table")

def make_log_csv():
    # converting Azure log to username csv
    try:
        # Check if the CSV has content
        log.info("Opening ./accessfile/Ebsco_Access_List.csv")
        if os.stat("./accessfile/Ebsco_Access_List.csv").st_size != 0:
            log.info("Preparing Ebsco user access log for import into Banner DB")
            # Open CSV file for copy to database
            col_names=['Date','Username']
            df = pd.read_csv("./accessfile/Ebsco_Access_List.csv", names=col_names, header=0)
            log.info("Ebsco_access_list.csv Loaded into memory")
            df['Date'] = df['Date'].str.replace('Z', '', regex=False)
            df['Date'] = df['Date'].str.replace('T', ' ', regex=False)
            df['Username'] = df['Username'].str.split('@')
            log.info("Split username from '@acu.edu'")
            date_df = []
            log.info("adding Activity_Date to date_df[]")
            for x in df['Date']:
                    date_df.append(x)
            usr_df = []
            log.info("adding ACU_Usernames to usr_df[]")
            for x in df['Username']:
                    usr_df.append(x[0])
            log.info("Writing Data Dictionary")
            data = {'ACTIVITY_DATE' : date_df, 'ACU_USERNAME' : usr_df}
            df = pd.DataFrame.from_dict(data)
            log.info('Extracted data to DataFrame')
            df.to_csv("./accessfile/Ebsco_Access_List_Usernames.csv", index=False)
            log.info("Writing data to ./accessfile/Ebsco_Access_List_Usernames.csv")
        else:
            log.info("No Users: Empty File")
    except:
        log.info("Unable to access ./accessfile/Ebsco_Access_List.csv because it is either missing or empty")

def csv_to_banner():
    #Upload users to Banner Table
    #Check if the CSV has content
    log.info("Preparing to import usernames into Banner")
    if os.stat("./accessfile/Ebsco_Access_List_Usernames.csv").st_size != 0:
        # Open CSV file for copy to database
        with open("./accessfile/Ebsco_Access_List_Usernames.csv") as usr_file:
            csv_dict_reader = DictReader(usr_file)
            c = get_cnx()
            crsr = c.cursor()
            #Iterate through rows making DB inserts
            with open('./insert.txt', 'w') as f:
                f.write('INSERT ALL\n')
                for row in csv_dict_reader:
                    f.write("   INTO ACU.ACU_EBSCOHOST_SSO_TEMP (ACU_USERNAME,ACTIVITY_DATE) VALUES('" + str(row['ACU_USERNAME']) + "',TO_DATE('" + str(row['ACTIVITY_DATE']) + "', 'yyyy-mm-dd hh24:mi:ss'))\n")
                f.write("SELECT * FROM DUAL")
                f.close()
                sql_file = open('./insert.txt', 'r')
                insert = sql_file.read()
                sql_file.close()
                log.info("Writing users to Banner DB")
                try:
                    crsr.execute(insert)
                    c.commit()
                    log.info("Inserting User insert.txt into Banner")
                except cx_Oracle.DatabaseError as e:
                    log.info("Failed to INSERT insert.txt into Banner:", e)
                    close_cnx(c)
                log.info(str(crsr.rowcount) + " Rows Inserted")
            usr_file.close()
            crsr.close()
            log.info("Banner Cursor Closed")
    else:
        log.info("Ebsco_Access_List_Usernames.csv is missing or empty")

def banner_merge():
    #Updating the remaining fields in Banner to pull in user data from other tables
    try:
        sql_file = open('./exec.txt', 'r')
        exec = sql_file.read()
        sql_file.close()
        c = get_cnx()
        crsr = c.cursor()
        log.info("merging information in Banner")
        crsr.execute(exec)
        c.commit()
        crsr.close()
    except:
        log.info("Error Merging info from Banner Tables")

def finalize_report():
    #Getting table data for report and sending to csv
    try:
        crnt_time = datetime.datetime.now()
        week_of = str(crnt_time.month) + '-' + str(crnt_time.day) + '-' + str(crnt_time.year)
        c = get_cnx()
        crsr = c.cursor()
        log.info("Selecting data from Table")
        query = "SELECT * FROM ACU.ACU_EBSCOHOST_SSO_TEMP ORDER BY ACTIVITY_DATE"
        df_ora = []
        for row in crsr.execute(query):
            try:
                df_ora.append(row)
            except cx_Oracle.DatabaseError as e:
                log.info("Error getting data from Banner: ", e)
                close_cnx(c)
        crsr.close()
        df = pd.DataFrame(df_ora, columns=['ACU_USERNAME','CAMPUS_CODE','MAJOR','ACTIVITY DATE','ACCOUNT TYPE','DEPARTMENT'])
        df.to_csv("./accessfile/Ebsco_Access_List_Usernames.csv", index=False)
        df.to_csv("./accessfile/Ebsco_Access_List_"+str(week_of)+".tar.gz", compression='gzip')
    except cx_Oracle.DatabaseError as e:
        log.info("Error updating ./accessfile/Ebsco_Access_List.csv", e)

def clean_table():
    #Truncate Temporary Table
    try:
        log.info("Truncating Temp Banner Table ACU.ACU_EBSCOHOST_SSO_TEMP")
        try:
            c = get_cnx()
            crsr = c.cursor()
            crsr.execute("TRUNCATE TABLE ACU.ACU_EBSCOHOST_SSO_TEMP")
            c.commit()
            crsr.close()
        except cx_Oracle.DatabaseError as e:
            log.info("There was a problem Truncating ACU.ACU_EBSCOHOST_SSO_TEMP: ", e)
            close_cnx(c)
    except:
        log.info("Unable to attempt to Truncate Temp Table")

    #Drop Temporary Table
    try:
        log.info("Dropping Temp Banner Table ACU.ACU_EBSCOHOST_SSO_TEMP")
        try:
            c = get_cnx()
            crsr = c.cursor()
            crsr.execute("DROP TABLE ACU.ACU_EBSCOHOST_SSO_TEMP")
            c.commit()
            crsr.close()
        except cx_Oracle.DatabaseError as e:
            log.info("There was a problem Dropping ACU.ACU_EBSCOHOST_SSO_TEMP: ", e)
            close_cnx(c)
    except:
        log.info("Unable to attempt to Drop Temp Table")

def send_and_rotate():
    #run ./ebsco_access_log.sh and rotate logs
    subprocess.call("./report.sh")
    log.info("Sending Ebsco_Access_List.csv to lzb20a@acu.edu")

def main():
    instant_client_set()
    get_logs()
    make_temp_table()
    make_log_csv()
    csv_to_banner()
    banner_merge()
    finalize_report()
    clean_table()
    send_and_rotate()

if __name__ == "__main__":
    main()
```
