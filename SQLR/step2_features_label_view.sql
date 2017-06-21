/*
 * SQL script to create views with feature and label columns for training, testing and prediction.
 * We also persist these views to physical tables for faster training/scoring times. 
 * If there is not much data these views can be used directly.
 * $(datasize) is substituted through Invoke-SqlCmd's Variable option
 * (in powershell).
 */
-- View over the underlying table for features and labels required
drop view if exists vw_loan_chargeoff_train_$(datasize)
go
create view vw_loan_chargeoff_train_$(datasize)
as
select t.loanId, t.payment_date, t.payment, t.past_due, t.remain_balance,
  l.loan_open_date, l.loanAmount,l.interestRate,l.grade,l.term,l.installment,l.isJointApplication,l.purpose,
  m.memberId,m.residentialState,m.branch,m.annualIncome,m.yearsEmployment,m.homeOwnership,m.incomeVerified,m.creditScore,m.dtiRatio,m.revolvingBalance,m.revolvingUtilizationRate,m.numDelinquency2Years,m.numDerogatoryRec,m.numInquiries6Mon,m.lengthCreditHistory,m.numOpenCreditLines,m.numTotalCreditLines,m.numChargeoff1year,
  ISNULL(t.payment_1, 0) payment_1,ISNULL(t.payment_2, 0) payment_2,ISNULL(t.payment_3, 0) payment_3,ISNULL(t.payment_4, 0) payment_4,ISNULL(t.payment_5, 0) payment_5, 
  ISNULL(t.past_due_1, 0) past_due_1,ISNULL(t.past_due_2, 0) past_due_2,ISNULL(t.past_due_3, 0) past_due_3,ISNULL(t.past_due_4, 0) past_due_4,ISNULL(t.past_due_5, 0) past_due_5,
  ISNULL(t.remain_balance_1, 0) remain_balance_1,ISNULL(t.remain_balance_2, 0) remain_balance_2,ISNULL(t.remain_balance_3, 0) remain_balance_3,ISNULL(t.remain_balance_4, 0) remain_balance_4,ISNULL(t.remain_balance_5, 0) remain_balance_5, t.charge_off
from 
(
select *, 
(select top 1 payment from payments_info_$(datasize) p2 where DATEDIFF(month, p2.payment_date,p1.payment_date) = 1 AND p1.loanId = p2.loanId) payment_1,
(select top 1 payment from payments_info_$(datasize) p2 where DATEDIFF(month, p2.payment_date,p1.payment_date) = 2 AND p1.loanId = p2.loanId) payment_2,
(select top 1 payment from payments_info_$(datasize) p2 where DATEDIFF(month, p2.payment_date,p1.payment_date) = 3 AND p1.loanId = p2.loanId) payment_3,
(select top 1 payment from payments_info_$(datasize) p2 where DATEDIFF(month, p2.payment_date,p1.payment_date) = 4 AND p1.loanId = p2.loanId) payment_4,
(select top 1 payment from payments_info_$(datasize) p2 where DATEDIFF(month, p2.payment_date,p1.payment_date) = 5 AND p1.loanId = p2.loanId) payment_5,
(select top 1 past_due from payments_info_$(datasize) p2 where DATEDIFF(month, p2.payment_date,p1.payment_date) = 1 AND p1.loanId = p2.loanId) past_due_1,
(select top 1 past_due from payments_info_$(datasize) p2 where DATEDIFF(month, p2.payment_date,p1.payment_date) = 2 AND p1.loanId = p2.loanId) past_due_2,
(select top 1 past_due from payments_info_$(datasize) p2 where DATEDIFF(month, p2.payment_date,p1.payment_date) = 3 AND p1.loanId = p2.loanId) past_due_3,
(select top 1 past_due from payments_info_$(datasize) p2 where DATEDIFF(month, p2.payment_date,p1.payment_date) = 4 AND p1.loanId = p2.loanId) past_due_4,
(select top 1 past_due from payments_info_$(datasize) p2 where DATEDIFF(month, p2.payment_date,p1.payment_date) = 5 AND p1.loanId = p2.loanId) past_due_5,
(select top 1 remain_balance from payments_info_$(datasize) p2 where DATEDIFF(month, p2.payment_date,p1.payment_date) = 1 AND p1.loanId = p2.loanId) remain_balance_1,
(select top 1 remain_balance from payments_info_$(datasize) p2 where DATEDIFF(month, p2.payment_date,p1.payment_date) = 2 AND p1.loanId = p2.loanId) remain_balance_2,
(select top 1 remain_balance from payments_info_$(datasize) p2 where DATEDIFF(month, p2.payment_date,p1.payment_date) = 3 AND p1.loanId = p2.loanId) remain_balance_3,
(select top 1 remain_balance from payments_info_$(datasize) p2 where DATEDIFF(month, p2.payment_date,p1.payment_date) = 4 AND p1.loanId = p2.loanId) remain_balance_4,
(select top 1 remain_balance from payments_info_$(datasize) p2 where DATEDIFF(month, p2.payment_date,p1.payment_date) = 5 AND p1.loanId = p2.loanId) remain_balance_5,
(select MAX(charged_off+0) from payments_info_$(datasize) p2 where DATEDIFF(month, p1.payment_date,p2.payment_date) IN (1,2,3) AND p1.loanId = p2.loanId) charge_off
from payments_info_$(datasize) p1 ) AS t inner join loan_info_$(datasize) l ON t.loanId = l.loanId inner join member_info_$(datasize) m ON l.memberId = m.memberId 
where t.charge_off IS NOT NULL
and ((payment_date between '2016-09-12' and '2016-12-12' and charge_off = 1) or (payment_date = '2017-01-12'));
go

drop view if exists vw_loan_chargeoff_test_$(datasize)
go
create view vw_loan_chargeoff_test_$(datasize)
as
select t.loanId, t.payment_date, t.payment, t.past_due, t.remain_balance,
  l.loan_open_date, l.loanAmount,l.interestRate,l.grade,l.term,l.installment,l.isJointApplication,l.purpose,
  m.memberId,m.residentialState,m.branch,m.annualIncome,m.yearsEmployment,m.homeOwnership,m.incomeVerified,m.creditScore,m.dtiRatio,m.revolvingBalance,m.revolvingUtilizationRate,m.numDelinquency2Years,m.numDerogatoryRec,m.numInquiries6Mon,m.lengthCreditHistory,m.numOpenCreditLines,m.numTotalCreditLines,m.numChargeoff1year,
  ISNULL(t.payment_1, 0) payment_1,ISNULL(t.payment_2, 0) payment_2,ISNULL(t.payment_3, 0) payment_3,ISNULL(t.payment_4, 0) payment_4,ISNULL(t.payment_5, 0) payment_5, 
  ISNULL(t.past_due_1, 0) past_due_1,ISNULL(t.past_due_2, 0) past_due_2,ISNULL(t.past_due_3, 0) past_due_3,ISNULL(t.past_due_4, 0) past_due_4,ISNULL(t.past_due_5, 0) past_due_5,
  ISNULL(t.remain_balance_1, 0) remain_balance_1,ISNULL(t.remain_balance_2, 0) remain_balance_2,ISNULL(t.remain_balance_3, 0) remain_balance_3,ISNULL(t.remain_balance_4, 0) remain_balance_4,ISNULL(t.remain_balance_5, 0) remain_balance_5, t.charge_off
from 
(
select *, 
(select top 1 payment from payments_info_$(datasize) p2 where DATEDIFF(month, p2.payment_date,p1.payment_date) = 1 AND p1.loanId = p2.loanId) payment_1,
(select top 1 payment from payments_info_$(datasize) p2 where DATEDIFF(month, p2.payment_date,p1.payment_date) = 2 AND p1.loanId = p2.loanId) payment_2,
(select top 1 payment from payments_info_$(datasize) p2 where DATEDIFF(month, p2.payment_date,p1.payment_date) = 3 AND p1.loanId = p2.loanId) payment_3,
(select top 1 payment from payments_info_$(datasize) p2 where DATEDIFF(month, p2.payment_date,p1.payment_date) = 4 AND p1.loanId = p2.loanId) payment_4,
(select top 1 payment from payments_info_$(datasize) p2 where DATEDIFF(month, p2.payment_date,p1.payment_date) = 5 AND p1.loanId = p2.loanId) payment_5,
(select top 1 past_due from payments_info_$(datasize) p2 where DATEDIFF(month, p2.payment_date,p1.payment_date) = 1 AND p1.loanId = p2.loanId) past_due_1,
(select top 1 past_due from payments_info_$(datasize) p2 where DATEDIFF(month, p2.payment_date,p1.payment_date) = 2 AND p1.loanId = p2.loanId) past_due_2,
(select top 1 past_due from payments_info_$(datasize) p2 where DATEDIFF(month, p2.payment_date,p1.payment_date) = 3 AND p1.loanId = p2.loanId) past_due_3,
(select top 1 past_due from payments_info_$(datasize) p2 where DATEDIFF(month, p2.payment_date,p1.payment_date) = 4 AND p1.loanId = p2.loanId) past_due_4,
(select top 1 past_due from payments_info_$(datasize) p2 where DATEDIFF(month, p2.payment_date,p1.payment_date) = 5 AND p1.loanId = p2.loanId) past_due_5,
(select top 1 remain_balance from payments_info_$(datasize) p2 where DATEDIFF(month, p2.payment_date,p1.payment_date) = 1 AND p1.loanId = p2.loanId) remain_balance_1,
(select top 1 remain_balance from payments_info_$(datasize) p2 where DATEDIFF(month, p2.payment_date,p1.payment_date) = 2 AND p1.loanId = p2.loanId) remain_balance_2,
(select top 1 remain_balance from payments_info_$(datasize) p2 where DATEDIFF(month, p2.payment_date,p1.payment_date) = 3 AND p1.loanId = p2.loanId) remain_balance_3,
(select top 1 remain_balance from payments_info_$(datasize) p2 where DATEDIFF(month, p2.payment_date,p1.payment_date) = 4 AND p1.loanId = p2.loanId) remain_balance_4,
(select top 1 remain_balance from payments_info_$(datasize) p2 where DATEDIFF(month, p2.payment_date,p1.payment_date) = 5 AND p1.loanId = p2.loanId) remain_balance_5,
(select MAX(charged_off+0) from payments_info_$(datasize) p2 where DATEDIFF(month, p1.payment_date,p2.payment_date) IN (1,2,3) AND p1.loanId = p2.loanId) charge_off
from payments_info_$(datasize) p1 ) AS t inner join loan_info_$(datasize) l ON t.loanId = l.loanId inner join member_info_$(datasize) m ON l.memberId = m.memberId 
where t.charge_off IS NOT NULL
and payment_date = '2017-02-12';
go

drop view if exists vw_loan_chargeoff_score_$(datasize)
go
create view vw_loan_chargeoff_score_$(datasize)
as
select t.loanId, t.payment_date, t.payment, t.past_due, t.remain_balance,
  l.loan_open_date, l.loanAmount,l.interestRate,l.grade,l.term,l.installment,l.isJointApplication,l.purpose,
  m.memberId,m.residentialState,m.branch,m.annualIncome,m.yearsEmployment,m.homeOwnership,m.incomeVerified,m.creditScore,m.dtiRatio,m.revolvingBalance,m.revolvingUtilizationRate,m.numDelinquency2Years,m.numDerogatoryRec,m.numInquiries6Mon,m.lengthCreditHistory,m.numOpenCreditLines,m.numTotalCreditLines,m.numChargeoff1year,
  ISNULL(t.payment_1, 0) payment_1,ISNULL(t.payment_2, 0) payment_2,ISNULL(t.payment_3, 0) payment_3,ISNULL(t.payment_4, 0) payment_4,ISNULL(t.payment_5, 0) payment_5, 
  ISNULL(t.past_due_1, 0) past_due_1,ISNULL(t.past_due_2, 0) past_due_2,ISNULL(t.past_due_3, 0) past_due_3,ISNULL(t.past_due_4, 0) past_due_4,ISNULL(t.past_due_5, 0) past_due_5,
  ISNULL(t.remain_balance_1, 0) remain_balance_1,ISNULL(t.remain_balance_2, 0) remain_balance_2,ISNULL(t.remain_balance_3, 0) remain_balance_3,ISNULL(t.remain_balance_4, 0) remain_balance_4,ISNULL(t.remain_balance_5, 0) remain_balance_5
from 
(
select *, 
(select top 1 payment from payments_info_$(datasize) p2 where DATEDIFF(month, p2.payment_date,p1.payment_date) = 1 AND p1.loanId = p2.loanId) payment_1,
(select top 1 payment from payments_info_$(datasize) p2 where DATEDIFF(month, p2.payment_date,p1.payment_date) = 2 AND p1.loanId = p2.loanId) payment_2,
(select top 1 payment from payments_info_$(datasize) p2 where DATEDIFF(month, p2.payment_date,p1.payment_date) = 3 AND p1.loanId = p2.loanId) payment_3,
(select top 1 payment from payments_info_$(datasize) p2 where DATEDIFF(month, p2.payment_date,p1.payment_date) = 4 AND p1.loanId = p2.loanId) payment_4,
(select top 1 payment from payments_info_$(datasize) p2 where DATEDIFF(month, p2.payment_date,p1.payment_date) = 5 AND p1.loanId = p2.loanId) payment_5,
(select top 1 past_due from payments_info_$(datasize) p2 where DATEDIFF(month, p2.payment_date,p1.payment_date) = 1 AND p1.loanId = p2.loanId) past_due_1,
(select top 1 past_due from payments_info_$(datasize) p2 where DATEDIFF(month, p2.payment_date,p1.payment_date) = 2 AND p1.loanId = p2.loanId) past_due_2,
(select top 1 past_due from payments_info_$(datasize) p2 where DATEDIFF(month, p2.payment_date,p1.payment_date) = 3 AND p1.loanId = p2.loanId) past_due_3,
(select top 1 past_due from payments_info_$(datasize) p2 where DATEDIFF(month, p2.payment_date,p1.payment_date) = 4 AND p1.loanId = p2.loanId) past_due_4,
(select top 1 past_due from payments_info_$(datasize) p2 where DATEDIFF(month, p2.payment_date,p1.payment_date) = 5 AND p1.loanId = p2.loanId) past_due_5,
(select top 1 remain_balance from payments_info_$(datasize) p2 where DATEDIFF(month, p2.payment_date,p1.payment_date) = 1 AND p1.loanId = p2.loanId) remain_balance_1,
(select top 1 remain_balance from payments_info_$(datasize) p2 where DATEDIFF(month, p2.payment_date,p1.payment_date) = 2 AND p1.loanId = p2.loanId) remain_balance_2,
(select top 1 remain_balance from payments_info_$(datasize) p2 where DATEDIFF(month, p2.payment_date,p1.payment_date) = 3 AND p1.loanId = p2.loanId) remain_balance_3,
(select top 1 remain_balance from payments_info_$(datasize) p2 where DATEDIFF(month, p2.payment_date,p1.payment_date) = 4 AND p1.loanId = p2.loanId) remain_balance_4,
(select top 1 remain_balance from payments_info_$(datasize) p2 where DATEDIFF(month, p2.payment_date,p1.payment_date) = 5 AND p1.loanId = p2.loanId) remain_balance_5
from payments_info_$(datasize) p1 ) AS t inner join loan_info_$(datasize) l ON t.loanId = l.loanId inner join member_info_$(datasize) m ON l.memberId = m.memberId 
where payment_date > '2017-02-12';
go


-- persist the view in case of large dataset in order to get faster results
drop table if exists [loan_chargeoff_train_$(datasize)]
go

select *
into [loan_chargeoff_train_$(datasize)]
from [vw_loan_chargeoff_train_$(datasize)]
go

create clustered columnstore index [cci_loan_chargeoff_train_$(datasize)] on [loan_chargeoff_train_$(datasize)]
go

drop table if exists [loan_chargeoff_test_$(datasize)]
go

select *
into [loan_chargeoff_test_$(datasize)]
from [vw_loan_chargeoff_test_$(datasize)]
go

create clustered columnstore index [cci_loan_chargeoff_test_$(datasize)] on [loan_chargeoff_test_$(datasize)]
go

drop table if exists [loan_chargeoff_score_$(datasize)]
go

select *
into [loan_chargeoff_score_$(datasize)]
from [vw_loan_chargeoff_score_$(datasize)]
go

create clustered columnstore index [cci_loan_chargeoff_score_$(datasize)] on [loan_chargeoff_score_$(datasize)]
go
