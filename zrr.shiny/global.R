library(shiny)
library(googleVis)
library(calibrate)
library(ggplot2)
library(reshape2)
library(gridExtra)

# global risk dataset - only read and process once
r<-read.csv("../data/countryrisks.csv")

# melt dataset & get rid of NA columns (i.e. Risk Categories)
rm <- melt(r,variable.name="risk")
rm <- rm[colSums(is.na(rm)) != nrow(rm)]

# extract country codes, names, risk hierarchies, risks
# ... some levels of the molten dataset
datelevels    <- levels(factor(rm[,"Date"]))
risklevels    <- levels(factor(rm[,"risk"]))
countrylevels <- levels(factor(rm[,"Country.Name"]))

# ... country codes and names
r1 <- subset(r,Date == r[1,"Date"])
countries <- r1[,c("Country.Name","Code")]

# ... risk categories
rcats <- names(r[colSums(is.na(r)) == nrow(r)])

# ... hierarchy of risks within risk categories
rh <- list(rcats)
rc1 <- rcats[1]
for (rc2 in rcats[-1]) {
  pos1 <- match(rc1,colnames(r)) + 1
  pos2 <- match(rc2,colnames(r)) - 1
  rh[[rc1]] <- list(colnames(r[,pos1:pos2]))
  rc1 <- rc2
}
pos1 <- match(rc1,colnames(r)) + 1
pos2 <- length(colnames(r))
rh[[rc1]] <- list(colnames(r[,pos1:pos2]))

# identify the risk names 
rnames <- unlist(rh,use.names=FALSE)
rnames <- rnames[(length(rcats)+1):length(rnames)]


# include the calculation algorithms
source(file = "algorithms.R")
# using the compiled algorithms version will speed up things
#library(compiler)
#loadcmp(file="algorithms.Rc")

# turn on profiling
#Rprof(filename="Rprof.out",append=FALSE,interval=0.02,memory.profiling=FALSE)


# Recent earthquakes data and S&P rating data
# World Bank Indicator library
if(FALSE) {
  
  library(WDI)
  library(XML)
  # S&P Ratings 
  url <- "http://en.wikipedia.org/wiki/List_of_countries_by_credit_rating"
  x <- readHTMLTable(readLines(url), which=2)
  levels(x$Rating) <- substring(levels(x$Rating), 4, 
                                nchar(levels(x$Rating)))
  x$Ranking <- x$Rating
  levels(x$Ranking) <- nlevels(x$Rating):1
  x$Ranking <- as.character(x$Ranking)
  x$Rating <- paste(x$Country, x$Rating, sep=": ")
  
  # recent earthquakes
  eq <- read.csv("http://earthquake.usgs.gov/earthquakes/feed/v0.1/summary/2.5_week.csv")
  eq$loc=paste(eq$Latitude, eq$Longitude, sep=":")
}