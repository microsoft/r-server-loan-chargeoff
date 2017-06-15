##########################################################################################################################################
##  IMPORTANT: Before you run this for the first time, make sure you've executed Copy_Dev2Prod.R to copy your
##   development model into the production directory!  Rerun that script whenever you have an updated model.
##
##########################################################################################################################################
## This R script will do the following:
## 1. Specify parameters for scoring function: 
##    1) Working directories on edge node and HDFS
##    2) Full path of the four input tables on HDFS
## 2. Define the scoring function for batch scoring 
## 3. Invoke the scoring function for batch scoring

## Input : 1. Working directories of HDFS
##         2. Full path of the input data on HDFS
##         3. Stage: "Dev" for development; "Prod" for batch scoring; "Web" for scoring remotely with web service
## Output: The directory on HDFS which contains the result of recommendations

##########################################################################################################################################

##############################################################################################################################
#
#                                                    Specify Parameters                                                      #
#
##############################################################################################################################

# Specify working directories on edge node and HDFS
LocalWorkDir <- paste("/var/RevoShare/", Sys.info()[["user"]], "/LoanChargeOff/prod", sep="" ) 
HDFSWorkDir <- "/LoanChargeOff/prod"
if (system(paste("hadoop fs -test -e ", HDFSWorkDir, sep="")) == 0)
{
  system(paste("hadoop dfs -rm -r ", HDFSWorkDir, sep=""))
}
system(paste("hadoop fs -mkdir ", HDFSWorkDir, sep=""))

# Specify the full path of input .csv files on HDFS
HDFSDataDir <-  "/LoanChargeOff/Data"
Loan_Data <-  "Loan_Data10000.csv"

##############################################################################################################################
#
#                                                  Define Scoring Function                                                   #
#
##############################################################################################################################

# Define the scoring function for batch scoring
loanchargeoff_score <- function(Loan_Data,
                                LocalWorkDir,
                                HDFSWorkDir,
                                HDFSDataDir,
                                Stage = "Prod")
{
  # step4: prepare new data for prediction
  source("step4_prepare_new_data.R")
  newDataSet <- prepare_newdata(HDFSDataDir = HDFSDataDir,
                                HDFSWorkDir = HDFSWorkDir,
                                Loan_Data = Loan_Data, 
                                recentData = FALSE)
  
  # step5: loan prediction
  source("step5_loan_prediction.R")
  loan_prediction(LocalWorkDir = LocalWorkDir,
                  HDFSWorkDir = HDFSWorkDir, 
                  newData = newDataSet,
                  Stage = Stage)
}

##############################################################################################################################
#                                                                                                                            #   
#                                                 Invoke the Scoring Function                                                #
#                                                                                                                            #
##############################################################################################################################

# Invoke the scoring function for batch scoring
loanchargeoff_score(Loan_Data = Loan_Data,
                    LocalWorkDir = LocalWorkDir,
                    HDFSWorkDir = HDFSWorkDir,
                    HDFSDataDir = HDFSDataDir,
                    Stage = "Prod")
