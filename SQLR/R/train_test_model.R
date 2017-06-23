######################################################################################################################################
# R script for training of models using MicrosoftML algorithms. 
#
######################################################################################################################################

library(RevoScaleR)
library(MicrosoftML)
# model evaluation stats
model_eval_stats <- function(scored_data, label="charge_off", predicted_prob="Probability", predicted_label="PredictedLabel")
{
  roc <- rxRoc(label, grep(predicted_prob, names(scored_data), value=T), scored_data)
  auc <- rxAuc(roc)
  crosstab_formula <- as.formula(paste("~as.factor(", label, "):as.factor(", predicted_label, ")"))
  cross_tab <- rxCrossTabs(crosstab_formula, scored_data)
  conf_matrix <- cross_tab$counts[[1]]
  tn <- conf_matrix[1,1]
  fp <- conf_matrix[1,2]
  fn <- conf_matrix[2,1]
  tp <- conf_matrix[2,2]
  accuracy <- (tp + tn) / (tp + fn + fp + tn)
  precision <- tp/(tp+fp)
  recall <- tp / (tp+fn)
  f1score <- 2 * (precision * recall) / (precision + recall)
  return(list(auc=auc, accuracy=accuracy, precision = precision, recall=recall, f1score=f1score))
}

###########################################################################################################################################
# Function for training of models using MicrosoftML algorithms. Feature selection is done during training using selectFeatures mlTransforms
# as well as categorical transform.
# 
# Parameters:
#                * model_name - name of the model to train_set
#                * train_set - table name of training set (usually the prefix of 10k/100k/1m will only change based on data set size)
#                * test_set - table name of testing set
#                * score_set - table name to be used for scoring the test_set table for evaluation
#                * connection_string - substitute appropriate username and password along with database name and server if needed
#
# Pre-Requisites:
#                Make sure Loan_ChargeOff.ps1 has been run for your appropriate size data set so the required tables have already been 
#                created and dataset imported (it's already been run for 10k loans data set)
#                   
###########################################################################################################################################
train_model <- function(model_name = "logistic_regression",
                        train_set = "loan_chargeoff_train_10k",
                        test_set = "loan_chargeoff_test_10k",
                        score_set = "loan_chargeoff_eval_score_10k",
                        connection_string = "Driver=SQL Server;Server=.;Database=LoanChargeOff;UID=<sql username>;PWD=<sql password>"
                        )
{

    cc <- RxInSqlServer(connectionString = connection_string)
    rxSetComputeContext(cc)
    training_set <- RxSqlServerData(table=train_set, connectionString = connection_string)
    testing_set <- RxSqlServerData(table=test_set, connectionString = connection_string)
    scoring_set <- RxSqlServerData(table=score_set, connectionString = connection_string, overwrite=TRUE)
    ##########################################################################################################################################
    ## Training and evaluating model based on model selection
    ##########################################################################################################################################
    features <- rxGetVarNames(training_set)
    vars_to_remove <- c("memberId", "loanId", "payment_date", "loan_open_date", "charge_off")
    feature_names <- features[!(features %in% vars_to_remove)]
    model_formula <- as.formula(paste(paste("charge_off~"), paste(feature_names, collapse = "+")))
    ml_trans <- list(categorical(vars = c("purpose", "residentialState", "branch", "homeOwnership", "yearsEmployment")),
                    selectFeatures(model_formula, mode = mutualInformation(numFeaturesToKeep = 100)))
    
    print(paste("Starting to train with", model_name))
    if (model_name == "logistic_reg") {
        model <- rxLogisticRegression(formula = model_formula,
                        data = training_set,
                        mlTransforms = ml_trans)
    } else if (model_name == "fast_trees") {
        model <- rxFastTrees(formula = model_formula,
                        data = training_set,
                        mlTransforms = ml_trans)
    } else if (model_name == "fast_forest") {
        model <- rxFastForest(formula = model_formula,
                        data = training_set,
                        mlTransforms = ml_trans)
    } else if (model_name == "fast_linear") {
        model <- rxFastLinear(formula = model_formula,
                        data = training_set,
                        mlTransforms = ml_trans)
    } else if (model_name == "neural_net") {
        model <- rxNeuralNet(formula = model_formula,
                        data = training_set,
                        numIterations = 42,
                        optimizer = adaDeltaSgd(),
                        mlTransforms = ml_trans)
    }
    print("Done training.")
    
    # selected features
    features_to_remove <- c("(Bias)")
    selected_features <- rxGetVarInfo(summary(model)$summary)
    selected_feature_names <- names(selected_features)
    selected_feature_filtered <- selected_feature_names[!(selected_feature_names %in% features_to_remove)]
    
    # evaluate model
    rxPredict(model, testing_set, outData = scoring_set, extraVarsToWrite = c("loanId", "payment_date", "charge_off"), overwrite=TRUE)
    print("Done writing predictions for evaluation of model.")
    list(model_name = model_name, model = model, stats = model_eval_stats(scoring_set))
}

# train on MicrosoftML algorithms
ml_algs <- c("logistic_reg", "fast_trees", "fast_forest", "fast_linear", "neural_net")
model_stats <- lapply(ml_algs, train_model)

# find the best model based on f1score
best_model <- model_stats[[which.max(sapply(model_stats, function(stat) stat$stats$f1score))]]
# save to file for use during scoring
save(best_model, file="loan_chargeoff_best_model_10k.rdata")
best_model