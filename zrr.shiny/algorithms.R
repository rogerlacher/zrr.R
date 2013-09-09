# MDM and other ZRR algorithms in R
#
# Created:  30.10.2012      Roger Lacher
# Revision:  22.07.2013      Roger Lacher
#            optimize performance of algos in regards to display
#            as a Google Motion chart via shiny/rgoogleVis
# =======================================
#
# rMDM Calculations:
# 
# Let:
#     r(k,i)
#         be a Matrix of Risk Values for a set of Entities
#         where k=1..m is the number of risks
#               i=1..n is the number of entities (countries)
#               r(k,i) ??? [0..1] for all k,i
#   
#     R(i) a shorthand notation for (r(1,i),r(2,i),....r(m,i))
#
#
#     p   be a vector of indices with dim(p) < m
#                 e.g. p = c(2,5,6,7,8)
#     q   be a vector of indices with dim(q) <= (m-p)
#                 e.g. q = c()
#         and p ^ q = 0 (no overlapping elements)
#     1??  a 1-vector of dimension m
#     0??  a 0-vector of dimension m
#
#   [Remark: Directly implement p,q as vectors of strings, i.e. risk names?]
#    
#     
# Then:
#     E(x)=1??[p]      a 1-vector for the MDM x-projection
#                             of r(k,i) with dimension p < m
#     E(y)=1??[q]      a 1-vector for the MDM y-projection
#                             of r(k,i) with dimension q <= (m-p)
#     E(A)=1??[c(p,q)] a 1-vector for the MDM projection of the
#                             Armaggeddon point with dimension p+q
#     E(N)=0??[c(p,q)] a 0-vector for the MDM projection of the
#                             Nirvana point with dimension p+q
#
#
#     Ln(i)= ||R(i)||       = sum(R(i)^2)
#     La(i)= ||R(i)-E(A)||  = sum((R(i)-E(A))^2)
#     Lx(i)= ||R(i)-E(x)||  = sum((R(i)-E(x))^2)
#     Ly(i)= ||R(i)-E(y)||  = sum((R(i)-E(y))^2)
#
#     h(i) = 0.5*(Ln(i)-Ly(i)+||E(y)||^2)/||E(y)||
#     g(i) = 0.5*(Ly(i)-La(i)+||E(x)||^2)/||E(x)||
#
#     u(i) = 0.5 * (-sqrt(Lx(i)-h(i)^2)+sqrt(Ln(i)-h(i)^2) + ||E(x)||^2)/||E(x)||
#     v(i) = 0.5 * (-sqrt(Ly(i)-g(i)^2)+sqrt(Ln(i)-g(i)^2) + ||E(y)||^2)/||E(y)||
#
# ================================================================================

# returns the mdm that can be displayed in a 
# Google Visualization MotionChart with r-GoogleVis
# Structure:
#   Name    Year  Region  qx    qy    overlayData   Date
#   Sambia  2008  Africa  0.4   0.65  2.3 M (USD)   2008-11-01

rMDM_Motion <- function(r,p,q,sF=0.1) {
  # TODO: implement this properly
  # for now:
  mdm <- rMDM(r,p,q,sF=0.1)
  return(cbind(Country.Name=mdm[,"Country.Name"],Date=as.Date(mdm[,"Date"]),Continent=mdm[,"Continent"],mdm[,c("qx","qy")]))
}

rMDMm_Motion <- function(rm,t,p,q,c,sF=0.1) {
  # TODO: implement this properly
  # for now:
  mdm <- rMDMm(rm,t,p,q,c,sF=0.1)
  
  # TODO: This is very inefficient, as the same subsetting has already been done
  #       in the rMDMm calculation itself. So better change the return value of 
  #       rMDMm to be include all these columns than to subset again & cbind....
  rms <- subset(rm,Date == datelevels[t] & risk %in% risklevels[c(p,q)])
  return(cbind(rms[c,c("Country.Name","Date","Continent")],mdm))  
}

# calculcate the rMDM of a matrix of country coordinates
#   params:   r = matrix of countries (rows) and risk values (cols)
#             p = index-vector (numeric) for MDM x-projection
#             q = index-vector (numeric) for MDM y-projection
#             sF = scaling factor (defaults to 0.1)
#   returns:  c(qx,qy) = rMDM projection coordinates
# ==================================================================
rMDM <- function(r,p,q,sF=0.1) {
  ret <- vector();  
  if (is.vector(r)) {
    ret <- rbind(ret,rMDMOneEntity(r,p,q));
  } else {
    for (i in 1:nrow(r)) {
      ret <- rbind(ret,rMDMOneEntity(r[i,],p,q));
    }        
  }
  # rescale  for [0.1 ... 0.9]
  ret[,1] = sF + (1-2*sF) * (ret[,1] - min(ret[,1])) / (max(ret[,1]) - min(ret[,1]))
  ret[,2] = sF + (1-2*sF) * (ret[,2] - min(ret[,2])) / (max(ret[,2]) - min(ret[,2]))  
  colnames(ret) <- c("qx","qy");
  # TODO: THIS IS SEVERELY HARD CODED AND WILL FAIL AT NEXT OCCASION !!!!!!
  index <- match(c("Rising.food.price"),colnames(r)) - 1;
  ret <- cbind(r[,1:index],ret);
}


# calculcate the rMDM position of 1 entity (one row of the matrix)
#   params:   r = point coordinates in m-dim space (a matrix or vector)
#             p = index-vector (numeric) for MDM x-projection
#             q = index-vector (numeric) for MDM y-projection
#   returns:  c(u,v) = rMDM projection coordinates
# ==================================================================
rMDMOneEntity <- function(r,p,q) {
  
  T <- 10^-8;
  
  r_ <- r[c(p,q)];
  sx = sqrt(length(p));
  sy = sqrt(length(q));
  
  ln <- l2(r_);
  la <- l2(r_ - 1);
  lx <- l2(r[p] - 1) + l2(r[q]);
  ly <- l2(r[q] - 1) + l2(r[p]);  
  
  h <- 0.5*(ln-ly+sy*sy)/sy;
  g <- 0.5*(ly-la+sx*sx)/sx;
  
  u <- 0.5*(-sqrt(T+lx-h*h) + sqrt(T+ln-h*h) + sx)/sx;
  v <- 0.5*(-sqrt(T+ly-g*g) + sqrt(T+ln-g*g) + sy)/sy;
  
  ret <- c(u,v);
  #ret
  ln
}

# calculcate the countries rMDM positions from the molten dataset rm (-> global.R)
#   params:   rm = a molten dataset containing columns "Date", "Code", "risk" and "value"
#             t = factor level (numeric) "Date"
#             p = factor levels (numeric) for "risk" (MDM x-projection)
#             q = factor levels (numeric) for "risk" (MDM y-projection)
#             c = factor levels (numeric) for "Code" (MDM focus countries)
#             sF = scaling factor (defaults to 0.1)
#   returns:  c(u,v) = rMDM projection coordinates
# ==================================================================
rMDMm <- function(rm,t,p,q,c,sF=1) {
  # restrict molten dataset to selected timestamp, risks and countries
  
  #TODO: check correctness of calculations!!
  
  rmx <- subset(rm,Date == datelevels[t] & risk %in% risklevels[p])
  rmy <- subset(rm,Date == datelevels[t] & risk %in% risklevels[q])
  rma <- rbind(rmx, rmy)  
  
  epsilon <- 10^-8;
  
  sx = sqrt(length(p));
  sy = sqrt(length(q));
  
  ln <- aggregate(x=rma[,"value"],by=list(rma[,"Code"]),FUN=l2)[,2]
  la <- aggregate(x=rma[,"value"]-1,by=list(rma[,"Code"]),FUN=l2)[,2]
  lx <- aggregate(x=rmx[,"value"]-1,by=list(rmx[,"Code"]),FUN=l2)[,2] + aggregate(x=rmy[,"value"],by=list(rmy[,"Code"]),FUN=l2)[,2] 
  ly <- aggregate(x=rmy[,"value"]-1,by=list(rmy[,"Code"]),FUN=l2)[,2] + aggregate(x=rmx[,"value"],by=list(rmx[,"Code"]),FUN=l2)[,2]
  
  h <- 0.5*(ln-ly+sy*sy)/sy;
  g <- 0.5*(ly-la+sx*sx)/sx;
  
  u <- 0.5*(-sqrt(epsilon+lx-h*h) + sqrt(epsilon+ln-h*h) + sx)/sx;
  v <- 0.5*(-sqrt(epsilon+ly-g*g) + sqrt(epsilon+ln-g*g) + sy)/sy;
  
  ret <- cbind(u,v);
  
  # rescale
  ret[,1] = sF + (1-2*sF) * (ret[,1] - min(ret[,1])) / (max(ret[,1]) - min(ret[,1]))
  ret[,2] = sF + (1-2*sF) * (ret[,2] - min(ret[,2])) / (max(ret[,2]) - min(ret[,2]))  
  # restrict to the selected countries 
  ret <-ret[c,]
  
  ret
}

# a "shiny-optimized" version of the rMDMm function using directly the input that's available
# from the ui.R input fields (input$xRisks, input$yRisks, input$countries...)
#   params:   rm = a molten dataset containing columns "Date", "Country.Names", "Code", "risk" and "value"
#             t = factor level (numeric) "Date"
#             xRisks -> risks for MDM x-projection
#             yRisks -> risks for MDM y-projection
#             countries -> countries to select
#             sF = scaling factor (defaults to 0.1)
#   returns:  c("Date","Country.Names","risk",u,v) -> rMDM projection coordinates
# ==================================================================
rMDMmS <- function(rm,t,xRisks,yRisks,countries,sF=1) {
  # restrict molten dataset to selected timestamp, risks and countries
  
  #TODO: check correctness of calculations!!
  
  rmx <- subset(rm,Date == datelevels[t] & risk %in% xRisks)
  rmy <- subset(rm,Date == datelevels[t] & risk %in% yRisks)
  rma <- rbind(rmx, rmy)  
  
  epsilon <- 10^-8;
  
  sx = sqrt(length(xRisks));
  sy = sqrt(length(yRisks));
  
  ln <- aggregate(x=rma[,"value"],by=list(rma[,"Country.Name"]),FUN=l2)[,2]
  la <- aggregate(x=rma[,"value"]-1,by=list(rma[,"Country.Name"]),FUN=l2)[,2]
  lx <- aggregate(x=rmx[,"value"]-1,by=list(rmx[,"Country.Name"]),FUN=l2)[,2] + aggregate(x=rmy[,"value"],by=list(rmy[,"Country.Name"]),FUN=l2)[,2] 
  ly <- aggregate(x=rmy[,"value"]-1,by=list(rmy[,"Country.Name"]),FUN=l2)[,2] + aggregate(x=rmx[,"value"],by=list(rmx[,"Country.Name"]),FUN=l2)[,2]
  
  h <- 0.5*(ln-ly+sy*sy)/sy;
  g <- 0.5*(ly-la+sx*sx)/sx;
  
  qx <- 0.5*(-sqrt(epsilon+lx-h*h) + sqrt(epsilon+ln-h*h) + sx)/sx;
  qy <- 0.5*(-sqrt(epsilon+ly-g*g) + sqrt(epsilon+ln-g*g) + sy)/sy;
  ret <- cbind(unique(rma[,c("Country.Name","Date","Continent")]),qx,qy)
  
  # rescale
  ret[,"qx"] = sF + (1-2*sF) * (ret[,"qx"] - min(ret[,"qx"])) / (max(ret[,"qx"]) - min(ret[,"qx"]))
  ret[,"qy"] = sF + (1-2*sF) * (ret[,"qy"] - min(ret[,"qy"])) / (max(ret[,"qy"]) - min(ret[,"qy"]))  
  
  ret <- subset(ret,Country.Name %in% countries)
  ret
}


# calculates the squared euclidian norm of a vector v
# ===================================================
l2 <- function(v) {
  ret <- sum(v^2)
  ret
}



# ==================================================================

# creates a labelled scatter plot of the MDM values
#   params:   mdm = a calculated mdm (return value from rMDM() function)
#             xLabel, yLabel = alternate labels for x/y axes
# ==================================================================
plotMDM <- function(mdm, xLabel="qx", yLabel="qy") {
  x <- mdm[,"qx"];
  y <- mdm[,"qy"];       
  plot(x,y, main="ZRR rMDM Plot",asp=1, xlim=c(0,1), ylim=c(0,1), 
       xlab=xLabel, ylab=yLabel);
  textxy(x,y,rownames(mdm));
}


# Creates boxplots for the wall risks
#   params:   r = a matrix of risks to boxplot
#             label = label for the plot
# ==================================================================
plotWall <- function(r,label="Wall Risks") {
  par(mai=par("mai")+c(1,0,0,0));    # increase the bottom margin
  # to make room for the labels
  boxplot(r,las=3,main=label);
  
  # with risk values for a given country (4) overlayed:
  # plot(p,r[4,p],xlab="",xaxt='n',ylim=c(0,1))
  # boxplot(r[,p],las=3,main="Economic Risks", add=TRUE)
  
  # or, with good results for length(p) > ~12:
  # boxplot(r[,p],las=3,main="Economic Risks",at=seq(0.5,length(p)+0.5,by=(length(p)+1)/length(p)))
  # par(new=TRUE)
  # plot(p,r[4,p],xlab="",xaxt='n',ylim=c(0,1))
  
}

draw <- function(panel,mdm, xLabel="qx", yLabel="qy") {
  x <- mdm[,1];
  y <- mdm[,2];       
  plot(x,y, main="ZRR rMDM Plot",asp=1, xlim=c(0,1), ylim=c(0,1), 
       xlab=xLabel, ylab=yLabel);
  textxy(x,y,rownames(mdm));
  panel;
}


# ==================================================================
# 
# test function
test_MDM <- function() {  
  
  NCOL <- 8
  
  r <- read.csv("data/countryrisks.csv");  
  
    
  # randomly subset for some 10 countries only
  r <- r[sample(1:nrow(r),10,replace=FALSE),]
    
  # get rid of columns only containing NAs (i.e. risk categories)
  r <- r[,colSums(is.na(r))<nrow(r)];
  
  # some random risk frame
  # filter out the categories & first NCOL columns
  #c_ex <- c(1:NCOL,match(names(r[colSums(is.na(r)) > 10]),colnames(r)))
  x <- 1:ncol(r)
  #x <- x[-c_ex]
  x <- x[-c(1:NCOL)]
  p <- sample(x, 15, replace = F);    # x-projection indices, 15 dimensions
  q <- sample(x[-p], 10, replace = F);    # y-projection indices, 10 dimensions
  
  mdm <- rMDM_Motion(r,p,q);
  Motion=gvisMotionChart(mdm, idvar="Country.Name", timevar="Date", options=list(height=600, width=800)) # Display chart plot(Motion)  
  plot(Motion)
  #plotMDM(mdm, xLabel="My x Risks", yLabel="My y Risks");
  mdm;
}
# 
# 
# # library "googleVis" is required for the textxy labeling in the test function
library("googleVis");
library("calibrate");
