# Logan Burkham ePortfolio
###### [Portfolio Home](./README.md) | [Code Review](./code_review.md) | [Narratives & Enhancements](./narratives_and_enhancements_lander.md) | [Contact](./contact_me.md)
#### [Portfolio Home](./README.md) > [Enhancement Three Narrative](./enhancement_narrative_three.md) > [Enhancement Three](./enhancement_three.md)

## Enhancement Three (Databases)

```python

#!/usr/app/Ebsco/bin/python3
import os
import cx_Oracle
import sqlalchemy
import pandas as pd
import datetime
import subprocess

from csv import DictReader
from loguru import logger as log
from dotenv import load_dotenv
from platform import system
from sqlalchemy.exc import SQLAlchemyError

#Written by lzb20a ACU - Enterprise Applications 2021

#Loads .env variables into OS PATH
load_dotenv()

PASSWORD = os.getenv('PASSWORD')
DB_URL = os.getenv('DB_URL')
DB_USER = os.getenv('DB_USER')
DB_PORT = os.getenv('DB_PORT')
DB_SERVICE_NAME = os.getenv('DB_SERVICE_NAME')
DIALECT = os.getenv('DIALECT')
SQL_DRIVER = os.getenv('SQL_DRIVER')

#Creating a connection URI for SQLAlchemy
ENGINE_PATH_WIN_AUTH = DIALECT + '+' + SQL_DRIVER + '://' + DB_USER + ':' + PASSWORD + '@' + DB_URL + ':' + DB_PORT + '/?service_name=' + DB_SERVICE_NAME

# Open Banner connection
def get_cnx():
    try:
        log.info("Establishing Banner Connection")
        engine = sqlalchemy.create_engine(ENGINE_PATH_WIN_AUTH, arraysize=1000)
        return engine
    except SQLAlchemyError as e:
        log.info(f"There is a problem with the Banner connection: {e}")

# Close Banner connection
def close_cnx(c):
    if c:
        try:
            log.info("Closing Banner connection")
            c.dispose()
            log.info("Connection to Banner closed")
        except SQLAlchemyError as e:
            log.info(f"There is a problem closing the Banner connection: {e}")
    else:
        log.info("No Open Connection to Banner---Exiting")

def instant_client_set():
    #Sets the Oracle instantclient to the SDK in .include directory if on Windows
    os_name = system()
    if os_name == 'Windows':
        cx_Oracle.init_oracle_client(lib_dir=r".\include\instantclient_19_12_Windows")

def get_logs():
    #run ./ebsco_access_log.sh to pull user log CSV from shared server
    subprocess.call("./ebsco_access_log.sh")

def make_temp_table():
#Create Temp table for user access data
    try:
        log.info("Creating Temp Banner Table ACU.ACU_EBSCOHOST_SSO_TEMP")
        try:
            sql_file = open('./create.txt', 'r')
            create = sql_file.read()
            sql_file.close()
            c = get_cnx()
            c.execute(create)
        except SQLAlchemyError as e:
            log.info(f"There was a problem creating ACU.ACU_EBSCOHOST_SSO_TEMP: {e}")
            close_cnx(c)
    except:
        log.info("Unable to attempt to Create Temp Table")

def make_log_csv():
    # converting Azure log to username CSV
    try:
        # Check if the CSV has content, if so, then run baby run
        log.info("Opening ./accessfile/Ebsco_Access_List.csv")
        if os.stat("./accessfile/Ebsco_Access_List.csv").st_size != 0:
            log.info("Preparing Ebsco user access log for import into Banner DB")

            # Open CSV file for copy to database
            col_names=['Date','Username']
            df = pd.read_csv("./accessfile/Ebsco_Access_List.csv", names=col_names, header=0)
            log.info("Ebsco_access_list.csv Loaded into memory")

            # Remove 'Z' and 'T' chars in datetime value in CSV
            df['Date'] = df['Date'].str.replace('Z', '', regex=False)
            df['Date'] = df['Date'].str.replace('T', ' ', regex=False)

            #split user emails from CSV into two parts at the @sign char
            df['Username'] = df['Username'].str.split('@')
            log.info("Split username from '@acu.edu'")
            
            #create date dataframe array for Pandas usage and insert dates in order from CSV
            date_df = []
            log.info("adding Activity_Date to date_df[]")
            for x in df['Date']:
                    date_df.append(x)
            
            #create user dataframe array for Pandas usage and insert first value from username arrays in order from CSV
            usr_df = []
            log.info("adding ACU_Usernames to usr_df[]")
            for x in df['Username']:
                    usr_df.append(x[0])
            
            #create a dictionary by merging date_df[] and usr_df[] arrays and write to a Pandas dataframe
            log.info("Writing Data Dictionary")
            data = {'ACTIVITY_DATE' : date_df, 'ACU_USERNAME' : usr_df}
            df = pd.DataFrame.from_dict(data)
            log.info('Extracted data to DataFrame')

            #write merged dataframe to new CSV
            df.to_csv("./accessfile/Ebsco_Access_List_Usernames.csv", index=False)
            log.info("Writing data to ./accessfile/Ebsco_Access_List_Usernames.csv")

        #executes if file is empty
        else:
            log.info("No Users: Empty File")

    #executes if failure in try call (line 80)
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
            #Iterate through rows making DB inserts
            with open('./insert.txt', 'w') as f:

                #create INSERT ALL statement for use with oracle db
                f.write('INSERT ALL\n')
                for row in csv_dict_reader:
                    f.write("   INTO ACU.ACU_EBSCOHOST_SSO_TEMP (ACU_USERNAME,ACTIVITY_DATE) VALUES('" + str(row['ACU_USERNAME']) + "',TO_DATE('" + str(row['ACTIVITY_DATE']) + "', 'yyyy-mm-dd hh24:mi:ss'))\n")
                f.write("SELECT * FROM DUAL")
                f.close()
                sql_file = open('./insert.txt', 'r')
                insert = sql_file.read()
                sql_file.close()
                log.info("Writing users to Banner DB")

                #writes SQL statement from insert.txt to db
                try:
                    count = c.execute(insert)
                    log.info("Inserting User insert.txt into Banner")
                
                #executes if failure in try call (line 153)
                except SQLAlchemyError as e:
                    log.info(f"Failed to INSERT insert.txt into Banner: {e}")
                
                #writes number of effected rows to CLI
                log.info(str(count.rowcount) + " Rows Inserted")
            
            #closes usr_file from with loop (line 135)
            usr_file.close()
            log.info("Banner Connection Closed")
    
    #executes if file is empty (line 133)
    else:
        log.info("Ebsco_Access_List_Usernames.csv is missing or empty")

def banner_merge():
    #Updating the remaining fields in Banner to merge in user data from other tables
    try:
        sql_file = open('./exec.txt', 'r')
        exec = sql_file.read()
        sql_file.close()
        c = get_cnx()
        log.info("merging information in Banner")
        c.execute(exec)
    
    #executes if failure in try call (line 174)
    except:
        log.info("Error Merging info from Banner Tables")

def finalize_report():
    #Getting table data for report and sending to csv
    try:
        #creates variables for logs housekeeping
        crnt_time = datetime.datetime.now()
        week_of = str(crnt_time.month) + '-' + str(crnt_time.day) + '-' + str(crnt_time.year)
        
        #getting connection to Banner DB and writing results of query tio df_ora[] array for later consumption
        c = get_cnx()
        log.info("Selecting data from Table")
        query = "SELECT * FROM ACU.ACU_EBSCOHOST_SSO_TEMP ORDER BY ACTIVITY_DATE"
        df_ora = []
        for row in c.execute(query):
            #appends information in query variable to end of df_ora[] array
            try:
                df_ora.append(row)
            
            #executes if failure in try call (line 196)
            except SQLAlchemyError as e:
                log.info(f"Error getting data from Banner: {e}")
                close_cnx(c)

        #creating a dataframe with the values of the CSV written to it 
        df = pd.DataFrame(df_ora, columns=['ACU_USERNAME','CAMPUS_CODE','MAJOR','ACTIVITY DATE','ACCOUNT TYPE','DEPARTMENT'])

        #creating CSVs with the final data to be written to the table
        df.to_csv("./accessfile/Ebsco_Access_List_Usernames.csv", index=False)
        df.to_csv("./accessfile/Ebsco_Access_List_"+str(week_of)+".tar.gz", compression='gzip')
    
    #executes if failure in try call (line 188)
    except SQLAlchemyError as e:
        log.info(f"Error updating ./accessfile/Ebsco_Access_List.csv: {e}")

def clean_table():
    #Truncate Temporary Table
    try:
        log.info("Truncating Temp Banner Table ACU.ACU_EBSCOHOST_SSO_TEMP")
        try:
            c = get_cnx()
            c.execute("TRUNCATE TABLE ACU.ACU_EBSCOHOST_SSO_TEMP")
        
        #executes if failure in try call (line 223)
        except SQLAlchemyError as e:
            log.info(f"There was a problem Truncating ACU.ACU_EBSCOHOST_SSO_TEMP: {e}")
            close_cnx(c)
    
    #executes if failure in try call (line 221)
    except:
        log.info("Unable to attempt to Truncate Temp Table")

    #Drop Temporary Table
    try:
        log.info("Dropping Temp Banner Table ACU.ACU_EBSCOHOST_SSO_TEMP")
        try:
            c = get_cnx()
            c.execute("DROP TABLE ACU.ACU_EBSCOHOST_SSO_TEMP")
        
        #executes if failure in try call (line 239)
        except SQLAlchemyError as e:
            log.info(f"There was a problem Dropping ACU.ACU_EBSCOHOST_SSO_TEMP: {e}")
            close_cnx(c)
    
    #executes if failure in try call (line 237)
    except:
        log.info("Unable to attempt to Drop Temp Table")

def send_and_rotate():
    #run ./ebsco_access_log.sh and rotate logs
    subprocess.call("./report.sh")
    log.info("Sending Ebsco_Access_List.csv to lzb20a@acu.edu")

#main method calling def objects in order needed to run the program appropriately
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
    close_cnx()

#start of program
if __name__ == "__main__":
    main()
    
```
