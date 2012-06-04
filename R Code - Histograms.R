#NEW STUFF

setwd("~/James Docs")
wd <- getwd()
list.files(wd)
cabi <- read.csv(file="bikeBatchOut-test.csv", header=TRUE)

#Return the whole row of the highest TransitTime
cabi[cabi$TransitTime == max(cabi$TransitTime, na.rm=TRUE),]

#View a subset of columns of data
#How do I select columns 3, 6-8 and 11, for example?
View(subset(cabi,select=WalkTime:PlannedBikeDist))

#Avoids retyping data table
with(cabi,plot(CaBiTripTime,TransitTime))

#Add Columns calculated from previous columns


cabi = transform(cabi, TotalTransitTime = WalkTime+TransitTime+WaitingTime)
cabi = transform(cabi, TotalTransitTime_mins = TotalTransitTime/60)
cabi = transform(cabi, CaBiTime_mins=CaBiTripTime/60)
cabi = transform(cabi, 
                 WalkTime_mins=WalkTime/60, 
                 TransitTime_mins=TransitTime/60,
                 WaitingTime_mins=WaitingTime/60,
                 PlannedBikeTime_mins=PlannedBikeTime/60, 
                 TotalTransitTripDist=TotalTransitTripDist/1609.344,
                 PlannedBikeDist=PlannedBikeDist/1609.344)
                 
cabi = transform(cabi,              
                 CaBi_mph=PlannedBikeDist/(CaBiTime_mins/60),
                 PlannedBike_mph=PlannedBikeDist/(PlannedBikeTime_mins/60))
                 
cabi = transform(cabi, 
                 BikeTimeDiff_percent = (PlannedBikeTime_mins-CaBiTime_mins)/PlannedBikeTime_mins,
                 BikeTimeDiff_abs = (PlannedBikeTime_mins-CaBiTime_mins))

#View a subset of columns to store
#is there a faster way to create a view/subset of specific columns?
keep <- c("CaBiTripTime","TotalTransitTripDist","PlannedBikeTime","PlannedBikeDist","CaBiTime_mins","TotalTransitTime_mins","WalkTime_mins","TransitTime_mins","WaitingTime_mins","PlannedBikeTime_mins","BikeTimeDiff_percent")
View(subset(cabi,select=keep))

#Plot a Histogram about comparing planned and actual bike travel times (percentages)
bins=c(-5000, -2.5, -2.4, -2.3, -2.2, -2.1, -2, -1.9, -1.8, -1.7, -1.6, -1.5, -1.4, -1.3, -1.2, -1.1, -1, -0.9, -0.8, -0.7, -0.6, -0.5, -0.4, -0.3, -0.2, -0.1, 0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1, 1.1, 1.2, 1.3, 1.4, 1.5, 1.6, 1.7, 1.8, 1.9, 2, 2.1, 2.2, 2.3, 2.4, 2.5, 5000)
hist(cabi$BikeTimeDiff_percent,
     breaks=bins, 
     freq=TRUE,
     xlim=c(-2.2,2.2),
     xlab="Percent Travel Time Difference between Planned and CaBi Trips",
     main="Comparison of planned and actual bike travel times between CaBi stations",
     col=rgb(100,100,100,75,maxColorValue=255))

#A beautiful histogram
hist(cabi$PlannedBike_mph,
     breaks=500, 
     freq=TRUE,
     xlim=c(0,60),
     xlab="Length of CaBi Trips (min)",
     main="Distributon of CaBi Trip Times",
     col=rgb(152,30,50,200,maxColorValue=255),
     border=FALSE,
     lab=c(5,10),
     xaxt="n",
     yaxt="n")
axis(2,at=100*(0:20),las=2)
axis(2,at=100*(0:20),tck=1,col="white",lwd=2,labels=FALSE)
axis(1,at=10*(0:6), tck=1,col="white",lwd=5,labels=FALSE)
axis(1,at=10*(0:6))

#Another one
hist(cabi$CaBi_mph,
     breaks=25, 
     freq=TRUE,
     xlim=c(0,30),
     xlab="Average CaBi Trip Speed (mph) \n Based on OTP planned distance",
     main="Distributon of CaBi Speeds",
     col=rgb(152,30,50,200,maxColorValue=255),
     border=FALSE,
     lab=c(5,10),
     xaxt="n",
     yaxt="n")
axis(2,at=100*(0:20),las=2)
axis(2,at=100*(0:20),tck=1,col="white",lwd=1,labels=FALSE)
axis(1,at=5*(0:20), tck=1,col="white",lwd=1,labels=FALSE)
axis(1,at=5*(0:20))

#Practice scatterplot

with(cabi,
     plot(
       TotalTransitTime_mins,
       PlannedBikeTime_mins,
       xlim=c(0,45),
       ylim=c(0,45),
       xlab="OTP Transit Time (min)",
       ylab="OTP Bike Time (min)",
       main="Comparison of Expected Travel Time \n by Transit and Bicycle Modes",
       col=rgb(100,100,100,25,maxColorValue=255),
       pch=16,
       asp=1,
       xaxt="n",
       yaxt="n",
       bty="n")
)
axis(2,at=10*(0:6),tck=1,col="white",lwd=1,labels=FALSE)
axis(2,at=10*(0:6),las=2)
axis(1,at=10*(0:6), tck=1,col="white",lwd=1,labels=FALSE)
axis(1,at=10*(0:6))
abline(a=0,b=1,col="red",lwd=2)

with(cabi,
     plot(
       TotalTransitTime_mins,
       CaBiTime_mins,
       xlim=c(0,45),
       ylim=c(0,45),
       ylab="CaBi Trip Time (min)",
       xlab="OTP Transit Time (min)",
       main="CaBi Trip Time as a function of Predicted Bike Travel Time",
       col=rgb(100,100,100,45,maxColorValue=255),
       pch=16,
       asp=1,
       abline(a=0,b=1)
     )
)
