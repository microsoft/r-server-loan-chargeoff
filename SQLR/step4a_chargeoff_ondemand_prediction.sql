/*
 * SQLR script to do on demand scoring/prediction of one record.
 */
SET ANSI_NULLS ON 
GO 
SET QUOTED_IDENTIFIER ON 
GO 
/*
 * Stored Procedure for on demand scoring/prediction using the 'best model' based on f1score.
 * Parameters:
 *           @models_table - Table which has serialized binary models stored along with evaluation stats (during training step)
 *           Rest of the parameters are the features used during training.
 */
DROP PROCEDURE IF EXISTS [dbo].[predict_chargeoff_ondemand]
GO

CREATE PROCEDURE [predict_chargeoff_ondemand]
	@models_table nvarchar(100),
	@loanId int,
	@payment_date date,
	@payment real,
	@past_due real,
	@remain_balance real,
	@loan_open_date date,
	@loanAmount real,
	@interestRate real,
	@grade int,
	@term int,
	@installment real,
	@isJointApplication bit,
	@purpose nvarchar(255),
	@memberId int,
	@residentialState nvarchar(4),
	@branch nvarchar(255),
	@annualIncome real,
	@yearsEmployment nvarchar(11),
	@homeOwnership nvarchar(10),
	@incomeVerified bit,
	@creditScore int,
	@dtiRatio real,
	@revolvingBalance real,
	@revolvingUtilizationRate real,
	@numDelinquency2Years int,
	@numDerogatoryRec int,
	@numInquiries6Mon int,
	@lengthCreditHistory int,
	@numOpenCreditLines int,
	@numTotalCreditLines int,
	@numChargeoff1year int,
	@payment_1 real,
	@payment_2 real,
	@payment_3 real,
	@payment_4 real,
	@payment_5 real,
	@past_due_1 real,
	@past_due_2 real,
	@past_due_3 real,
	@past_due_4 real,
	@past_due_5 real,
	@remain_balance_1 real,
	@remain_balance_2 real,
	@remain_balance_3 real,
	@remain_balance_4 real,
	@remain_balance_5 real

AS
BEGIN

    DECLARE @best_model_query nvarchar(300), @param_def nvarchar(100)
	DECLARE @bestmodel varbinary(max)
	SET @best_model_query = 'select top 1 @p_best_model = model from ' + @models_table + ' where f1score in (select max(f1score) from ' + @models_table + ')'
	SET @param_def = N'@p_best_model varbinary(max) OUTPUT';
	EXEC sp_executesql @best_model_query, @param_def, @p_best_model=@bestmodel OUTPUT;
	DECLARE @inquery nvarchar(max) = N'SELECT @p_loanId  loanId 
      ,@p_payment_date payment_date
      ,@p_payment payment
      ,@p_past_due past_due
      ,@p_remain_balance remain_balance
      ,@p_loan_open_date loan_open_date
      ,@p_loanAmount loanAmount
      ,@p_interestRate interestRate
      ,@p_grade grade
      ,@p_term term
      ,@p_installment installment
      ,@p_isJointApplication isJointApplication
      ,@p_purpose purpose
      ,@p_memberId memberId
      ,@p_residentialState residentialState
      ,@p_branch branch
      ,@p_annualIncome annualIncome
      ,@p_yearsEmployment yearsEmployment
      ,@p_homeOwnership homeOwnership
      ,@p_incomeVerified incomeVerified
      ,@p_creditScore creditScore
      ,@p_dtiRatio dtiRatio
      ,@p_revolvingBalance revolvingBalance
      ,@p_revolvingUtilizationRate revolvingUtilizationRate
      ,@p_numDelinquency2Years numDelinquency2Years
      ,@p_numDerogatoryRec numDerogatoryRec
      ,@p_numInquiries6Mon numInquiries6Mon
      ,@p_lengthCreditHistory lengthCreditHistory
      ,@p_numOpenCreditLines numOpenCreditLines
      ,@p_numTotalCreditLines numTotalCreditLines
      ,@p_numChargeoff1year numChargeoff1year
      ,@p_payment_1 payment_1
      ,@p_payment_2 payment_2
      ,@p_payment_3 payment_3
      ,@p_payment_4 payment_4
      ,@p_payment_5 payment_5
      ,@p_past_due_1 past_due_1
      ,@p_past_due_2 past_due_2
      ,@p_past_due_3 past_due_3
      ,@p_past_due_4 past_due_4
      ,@p_past_due_5 past_due_5
      ,@p_remain_balance_1 remain_balance_1
      ,@p_remain_balance_2 remain_balance_2
      ,@p_remain_balance_3 remain_balance_3
      ,@p_remain_balance_4 remain_balance_4
      ,@p_remain_balance_5 remain_balance_5'
	  
    EXEC sp_execute_external_script @language = N'R',
				    @script = N'
library(RevoScaleR)
library(MicrosoftML)
# Get best_model.
best_model <- unserialize(best_model)
# rxPredict has an issue currently where it needs the label column in source data set, working around for that
InputDataSet <- cbind(InputDataSet, charge_off=c(as.integer(NA)))
# convert implicit factors in InputDataSet to character as mlTransforms in the model for categorical variables do not like factors
i <- sapply(InputDataSet, is.factor)
InputDataSet[i] <- lapply(InputDataSet[i], as.character)
OutputDataSet <- rxPredict(best_model, InputDataSet, outData = NULL, extraVarsToWrite = c("loanId", "payment_date"))
# MicrosoftML has a known issue where it converts the date type to numeric which then gets translated as float by SQL Server
OutputDataSet$payment_date = as.POSIXct(OutputDataSet$payment_date, origin="1970-01-01")
'
, @input_data_1 = @inquery
, @params = N'@best_model varbinary(max), 
			  @p_loanId int,
			  @p_payment_date date,
			  @p_payment real,
			  @p_past_due real,
			  @p_remain_balance real,
			  @p_loan_open_date date,
			  @p_loanAmount real,
			  @p_interestRate real,
			  @p_grade int,
			  @p_term int,
			  @p_installment real,
			  @p_isJointApplication bit,
			  @p_purpose nvarchar(255),
			  @p_memberId int,
			  @p_residentialState nvarchar(4),
			  @p_branch nvarchar(255),
			  @p_annualIncome real,
			  @p_yearsEmployment nvarchar(11),
			  @p_homeOwnership nvarchar(10),
			  @p_incomeVerified bit,
			  @p_creditScore int,
			  @p_dtiRatio real,
			  @p_revolvingBalance real,
			  @p_revolvingUtilizationRate real,
			  @p_numDelinquency2Years int,
			  @p_numDerogatoryRec int,
			  @p_numInquiries6Mon int,
			  @p_lengthCreditHistory int,
			  @p_numOpenCreditLines int,
			  @p_numTotalCreditLines int,
			  @p_numChargeoff1year int,
			  @p_payment_1 real,
			  @p_payment_2 real,
			  @p_payment_3 real,
			  @p_payment_4 real,
			  @p_payment_5 real,
			  @p_past_due_1 real,
			  @p_past_due_2 real,
			  @p_past_due_3 real,
			  @p_past_due_4 real,
			  @p_past_due_5 real,
			  @p_remain_balance_1 real,
			  @p_remain_balance_2 real,
			  @p_remain_balance_3 real,
			  @p_remain_balance_4 real,
			  @p_remain_balance_5 real'
, @p_loanId=@loanId
, @p_payment_date=@payment_date
, @p_payment=@payment
, @p_past_due=@past_due
, @p_remain_balance=@remain_balance
, @p_loan_open_date=@loan_open_date
, @p_loanAmount=@loanAmount
, @p_interestRate=@interestRate
, @p_grade=@grade
, @p_term=@term
, @p_installment=@installment
, @p_isJointApplication=@isJointApplication
, @p_purpose=@purpose
, @p_memberId=@memberId
, @p_residentialState=@residentialState
, @p_branch=@branch
, @p_annualIncome=@annualIncome
, @p_yearsEmployment=@yearsEmployment
, @p_homeOwnership=@homeOwnership
, @p_incomeVerified=@incomeVerified
, @p_creditScore=@creditScore
, @p_dtiRatio=@dtiRatio
, @p_revolvingBalance=@revolvingBalance
, @p_revolvingUtilizationRate=@revolvingUtilizationRate
, @p_numDelinquency2Years=@numDelinquency2Years
, @p_numDerogatoryRec=@numDerogatoryRec
, @p_numInquiries6Mon=@numInquiries6Mon
, @p_lengthCreditHistory=@lengthCreditHistory
, @p_numOpenCreditLines=@numOpenCreditLines
, @p_numTotalCreditLines=@numTotalCreditLines
, @p_numChargeoff1year=@numChargeoff1year
, @p_payment_1=@payment_1
, @p_payment_2=@payment_2
, @p_payment_3=@payment_3
, @p_payment_4=@payment_4
, @p_payment_5=@payment_5
, @p_past_due_1=@past_due_1
, @p_past_due_2=@past_due_2
, @p_past_due_3=@past_due_3
, @p_past_due_4=@past_due_4
, @p_past_due_5=@past_due_5
, @p_remain_balance_1=@remain_balance_1
, @p_remain_balance_2=@remain_balance_2
, @p_remain_balance_3=@remain_balance_3
, @p_remain_balance_4=@remain_balance_4
, @p_remain_balance_5=@remain_balance_5
, @best_model = @bestmodel
WITH RESULT SETS (("loanId" int not null, "payment_date" date not null, "PredictedLabel" int not null, "Score.1" float not null, "Probability.1" float not null))
;
END
GO