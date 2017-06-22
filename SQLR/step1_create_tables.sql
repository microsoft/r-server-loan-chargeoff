/*
 * SQL Script to create tables required for training, testing and scoring
 * of models. 
 * It creates tables for member_info, loan_info and payments_info tables.
 * It also creates tables to store models with evaluation stats, selected features
 * and prediction tables.
 * $(datasize) is substituted through Invoke-SqlCmd's Variable option
 * (in powershell).
 */
SET ansi_nulls on
GO
SET quoted_identifier on
GO

/*  Create the member_info Table. */  

DROP TABLE IF EXISTS member_info_$(datasize)

CREATE TABLE [member_info_$(datasize)](
    [memberId] [int],
    [residentialState] [nvarchar](4),
    [branch] [nvarchar](255),
    [annualIncome] [real],
    [yearsEmployment] [nvarchar](11),
    [homeOwnership] [nvarchar](10),
    [incomeVerified] [bit],
    [creditScore] [int],
    [dtiRatio] [real],
    [revolvingBalance] [real],
    [revolvingUtilizationRate] [real],
    [numDelinquency2Years] [int],
    [numDerogatoryRec] [int],
    [numInquiries6Mon] [int],
    [lengthCreditHistory] [int],
    [numOpenCreditLines] [int],
    [numTotalCreditLines] [int],
    [numChargeoff1year] [int]
);

CREATE CLUSTERED COLUMNSTORE INDEX member_info_$(datasize)_cci ON member_info_$(datasize) WITH (DROP_EXISTING = OFF);
GO
/*  Create the loan_info Table. */  

DROP TABLE IF EXISTS loan_info_$(datasize)

CREATE TABLE [loan_info_$(datasize)](
    [loanId] [int],
    [loan_open_date] [date],
    [memberId] [int],
    [loanAmount] [real],
    [interestRate] [real],
    [grade] [int],
    [term] [int],
    [installment] [real],
    [isJointApplication] [bit],
    [purpose] [nvarchar](255)
);

CREATE CLUSTERED COLUMNSTORE INDEX loan_info_$(datasize)_cci ON loan_info_$(datasize) WITH (DROP_EXISTING = OFF);
GO
/* Create the payments_info Table*/  

DROP TABLE IF EXISTS payments_info_$(datasize)

CREATE TABLE [payments_info_$(datasize)](
    [loanId] [int],
    [payment_date] [date],
    [payment] [real],
    [past_due] [real],
    [remain_balance] [real],
    [closed] [bit],
    [charged_off] [bit]
);

CREATE CLUSTERED COLUMNSTORE INDEX payments_info_$(datasize)_cci ON payments_info_$(datasize) WITH (DROP_EXISTING = OFF);
GO

DROP TABLE IF EXISTS [loan_chargeoff_models_$(datasize)];

CREATE TABLE [loan_chargeoff_models_$(datasize)]
(
    [model_name] nvarchar(30) not null default('default model') primary key,
    [training_ts] datetime default(GETDATE()),
    [model] varbinary(max) not null,
    [auc] real,
    [accuracy] real,
    [precision] real,
    [recall] real,
    [f1score] real,
    [selected_features] nvarchar(1000) null
);
GO

DROP TABLE IF EXISTS [loan_chargeoff_prediction_$(datasize)]

CREATE TABLE [loan_chargeoff_prediction_$(datasize)](
    [loanId] [int],
    [payment_date] [date],
    [prediction_date] [date] default(GETDATE()),
    [PredictedLabel] int,
    [Score.1] [float],
    [Probability.1] [float]
);

GO

/* helper view for Power BI visualization */
drop view if exists [vw_loan_chargeoff_prediction]
go

create view [vw_loan_chargeoff_prediction]
as
select * from [loan_chargeoff_prediction_$(datasize)]
go
