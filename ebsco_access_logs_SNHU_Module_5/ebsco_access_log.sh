#!/bin/bash
cd /usr/app/Ebsco/accessfile
rm *

webdav_pass=`cat .webdavpass`
directory="https://{SERVER_URL_REDACTED}/incoming/nightly/Ebsco/Ebsco_Access_List.csv"

wget --no-check-certificate --http-user=cteac --http-password=$webdav_pass -O "./accessfile/Ebsco_Access_List.csv" "$directory"
echo "Retrieved Ebsco_Access_List.csv from Webdavhub"
echo "done"