#################################################################################################################################
## This R script will do the following:
## 1. load the models and selected the best models
## 2. Apply the model to the new data set
## 3. Save the predicted results on HDFS

## Input : HDFSWorkDir,
##         LocalWorkDir
##         newData

##############################################################################################################################
#
#                                       Define loan_prediction function                                                      #
#
##############################################################################################################################


loan_prediction <- function(LocalWorkDir,
                            HDFSWorkDir, 
                            newData,
                            Stage)
{ 
  print("Start step5: prediction....")
  library(MicrosoftML)
  rxSetComputeContext('local')
  
  # specify the folder store models and training xdf file
  myLocalTrainDir <- file.path(LocalWorkDir, "model")
  
  # specify the folder on HDFS to store the predicted results
  HDFSPredictedDir <- file.path(HDFSWorkDir, "PredictedResults")
  if (system(paste("hadoop fs -test -e ", HDFSPredictedDir, sep="")) == 0)
  {
    system(paste("hadoop dfs -rm -r ", HDFSPredictedDir, sep=""))
  }
  system(paste("hadoop fs -mkdir ", HDFSPredictedDir, sep=""))
  
  # define a function to get the best model
  importedModel <- function(bestModelName) {
    switch(as.character(bestModelName),
           random_forest = {import_model <- model_obj$forest_model},
           logistic = {import_model <- model_obj$logistic_model},
           fast_tree = {import_model <- model_obj$tree_model},
           fast_linear = {import_model <- model_obj$linear_model},
           neural_network = {import_model <- model_obj$NN_model})
  }
  
  # select the best model based on Stage
  if (Stage == "Web") {
    # "model_obj" is defined in script "loanchargeoff_deployment" when publishing web service
    best_model_name <- model_obj$best_model_name
    best_model <- importedModel(best_model_name)
  } else {
    best_model_name <- readRDS(file = file.path(myLocalTrainDir, "best_model_name.rds"))
    best_model <- readRDS(file = file.path(paste(myLocalTrainDir, "/", best_model_name, "_model.rds", sep="")))
  }
  
  # set up to spark compute context
  sparkContext <- rxSparkConnect(consoleOutput = TRUE)
  rxSetComputeContext(sparkContext)
  hdfsFS <- RxHdfsFileSystem()
  ## define the result file
  finalResult <- file.path(HDFSPredictedDir, "results")
  Output_Table <- RxXdfData(file = finalResult,fileSystem = hdfsFS)
  rxPredict(best_model, data = newData, outData = Output_Table, overwrite = TRUE,
            extraVarsToWrite = names(newData), 
            reportProgress = 0)
  print("The prediction results are stored : ")
  print(Output_Table)
  
  renameColumns <- function(dataList) {
    names(dataList)[match(c('Score.1', 'Probability.1'), names(dataList))] <- c('Score', 'Probability')
    return(dataList)
  }
  
  # Remove dot in column names so that it can be uploaded to hive 
  rxDataStep(inData = Output_Table,
             outFile = Output_Table,
             transformFunc = renameColumns,
             transformVars = c('Score.1', 'Probability.1'),
             overwrite=TRUE)

  ## Upload prediction results into hive table which then can be consumed by PowerBI for visualization
  rxDataStep(inData = Output_Table, outFile = RxHiveData(table="loanchargeoff_predictions"), overwrite = TRUE, reportProgress = 0)
  print("The prediction results are also stored in hive table loanchargeoff_predictions")
  
  return(finalResult)
}