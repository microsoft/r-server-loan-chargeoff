library(RevoScaleR)
library(MicrosoftML)
###########################################################################################################################################
# Function for demonstrating MicrosoftML's selectFeatures and categorical transforms.
# 
# Parameters:
#                * connection_string - substitute appropriate username and password along with database name and server if needed
#                * models_table - table where model binary is stored
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
                         best_models_file = "loan_chargeoff_models_10k.rds",
                         score_set = "loan_chargeoff_score_10k",
                         score_prediction = "loan_chargeoff_prediction_10k")
{
    best_model <- load(best_models_file)
    cc <- RxInSqlServer(connectionString = connection_string)
    rxSetComputeContext(cc)
    scoring_data <- RxSqlServevrData(table = score_set, connectionString = connection_string)
    prediction_data <- RxSqlServevrData(table = score_prediction, connectionString = connection_string)
    
    # Warning: this will drop and recreate the prediction table
    rxPredict(best_model, scoring_data, outData = extraVarsToWrite = c("loanId", "payment_date"), overwrite=TRUE)

}

batch_score()