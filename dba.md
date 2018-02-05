---
layout: default
title: For the Database Analyst
---
<div class="alert alert-success" role="alert"> This page describes the 
<strong>
<span class="cig">{{ site.cig_text }}</span>
<span class="onp">{{ site.onp_text }}</span>
<span class="hdi">{{ site.hdi_text }}</span> 
</strong>
solution.
 {% include choices.md %}
</div> 

## For the Database Analyst - Operationalize with SQL
------------------------------

<div class="row">
    <div class="col-md-6">
        <div class="toc">
          <li><a href="#system-requirements">System Requirements</a></li>
          <li><a href="#workflow-automation">Workflow Automation</a></li>
        <li><a href="#step1">Step 1: Creating Tables</a></li>
        <li><a href="#step2">Step 2: Creating Views with Features and Labels</a></li>
        <li><a href="#step2a">Step 2a (optional): Demonstrate feature selection using MicrosoftML package</a></li>
        <li><a href="#step3">Step 3: Training and Testing Model</a></li>
        <li><a href="#step4">Step 4: Chargeoff Prediction (batch)</a></li>
        <li><a href="#step4a">Step 4a: Chargeoff OnDemand</a></li>
        </div>
    </div>
    <div class="col-md-6">
      SQL Server R Services takes advantage of the power of SQL Server and RevoScaleR (Microsoft R Server package) by allowing R to run on the same server as the database. It includes a database service that runs outside the SQL Server process and communicates securely with the R runtime. This allows the application analyst to use the power of SQL Server to build advanced analytics application.
          </div>
</div>
<p>
With the simulated data and R scripts contained in this solution, application analyst is able to use SQL Server 2017 to evaluate the solution end to end, including the steps needed to deploy machine learning model in SQL Server and consumed by business application. This template deploys a Data Science Virtual Machine (DSVM) that has SQL Server 2017 with Microsoft ML Server installed.
</p>

For businesses that prefer an on-prem solution, the implementation with SQL Server R Services is a great option, which takes advantage of the power of SQL Server and RevoScaleR (Microsoft R Server). In this template, we implemented all steps in SQL stored procedures: data preprocessing, and feature engineering are implemented in pure SQL, while data cleaning, and the model training, scoring and evaluation steps are implemented with SQL stored procedures calling R (Microsoft R Server) code.

All the steps can be executed on SQL Server client environment (SQL Server Management Studio). We provide a Windows PowerShell script which invokes the SQL scripts and demonstrates the end-to-end modeling process.

## System Requirements
-----------------------

The following are required to run the scripts in this solution:
<ul>
<li>SQL Server (2016 or higher) with Microsoft R Server  (version 9.1.0) installed and configured.  </li>   
<li>The SQL user name and password, and the user configured properly to execute R scripts in-memory.</li> 
<li>SQL Database which the user has write permission and execute stored procedures.</li> 
<li>For more information about SQL server and R service, please visit: <a href="https://msdn.microsoft.com/en-us/library/mt604847.aspx">https://msdn.microsoft.com/en-us/library/mt604847.aspx</a></li> 
</ul>
</ul>


## Workflow Automation
-------------------
Follow the [PowerShell instructions](Powershell_Instructions.html) to execute all the scripts described below.  [Click here](tables.html) to view the details all tables created in this solution.

 
<a name="step1">

## Step 1: Creating Tables
--------------------------


The following data are provided in the <strong>D:\LoanChargeOffSolution\Data</strong> directory:

 {% include data.md %}

In this step, we create six tables: member_info_10k, loan_info_10k, payment_info_10k, loan_chargeoff_models_10k, selected_features_10k and loan_chargeoff_prediction_10k in a SQL Server database, and the data is uploaded to these tables using bcp command in the PowerShell script.

### Input:

* Raw data:  **loan_info_10k.csv**, **member_info_10k.csv**, and **payments_info_10k.csv**

### Output:

* 6 Tables filled with the raw data: `member_info_10k`, `loan_info_10k`, `payment_info_10k`, `loan_chargeoff_models_10k`, `selected_features_10k` and `loan_chargeoff_prediction_10k`. In order for them to be filled with the data, power shell script named `Loan_ChargeOff.ps1` should be run

### Related files:

* step1_create_tables.sql

<a name="step2">

## Step 2: Creating Views with Features and Labels
----------------------------------------

In this step, we create 3 views for training, testing, and scoring by selecting features and assign with labels from `payments_info` and joined with `loan_info` and `member_info` table using payment_date as the criterion. 

<table class="table table-compressed table-striped">
  <tr>
    <th>Views</th>
    <th>Description</th>
  </tr>
  <tr>
    <td>vw_loan_chargeoff_train_10k</td>
    <td>For training, we select features from the table joints with payment date between '2016-09-12' and '2016-12-12' and charge_off status = 1 or (payment_date = '2017-01-12')</td>
  </tr>
  <tr>
    <td>vw_loan_chargeoff_test_10k</td>
    <td>For testing, we create view from the joined tables with payment date = '2017-02-12'</td>
  </tr>
  <tr>
    <td>vw_loan_chargeoff_score_10k</td>
    <td>For scoring, we create view from the joined tables with the payment date > '2017-02-12'</td>
  </tr>
</table>

These three views will get persisted in tables to get faster scoring results.

### Input:

* 3 Tables filled with the raw data: `member_info_10k`, `loan_info_10k`, `payment_info_10k`

### Output:

* 3 Views created: `vw_loan_chargeoff_train_10k`, `vw_loan_chargeoff_test_10k` and `vw_loan_chargeoff_score_10k`
* 3 tables created: `loan_chargeoff_train_10k`, `loan_chargeoff_test_10k` and `loan_chargeoff_score_10k`

### Related files:
* step2_features_label_view.sql

<a name="step2a">

## Step 2a (optional): Demonstrate feature selection using MicrosoftML package 
-------------------------------

In this step, we create a table `[dbo].[selected_features]` that stores the feature names from feature selection using MicrosoftML package:
* Select features from training_set
* Remove biased features like memberId, loanId, payment_date, loan_open_date and charge_off
* Demonstrate feature selection using logistic regression model 
* Store selected features in a table.

### Input:

* Enter [Training_set_table] as parameter
* Enter [Test_set_table] as parameter
* Enter [selected_features_table] as parameter
* Enter [connectionString] as parameter

### Output:

* `Selected_features_10k` table containing features that are selected by applying categorical and selectFeatures transforms from MicrosoftML package.

### Related files:

* Loan_ChargeOff.ps1
* step2a_optional_feature_selection.sql

<a name="step3">

## Step 3: Training and Testing Model
---------------------------

In this step, we create a stored procedure for training of models using MicrosoftML algorithms. This also evaluates the models and stores the model stats along with serialized model binary, accuracy, auc, precision, recall, f1score. We will be using 5 algorithms to train :

* rxLogisticRegression
* rxFastTrees
* rxFastForest
* rxFastLinear
* rxNeuralNet

The performance result from each of this model will get stored in `Loan_chargeoff_models_10k` table.

### Input:

* `Loan_chargeoff_train_10k` table.

### Output:

* `Loan_chargeoff_models_10k` table containing model name, auc, accuracy, precision, recall and f1score

### Related files:

* step3_train_test_model.sql

<a name="step3a">

## Step 4: Chargeoff Prediction (batch)
-----------------------------------

In this step, we create a stored procedure `[dbo].[chargeoff_batch_prediction]` that do scoring using best model on the data split created in Step 2 and store the predictions in `[dbo].[loan_chargeoff_prediction_10k]`  table.

### Input:

* `loan_chargeoff_score_10k` table

### Output:

* `[dbo].[loan_chargeoff_prediction_10k]` table

### Related files:

* Chargeoff_batch_prediction.sql

<a name="step3b">

## Step 4a: Chargeoff OnDemand
----------------------

In this step, the business application can call this stored procedure for adhoc scoring scenario. `predict_chargeoff_ondemand` stored procedure is created for ad-hoc scoring wherein it can be called with a single record and a single prediction result is returned to the caller.

### Input:

* Please see input parameters in `predict_chargeoff_ondemand` stored procedure

### Output:

* `LoanId, Payment_date, predicatedLabel, Score.1, Probability.1` table containing the RF and GBT trained models. 

### Related files:

* Predict_chargeoff_ondemand.sql