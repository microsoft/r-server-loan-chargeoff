##########################################################################################################################################
## This R script will prepare the new data that we want to do prediction on it
## Input : most recently process date data
## Output: new data set

##########################################################################################################################################

prepare_newdata <- function(HDFSDataDir,
                            HDFSWorkDir,
                            Loan_Data)
  
{
  print("step4: Start getting new data...")
  library(RevoScaleR)
  
  # define HDFS file system
  sparkContext <- rxSparkConnect(consoleOutput = TRUE)
  rxSetComputeContext(sparkContext)
  hdfsFS <- RxHdfsFileSystem()
  
  # data input can be a string of fileName or a data frame
  if(is(Loan_Data)[1] == "character"){
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
    dataDS <- RxTextData(file = file.path(HDFSDataDir, Loan_Data), missingValueString = "M", colInfo = colInfo, fileSystem = hdfsFS)
  } else if (is(Loan_Data)[1] == "data.frame"){
    dataDS <- Loan_Data
  } else {
    stop("invalid input format")
  }
  
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
  
  # define the new data set
  newData <- RxXdfData(paste(HDFSWorkDir,"/newSet",sep=""), fileSystem = hdfsFS)
  rxDataStep(inData = dataDS, outFile = newData, 
             rowSelection = (paydate == '2017-03-12'), 
             transformFunc = NAreplace,
             overwrite = TRUE)
  
  return(newData)
}
