#################################################################################################################################
## This R script will do the following:
## 1. Using training data created in step 1 to train 5 different models 
## 2. Save the models on HDFS and edge node
## 3. Select the best model based on TPR

## Input : HDFSWorkDir
##         LocalWorkDir
##         trainigSet
##         testingSet
##         selectedFeaturesName

##############################################################################################################################
#
#                                       Define training_evaluation function                                                  #
#
##############################################################################################################################

training_evaluation <- function(HDFSWorkDir,
                                LocalWorkDir,
                                trainingSet,
                                testingSet,
                                selectedFeaturesName)
{ 
  print("Start Step3: training and evaluation...")
  sparkContext <- rxSparkConnect(consoleOutput = TRUE)
  rxSetComputeContext(sparkContext)
  hdfsFS <- RxHdfsFileSystem()
  
  ############################################################################
  ## make folders store models and training xdf file
  ############################################################################
  myLocalTrainDir <- file.path(LocalWorkDir,"model")
  HDFSTrainDir <- file.path(HDFSWorkDir,"model")
  HDFSIntermediateDir <- file.path(HDFSWorkDir, "temp")
  
  # clean up/remove folders storing trained model/modelInfo and make new folders
  if(dir.exists(myLocalTrainDir)){
    system(paste("rm -rf ",myLocalTrainDir, sep="")) # remove the directory if exists
    system(paste("mkdir -p -m 777 ", myLocalTrainDir, sep="")) # create a new directory
  } else {
    system(paste("mkdir -p -m 777 ", myLocalTrainDir, sep="")) # make new directory if doesn't exist
  }
  
  ###########################################################
  ## clean up/remove folders stroting trained model in HDFS, 
  ## and create folder to storing trained model and intermediate files
  ###########################################################
  if (system(paste("hadoop fs -test -e ", HDFSTrainDir, sep="")) == 0)
  {
    system(paste("hadoop dfs -rm -r ", HDFSTrainDir, sep=""))
  }
  system(paste("hadoop fs -mkdir ", HDFSTrainDir, sep=""))
  
  if (system(paste("hadoop fs -test -e ", HDFSIntermediateDir, sep="")) == 0)
  {
    system(paste("hadoop dfs -rm -r ", HDFSIntermediateDir, sep=""))
  }
  system(paste("hadoop fs -mkdir ", HDFSIntermediateDir, sep=""))
  
  
  ####################################################################
  ## Start training five different models
  ###################################################################
  # get the formula for modeling
  modelFormula <- as.formula(paste(paste("charge_off~"), paste(selectedFeaturesName, collapse = "+")))
  # Train the Random Forest.
  print("Training RF model...")
  forest_model <- rxFastForest(modelFormula, 
                               data = trainingSet, 
                               numTrees = 100, 
                               numLeaves = 100)
  
  # save the fitted model to local edge node.
  rxSetComputeContext('local')
  print("Saving RF model to edge node and HDFS...")
  saveRDS(forest_model, file = paste(myLocalTrainDir,"/forest_model.rds",sep=""))
  # copy to HDFS
  rxHadoopCopyFromLocal(paste(myLocalTrainDir,"/forest_model.rds",sep=""), paste(HDFSTrainDir,"/forest_model.rds",sep=""))
  
  # Train the logistic regression model.
  print("Training Logistic model...")
  rxSetComputeContext(sparkContext)
  logistic_model <- rxLogisticRegression(formula = modelFormula,
                                         data = trainingSet,
                                         reportProgress = 0)
  
  # save the fitted model to local edge node.
  print("Saving logistic model to edge node and HDFS...")
  rxSetComputeContext('local')
  saveRDS(logistic_model, file = paste(myLocalTrainDir,"/logistic_model.rds",sep=""))
  # copy to HDFS
  rxHadoopCopyFromLocal(paste(myLocalTrainDir,"/logistic_model.rds",sep=""), paste(HDFSTrainDir,"/logistic_model.rds",sep=""))
  
  # Train fast tree model
  print("Training fast tree model...")
  rxSetComputeContext(sparkContext)
  tree_model <- rxFastTrees(formula = modelFormula,
                            data = trainingSet,
                            reportProgress = 0)
  
  # save the fitted model to local edge node.
  print("Saving fast tree model to edge node and HDFS...")
  rxSetComputeContext('local')
  saveRDS(tree_model, file = paste(myLocalTrainDir,"/tree_model.rds",sep=""))
  # copy to HDFS
  rxHadoopCopyFromLocal(paste(myLocalTrainDir,"/tree_model.rds",sep=""), paste(HDFSTrainDir,"/tree_model.rds",sep=""))
  
  # Train fast linear model
  print("Training fast linear model...")
  rxSetComputeContext(sparkContext)
  linear_model <- rxFastLinear(formula = modelFormula,
                               data = trainingSet,
                               reportProgress = 0)
  
  # save the fitted model to local edge node.
  print("Saving fast linear model to edge node and HDFS...")
  rxSetComputeContext('local')
  saveRDS(linear_model, file = paste(myLocalTrainDir,"/linear_model.rds",sep=""))
  # copy to HDFS
  rxHadoopCopyFromLocal(paste(myLocalTrainDir,"/linear_model.rds",sep=""), paste(HDFSTrainDir,"/linear_model.rds",sep=""))
  
  # Train neural network model
  print("Training neural network model...")
  rxSetComputeContext(sparkContext)
  NN_model <- rxNeuralNet(formula = modelFormula,
                          data = trainingSet,
                          numIterations = 6,
                          optimizer = adaDeltaSgd(),
                          reportProgress = 0)
  
  # save the fitted model to local edge node.
  print("Saving neural network model to edge node and HDFS...")
  rxSetComputeContext('local')
  saveRDS(NN_model, file = paste(myLocalTrainDir,"/NN_model.rds",sep=""))
  # copy to HDFS
  rxHadoopCopyFromLocal(paste(myLocalTrainDir,"/NN_model.rds",sep=""), paste(HDFSTrainDir,"/NN_model.rds",sep=""))
  
  ############################################################################################################
  ## evaluate the models using testing set
  ############################################################################################################
  
  # Make Predictions using random forest model 
  print("Predicting on RF model...")
  rxSetComputeContext(sparkContext)
  Prediction_Table_RF <- RxXdfData(file = paste(HDFSIntermediateDir, "/PredictionTableRFXdf", sep=""),fileSystem = hdfsFS)
  fitScores <- rxPredict(forest_model, testingSet, suffix = ".rxFastForest",
                         extraVarsToWrite = names(testingSet),
                         outData = Prediction_Table_RF, overwrite = TRUE)
  
  print("Predicting on Logistic regression model...")
  Prediction_Table_Logit <- RxXdfData(file = paste(HDFSIntermediateDir, "/PredictionTableLogitXdf", sep=""),fileSystem = hdfsFS)
  fitScores <- rxPredict(logistic_model, fitScores, suffix = ".rxLogisticRegression",
                         extraVarsToWrite = names(fitScores),
                         outData = Prediction_Table_Logit, overwrite = TRUE)
  
  print("predicting on fast tree model...")
  Prediction_Table_FT <- RxXdfData(file = paste(HDFSIntermediateDir, "/PredictionTableFTXdf", sep=""),fileSystem = hdfsFS)
  fitScores <- rxPredict(tree_model, fitScores, suffix = ".rxFastTree",
                         extraVarsToWrite = names(fitScores),
                         outData = Prediction_Table_FT, overwrite = TRUE)
  
  print("predicting on fast linear model...")
  Prediction_Table_FL <- RxXdfData(file = paste(HDFSIntermediateDir, "/PredictionTableFLXdf", sep=""),fileSystem = hdfsFS)
  fitScores <- rxPredict(linear_model, fitScores, suffix = ".rxFastLinear",
                         extraVarsToWrite = names(fitScores),
                         outData = Prediction_Table_FL, overwrite = TRUE)
  
  print("predicting on neural network model...")
  Prediction_Table_NN <- RxXdfData(file = paste(HDFSIntermediateDir, "/PredictionTableNNXdf", sep=""),fileSystem = hdfsFS)
  fitScores <- rxPredict(NN_model, fitScores, suffix = ".rxNeuralNet",
                         extraVarsToWrite = names(fitScores),
                         outData = Prediction_Table_NN, overwrite = TRUE)
  
  ######################################################################################################
  # calculate TPR, TNR, AUC in local compute context
  ######################################################################################################
  rxSetComputeContext("local")
  
  # ROC computation for 5 models
  fitRoc <- rxRoc("charge_off", grep("Probability.", names(fitScores), value = T), fitScores)
  plot(fitRoc)
  
  # load testing results into data frame
  fitScoresDF <- rxImport(fitScores)
  P <- nrow(fitScoresDF[fitScoresDF$charge_off == 1, ])
  N <- nrow(fitScoresDF[fitScoresDF$charge_off == 0, ])
  
  # calculate TPR, TNR and AUC for random forest model
  TP_RF <- nrow(fitScoresDF[fitScoresDF$charge_off == 1 & fitScoresDF$PredictedLabel.rxFastForest == 1, ])
  TN_RF <- nrow(fitScoresDF[fitScoresDF$charge_off == 0 & fitScoresDF$PredictedLabel.rxFastForest == 0, ])
  TPR_RF <- TP_RF/P
  TNR_RF <- TN_RF/N
  ROC_RF <- rxRoc(actualVarName = "charge_off", predVarNames = "Probability.rxFastForest.1", data = Prediction_Table_RF)
  AUC_RF <- rxAuc(ROC_RF)
  
  # calculate TPR, TNR and AUC for logistic regression model
  TP_Logit <- nrow(fitScoresDF[fitScoresDF$charge_off == 1 & fitScoresDF$PredictedLabel.rxLogisticRegression == 1, ])
  TN_Logit <- nrow(fitScoresDF[fitScoresDF$charge_off == 0 & fitScoresDF$PredictedLabel.rxLogisticRegression == 0, ])
  TPR_Logit <- TP_Logit/P
  TNR_Logit <- TN_Logit/N
  ROC_Logit <- rxRoc(actualVarName = "charge_off", predVarNames = "Probability.rxLogisticRegression.1", data = Prediction_Table_Logit)
  AUC_Logit <- rxAuc(ROC_Logit)
  
  # calculate TPR, TNR and AUC for fast tree model 
  TP_FT <- nrow(fitScoresDF[fitScoresDF$charge_off == 1 & fitScoresDF$PredictedLabel.rxFastTree == 1, ])
  TN_FT <- nrow(fitScoresDF[fitScoresDF$charge_off == 0 & fitScoresDF$PredictedLabel.rxFastTree == 0, ])
  TPR_FT <- TP_FT/P
  TNR_FT <- TN_FT/N
  ROC_FT <- rxRoc(actualVarName = "charge_off", predVarNames = "Probability.rxFastTree.1", data = Prediction_Table_FT)
  AUC_FT <- rxAuc(ROC_FT)
  
  # calculate TPR, TNR and AUC for fast linear model
  TP_FL <- nrow(fitScoresDF[fitScoresDF$charge_off == 1 & fitScoresDF$PredictedLabel.rxFastLinear == 1, ])
  TN_FL <- nrow(fitScoresDF[fitScoresDF$charge_off == 0 & fitScoresDF$PredictedLabel.rxFastLinear == 0, ])
  TPR_FL <- TP_FL/P
  TNR_FL <- TN_FL/N
  ROC_FL <- rxRoc(actualVarName = "charge_off", predVarNames = "Probability.rxFastLinear.1", data = Prediction_Table_FL)
  AUC_FL <- rxAuc(ROC_FL)
  
  # calculate TPR, TNR and AUC for neural network model 
  TP_NN <- nrow(fitScoresDF[fitScoresDF$charge_off == 1 & fitScoresDF$PredictedLabel.rxNeuralNet == 1, ])
  TN_NN <- nrow(fitScoresDF[fitScoresDF$charge_off == 0 & fitScoresDF$PredictedLabel.rxNeuralNet == 0, ])
  TPR_NN <- TP_NN/P
  TNR_NN <- TN_NN/N
  ROC_NN <- rxRoc(actualVarName = "charge_off", predVarNames = "Probability.rxNeuralNet.1", data = Prediction_Table_NN)
  AUC_NN <- rxAuc(ROC_NN)
  
  #####################################################################################################
  ## select the best model based on AUC
  #####################################################################################################
  print("Select the best model...")
  models <- data.frame(metrics = c(AUC_RF, AUC_Logit, AUC_FT, AUC_FL, AUC_NN), 
                       names = c("forest", "logistic", "tree", "linear", "NN"))
  best_model_name <- models[which.max(models$metrics), "names"]
  
  saveRDS(best_model_name, file = file.path(myLocalTrainDir,"best_model_name.rds"))
  # copy to HDFS
  rxHadoopCopyFromLocal(paste(myLocalTrainDir,"/best_model_name.rds",sep=""), paste(HDFSTrainDir,"/best_model_name.rds",sep=""))
}