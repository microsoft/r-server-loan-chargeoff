---
layout: default
title: For the Business Manager
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

## For the Business Manager
------------------------------

This loan chargeoff prediction uses a simulated loan history data to predict probability of loan chargeoff in the immediate future (next three months). The higher the score, the higher is the probability of the loan getting charged-off in the future. To simplify data analysis, the loan chargeoff probability scores are grouped into High, Medium and Low categories so that loan managers can make actionable decision to offer personalized incentive to loan holders.

Loan manager is also presented with the trends and analysis of the chargeoff loans by branch locations. Characteristics of the loans that are highly probable of getting chargedoff have lower credit score for example will help loan managers to make a business plan for loan offering in that geographical area.   

<div class="sql"> 
SQL Server R Services brings the compute to the data by allowing R to run on the same computer as the database. It includes a database service that runs outside the SQL Server process and communicates securely with the R runtime.

This solution template walks through how to create and clean up a set of simulated data, use various algorithms to train the R models, select the best performant model and perform chargeoff predictions and save the prediction results back to SQL Server. A PowerBI report connects to the prediction result table and show interactive reports with the user on the predictive analytics.
</div>

<div class="hdi">
Microsoft R Server on HDInsight Spark clusters provides distributed and scalable machine learning capabilities for big data, leveraging the combined power of R Server and Apache Spark. This solution demonstrates how to develop machine learning models for Loan ChargeOff Prediction (including data processing, feature engineering, training and evaluating models), deploy the models as a web service (on the edge node) and consume the web service remotely with Microsoft R Server on Azure HDInsight Spark clusters.

The final predictions are saved to a Hive table containing loan chargeoff predictions. This data is then visualized in Power BI.
</div>


![Visualize](images/visualize1.png?raw=true)
![Visualize](images/visualize2.png?raw=true)

{% include pbix.md %}

There are two tabs in the PowerBI report: (1) Loan summary tab which shows the overall loan information across different states and branches in U.S. and (2) Chargeoff risk which shows chargeoff probability in loans for loan officer to take action on.

For this specific lending institution, the loan summary tab shows the loan profiles which include information like loan types, number of loans, loan amount and charged off count. Report user can use the location map to further drill down to state and branch level and the time slider to analyze historical loan profiles. 

The charge off forecast tab displays the probability of loan getting charge off in the next three months. Loan officer can further drill down into each state and branch locations to evaluate loans which have highest probability of getting charged off and their respective probability scores. High level loan holder information is also available in the report. Information like loan interest rate, loan amount, debt to income ratio, and number of delinquent payments. Loan officer can further formulate action plan to prevent loan from charging off by looking up detailed loan profile in their business application and offer personalized incentive plan to the borrower.

To understand more about the entire process of modeling and deploying this example, see [For the Data Scientist](data-scientist.html).
 
[&lt; Home](index.html)