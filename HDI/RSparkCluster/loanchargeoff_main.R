##############################################################################################################################
## This R script will do the following:
## 1. Specify parameters for main function: 
##    1) Working directories on edge node and HDFS
##    2) Name of the input file on HDFS
## 2. Define the main function for development 
## 3. Invoke the main function for development

## Input : 1. Working directory on edge node 
##         2. Working directory on HDFS
##         3. Name of the input files on HDFS
##         4. Stage: "Dev" for development; "Prod" for batch scoring; "Web" for scoring remotely with web service
## Output: The directory on HDFS which contains the result of recommendations

##############################################################################################################################

##############################################################################################################################
#
#                                             Specify Parameters                                                             #
#
##############################################################################################################################

# Specify working directories on edge node and HDFS
LocalWorkDir <- paste("/var/RevoShare/", Sys.info()[["user"]], "/LoanChargeOff/dev", sep="" ) 
HDFSDataDir <- "/LoanChargeOff/Data"
HDFSWorkDir <- "/LoanChargeOff/dev"
if (system(paste("hadoop fs -test -e ", HDFSWorkDir, sep="")) == 0)
{
  system(paste("hadoop dfs -rm -r ", HDFSWorkDir, sep=""))
}
system(paste("hadoop fs -mkdir ", HDFSWorkDir, sep=""))

# Specify the full path of input .csv files on HDFS
Loan_Data <- "Loan_Data100000.csv"
##############################################################################################################################
#
#                                       Define Main Function for Development                                                 #
#
##############################################################################################################################

# The main function for development
loan_main <- function(LocalWorkDir,
                      HDFSDataDir,
                      HDFSWorkDir,
                      Loan_Data,
                      Stage = "Dev"){
  
  # step1: data processing
  source("step1_get_training_testing_data.R")
  step1_res_list <- prepare_training_testing(HDFSDataDir = HDFSDataDir,
                                             HDFSWorkDir = HDFSWorkDir,
                                             Loan_Data = Loan_Data)
  
  # step2: feature engineering
  source("step2_feature_engineering.R")
  step2_res_list <- feature_engineer(trainingSet = step1_res_list$trainingSet,
                                     testingSet = step1_res_list$testingSet,
                                     numFeaturesToKeep = 30)
  
  # step3: training and evaluation
  source("step3_training_evaluation.R")
  training_evaluation(HDFSWorkDir = HDFSWorkDir,
                      LocalWorkDir = LocalWorkDir,
                      trainingSet = step1_res_list$trainingSet,
                      testingSet = step1_res_list$testingSet,
                      selectedFeaturesName = step2_res_list$selectedFeaturesName)
  
  # step4: prepare new data for prediction
  source("step4_prepare_new_data.R")
  newDataSet <- prepare_newdata(HDFSDataDir = HDFSDataDir,
                                HDFSWorkDir = HDFSWorkDir,
                                Loan_Data = Loan_Data)
  
  # step5: loan prediction
  source("step5_loan_prediction.R")
  loan_prediction(LocalWorkDir = LocalWorkDir,
                  HDFSWorkDir = HDFSWorkDir, 
                  newData = newDataSet,
                  Stage = Stage)
}

##############################################################################################################################
#
#                                             Invoke Main Function                                                           #
#
##############################################################################################################################

# Invoke main function for development
loan_main(LocalWorkDir = LocalWorkDir,
          HDFSDataDir = HDFSDataDir,
          HDFSWorkDir = HDFSWorkDir,
          Loan_Data = Loan_Data,
          Stage = "Dev")