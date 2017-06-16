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
CREATE PROCEDURE [predict_chargeoff] @score_table varchar(100), @score_prediction_table varchar(100), @models_table varchar(100), @connectionString varchar(300)

AS
BEGIN

    DECLARE @best_model_query nvarchar(300), @param_def nvarchar(100)
	DECLARE @bestmodel varbinary(max)
	SET @best_model_query = 'select top 1 @p_best_model = model from ' + @models_table + ' where f1score in (select max(f1score) from ' + @models_table + ')'
	SET @param_def = N'@p_best_model varbinary(max) OUTPUT';
	EXEC sp_executesql @best_model_query, @param_def, @p_best_model=@bestmodel OUTPUT;
    EXEC sp_execute_external_script @language = N'R',
				    @script = N'
library(RevoScaleR)
library(MicrosoftML)
# Get best_model.
best_model <- unserialize(best_model)
scoring_set <- RxSqlServerData(table=score_set, connectionString = connection_string)
scored_output <- RxSqlServerData(table=score_prediction, connectionString = connection_string, overwrite=TRUE)
print(summary(best_model))
rxPredict(best_model, scoring_set, outData = scored_output, extraVarsToWrite = c("memberId", "loanId", "payment_date"), overwrite=TRUE)
'
, @params = N'@best_model varbinary(max), @score_set varchar(100), @score_prediction varchar(100), @connection_string varchar(300)' 
, @best_model = @bestmodel 
, @score_set = @score_table
, @score_prediction = @score_prediction_table
, @connection_string = @connectionString    
;
END
GO