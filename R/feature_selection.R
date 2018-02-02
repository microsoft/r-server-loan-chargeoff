library(RevoScaleR)
library(MicrosoftML)
###########################################################################################################################################
# Function for demonstrating MicrosoftML's selectFeatures and categorical transforms.
# 
# Parameters:
#                * connection_string - substitute appropriate username and password along with database name and server if needed
#                * train_set - table name of training set (usually the prefix of 10k/100k/1m will only change based on data set size)
#                * test_set - table name of testing set
#
# Pre-Requisites:
#                Make sure Loan_ChargeOff.ps1 has been run for your appropriate size data set so the required tables have already been 
#                created and dataset imported (it's already been run for 10k loans data set)
#                   
###########################################################################################################################################
select_features <- function(connection_string = "Driver=SQL Server;Server=.;Database=LoanChargeOff_R;Trusted_Connection=True",
                            train_set = "loan_chargeoff_train_10k",
                            test_set = "loan_chargeoff_test_10k")
{
    cc <- RxInSqlServer(connectionString = connection_string)
    rxSetComputeContext(cc)
    testing_set <- RxSqlServerData(table=test_set, connectionString = connection_string)
    training_set <- RxSqlServerData(table=train_set, connectionString = connection_string)
    
    features <- rxGetVarNames(testing_set)
    variables_to_remove <- c("memberId", "loanId", "payment_date", "loan_open_date", "charge_off")
    feature_names <- features[!(features %in% variables_to_remove)]
    model_formula <- as.formula(paste(paste("charge_off~"), paste(feature_names, collapse = "+")))
    selected_count <- 0
    
    ml_trans <- list(categorical(vars = c("purpose", "residentialState", "branch", "homeOwnership", "yearsEmployment")),
                    selectFeatures(model_formula, mode = mutualInformation(numFeaturesToKeep = 100)))
    candidate_model <- rxLogisticRegression(model_formula, data = training_set, mlTransforms = ml_trans)
    predicted_score <- rxPredict(candidate_model, testing_set, extraVarsToWrite = c("charge_off"))
    # set compute context to local otherwise need to store prediction in RxSqlServerData data source for RxInSqlServer compute context
    rxSetComputeContext("local")
    predicted_roc <- rxRoc("charge_off", grep("Probability", names(predicted_score), value = T), predicted_score)
    auc <- rxAuc(predicted_roc)
    
    features_to_remove <- c("(Bias)")
    selected_features <- rxGetVarInfo(summary(candidate_model)$summary)
    selected_feature_names <- names(selected_features)
    selected_feature_names[!(selected_feature_names %in% features_to_remove)]
}

features <- select_features()
features
