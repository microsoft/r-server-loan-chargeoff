/*
 * SQLR script to demonstrate feature selection available in MicrosoftML package.
 * We use this same mechanism during training so this step is optional to run, but
 * serves as an example of an approach for feature selection, i.e., preselect features
 * and store in database table for later use in training of models.
 */
 
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


DROP TABLE IF EXISTS [selected_features_$(datasize)];

CREATE TABLE [selected_features_$(datasize)](
    [feature_id] [int] IDENTITY(1,1) NOT NULL,
    [feature_name] [nvarchar](500) NOT NULL
);
GO

DROP PROCEDURE IF EXISTS [dbo].[select_features];
GO

/*
 * Stored procedure for feature selection.
 * Parameters:
 *           @training_set_table - table with training data
 *           @test_set_table - table with test data
 *           @selected_features_table - table to store selected features in
 *           @connectionString - connection string to connect to the database for use in the R script
 */
CREATE PROCEDURE [select_features] @training_set_table nvarchar(100), @test_set_table nvarchar(100), @selected_features_table nvarchar(100), @connectionString nvarchar(300)
AS 
BEGIN
    DECLARE @testing_set_query nvarchar(400), @del_cmd nvarchar(100), @ins_cmd nvarchar(max)
    /*     select features using MicrosotML  */
    SET @del_cmd = 'DELETE FROM ' + @selected_features_table
    EXEC sp_executesql @del_cmd
    SET @ins_cmd = 'INSERT INTO ' + @selected_features_table + ' (feature_name)
    EXECUTE sp_execute_external_script @language = N''R'',
                       @script = N''
library(RevoScaleR)
library(MicrosoftML)
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
predicted_roc <- rxRoc("charge_off", grep("Probability", names(predicted_score), value = T), predicted_score)
auc <- rxAuc(predicted_roc)

features_to_remove <- c("(Bias)")
selected_features <- rxGetVarInfo(summary(candidate_model)$summary)
selected_feature_names <- names(selected_features)
selected_feature_filtered <- selected_feature_names[!(selected_feature_names %in% features_to_remove)]

selected_features_final <- data.frame(selected_feature_filtered)''
, @output_data_1_name = N''selected_features_final''
, @params = N''@connection_string nvarchar(300), @test_set nvarchar(100), @train_set nvarchar(100)''
, @connection_string = N''' + @connectionString + '''' +
', @train_set = N''' + @training_set_table + '''' +
', @test_set = N''' + @test_set_table + ''';'

EXEC sp_executesql @ins_cmd
END
GO