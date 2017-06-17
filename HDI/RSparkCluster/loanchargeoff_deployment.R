#########################################################################################################################################
## This R script will do the following:
## 1. Remote login to the edge node for authentication purpose
## 2. Load model related files as a list which will be used when publishing web service
## 3. Create the scoring function
## 4. Publish the web service
## 3. Verify the webservice locally

## Input : 1. Full path of the new data on HDFS
##         2. Working directories on local edge node and HDFS
##         3. Stage: "Dev" for development; "Prod" for batch scoring; "Web" for scoring remotely with web service
## Output: The directory on HDFS which contains the result of recommendations

##################################################################################################################################
#
#                                        Define Scoring Function                                                                 #
#
##################################################################################################################################

# Load mrsdeploy package
library(mrsdeploy)

# Remote login for authentication purpose
remoteLogin(
  "http://localhost:12800",
  username = "admin",
  password = "<Enter Cluster Login Password Here>",
  session = FALSE
)

LocalWorkDir <- paste("/var/RevoShare/", Sys.info()[["user"]], "/LoanChargeOff/prod", sep="") 
HDFSDataDir <- "/LoanChargeOff/Data"
HDFSWorkDir <- "/LoanChargeOff/web"
if (system(paste("hadoop fs -test -e ", HDFSWorkDir, sep="")) == 0)
{
  system(paste("hadoop dfs -rm -r ", HDFSWorkDir, sep=""))
}
system(paste("hadoop fs -mkdir ", HDFSWorkDir, sep=""))

# Load .rds files
# These .rds files are saved from development stage and will be used for web-scoring.
# These .rds files are loaded locally and packed as a list to be published along with the scoring function.
# After publishing, the objects in the list can be directly used by the scoring function
forest_model <- readRDS(file.path(LocalWorkDir,"model/forest_model.rds"))
logistic_model <- readRDS(file.path(LocalWorkDir,"model/logistic_model.rds"))
tree_model <- readRDS(file.path(LocalWorkDir,"model/tree_model.rds"))
linear_model <- readRDS(file.path(LocalWorkDir,"model/linear_model.rds"))
NN_model <- readRDS(file.path(LocalWorkDir,"model/NN_model.rds"))
best_model_name <- readRDS(file.path(LocalWorkDir,"model/best_model_name.rds"))

model_obj <- list(forest_model = forest_model,
                  logistic_model = logistic_model,
                  tree_model = tree_model,
                  linear_model = linear_model,
                  NN_model = NN_model,
                  best_model_name = best_model_name)

# Define the scoring function
# Please replace the directory in "source" function with the directory of your own
# The directory should be full path containing the source scripts
loan_web_scoring <- function(Loan_Data,
                             LocalWorkDir,
                             HDFSWorkDir,
                             HDFSDataDir,
                             userName,
                             Stage = "Web")
{
  # step1: prepare data for prediction
  source(paste("/home/", userName, "/step4_prepare_new_data.R", sep=""))
  newDataSet <- prepare_newdata(HDFSDataDir = HDFSDataDir,
                                HDFSWorkDir = HDFSWorkDir,
                                Loan_Data = Loan_Data)
  
  # step2: loan prediction
  source(paste("/home/", userName, "/step5_loan_prediction.R", sep=""))
  loan_prediction_result <- loan_prediction(LocalWorkDir = LocalWorkDir,
                                            HDFSWorkDir = HDFSWorkDir, 
                                            newData = newDataSet,
                                            Stage = Stage)
  return(loan_prediction_result)
}

##################################################################################################################################
#
#                                        Publish as a Web Service                                                                #
#
##################################################################################################################################

# Specify the version of the web service
version <- "v0.0.1"

# Publish the api for character input
api_string <- publishService(
  "loan_chargeoff_string_input",
  code = loan_web_scoring,
  model = model_obj,
  inputs = list(Loan_Data = "character",
                LocalWorkDir = "character",
                HDFSWorkDir = "character",
                HDFSDataDir = "character",
                userName = "character",
                Stage = "character"),
  outputs = list(answer = "character"),
  v = version
)

# Publish the api for data frame input
api_frame <- publishService(
  "loan_chargeoff_frame_input",
  code = loan_web_scoring,
  model = model_obj,
  inputs = list(Loan_Data = "data.frame",
                LocalWorkDir = "character",
                HDFSWorkDir = "character",
                HDFSDataDir = "character",
                userName = "character",
                Stage = "character"),
  outputs = list(answer = "character"),
  v = version
)

##################################################################################################################################
#
#                                    Verify The Published API                                                                    #
#
##################################################################################################################################

# Specify the name of input .csv files on HDFS
Loan_Data <- "Loan_Data1000.csv"

# Verify the string input case
result_string <- api_string$loan_web_scoring(
  Loan_Data = Loan_Data,
  LocalWorkDir = LocalWorkDir,
  HDFSWorkDir = HDFSWorkDir,
  HDFSDataDir = HDFSDataDir,
  userName = Sys.info()[["user"]],
  Stage = "Web")

Loan_Data_df <- rxImport(RxTextData(file = file.path(HDFSDataDir, Loan_Data), fileSystem = RxHdfsFileSystem()))
# Verify the data frame input case
result_string <- api_frame$loan_web_scoring(
  Loan_Data = Loan_Data_df,
  LocalWorkDir = LocalWorkDir,
  HDFSWorkDir = HDFSWorkDir,
  HDFSDataDir = HDFSDataDir,
  userName = Sys.info()[["user"]],
  Stage = "Web")