#################################################################################################################################
## This R script will do the following:
## 1. Read input data which contains all the history information for all the loans from HDFS
## 2. Extract training/testing data based on process date (paydate) from the input data
## 3. save training/testing data in HDFS working directory


## Input : Loan_Data: name of input data
##         HDFSWorkDir: HDFS working directory
##         HDFSDataDir: directory of input data
## Output: training data and testing data

##############################################################################################################################
#                                                                                                                            #
#                                       Define prepare_training_testing function                                             #
#                                                                                                                            #
##############################################################################################################################

prepare_training_testing <- function(HDFSDataDir,
                                     HDFSWorkDir,
                                     Loan_Data)
  
{
  library(RevoScaleR)
  ## set up spark compute context and define HDFS file system
  sparkContext <- rxSparkConnect(consoleOutput = TRUE)
  rxSetComputeContext(sparkContext)
  hdfsFS <- RxHdfsFileSystem()
  
  ## Define the data source
  dataSet <- file.path(HDFSDataDir, Loan_Data)
  colInfo <- list(payment_1 = list(type = "numeric"),
                  payment_2 = list(type = "numeric"),
                  payment_3 = list(type = "numeric"),
                  payment_4 = list(type = "numeric"),
                  payment_5 = list(type = "numeric"),
                  past_due_1 = list(type = "numeric"),
                  past_due_2 = list(type = "numeric"),
                  past_due_3 = list(type = "numeric"),
                  past_due_4 = list(type = "numeric"),
                  past_due_5 = list(type = "numeric"),
                  remain_balance_1 = list(type = "numeric"),
                  remain_balance_2 = list(type = "numeric"),
                  remain_balance_3 = list(type = "numeric"),
                  remain_balance_4 = list(type = "numeric"),
                  remain_balance_5 = list(type = "numeric"))
  
  dataDS <- RxTextData(file = dataSet, missingValueString = "M", colInfo = colInfo, fileSystem = hdfsFS)
  
  ## extract training pieces based on process date 
  print("making training data on HDFS...")
  trainingSet <- RxXdfData(paste(HDFSWorkDir, "/trainingSet",sep=""), fileSystem = hdfsFS)
  
  NAreplace <- function(dataList) {
    replaceFun <- function(x) {
      x[is.na(x)] <- 0
      return(x)
    }
    dataList <- lapply(dataList, replaceFun)
    dataList$memberId <- as.integer(dataList$memberId)
    dataList$loanId <- as.integer(dataList$loanId)
    return(dataList)
  }
  
  rxDataStep(inData = dataDS, outFile = trainingSet, 
             rowSelection = (paydate == '2017-01-12') |
               ((paydate == '2016-12-12') & (charge_off == 1)) |
               ((paydate == '2016-11-12') & (charge_off == 1)) |
               ((paydate == '2016-10-12') & (charge_off == 1)) |
               ((paydate == '2016-09-12') & (charge_off == 1)),
             transformFunc = NAreplace,
             overwrite = TRUE, reportProgress = 0)
  
  ## select the testing data based on latest available process date
  print("making testing data on HDFS...")
  testingSet <- RxXdfData(paste(HDFSWorkDir,"/testingSet",sep=""), fileSystem = hdfsFS)
  rxDataStep(inData = dataDS, outFile = testingSet, 
             rowSelection = (paydate == '2017-02-12'),
             transformFunc = NAreplace,
             overwrite = TRUE, reportProgress = 0)
  
  ## return training/testing data for later use
  return(list(trainingSet = trainingSet, testingSet = testingSet))
}