#!/usr/bin/python

import pymysql
import json
import sys
from csv import reader
from datetime import date

RDS = pymysql.connect(host='dbcluster-1.cluster-c6xoyndmnisp.us-east-1.rds.amazonaws.com', user='admin', password='
yourpasswordhere', database='YOURDB', cursorclass=pymysql.cursors.DictCursor)
cursor= RDS.cursor()
IMPORTFILE='transcription-mock.csv'

cursor.execute("select TID from transcripts")
AllLines = cursor.fetchall()

fp = open('transcription-mock.csv', 'r')

for line in AllLines:

	# print ("LINE from AllLines is:", line)
	tid = line['TID']

	fline = fp.readline()
	eid, fdate = fline.split(",")

	eid = eid.rstrip()
	fdate = fdate.rstrip()

	# print("FILINE IS :" + fline)
	# print("EID is: " + eid )
	# print("DATE is: " + fdate )
	print("DATE is: " + fdate )

	updatest = "update transcripts set transdate  = '" + fdate + "' , eeid = '" + eid + "' where tid = '" + str
(tid) + "'"

	print("Statement:  " + updatest)

	cursor.execute(updatest)

RDS.commit()
fp.close()
