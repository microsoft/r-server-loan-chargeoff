/*
 * SQLR script to create stored procedure for training.
 */
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

DROP PROCEDURE IF EXISTS [dbo].[train_model];
GO

/*
 * Stored Procedure for training of models using MicrosoftML algorithms. This also evaluates the models and stores
 * the following stats along with serialized model binary, accuracy, auc, precision, recall, f1score.
 * The parameters can be tuned for various algorithms based on performance on your data.
 * Parameters:
 *            @training_set_table - training data table name
 *            @test_set_table - test data table name for model evaluation
 *            @scored_table - table to store scores in when doing model evaluation
 *            @model_table - table to store model in serialized binary format along with evaluation stats
 *            @model_name_param - the algorithm to use for training the model.
 *                                Can be one of 'logistic_reg', 'fast_trees', 'fast_forest', 'fast_linear', 'neural_net'
 *            @connectionString - connection string to connect to the database for use in the R script
 */
CREATE PROCEDURE [train_model] @training_set_table varchar(100), @test_set_table varchar(100), @scored_table varchar(100), @model_table varchar(100), @model_alg varchar(50), @connectionString varchar(300)
AS 
BEGIN

	DECLARE @payload varbinary(max), @auc real, @accuracy real, @precision real, @recall real, @f1score real;
	DECLARE @del_cmd nvarchar(300), @ins_cmd nvarchar(300), @param_def nvarchar(300);
	EXECUTE sp_execute_external_script @language = N'R',
					   @script = N' 
library(RevoScaleR)
library(MicrosoftML)
# model evaluation functions
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
ml_trans <- list(categorical(vars = c("purpose", "residentialState", "homeOwnership", "yearsEmployment")),
				 selectFeatures(model_formula, mode = mutualInformation(numFeaturesToKeep = 41)))

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
# evaluate model
rxPredict(model, testing_set, outData = scoring_set, extraVarsToWrite = c("memberId", "loanId", "charge_off"), overwrite=TRUE)
print("Done writing predictions for evaluation of model.")
model_stats <- model_eval_stats(scoring_set)
print(model_stats)
modelbin <- serialize(model, connection=NULL)
stat_auc <- model_stats[[1]]

stat_accuracy <- model_stats[[2]]
stat_precision <- model_stats[[3]]
stat_recall <- model_stats[[4]]
stat_f1score <- model_stats[[5]]
'
, @params = N'@model_name varchar(20), @connection_string varchar(300), @train_set varchar(100), @test_set varchar(100), @score_set varchar(100),
			@modelbin varbinary(max) OUTPUT, @stat_auc real OUTPUT, @stat_accuracy real OUTPUT, @stat_precision real OUTPUT, @stat_recall real OUTPUT, @stat_f1score real OUTPUT'
, @model_name = @model_alg
, @connection_string = @connectionString
, @train_set = @training_set_table
, @test_set = @test_set_table
, @score_set = @scored_table
, @modelbin = @payload OUTPUT
, @stat_auc = @auc OUTPUT
, @stat_accuracy = @accuracy OUTPUT
, @stat_precision = @precision OUTPUT
, @stat_recall = @recall OUTPUT
, @stat_f1score = @f1score OUTPUT;

SET @del_cmd = N'DELETE FROM ' + @model_table + N' WHERE model_name = ''' + @model_alg + ''''
EXEC sp_executesql @del_cmd;
SET @ins_cmd = N'INSERT INTO ' + @model_table + N' (model_name, model, auc, accuracy, precision, recall, f1score) VALUES (''' + @model_alg + ''', @p_payload, @p_auc, @p_accuracy, @p_precision, @p_recall, @p_f1score)'
SET @param_def = N'@p_payload varbinary(max),
				   @p_auc real,
				   @p_accuracy real,
				   @p_precision real,
				   @p_recall real,
				   @p_f1score real'
EXEC sp_executesql @ins_cmd, @param_def, 
								@p_payload=@payload,
								@p_auc=@auc,
								@p_accuracy=@accuracy,
								@p_precision=@precision,
								@p_recall=@recall,
								@p_f1score=@f1score;

;
END
GO