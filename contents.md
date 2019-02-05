---
layout: default
title: Template Contents
---

## Template Contents
--------------------

The following is the directory structure for this template:

- [**Data**](#copy-of-input-datasets)  This contains the copy of the simulated input data with 100K unique customers.
- [**R**](#model-development-in-r)  This contains the R code to simulate the input datasets, pre-process them, create the analytical datasets, train the models, identify the champion model and provide predictions.
- [**SQLR**](#operationalize-in-sql) This contains T-SQL code to pre-process the datasets, train the models, identify the champion model and provide predictions. It also contains a PowerShell script to automate the entire process, including loading the data into the database (not included in the T-SQL code).
- [**HDI**](#hdinsight-solution-on-spark-cluster) This contains the R code to pre-process the datasets, train the models, identify the champion model and provide predictions on a Spark cluster. 

In this template with SQL Server ML Services, two versions of the SQL implementation and another version for HDInsight implementation:

1. [**Model Development in R IDE**](#model-development-in-r)  . Run the R code in R IDE (e.g., RStudio, R Tools for Visual Studio).
2. [**Operationalize in SQL**](#operationalize-in-sql). Run the SQL code in SQL Server using SQLR scripts from SSMS or from the PowerShell script.
3. [**HDInsight Solution on Spark Cluster**](#hdinsight-solution-on-spark-cluster).  Run this R code in RStudio on the edge node of the Spark cluster.


### Copy of Input Datasets
----------------------------

<div class="sql">
<table class="table table-compressed table-striped">
  <tr>
    <th>File</th>
    <th>Description</th>
  </tr>
  <tr>
    <td>loan_info.csv</td>
    <td>Raw data about each loan of a lending institution</td>
  </tr>
  <tr>
    <td>member_info.csv</td>
    <td>Raw data about each member of a lending institution</td>
  </tr>
  <tr>
    <td>payments_info.csv</td>
    <td>Raw data about loan payment history</td>
  </tr>
</table>
</div>

<div class="hdi">
<table class="table table-compressed table-striped">
  <tr>
    <th>File</th>
    <th>Description</th>
  </tr>
  <tr>
    <td>Loan_Data1000.csv</td>
    <td>Raw data about loan payment history for 1000 members</td>
  </tr>
  <tr>
    <td>Loan_Data10000.csv</td>
    <td>Raw data about loan payment history for 10000 members</td>
  </tr>
  <tr>
    <td>Loan_Data100000.csv</td>
    <td>Raw data about loan payment history for 100000 members</td>
  </tr>
</table>
</div>

###  Model Development in R
-------------------------
These files  in the **SQLR* directory for the SQL solution.  

<table class="table table-striped table-condensed">
<tr><th> File </th><th> Description </th></tr>
<tr><td>step2a_optional_feature_selection.sql </td><td>R script that performs feature selection</td></tr>
<tr><td>step3_train_test_model.sql</td><td>R script that performs data training using 5 different models and select the best performant model and do testing using the model</td></tr>
</table>

* See [For the Data Scientist](data-scientist.html?path=cig) for more details about these files.
* See [Typical Workflow](Typical.html?path=cig)  for more information about executing these scripts.

### Operationalize in SQL 
-------------------------------------------------------

These files are in the **SQLR** directory.

<table class="table table-striped table-condensed">
<tr><th> File </th><th> Description </th></tr>
<tr><td> step4_chargeoff_batch_prediction.sql  </td><td>R script that performs scoring using best model on the data split created in Step 2 and store the predictions in [dbo].[loan_chargeoff_prediction_10k]  table.</td></tr>
<tr><td> step4a_chargeoff_ondemand_prediction.sql   </td><td> chargeoff_ondemand_prediction stored procedure is created for ad-hoc scoring wherein it can be called with a single record and a single prediction result is returned to the caller. </td></tr>
<tr><td> Loan_chargeoff.ps1  </td><td> Loads the input data into the SQL server and automates the running of all .sql files </td></tr>
</table>

* See [ For the Database Analyst](dba.html?path=cig) for more information about these files.
* Follow the [PowerShell Instructions](Powershell_Instructions.html?path=cig) to execute the PowerShell script which automates the running of all these .sql files.


### HDInsight Solution on Spark Cluster
------------------------------------
These files are in the **HDI/RSparkCluster** directory.

<table class="table table-striped table-condensed">
<tr><th> File </th><th> Description </th></tr>
<tr><td>Copy_Dev2Prod.R </td><td> Copies a model from the <strong>dev</strong> folder to the <strong>prod</strong> folder for production use </td></tr>
<tr><td>loanchargeoff_main.R </td><td> is used to define the data and directories and then run all of the steps to process data, perform feature engineering, training, and scoring. </td></tr>
<tr><td>loanchargeoff_scoring.R</td><td>uses the previously trained model and invokes the steps to process data, perform feature engineering and scoring.</td></tr>
<tr><td>loanchargeoff_deployment.R </td><td> create a web service and test it on the edge node </td></tr>
<tr><td>loanchargeoff_web_scoring.R </td><td> access the web service on any computer with Microsoft ML Server installed</td></tr>
<tr><td>loan_main.R</td><td> Main R script that executes the rest of the R scripts </td></tr>
<tr><td>loan_scoring.R </td><td> Perform loan scoring using the model with the best performance  </td></tr>
<tr><td>step1_get_training_testing_data.R  </td><td> Read input data which contains all the history information for all the loans from HDFS. Extract training/testing data based on process date (paydate) from the input data. </td></tr>
<tr><td>step2_feature_engineering.R </td><td> Use MicrosoftML to do feature selection. Code can be added in this file to create some new features based on existing features. Open source package such as Caret can also be used to do feature selection here. Best features are selected using AUC.  </td></tr>
<tr><td>step3_training_evaluation.R </td><td> This script trains five different models and evaluate each. </td></tr>
<tr><td>step4_prepare_new_data.R </td><td>This script creates a new data which contains all the opened loans on a pay date which we do not know the status in next three month, the loans in this new data are not included in the training and testing dataset and have the same features as the loans used in training/testing dataset. </td></tr>
<tr><td>step5_loan_prediction.R </td><td>This script takes the new data created in the step4 and the champion model created in step3, output the predicted label and probability to be charge-off for each loan in next three months.</td></tr>
</table>

* See [For the Data Scientist](data-scientist.html?path=hdi) for more details about these files.
* See [Typical Workflow](Typical.html?path=hdi)  for more information about executing these scripts.


[&lt; Home](index.html)
