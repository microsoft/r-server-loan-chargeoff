#################################################################################################################################
## This R script will do the following:
## 1. Source and run step 1 to retrieve training and testing data
## 2. Use training data created in step 1 to train the xgboost model 
## 3. Use the trained model to perform prediction using testing data
## 4. Save predicted results
## 5. Evaluate model performance

## Input : HDFSWorkDir
##         HDFSDataDir
##         LocalWorkDir
##         Loan_Data

## Output: Model AUC
##         Model TPR
##         Model TNR

##############################################################################################################################
#
#                                       Define training_evaluation function                                                  #
#
##############################################################################################################################
xgboost_model <- function(HDFSWorkDir = NULL,
                          HDFSDataDir = NULL,
                          LocalWorkDir = NULL,
                          Loan_Data = NULL)
{
  
  ############################################################################################################
  ## Setup directories 
  ############################################################################################################
  # Specify working directories on edge node and HDFS
  if(is.null(LocalWorkDir)){
    LocalWorkDir <- paste("/var/RevoShare/", Sys.info()[["user"]], "/LoanChargeOff/dev", sep="" ) 
  }
  if(is.null(HDFSDataDir)){
    HDFSDataDir <- "/LoanChargeOff/Data"
  }
  if(is.null(HDFSWorkDir)){
    HDFSWorkDir <- "/LoanChargeOff/dev"
  }
  if(is.null(Loan_Data)){
    # Specify the full path of input .csv files on HDFS
    Loan_Data <- "Loan_Data100000.csv"
  }
  
  # ############################################################################
  # ## Create working directory if does not exist
  # ############################################################################
  # Create working directory if does not exist 
  if (! (system(paste("hadoop fs -test -e ", HDFSWorkDir, sep="")) == 0))
  {
    system(paste("hadoop fs -mkdir ", HDFSWorkDir, sep=""))
  }
  
  # ############################################################################
  # ## Make folder to train xdf file
  # ############################################################################
  myLocalTrainDir <- file.path(LocalWorkDir,"model")
  HDFSIntermediateDir <- file.path(HDFSWorkDir, "temp")
  
  if (! (dir.exists(myLocalTrainDir))){
    system(paste("mkdir -p -m 777 ", myLocalTrainDir, sep="")) # make new directory if doesn't exist
  } 
  
  # ############################################################################
  # ## Create folder to store trained model and intermediate files
  # ############################################################################
  if (! (system(paste("hadoop fs -test -e ", HDFSIntermediateDir, sep="")) == 0))
  {
    system(paste("hadoop fs -mkdir ", HDFSIntermediateDir, sep=""))
  }
  
  
  ############################################################################################################
  ## Set compute context and load libraries
  ############################################################################################################
  
  print("Start Step6: xgboost training and evaluation...")
  hdfsFS <- RxHdfsFileSystem()
  library(xgboost) 
  
  
  ############################################################################################################
  ## Retrieve training and testing data 
  ############################################################################################################
  
  source("step1_get_training_testing_data.R")
  step1_res_list <- prepare_training_testing(HDFSDataDir = HDFSDataDir,
                                             HDFSWorkDir = HDFSWorkDir,
                                             Loan_Data = Loan_Data)
  
  trainingSet <- step1_res_list$trainingSet
  testingSet <- step1_res_list$testingSet
  
  
  ############################################################################################################
  ## Start training XGBoost model
  ############################################################################################################
  
  # Train the XGBoost model
  print("Training XGBoost model...")
  
  rxSetComputeContext('local')
  train_data <- rxDataStep(inData = trainingSet,maxRowsByCols = NULL)    #convert XDF format to data frame 
  train_label <- train_data$charge_off                                   #train data charge_off
  train_numeric <- data.matrix(train_data, rownames.force = NA)          #convert categorical features to numeric 
  
  #remove columns from data
  cols.dont.want <- c("memberId","loanId","loan_open_date", "paydate", "charge_off")  
  train_numeric <- train_numeric[, ! colnames(train_numeric) %in% cols.dont.want, drop = F]
  
  #train the model
  XGB_model <- xgboost(data = train_numeric, label = train_label, 
                       max.depth = 4, eta = 1, nthread = 4, nround = 4,  
                       objective = "binary:logistic")
  
  ############################################################################################################
  ## Evaluate the model using testing set
  ############################################################################################################
  
  print("predicting on xgboost model...")
  test_data <- rxDataStep(inData = testingSet, maxRowsByCols = NULL)     #convert XDF format to data frame 
  test_label <- test_data$charge_off                                     #test data charge_off 
  test_numeric <- data.matrix(test_data, rownames.force = NA)            #convert categorical features to numeric 
  
  test_numeric <- test_numeric[, ! colnames(test_numeric) %in% cols.dont.want, drop = F]
  
  xgb_pred <- predict(XGB_model, test_numeric)                           #predict using trained model
  xgb_prediction <- as.numeric(xgb_pred > 0.5)                           #evaluate results to 0 or 1
  
  test_numeric_df <- data.frame(test_data)                            #convert matrix results to data frame
  test_numeric_df$"Probability.XGBoost.1" <- xgb_pred                 #add scored results column to test data
  test_numeric_df$"predictedLabel" <- xgb_prediction                  #add predicted results column to test data
  test_numeric_df$"charge_off" <- test_label                          #add observed results column to test data
  
  #save test data with results as XDF file
  Prediction_Table_XGB <- RxXdfData(file = paste(HDFSIntermediateDir, "/PredictionTableXGBXdf", sep=""),fileSystem = hdfsFS)
  rxDataStep(inData = test_numeric_df, outFile = Prediction_Table_XGB, overwrite = TRUE)  
  
  
  
  ############################################################################################################
  # Calculate TPR, TNR, AUC in local compute context
  ############################################################################################################
  
  print("Evaluating Performance of the XGBoost model...")
  
  #evaluate average error of model
  xgb_err <- mean(xgb_prediction != test_label)                
  
  #calculate ROC and AUC values
  ROC_XGB <- rxRoc(actualVarName = "charge_off", predVarNames = "Probability.XGBoost.1", data = test_numeric_df) 
  AUC_XGB <- rxAuc(ROC_XGB)
  AUC_XGB_short <- round(AUC_XGB, digits = 2)
  
  #calculate TNR and TPR values
  P <- nrow(test_numeric_df[test_numeric_df$charge_off == 1, ])
  N <- nrow(test_numeric_df[test_numeric_df$charge_off == 0, ])
  TP <- nrow(test_numeric_df[test_numeric_df$charge_off == 1 & test_numeric_df$predictedLabel == 1, ])
  TN <- nrow(test_numeric_df[test_numeric_df$charge_off == 0 & test_numeric_df$predictedLabel == 0, ])
  TNR_XGB <- TN/N
  TPR_XGB <- TP/P
  
  ############################################################################################################
  # Return AUC, TPR, TNR results
  ############################################################################################################
  
  print(paste("TPR_XGB: ", TPR_XGB))
  print(paste("TNR_XGB: ", TNR_XGB))
  print(paste("AUC_XGB: ", AUC_XGB))
  
  #return results 
  return(list(AUC = AUC_XGB, TPR = TPR_XGB, TNR = TNR_XGB))
  
}