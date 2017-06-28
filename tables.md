---
layout: default
title: Description of SQL Database Tables
---
<div class="alert alert-success" role="alert"> This page describes the 
<strong>
<span class="cig">{{ site.cig_text }}</span>
<span class="onp">{{ site.onp_text }}</span>
</strong>
solution.
 {% include sqlchoices.md %}

</div> 

## SQL Database Tables
--------------------------

Below are the different data sets that you will find in your database after deployment. 

<table class="table table-striped table-condensed">
   <tr>
    <th>Table</th>
    <th>Description</th>
  </tr>
  <tr>
    <td>Loan_chargeoff_eval_score_10k</td>
    <td>Table that stores the model score and prediction probability</td>
  </tr>
  <tr>
    <td>Loan_chargeoff_models_10k</td>
    <td>Outlines various models and their respective performance scores</td>
  </tr>
  <tr>
    <td>Loan_chargeoff_prediction_10k</td>
    <td>table that stores the prediction score and probability from scoring result</td>
  </tr>
  <tr>
    <td>Loan_chargeoff_score</td>
    <td>Table that stores the loan information and prediction result from the scoring exercise</td>
  </tr>
    <tr>
    <td>Loan_chargeoff_test</td>
    <td>Table that stores the loan and prediction result from testing exercise</td>
  </tr>
    <tr>
    <td>Loan_chargeoff_train</td>
    <td>Table that stores the loan and prediction result from training exercise</td>
  </tr>
    <tr>
    <td>Loan_info_10k</td>
    <td>Raw data about loan information</td>
  </tr>
    <tr>
    <td>Member_info_10k</td>
    <td>Raw data about member information</td>
  </tr>
    <tr>
    <td>Payments_info_10k</td>
    <td>Raw data about payments information</td>
  </tr>
    <tr>
    <td>Selected_features_10k</td>
    <td>Table that stores the features ran in feature selection step</td>
  </tr>    
</table>
