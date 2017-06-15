-- View over the underlying table for features and labels required
/* Large DataSets */
drop view if exists [dbo].[vw_loan_chargeoff_1m]
go
create view [dbo].[vw_loan_chargeoff_1m]
as
select t.loanId, t.payment_date, t.payment, t.past_due, t.remain_balance,
  l.loan_open_date, l.loanAmount,l.interestRate,l.grade,l.term,l.installment,l.isJointApplication,l.purpose,
  m.memberId,m.residentialState,m.annualIncome,m.yearsEmployment,m.homeOwnership,m.incomeVerified,m.creditScore,m.dtiRatio,m.revolvingBalance,m.revolvingUtilizationRate,m.numDelinquency2Years,m.numDerogatoryRec,m.numInquiries6Mon,m.lengthCreditHistory,m.numOpenCreditLines,m.numTotalCreditLines,m.numChargeoff1year,
  ISNULL(t.payment_1, 0) payment_1,ISNULL(t.payment_2, 0) payment_2,ISNULL(t.payment_3, 0) payment_3,ISNULL(t.payment_4, 0) payment_4,ISNULL(t.payment_5, 0) payment_5, 
  ISNULL(t.past_due_1, 0) past_due_1,ISNULL(t.past_due_2, 0) past_due_2,ISNULL(t.past_due_3, 0) past_due_3,ISNULL(t.past_due_4, 0) past_due_4,ISNULL(t.past_due_5, 0) past_due_5,
  ISNULL(t.remain_balance_1, 0) remain_balance_1,ISNULL(t.remain_balance_2, 0) remain_balance_2,ISNULL(t.remain_balance_3, 0) remain_balance_3,ISNULL(t.remain_balance_4, 0) remain_balance_4,ISNULL(t.remain_balance_5, 0) remain_balance_5, t.charge_off
from 
(
select *, 
(select top 1 payment from payments_info_1m p2 where DATEDIFF(month, p2.payment_date,p1.payment_date) = 1 AND p1.loanId = p2.loanId) payment_1,
(select top 1 payment from payments_info_1m p2 where DATEDIFF(month, p2.payment_date,p1.payment_date) = 2 AND p1.loanId = p2.loanId) payment_2,
(select top 1 payment from payments_info_1m p2 where DATEDIFF(month, p2.payment_date,p1.payment_date) = 3 AND p1.loanId = p2.loanId) payment_3,
(select top 1 payment from payments_info_1m p2 where DATEDIFF(month, p2.payment_date,p1.payment_date) = 4 AND p1.loanId = p2.loanId) payment_4,
(select top 1 payment from payments_info_1m p2 where DATEDIFF(month, p2.payment_date,p1.payment_date) = 5 AND p1.loanId = p2.loanId) payment_5,
(select top 1 past_due from payments_info_1m p2 where DATEDIFF(month, p2.payment_date,p1.payment_date) = 1 AND p1.loanId = p2.loanId) past_due_1,
(select top 1 past_due from payments_info_1m p2 where DATEDIFF(month, p2.payment_date,p1.payment_date) = 2 AND p1.loanId = p2.loanId) past_due_2,
(select top 1 past_due from payments_info_1m p2 where DATEDIFF(month, p2.payment_date,p1.payment_date) = 3 AND p1.loanId = p2.loanId) past_due_3,
(select top 1 past_due from payments_info_1m p2 where DATEDIFF(month, p2.payment_date,p1.payment_date) = 4 AND p1.loanId = p2.loanId) past_due_4,
(select top 1 past_due from payments_info_1m p2 where DATEDIFF(month, p2.payment_date,p1.payment_date) = 5 AND p1.loanId = p2.loanId) past_due_5,
(select top 1 remain_balance from payments_info_1m p2 where DATEDIFF(month, p2.payment_date,p1.payment_date) = 1 AND p1.loanId = p2.loanId) remain_balance_1,
(select top 1 remain_balance from payments_info_1m p2 where DATEDIFF(month, p2.payment_date,p1.payment_date) = 2 AND p1.loanId = p2.loanId) remain_balance_2,
(select top 1 remain_balance from payments_info_1m p2 where DATEDIFF(month, p2.payment_date,p1.payment_date) = 3 AND p1.loanId = p2.loanId) remain_balance_3,
(select top 1 remain_balance from payments_info_1m p2 where DATEDIFF(month, p2.payment_date,p1.payment_date) = 4 AND p1.loanId = p2.loanId) remain_balance_4,
(select top 1 remain_balance from payments_info_1m p2 where DATEDIFF(month, p2.payment_date,p1.payment_date) = 5 AND p1.loanId = p2.loanId) remain_balance_5,
(select MAX(charged_off+0) from payments_info_1m p2 where DATEDIFF(month, p1.payment_date,p2.payment_date) IN (1,2,3) AND p1.loanId = p2.loanId) charge_off
from payments_info_1m p1 ) AS t inner join loan_info_1m l ON t.loanId = l.loanId inner join member_info_1m m ON l.memberId = m.memberId 
where t.charge_off IS NOT NULL 
and ((payment_date between '2016-09-12' and '2016-12-12' and charge_off = 1) or (payment_date = '2017-01-12'))

GO

drop view if exists [dbo].[vw_loan_chargeoff_test_1m]
go
create view [dbo].[vw_loan_chargeoff_test_1m]
as
select t.loanId, t.payment_date, t.payment, t.past_due, t.remain_balance,
  l.loan_open_date, l.loanAmount,l.interestRate,l.grade,l.term,l.installment,l.isJointApplication,l.purpose,
  m.memberId,m.residentialState,m.annualIncome,m.yearsEmployment,m.homeOwnership,m.incomeVerified,m.creditScore,m.dtiRatio,m.revolvingBalance,m.revolvingUtilizationRate,m.numDelinquency2Years,m.numDerogatoryRec,m.numInquiries6Mon,m.lengthCreditHistory,m.numOpenCreditLines,m.numTotalCreditLines,m.numChargeoff1year,
  ISNULL(t.payment_1, 0) payment_1,ISNULL(t.payment_2, 0) payment_2,ISNULL(t.payment_3, 0) payment_3,ISNULL(t.payment_4, 0) payment_4,ISNULL(t.payment_5, 0) payment_5, 
  ISNULL(t.past_due_1, 0) past_due_1,ISNULL(t.past_due_2, 0) past_due_2,ISNULL(t.past_due_3, 0) past_due_3,ISNULL(t.past_due_4, 0) past_due_4,ISNULL(t.past_due_5, 0) past_due_5,
  ISNULL(t.remain_balance_1, 0) remain_balance_1,ISNULL(t.remain_balance_2, 0) remain_balance_2,ISNULL(t.remain_balance_3, 0) remain_balance_3,ISNULL(t.remain_balance_4, 0) remain_balance_4,ISNULL(t.remain_balance_5, 0) remain_balance_5, t.charge_off
from 
(
select *, 
(select top 1 payment from payments_info_1m p2 where DATEDIFF(month, p2.payment_date,p1.payment_date) = 1 AND p1.loanId = p2.loanId) payment_1,
(select top 1 payment from payments_info_1m p2 where DATEDIFF(month, p2.payment_date,p1.payment_date) = 2 AND p1.loanId = p2.loanId) payment_2,
(select top 1 payment from payments_info_1m p2 where DATEDIFF(month, p2.payment_date,p1.payment_date) = 3 AND p1.loanId = p2.loanId) payment_3,
(select top 1 payment from payments_info_1m p2 where DATEDIFF(month, p2.payment_date,p1.payment_date) = 4 AND p1.loanId = p2.loanId) payment_4,
(select top 1 payment from payments_info_1m p2 where DATEDIFF(month, p2.payment_date,p1.payment_date) = 5 AND p1.loanId = p2.loanId) payment_5,
(select top 1 past_due from payments_info_1m p2 where DATEDIFF(month, p2.payment_date,p1.payment_date) = 1 AND p1.loanId = p2.loanId) past_due_1,
(select top 1 past_due from payments_info_1m p2 where DATEDIFF(month, p2.payment_date,p1.payment_date) = 2 AND p1.loanId = p2.loanId) past_due_2,
(select top 1 past_due from payments_info_1m p2 where DATEDIFF(month, p2.payment_date,p1.payment_date) = 3 AND p1.loanId = p2.loanId) past_due_3,
(select top 1 past_due from payments_info_1m p2 where DATEDIFF(month, p2.payment_date,p1.payment_date) = 4 AND p1.loanId = p2.loanId) past_due_4,
(select top 1 past_due from payments_info_1m p2 where DATEDIFF(month, p2.payment_date,p1.payment_date) = 5 AND p1.loanId = p2.loanId) past_due_5,
(select top 1 remain_balance from payments_info_1m p2 where DATEDIFF(month, p2.payment_date,p1.payment_date) = 1 AND p1.loanId = p2.loanId) remain_balance_1,
(select top 1 remain_balance from payments_info_1m p2 where DATEDIFF(month, p2.payment_date,p1.payment_date) = 2 AND p1.loanId = p2.loanId) remain_balance_2,
(select top 1 remain_balance from payments_info_1m p2 where DATEDIFF(month, p2.payment_date,p1.payment_date) = 3 AND p1.loanId = p2.loanId) remain_balance_3,
(select top 1 remain_balance from payments_info_1m p2 where DATEDIFF(month, p2.payment_date,p1.payment_date) = 4 AND p1.loanId = p2.loanId) remain_balance_4,
(select top 1 remain_balance from payments_info_1m p2 where DATEDIFF(month, p2.payment_date,p1.payment_date) = 5 AND p1.loanId = p2.loanId) remain_balance_5,
(select MAX(charged_off+0) from payments_info_1m p2 where DATEDIFF(month, p1.payment_date,p2.payment_date) IN (1,2,3) AND p1.loanId = p2.loanId) charge_off
from payments_info_1m p1 ) AS t inner join loan_info_1m l ON t.loanId = l.loanId inner join member_info_1m m ON l.memberId = m.memberId 
where t.charge_off IS NOT NULL 
and payment_date = '2017-02-12'
GO

drop view if exists [dbo].[vw_loan_chargeoff_score_1m]
go
create view [dbo].[vw_loan_chargeoff_score_1m]
as
select t.loanId, t.payment_date, t.payment, t.past_due, t.remain_balance,
  l.loan_open_date, l.loanAmount,l.interestRate,l.grade,l.term,l.installment,l.isJointApplication,l.purpose,
  m.memberId,m.residentialState,m.annualIncome,m.yearsEmployment,m.homeOwnership,m.incomeVerified,m.creditScore,m.dtiRatio,m.revolvingBalance,m.revolvingUtilizationRate,m.numDelinquency2Years,m.numDerogatoryRec,m.numInquiries6Mon,m.lengthCreditHistory,m.numOpenCreditLines,m.numTotalCreditLines,m.numChargeoff1year,
  ISNULL(t.payment_1, 0) payment_1,ISNULL(t.payment_2, 0) payment_2,ISNULL(t.payment_3, 0) payment_3,ISNULL(t.payment_4, 0) payment_4,ISNULL(t.payment_5, 0) payment_5, 
  ISNULL(t.past_due_1, 0) past_due_1,ISNULL(t.past_due_2, 0) past_due_2,ISNULL(t.past_due_3, 0) past_due_3,ISNULL(t.past_due_4, 0) past_due_4,ISNULL(t.past_due_5, 0) past_due_5,
  ISNULL(t.remain_balance_1, 0) remain_balance_1,ISNULL(t.remain_balance_2, 0) remain_balance_2,ISNULL(t.remain_balance_3, 0) remain_balance_3,ISNULL(t.remain_balance_4, 0) remain_balance_4,ISNULL(t.remain_balance_5, 0) remain_balance_5, t.charge_off
from 
(
select *, 
(select top 1 payment from payments_info_1m p2 where DATEDIFF(month, p2.payment_date,p1.payment_date) = 1 AND p1.loanId = p2.loanId) payment_1,
(select top 1 payment from payments_info_1m p2 where DATEDIFF(month, p2.payment_date,p1.payment_date) = 2 AND p1.loanId = p2.loanId) payment_2,
(select top 1 payment from payments_info_1m p2 where DATEDIFF(month, p2.payment_date,p1.payment_date) = 3 AND p1.loanId = p2.loanId) payment_3,
(select top 1 payment from payments_info_1m p2 where DATEDIFF(month, p2.payment_date,p1.payment_date) = 4 AND p1.loanId = p2.loanId) payment_4,
(select top 1 payment from payments_info_1m p2 where DATEDIFF(month, p2.payment_date,p1.payment_date) = 5 AND p1.loanId = p2.loanId) payment_5,
(select top 1 past_due from payments_info_1m p2 where DATEDIFF(month, p2.payment_date,p1.payment_date) = 1 AND p1.loanId = p2.loanId) past_due_1,
(select top 1 past_due from payments_info_1m p2 where DATEDIFF(month, p2.payment_date,p1.payment_date) = 2 AND p1.loanId = p2.loanId) past_due_2,
(select top 1 past_due from payments_info_1m p2 where DATEDIFF(month, p2.payment_date,p1.payment_date) = 3 AND p1.loanId = p2.loanId) past_due_3,
(select top 1 past_due from payments_info_1m p2 where DATEDIFF(month, p2.payment_date,p1.payment_date) = 4 AND p1.loanId = p2.loanId) past_due_4,
(select top 1 past_due from payments_info_1m p2 where DATEDIFF(month, p2.payment_date,p1.payment_date) = 5 AND p1.loanId = p2.loanId) past_due_5,
(select top 1 remain_balance from payments_info_1m p2 where DATEDIFF(month, p2.payment_date,p1.payment_date) = 1 AND p1.loanId = p2.loanId) remain_balance_1,
(select top 1 remain_balance from payments_info_1m p2 where DATEDIFF(month, p2.payment_date,p1.payment_date) = 2 AND p1.loanId = p2.loanId) remain_balance_2,
(select top 1 remain_balance from payments_info_1m p2 where DATEDIFF(month, p2.payment_date,p1.payment_date) = 3 AND p1.loanId = p2.loanId) remain_balance_3,
(select top 1 remain_balance from payments_info_1m p2 where DATEDIFF(month, p2.payment_date,p1.payment_date) = 4 AND p1.loanId = p2.loanId) remain_balance_4,
(select top 1 remain_balance from payments_info_1m p2 where DATEDIFF(month, p2.payment_date,p1.payment_date) = 5 AND p1.loanId = p2.loanId) remain_balance_5,
(select MAX(charged_off+0) from payments_info_1m p2 where DATEDIFF(month, p1.payment_date,p2.payment_date) IN (1,2,3) AND p1.loanId = p2.loanId) charge_off
from payments_info_1m p1 ) AS t inner join loan_info_1m l ON t.loanId = l.loanId inner join member_info_1m m ON l.memberId = m.memberId 
where t.charge_off IS NOT NULL 
and payment_date > '2017-02-12'
GO

-- persist the view in case of large dataset in order to get faster results

/* Large dataset */
drop table if exists [loan_chargeoff_train_1m]
go

select *
into [loan_chargeoff_train_1m]
from [vw_loan_chargeoff_1m]
go

create clustered columnstore index [cci_loan_chargeoff_train_1m] on [loan_chargeoff_train_1m]
go

drop table if exists [loan_chargeoff_test_1m]
go

select *
into [loan_chargeoff_test_1m]
from [vw_loan_chargeoff_test_1m]
go

create clustered columnstore index [cci_loan_chargeoff_test_1m] on [loan_chargeoff_test_1m]
go

drop table if exists [loan_chargeoff_score_1m]
go

select *
into [loan_chargeoff_score_1m]
from [vw_loan_chargeoff_score_1m]
go

create clustered columnstore index [cci_loan_chargeoff_score_1m] on [loan_chargeoff_score_1m]
go