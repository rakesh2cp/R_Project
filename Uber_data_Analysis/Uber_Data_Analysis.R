############################################################################################
# Uber Data Analysis and   R Code for visualise the demand and supply gap for the cab      #
# demand in Airport and City during different duration during the day especially during    #
# peak hours when either cab demand is huge or trips are getting cancelled by drivers      #
# due to various reasons.                                                                  #
#                                                                                          #
# Author:      Rakesh Pattanaik.                                                           #
#                                                                                          #
############################################################################################

#import the required Library
library(dplyr)
library(lubridate)

#Set The working Directory
setwd("/Users/hduser/Desktop/Upgrad/Uber_Case/")

#Load the data in to R Data Frame uber_data
uber_data <- read.csv("Uber_Request_Data.csv", header = TRUE, strip.white = TRUE, stringsAsFactors = FALSE)

# Cleaning the data for the timestamp Column 
# Replacing"/" wtih "-" in timestamps columns (Request.timestamp,Drop.timestamp)
# e.g. in 11/7/2016 11:51, replace / with - , so that it will become 11-7-2016 11:51
# All the timestamp values converted to a standard timestamp format DD-MM-YYYY HH:MM
uber_clean_data <- uber_data[,c(1:4)]
uber_clean_data[,c(5:6)] <- lapply(uber_data[,c(5:6)], function(x) gsub("/", "-", as.character(x)))

#Function to add dummy seconds to each time stamp value
# e.g. for some values in the timestamp colum it's present as 11-7-2016 11:51 where we dont have 
# second, where as some of the values are 14-07-2016 12:01:02 where second is present
# in order to bring the time stamp column standardisised form following function is used.
add_seconds <- function(date){
  tempDate <- ifelse((lengths(strsplit(date,":"))!=3 & !is.na(date)), paste( date, ":00", sep="") , date)
  date_time<- strptime(tempDate, format = "%d-%m-%Y %H:%M:%S")
  return(date_time)
}

#adding missing second field to "Request.timestamp" and "Drop.timestamp" where field doesn't contain 'NA' value.
#and converting them to date object.

uber_clean_data[,c(5:6)] <- lapply(uber_clean_data[,c(5:6)], function(x) add_seconds(x))

#Extracting hour from request time. Request.time is added to the uber_clean_data
#which holds the Hour on which request is made
uber_clean_data$Request.time  <- ymd_hms(uber_clean_data$Request.timestamp,tz = "")
uber_clean_data$Request.time  <- hour(uber_clean_data$Request.time)

#Bar chart depicting the hour-wise trip request made at city and airport
ggplot(uber_clean_data, aes(factor(Request.time), fill = factor(Pickup.point))) + geom_bar(position = "dodge")

#Request-time is divided into 5 time-slots as per the following convention
#Pre_Morning    : 00:00:00 to 04:00:00
#Morning_Rush   : 04:00:01 to 08:00:00 
#Day_Time       : 08:00:01 to 16:00:00
#Evening_Rush   : 16:00:01 to 22:00:00
#Late_Night     : 20:00:01 to 23:59:59
#uber_clean_data data frame is assigned with a new column Time_Slot with their respective values
#Pre_Morning, Morning_Rush, Day_Time, Evening_Rush and Late_Night as per their time slots.

uber_clean_data$Time_Slot <-
  ifelse(
    as.numeric(uber_clean_data$Request.time) >= 0 &
      as.numeric(uber_clean_data$Request.time) <= 4,
    'Pre_Morning',
    ifelse(
      as.numeric(uber_clean_data$Request.time) > 4 &
        as.numeric(uber_clean_data$Request.time) <= 8,
      'Morning_Rush',
      ifelse(
        as.numeric(uber_clean_data$Request.time) > 8 &
          as.numeric(uber_clean_data$Request.time) <= 16,
        'Day_Time',
        ifelse(
          as.numeric(uber_clean_data$Request.time) > 16 &
            as.numeric(uber_clean_data$Request.time) <= 22,
          'Evening_Rush',
          'Late_Night'
        )
      )
    )
  )

# Below Chart is best viewed when opened in Zoom mode in a new window.
# Bar chart for number of trips made during different time-slots at Airport and City 
# The Problem is clearly visible here. Evening_Rush at Airport and Morning_Rush at the City are the 
# more pain points for Uber in this case study. Hence we will be looking in to those areas carefully 
# in the case study.

ggplot(uber_clean_data, aes(Time_Slot, fill = factor(Pickup.point))) + geom_bar(position = "dodge") + geom_text(stat = "count", position = 'stack', aes(label=..count..),vjust=0.5, size=3) + facet_wrap(~Pickup.point)

# Below Chart is best viewed when opened in Zoom mode in a new window.
# Stacked bar chart where each bar represents a time slot and y axis shows the frequency of requests
# Out of total number of requests No Cars Available and Cancelled are contrubuting to the problem.
# Hence those areas need to be looked carefully.

ggplot(uber_clean_data, aes(Time_Slot, fill = factor(Status))) + geom_bar() + geom_text(stat = "count", position = 'stack', aes(label=..count..),vjust=0.5, size=3) + facet_wrap(~Pickup.point) + theme(axis.text.x = element_text(angle = 90)) + theme_bw()

# Since Evening_Rush at Airport was one of the pain points hence we are 
# Subsetting Evening Rush trips to evening_rush DF in order to depict the 
# Status of requests, e.g. Cancelled vs No Cars vs Trip Completed during Evening_Rush hours

evening_rush <- subset(uber_clean_data, Time_Slot == "Evening_Rush")

# Below Chart is best viewed when opened in Zoom mode in a new window.
# Bar chart shows Status of requests, e.g. Cancelled vs No Cars vs Trip Completed
# Graph clearly shows Cars are not available during evening rush hours, which needs to be looked 
# carefully.

ggplot(evening_rush, aes(Request.time, fill = factor(Status))) + geom_bar(position = "stack") + geom_text(stat = "count", position = 'stack', aes(label=..count..),vjust=0.5, size=3) + facet_wrap(~Pickup.point) + theme(axis.text.x = element_text(angle = 90)) + theme_bw()

# Below Chart is best viewed when opened in Zoom mode in a new window.
# Bar chart to differentiate the requests made at Airport vs City
# stacked bar chart which shows problem is more severe for pick-up requests made at airport
# No Cars available supercedes all other requests made at Airport.

ggplot(evening_rush, aes(Request.time, fill = factor(Status))) + geom_bar() + facet_wrap(~Pickup.point)

#Deriving gap between supply and demand in the city which is 2180 
demand_supply_diff_city <- nrow(uber_clean_data[uber_clean_data$Pickup.point == "City",]) - nrow(uber_clean_data[uber_clean_data$Pickup.point=="Airport" & uber_clean_data$Status=="Trip Completed",])

# Subsetting Morning trips to morning_cancellations DF in order to depict the 
# Count of requests in each category, e.g. Cancelled vs No Cars vs Trip Completed
morning_cancellations <- subset(uber_clean_data, Time_Slot == "Morning_Rush")

# Bar chart showing Count of requests in each category, e.g. Cancelled vs No Cars vs Trip Completed
ggplot(morning_cancellations, aes(Request.time, fill = factor(Status))) + geom_bar() + geom_text(stat = "count", position = 'stack', aes(label=..count..),vjust=0.5, size=3) + facet_wrap(~Pickup.point)

# Stacked bar chart  which shows problem is more severe for pick-up requests made at city in the morning
# which needs to be looked upon
ggplot(morning_cancellations, aes(Request.time, fill = factor(Status))) + geom_bar() + facet_wrap(~Pickup.point)


#gap between supply and demand At Airport is 1734
demand_supply_diff_airport <- nrow(uber_clean_data[uber_clean_data$Pickup.point == "Airport",]) - nrow(uber_clean_data[uber_clean_data$Pickup.point=="City" & uber_clean_data$Status=="Trip Completed",])

