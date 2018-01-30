library(RevoScaleR)
library(MicrosoftML)
###########################################################################################################################################
# Function for demonstrating MicrosoftML's selectFeatures and categorical transforms.
# 
# Parameters:
#                * connection_string - substitute appropriate username and password along with database name and server if needed
#                * best_models_file - file where best_model object from training/testing step is stored
#                * score_set - table name of for scoring data (usually the prefix of 10k/100k/1m will only change based on data set size)
#                * score_prediction - table name where to store prediction results
#
# Pre-Requisites:
#                1. Make sure Loan_ChargeOff.ps1 has been run for your appropriate size data set so the required tables have already been 
#                   created and dataset imported (it's already been run for 10k loans data set)
#                2. Modelling must have been completed
#                   
###########################################################################################################################################
batch_score <- function (connection_string = "Driver=SQL Server;Server=.;Database=LoanChargeOff;UID=<sql username>;PWD=<sql password>",
                         best_models_file = "loan_chargeoff_best_model_10k.rdata",
                         score_set = "loan_chargeoff_score_10k",
                         score_prediction = "loan_chargeoff_prediction_10k")
{
    load(best_models_file)
    if (!exists("best_model"))
    {
      stop("best_models_file does not contain best_model object, make sure you saved it properly during training step.")
    }
    cc <- RxInSqlServer(connectionString = connection_string)
    rxSetComputeContext(cc)
    scoring_data <- RxSqlServerData(table = score_set, connectionString = connection_string)
    prediction_data <- RxSqlServerData(table = score_prediction, connectionString = connection_string)
    
    # Warning: this will drop and recreate the prediction table
    rxPredict(best_model$model, scoring_data, outData = prediction_data, extraVarsToWrite = c("loanId", "payment_date"), overwrite=TRUE)
}

batch_score()