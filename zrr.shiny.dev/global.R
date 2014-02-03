library(RODBC)
library(reshape2)


# Source the DB configuration
source("dbconf.R")

# Current environment
env    <- "dev"
envId  <- envs[[env]]
#con    <- odbcConnect(dsn[envId],uid=user[envId],pwd=pass[envId])
con    <- odbcConnect(dsn[envId],uid=user[envId],pwd=pass[envId],
                      rows_at_time=rows_at_time[envId],
                      believeNRows=believeNRows[envId])

# Does the same thing as sqlFetch, however, sqlFetch does not work with
# the ODBC text driver on text (.csv) files
#
mSqlFetch <- function(con,tblname,ext="") {  
  return(sqlQuery(con,paste("SELECT * FROM ",tblname, ext,sep="")));
}

# Select data for filters 
countries <-  mSqlFetch(con,"RR_GEO_UNIT")
risknames <-  mSqlFetch(con,"RR_INDICATOR")
riskcats  <-  levels(factor(risknames[,"INDICATOR_CATEGORY"]))
periods   <-  mSqlFetch(con,"RR_TIME_PERIOD")


# for the CRIM cords
data <- read.csv("www/CRIM.csv", sep=";");
risks <- colnames(data);