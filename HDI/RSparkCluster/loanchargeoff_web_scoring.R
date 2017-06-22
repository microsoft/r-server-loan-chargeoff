##########################################################################################################################################
##  IMPORTANT: Make sure you've run loanchargeoff_deployment.R to create the web service before using this script.  You'll also
##  need to have an ssh session open to the server, as described in the steps in https://aka.ms/campaigntypical?path=hdi#step3 
##  Finally, scroll to last section to read further instructions for testing the api_frame call
##
##########################################################################################################################################
## This R script should be executed in your local machine to test the web service
## Before remote login from local, please open a ssh session with localhost port 12800 (ssh user login, not admin)
##
## This R script will do the followings:
## 1. Remote connect to the port 12800 of the edge node which hosts the web service
## 2. Call the web service from your local machine

## Input : 1. Full path of the four input tables on HDFS or four tables in data frame
##         2. Working directories on local edge node and HDFS
##         3. Stage: "Dev" for development; "Prod" for batch scoring; "Web" for scoring remotely with web service
## Output: The directory on HDFS which contains the result of recommendations

##########################################################################################################################################

##############################################################################################################################
#
#                                                  Remote Login for Authentication                                           #
#
##############################################################################################################################

# Load mrsdeploy package
library(mrsdeploy)

# Remote login (admin login)
remoteLogin(
  "http://localhost:12800",
  username = "admin",
  password = "<Enter Cluster Login Password Here>",
  session = FALSE
)

##############################################################################################################################
#
#                                                Get and Call the Web Service for String Input                               #
#
##############################################################################################################################

# Specify the name and version of the web service
name_string <- "loan_chargeoff_string_input"
version <- "v0.0.1" 

# Get the API for string input
api_string <- getService(name_string, version)

# Specify working directories on edge node and HDFS
LocalWorkDir <- paste("/var/RevoShare/", Sys.info()[["user"]], "/LoanChargeOff/prod", sep="") 
HDFSDataDir <- "/LoanChargeOff/Data"
HDFSWorkDir <- "/LoanChargeOff/web"

# Specify the full path of .csv files on HDFS
Loan_Data <- "Loan_Data1000.csv"

# Call the web service

result_string <- api_string$loan_web_scoring(
  Loan_Data = Loan_Data,
  LocalWorkDir = LocalWorkDir,
  HDFSWorkDir = HDFSWorkDir,
  HDFSDataDir = HDFSDataDir,
  userName = Sys.info()[["user"]],
  Stage = "Web")

##############################################################################################################################
#
#                                            Get and Call the Web Service for data frame Input  
#                                         Run this section after putting data into a local folder
#                                                      Change local_data_dir accordingly
#
##############################################################################################################################

# Specify the name and version of the web service
name_frame <- "loan_chargeoff_frame_input"
version <- "v0.0.1" 

# Get the API for data frame input
api_frame <- getService(name_frame, version)

# Specify working directories on edge node and HDFS
LocalWorkDir <- paste("/var/RevoShare/", Sys.info()[["user"]], "/LoanChargeOff/prod", sep="") 
HDFSDataDir <- "/LoanChargeOff/Data"
HDFSWorkDir <- "/LoanChargeOff/web"

# input data 
download.file("https://raw.githubusercontent.com/Microsoft/r-server-loan-chargeoff/master/HDI/Data/Loan_Data1000.csv", destfile = Loan_Data)
Loan_Data_df <- read.csv(Loan_Data)

# Call the web service
result_string <- api_frame$loan_web_scoring(
  Loan_Data = Loan_Data_df,
  LocalWorkDir = LocalWorkDir,
  HDFSWorkDir = HDFSWorkDir,
  HDFSDataDir = HDFSDataDir,
  userName = Sys.info()[["user"]],
  Stage = "Web")
