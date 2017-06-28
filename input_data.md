---
layout: default
title: Input Data
---

 
## CSV File Description
--------------------------

There are three input files used in this solution. They are:

* [loan_info.csv](#loan-info)
* [member_info.csv](#member-info)
* [payment_info.csv](#payment-info)

See each section below for a description of the data fields for each file.

<h3 id="loan-info">loan_info.csv</h3>
			
This file contains data about each loan that occurred in the past three years

<table class="table table-striped table-condensed">
<tr><th>Index</th><th>Data Field</th><th>Description</th></tr>
<tr><td>1</td><td>	loanId</td><td>Unique Id of the loan </td></tr>
<tr><td>2</td><td>	loan_open_date</td><td>Date when the loan is opened</td></tr>
<tr><td>3</td><td>	memberId</td><td>Unique Id of member of the banking institution</td></tr>
<tr><td>4</td><td>	loanAmount</td><td>Amount of loan</td></tr>
<tr><td>5</td><td>	interestRate</td><td>Interest rate that applies to the loan</td></tr>
<tr><td>6</td><td>	grade</td><td>Quality of the asset associated in the loan e.g. 1,2,3. The higher the number, the higher quality of the asset</td></tr>
<tr><td>7</td><td>	term</td><td>Time period of the loan</td></tr>
<tr><td>8</td><td>	installment</td><td>Installment amount for the loan</td></tr>
<tr><td>9</td><td>	isJointApplication</td><td>Is this a jointed loan application. 0 is No, 1 is Yes</td></tr>
<tr><td>10</td><td>	purpose</td><td>Loan type or loan purpose e.g. auto, debt consolidation, business etc</td></tr>
</table>

<h3 id="member-info">member_info.csv	</h3>

This file contains demographics and financial data about each customer.
<table class="table table-striped table-condensed">
<tr><th>Index</th><th>Data Field</th><th>Description</th></tr>
<tr><td>1</td><td>	memberId</td><td>Unique Id of the member of the lending institution</td></tr>
<tr><td>2</td><td>	residentialState</td><td>State of the member where he/she resides in</td></tr>
<tr><td>3</td><td>	Branch</td><td>Lending institution branch</td></tr>
<tr><td>4</td><td>	annualIncome</td><td>Average annual income of the member</td></tr>
<tr><td>5</td><td>  yearsEmployment</td><td>Number of years the member is employed</td></tr>
<tr><td>6</td><td>  homeOwnership</td><td>Type of home ownership e.g. own, mortgage, rent</td></tr>
<tr><td>7</td><td>	incomeVerified</td><td>Has the debt holder income been verified by the lending institution e.g. 0 is No, 1 is Yes</td></tr>
<tr><td>8</td><td>	creditScore</td><td>Average credit score of the debt holder</td></tr>
<tr><td>9</td><td>	dtiRatio</td><td>Debt to income ratio</td></tr>
<tr><td>10</td><td>	revolvingBalance</td><td>Portion of the debt that is unpaid</td></tr>
<tr><td>11</td><td>	revolvingUtilizationRate</td><td>Measures the amount of revolving credit limits that debt holder is using</td></tr>
<tr><td>12</td><td>	numDelinquency2Years</td><td>Number of times that loan payment is late in the last 2 years</td></tr>
<tr><td>13</td><td>	numDerogatoryRec</td><td>Public records that are often result from an unpaid bill or financial obligation</td></tr>
<tr><td>14</td><td>	numInquiries6Mon</td><td>Number of loan history inquiries in the last 6 months</td></tr>
<tr><td>15</td><td>	lengthCreditHistory</td><td>Number of months with the current credit score</td></tr>
<tr><td>16</td><td>	numOpenCreditLines</td><td>Number of line of credits that the debt holder has</td></tr>
<tr><td>17</td><td>	numChargeoff1year</td><td>Number of chargeoff by bank on the loan owned by this member</td></tr>
</table>

<h3 id="payment-info">payment_info.csv</h3>

This file contains data about payment and payment history of a loan

<table class="table table-striped table-condensed">
<tr><th>Index</th><th>Data Field</th><th>Description</th></tr>
<tr><td>1</td><td>loanId</td><td>Unique Id of the loan</td></tr>
<tr><td>2</td><td>date</td><td>Date when the payment is made</td></tr>
<tr><td>3</td><td>Payment</td><td>Payment amount</td></tr>
<tr><td>4</td><td>Past_due</td><td>If the payment is past due e.g. 0 is No, 1 is Yes</td></tr>
<tr><td>5</td><td>Remain_balance</td><td>Remaining of the loan balance</td></tr>
<tr><td>6</td><td>Closed</td><td>If the loan is closed (paid off) e.g. 0 is No, 1 is Yes</td></tr>
<tr><td>7</td><td>Charged_off</td><td>If the loan is chargeoff e.g. 0 is No, 1 is Yes</td></tr>
</table>