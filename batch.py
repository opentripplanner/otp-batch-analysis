#!/usr/bin/python

# -------------------------------------------------------
#	Batch O-D Processing Script for OpenTripPlanner
#	Written by:	Andrew Byrd (abyrd@openplans.org) and
#               James Wong (jcwong86@gmail.com)
#	Last Updated: 	May 2012
#
#	Useful links: 	www.opentripplanner.org/api-doc
#					www.openplans.org
#
#--------------------------------------------------------

import urllib, urllib2, json, csv					#import libraries
from datetime import date, datetime, timedelta
from time import sleep, strftime

INPUT = "cabi.csv"									#Designate Input filename and path
OUTPUT = "bikeBatchOut-test.csv"					#Designate Output filename and path
DECIMATE = 100										#Script samples every Nth record
URL = 'http://analyst.opentripplanner.org/opentripplanner-api-webapp/ws/plan?'
													#URL and PLAN api from OTP deployment
SLEEP = 1 											#Seconds between api calls
LIMIT = 3600 										#Number of total executed requests
	
weekday = date.today().weekday() 					#Current day of the week
monday = date.today() - timedelta(days=weekday) 	#Num of days away from nearest Monday

# Universal linefeed reader for mac/win text files
outputFile = open(OUTPUT, 'w') 						#Overwrite a file
writer = csv.writer(outputFile, dialect='excel')
	#Format for .csv
writer.writerow(['rowNum','CaBiTripTime','StartDate','StartTime','StartLat','StartLon','EndLat','EndLon','WalkTime', 'TransitTime','WaitingTime','NumTransfers','TotalTransitTripDist','PlannedBikeTime','PlannedBikeDist'])
													#Write header row in .csv file

# Takes CSV input, creates URLs, stores data locally in row array
with open(INPUT, 'rU') as inputFile : 				#Continue using file
    reader = csv.reader(inputFile, dialect='excel')	#Read the input .csv file
    rowNum = 1
    for row in reader :								#Samples file based on DECIMATE
        rowNum += 1

        if rowNum >LIMIT*DECIMATE :
            break
        if rowNum % DECIMATE != 0 :
            continue
        print "Row ", rowNum
        try :
            										#assign input values directly into row
            duration, date, time, o_lat, o_lon, d_lat, d_lon = row 
            										# [t(f) for t, f in zip(types2, row)]
            #Sets date to current equivalent weekday for use with up-to-date GTFS
            date_new = datetime.strptime(date, "%m/%d/%Y")
            date_new = monday + timedelta(days=date_new.weekday())
            date_new = date_new.strftime("%m/%d/%Y")
            row[1] = date_new            
            time_new = datetime.strptime(time, "%I:%M:%S %p").strftime("%T")
													#creates time object
        except Exception as e :
            print e
            print 'cannot parse input record, skipping'
            continue
        arriveBy = False							#Using departure times for all calls
        params =  {'time' : '%s' % time_new,		#Sets up the URL parameters
                   'fromPlace' : '%s,%s' % (o_lat, o_lon),
                   'toPlace' :   '%s,%s' % (d_lat, d_lon),
                   'maxWalkDistance' : 2000,		#Arbitrary
                   'mode' : 'WALK,TRANSIT', 		#See OTP API Documentation
                   'date' : date_new,
                   'numItineraries' : 1, 			#For simplicity, keep set at 1. Max=3
                   'bannedRoutes' : 'Test_Purple',
                   'arriveBy' : 'true' if arriveBy else 'false' }
        # Tomcat server + spaces in URLs -> HTTP 505 confusion. urlencode percent-encodes parameters.
        url = URL + urllib.urlencode(params)		#Create a POST link using params
        req = urllib2.Request(url)
        req.add_header('Accept', 'application/json')
        print url
        try :
            response = urllib2.urlopen(req) 
        except urllib2.HTTPError as e :
            print e
            continue
        try :
            content = response.read()				#Store response from OTP
            objs = json.loads(content)
            itineraries = objs['plan']['itineraries']
            										#Access itinerary objects from content
        except :
            print 'no itineraries'
            continue
        for i in itineraries :						#Calc total dist from a multi-leg trip
        	dist = 0
        	if i['transitTime'] != 0 :
        		for leg in i['legs'] :
        			dist += leg['distance']
        			
		#Within each itinerary, get specific metrics and store them in the output row
        for i in itineraries :						
            outrow = [ rowNum ] + row + [ i['walkTime'], i['transitTime'], i['waitingTime'], i['transfers'], dist]


		#Repeat API call to get a BIKE itinerary and store results
        params =  {'time' : '%s' % time_new,
                   'fromPlace' : '%s,%s' % (o_lat, o_lon),
                   'toPlace' :   '%s,%s' % (d_lat, d_lon),
                   'maxWalkDistance' : 2000,
                   'mode' : 'BICYCLE', 				#Only diff is in mode
                   'date' : date_new,
                   'numItineraries' : 1, 
                   'bannedRoutes' : 'Test_Purple',
                   'arriveBy' : 'true' if arriveBy else 'false' }
        url = URL + urllib.urlencode(params)
        req = urllib2.Request(url)
        req.add_header('Accept', 'application/json')
        print url
        try :
            response = urllib2.urlopen(req) 
        except urllib2.HTTPError as e :
            print e
            continue
        try :
            content = response.read()
            objs = json.loads(content)
            itineraries = objs['plan']['itineraries']
        except :
            print 'no itineraries'
            continue
            print outrow
        for i in itineraries :						#Walktime=Biketime when mode=BICYCLE
            outrow = outrow + [i['walkTime'],i['walkDistance']]
        writer.writerow(outrow)						#Write full row to output file
        sleep(SLEEP)								#Delay to maintain OTP performance

            
