# global risk dataset - only read and process once

r<-read.csv("../data/countryrisks.csv")
# restrict to 1 timestamp
r1 <- subset(r,Date == r[1,"Date"])
countries <- r1[,c("Country.Name","Code")]

# identify the risk categories
# constructs a hierarchical list of risk categories and associated risks
# TODO: need to define a sensible limits for the number of NA's
rcats <- names(r[colSums(is.na(r)) == nrow(r)])
rh <- list(rcats)
# some change here
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