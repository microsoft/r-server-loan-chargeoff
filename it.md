---
layout: default
title: For the IT Administrator
---
<div class="alert alert-success" role="alert"> This page describes the 
<strong>
{{ site.hdi_text }}
</strong>
solution.
</div> 

## For the IT Administrator
------------------------------

<div class="row">
    <div class="col-md-6">
        <div class="toc">
          <li><a href="#system-requirements">System Requirements</a></li>
          <li><a href="#step1">Cluster Maintenance</a></li>
          <li><a href="#workflow-automation">Workflow Automation</a></li>
        <li><a href="#step0">Data</a></li>
        </div>
    </div>
    <div class="col-md-6">
      As lending institutions are starting to acknowledge the power of data, leveraging machine learning techniques to grow has become a must. In particular, lending institutions can learn payment patterns from their data to intelligently predict loan charge off risk.
          </div>
</div>
<p>
Among the key variables to learn from data are the loan payments, past due and remaining balance through which a given loan can be predicted as a potential charge off. This template provides a lending institution with an analytics tool that helps predict the likelihood of loans getting charged off and run a report on the analytics result stored in HDFS and hive tables. 
</p>

While this solution demonstrates the code with 100,000 loans for developing the model, using HDInsight Spark clusters makes it simple to extend to large data, both for training and scoring. The only thing that changes is the size of the data and the number of clusters; the code remains exactly the same.

## System Requirements
-----------------------

This solution uses:

 * [ML Server for HDInsight](https://azure.microsoft.com/en-us/services/hdinsight/r-server/)


## Cluster Maintenance
--------------------------

HDInsight Spark cluster billing starts once a cluster is created and stops when the cluster is deleted. <strong>See <a href="hdinsight.html"> these instructions for important information</a> about deleting a cluster and re-using your files on a new cluster. </strong>


## Workflow Automation
-------------------
Access RStudio on the cluster edge node by using the url of the form `http://CLUSTERNAME.azurehdinsight.net/rstudio`  Run the script **loanchargeoff_main.R** to perform all the steps of the solution.

 
<a name="step0">
## Data Files
--------------

The following data files are available in the **LoanChargeOff/Data** directory in the storage account associated with the cluster:

 <table class="table table-compressed table-striped">
  <tr>
    <th>File</th>
    <th>Description</th>
  </tr>
  <tr>
    <td>Loan_Data1000.csv</td>
    <td>Raw data about loan payments for 1000 members</td>
  </tr>
  <tr>
    <td>Loan_Data10000.csv</td>
    <td>Raw data about loan payments for 10000 members</td>
  </tr>
  <tr>
    <td>Loan_Data100000.csv</td>
    <td>Raw data about loan payments for 100000 members</td>
  </tr>
</table>
<a name="step1">