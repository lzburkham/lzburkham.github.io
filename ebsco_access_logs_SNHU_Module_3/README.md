# Ebsco Access Log Application #

This application is a python application that is hosted on <<SERVER NAME REDACTED>> at /usr/app/Ebsco that runs via crontab every Tuesday at 8:15am.

The application grabs a file from webdavhub utilizing a password file that is found within the directory on the host server at /usr/app/Ebsco/.webdavpass and places it within the directory. The python application, main.py, then parses that information and calls report.sh to email the access log to lzb20a@acu.edu.

There is a file /usr/app/Ebsco/.env that houses the database credentials used for this application.

This application also has a virtual environment set up on <<SERVER NAME REDACTED>>. To start this applicaiton manually, simply navigate to the directory, switch to the ebscologs user. and run "./main.py"

### What is this repository? ###

* This is an access log for the Ebsco Cloud hosted application for the ACU Library

### Primary Contact ###

* Written by lzb20a (2021)