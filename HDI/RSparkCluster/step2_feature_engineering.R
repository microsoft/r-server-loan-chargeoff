###############################################################################################################################
## This R script will do the following :
## 1. Feature selection, here we use MicrosoftML to do feature selection
## 2. Can add code in this file to create some new features based on existing features
## 3. Can try open sourced package such as Caret to do feature selection here
## 4. Selected the best features based on AUC

## Input : training/testing set (RxXdfData Source), HDFSWorkDir
## Output: name of selected features.

##############################################################################################################################
#
#                                       Define feature_engineer function                                                     #
#
##############################################################################################################################

feature_engineer <- function(trainingSet, 
                             testingSet,
                             numFeaturesToKeep = 0)
{
  # Load packages. 
  library(MicrosoftML)
  
  sparkContext <- rxSparkConnect(consoleOutput = TRUE)
  
  # get the features list and the number of features
  features <- rxGetVarNames(trainingSet)
  variables_to_remove <- c("memberId", "loanId", "paydate", "loan_open_date", "charge_off")
  featuresName <- features[!(features %in% variables_to_remove)]
  
  # Get the formula of the machine learning model
  modelFormula <- as.formula(paste(paste("charge_off~"), paste(featuresName, collapse = "+")))
  feature_to_remove <- c("(Bias)")
  ##########################################################################################################################
  #                                      Feature selection part                                                            #
  #    using function selectFeatures in MicrosoftML package to do features selection                                       #   
  #    set the number of features you want to keep for the model                                                           #
  #    select the best number of features used for model based on AUC of random forest model                               #
  #    If you are already aware of the number of features to keep, pass the value as argument to this function             #
  ##########################################################################################################################
  
  if(numFeaturesToKeep == 0){
    print("starting feature selection...")
    featuresNum <- c(40, 35, 30, 20)
    maxAUC <- 0.0
    
    # The following for loop may run for a long time depending on the number of elements in featuresNum
    for (i in featuresNum)
    {
      rxSetComputeContext(sparkContext)
      mlTrans <- list(categorical(vars = c("purpose", "residentialState", "homeOwnership", "yearsEmployment")),
                      selectFeatures(modelFormula, mode = mutualInformation(numFeaturesToKeep = i)))
      candinateModel <- rxLogisticRegression(modelFormula, data = trainingSet, mlTransforms = mlTrans)
      predictedScore <- rxPredict(candinateModel, testingSet, extraVarsToWrite = c("charge_off"))
      
      ## ROC computations not supported for Spark compute context, change to local compute context to calculate AUC
      rxSetComputeContext("local")
      predictedRoc <- rxRoc("charge_off", grep("Probability", names(predictedScore), value = T), predictedScore)
      AUC <- rxAuc(predictedRoc)
      if (maxAUC < AUC)
      {
        maxAUC <- AUC
        numFeaturesToKeep <- i
      }
      selectedFeaturesName <- names(summary(model)$summary)
      selectedFeaturesName <- selectedFeaturesName[!(selectedFeaturesName %in% feature_to_remove)]
      modelFormula <- as.formula(paste(paste("charge_off~"), paste(selectedFeaturesName, collapse = "+")))
    }
  }
  
  #######################################################################################################
  #   Get selected features list
  #######################################################################################################
  print("selecting features...")
  rxSetComputeContext(sparkContext)
  modelFormula <- as.formula(paste(paste("charge_off~"), paste(featuresName, collapse = "+")))
  mlTrans <- list(categorical(vars = c("purpose", "residentialState", "homeOwnership", "yearsEmployment")),
                  selectFeatures(modelFormula, mode = mutualInformation(numFeaturesToKeep = numFeaturesToKeep)))
  model <- rxLogisticRegression(modelFormula, data = trainingSet, mlTransforms = mlTrans)
  selectedFeaturesName <- names(summary(model)$summary)
  selectedFeaturesName <- selectedFeaturesName[!(selectedFeaturesName %in% feature_to_remove)]
  return(list(selectedFeaturesName = selectedFeaturesName))
}