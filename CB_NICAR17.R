############################################
#### Cleaning and structuring data in R ####
############### Caelainn Barr ##############
############### The Guardian ###############
################ NICAR 2017 ################
############################################

#In this class we'll start by pulling data from the web
#In the second half of the class we'll call data using APIs and structure the output

#At the start of the script we install and load the packages needed for the project
#However the packages have been pre-installed on these machines
#For that reason I've commented the code below
#If you want to use this code at a later stage just remove the hash tag
install.packages("rvest", "stringr", "tidyr")

#Rvest is used for scraping data from the web and includes commands html and html_node
#Stringr is useful for working with strings, including matching, subsetting and extracting data
#Tidyr is a common package and is used for reshaping data

#Once the packages have been installed, let's load them using the library command
library(rvest, stringr, tidyr)

#First assign the web address to url
url <- 'http://espn.go.com/nfl/superbowl/history/winners'

#Pass it to the command 'read_html'
#read_html is part of the rvest package and pulls the underlying html from a webpage
superbowl <- read_html(url)
#OR
superbowl <- read_html('superbowl.htm')

#Next, we use the rvest functions html_nodes and html_table 
#We'll extract the HTML table and convert it to a data frame
superbowl_table <- html_nodes(superbowl, 'table')
sb <- html_table(superbowl_table)[[1]]
head(sb)

#What should we remove from the table?
sb <- sb[-(1:2), ]
head(sb)

#Now let's set new column names or variables
names(sb) <- c("number", "date", "site", "result")
head(sb)

#We can also clean up the data here
#We'll replace Roman numerals with numeric values
sb$number <- 1:51

#We will also convert the date to a standard format
sb$date <- as.Date(sb$date, "%B. %d, %Y")
head(sb)

#The result column should be split so we can more easily work with the data
#We'll divide it into 4 new columns
#Let's start splitting by the comma delimiter
sb <- separate(sb, result, c('winner', 'loser'), sep=', ', remove=TRUE)
head(sb)

#Now we'll split out the scores from the winner and loser columns 
#We'll do this by substring pattern matches, which is based on regex
#Let's look at the table and figure what we want...

scorepattern <- " \\d+$"
sb$winnerScore <- as.numeric(str_extract(sb$winner, scorepattern))
sb$loserScore <- as.numeric(str_extract(sb$loser, scorepattern))
sb$winner <- gsub(scorepattern, "", sb$winner)
sb$loser <- gsub(scorepattern, "", sb$loser)
head(sb)

#Let's write the result out to a csv
write.csv(sb, 'superbowl.csv', row.names=F)

##################
### Zillow API ###
##################

#For the second part of this class we're going to pull data from APIs
#An API, aka application programming interface, is basically a way of extracting data from a database
#But rather than using a search interface its driven by a direct command which we write
#Each API has its own search parameters and can vary when it comes to useability
#For this class we're going to use property website Zillow's API as it's reasonably straightforward to use

#In order to use an API you need a key, or an ID to call data with
#To follow the next steps you'll need to register with Zillow for an API key 
#You can register here: https://www.zillow.com/howto/api/APIOverview.htm
#Once you have the key in your email we'll use the 23 character code later in this class
#If you haven't registered or there are wifi problems there is data below that can be used for the lesson

#Register for xml key with Zillow and assign it to a 'key'
#The API will not let you call the key but it helps to have it noted in the project
key <- 'X1-ZWz1fojwj0cs23_3l8b3'

#Just as before we would usually install the packages needed for this project at the start of the script
install.packages("RCurl", "XML")
#RCurl is used to interact with the API, this contains the command getForm
#The results of the API call will be in XML and the package allows us to parse the data

#Let's ensure the packages are loaded from the library
library(RCurl, XML)

#Let's look at the documentation for the Zillow API key 
#https://www.zillow.com/howto/api/GetSearchResults.htm
#We're going to use the GetSearchResults call first

wbreply = getForm("http://www.zillow.com/webservice/GetSearchResults.htm",
                'zws-id' = "X1-ZWz1fojwj0cs23_3l8b3",
                address = "2030 Webster Street",
                citystatezip = "Philadelphia, PA 19146")


#From the getForm call we have created something called 'wbreply'
#Let's parse it into a document
#As we're working with an API the response is in XML
#XML, much like html, has it's own structure called XPath
#The XPath has what's known as nodes and trees - ways of structuring the information
#We'll put the XML into an object, using the internal XPath stucture- we won't define the unique XML

wbdoc = xmlTreeParse(wbreply, asText = TRUE, useInternal = TRUE)

#We now have the data parsed into doc, based on the structure of the XML tree supplied 
#To navigate through the document we need to know a little about XPath
#Let's look at the data
wbdoc

#Where is the value of the property stored in the XML?

xmlValue(wbdoc[["//amount"]]) #two brackets are the nodes

#Let's carry out a larger API call and structure the output into a dataframe
#This time we're going to look at the GetRegionChildren
#The documentation can be found here: https://www.zillow.com/howto/api/GetRegionChildren.htm
#We're required to specify the state, city and childtype, i.e. what data we'd like to be returned
#Let's structure the call using getForm again 

phlreply = getForm("http://www.zillow.com/webservice/GetRegionChildren.htm",
                   'zws-id' = "X1-ZWz1fojwj0cs23_3l8b3",
                   state = "pa",
                   city = "Philadelphia",
                   childtype = "neighborhood")

#Let's parse the content to an object based on it's internal xmlTree structure 
phldoc = xmlTreeParse(phlreply, asText = TRUE, useInternal = TRUE)

#Write result to XML file
saveXML(phldoc, file="phldoc.xml")

#What does the output look like?
phldoc

#Use XMLtoList to transform your XML output to a list
phllist <-xmlToList(phldoc)

#Convert the list into a dataframe
phltable <- ldply(phllist, data.frame)

#We now want to restructure the dataframe
#By parsing we'll disgard the useless data and keep the elements we need

#Let's export the data into a csv 
write.csv(phltable, "phltable.csv")