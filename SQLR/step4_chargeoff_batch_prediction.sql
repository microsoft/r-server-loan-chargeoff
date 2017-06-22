/*
 * SQLR script to do batch scoring.
 */
SET ANSI_NULLS ON 
GO 
SET QUOTED_IDENTIFIER ON 
GO 

DROP PROCEDURE IF EXISTS [dbo].[predict_chargeoff]
GO

/*
 * Stored Procedure to do batch scoring using the 'best model' based on f1score.
 * Parameters:
 *            @score_table - Table with data to score/make prediction on
 *            @score_prediction_table - Table to store predictions
 *            @models_table - Table which has serialized binary models stored along with evaluation stats (during training step)
 *            @connectionString - connection string to connect to the database for use in the R script
 */
CREATE PROCEDURE [predict_chargeoff] @score_table nvarchar(100), @score_prediction_table nvarchar(100), @models_table nvarchar(100)

AS
BEGIN

    DECLARE @best_model_query nvarchar(300), @param_def nvarchar(100), @spees_model_param_def nvarchar(100)
    DECLARE @bestmodel varbinary(max)
    DECLARE @ins_cmd nvarchar(max)
    DECLARE @inquery nvarchar(max) = N'SELECT * from ' + @score_table
    SET @best_model_query = 'select top 1 @p_best_model = model from ' + @models_table + ' where f1score in (select max(f1score) from ' + @models_table + ')'
    SET @param_def = N'@p_best_model varbinary(max) OUTPUT';

    EXEC sp_executesql @best_model_query, @param_def, @p_best_model=@bestmodel OUTPUT;

    SET @spees_model_param_def = N'@p_bestmodel varbinary(max)'
    SET @ins_cmd = 'INSERT INTO ' + @score_prediction_table + ' ([loanId], [payment_date], [PredictedLabel], [Score.1], [Probability.1])
    EXEC sp_execute_external_script @language = N''R'',
                    @script = N''
library(RevoScaleR)
library(MicrosoftML)
# Get best_model.
best_model <- unserialize(best_model_raw)
i <- sapply(InputDataSet, is.factor)
InputDataSet[i] <- lapply(InputDataSet[i], as.character)

OutputDataSet <- rxPredict(best_model, InputDataSet, extraVarsToWrite = c("loanId", "payment_date"), overwrite=TRUE)
OutputDataSet$payment_date = as.POSIXct(OutputDataSet$payment_date, origin="1970-01-01")
''
, @input_data_1 = N''' + @inquery + '''' +
', @params = N''@r_rowsPerRead int, @best_model_raw varbinary(max), @score_set nvarchar(100), @score_prediction nvarchar(100)'' 
, @best_model_raw = @p_bestmodel
, @r_rowsPerRead = 10000
, @score_set = N''' + @score_table + '''' +
', @score_prediction = N''' + @score_prediction_table + ''';';

EXEC sp_executeSQL @ins_cmd, @spees_model_param_def, @p_bestmodel = @bestmodel;
END
GO