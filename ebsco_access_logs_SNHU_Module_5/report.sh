#!/bin/bash

echo "Sending report..."
echo "EBSCOHOST - Single Sign-On Report" | mailx -a ./accessfile/Ebsco_Access_List_Usernames.csv -s "Ebsco Access Logs" lzb20a@acu.edu

echo "Rotating logs..."
find ./logs -type f -mtime +365 -delete 

echo "Adding to logs..."
mv ./accessfile/*.tar.gz ./logs
