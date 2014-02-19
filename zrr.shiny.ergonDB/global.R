library(RODBC)
library(reshape2)


# Source the DB configuration
source("dbconf.R")

# Current environment
env    <- "uat"
envId  <- envs[[env]]
schema <- schema[envId]
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

# as every other input element, dataset selection is the only non-dynamic selection
# i.e. all other queries to be found in server.R
#
 
dataSets  <-  sqlQuery(con,paste("SELECT ID, NAME FROM ", schema, ".TBL_DATASET ", 
                                 "ORDER BY NAME ASC", sep=""))
vals        <- as.vector(dataSets[,"ID"])
names(vals) <- as.vector(dataSets[,"NAME"])
dataSets    <- vals