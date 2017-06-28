
Now you're ready to follow along with Debra as she creates the scripts needed for this solution. <span class="sql"> If you are using Visual Studio, you will see these file in the <code>Solution Explorer</code> tab on the right. In RStudio, the files can be found in the <code>Files</code> tab, also on the right. </span> 

<div class="hdi">The steps described below each create a function to perform their task.  The individual steps are described in more detail below.  The following scripts are then used to execute the steps.  
<ul><li>
<strong>loanchargeoff_main.R</strong> is used to define the data and directories and then run all of the steps to process data, perform feature engineering, training, and scoring.  
<p></p>
The default input for this script uses 100,000 loans for training models, and will split this into train and test data.  After running this script you will see data files in the <strong>/LoanChargeOff/dev/temp</strong> directory on your storage account.  Models are stored in the <strong>/LoanChargeOff/dev/model</strong> directory on your storage account. The Hive table <code>loanchargeoff_predictions</code> contains the 100,000 records with predictions (<code>Score</code>, <code>Probability</code>) created from the best model.
</li>
<li>
<strong>Copy_Dev2Prod.R</strong> copies the model information from the <strong>dev</strong> folder to the <strong>prod</strong> folder to be used for production.  This script must be executed once after <strong>loanchargeoff_main.R</strong> completes, before running <strong>loanchargeoff_scoring.R</strong>.  It can then be used again as desired to update the production model. 
<p></p>
After running this script models created during <strong>loanchargeoff_main.R</strong> are copied into the <strong>/var/RevoShare/user/LoanChargeOff/prod/model</strong> directory.
</li>
<li>
<strong>loanchargeoff_scoring.R</strong> uses the previously trained model and invokes the steps to process data, perform feature engineering and scoring.  Use this script after first executing <strong>loanchargeoff_main.R</strong> and <strong>Copy_Dev2Prod.R</strong>.
<p></p>
The input to this script defaults to 10,000 loans to be scored with the model in the <strong>prod</strong> directory. After running this script the Hive table <code>loanchargeoff_predictions</code> now contains the predictions.  
</li></ul>
</div>
<div class="sql">
<a href="https://microsoft.github.io/r-server-loan-chargeoff/dba.html#workflow-automation"> SQL Workflow Automation </a> 
</div>

<div class="hdi">
Below is a summary of the individual steps used for this solution. 
<ul>
<li>  <strong>step1_get_training_testing_data.R</strong>: Read input data which contains all the history information for all the loans from HDFS. Extract training/testing data based on process date (paydate) from the input data. Save training/testing data in HDFS working directory </li>

<li>  <strong>step2_feature_engineering.R</strong>:  Here we use MicrosoftML to do feature selection. Code can be added in this file to create some new features based on existing features. Open source package such as Caret can also be used to do feature selection here. Best features are selected using AUC. </li>

    
<div class="alert alert-info" role="alert">
<div class="cig">
You can run these scripts if you wish, but you may also skip them if you want to get right to the modeling.  The data that these scripts create already exists in the SQL database.
<p/>
</div>
<div class="hdi" >
To run all the scripts described above as well as those in the next few steps, open and execute the file <strong>loanchargeoff_main.R.</strong>
<p/>
</div>
In <span class="sql">both Visual Studio and</span> RStudio, there are multiple ways to execute the code from the R Script window.  The fastest way <span class="sql">for both IDEs</span> is to use Ctrl-Enter on a single line or a selection.  Learn more about  <span class="sql"><a href="http://microsoft.github.io/RTVS-docs/">R Tools for Visual Studio</a> or</span> <a href="https://www.rstudio.com/products/rstudio/features/">RStudio</a>.

</div>

<li>  Now she is ready for training the models, using <strong>step3_training_evaluation.R</strong>.  This step will train two different models and evaluate each.  
<p> 
   The R script draws the ROC or Receiver Operating Characteristic for each prediction model. It shows the performance of the model in terms of true positive rate and false positive rate, when the decision threshold varies. 
</p>
<p>
   The AUC is a number between 0 and 1.  It corresponds to the area under the ROC curve. It is a performance metric related to how good the model is at separating the two classes (converted clients vs. not converted), with a good choice of decision threshold separating between the predicted probabilities.  The closer the AUC is to 1, and the better the model is. Given that we are not looking for that optimal decision threshold, the AUC is more representative of the prediction performance than the Accuracy (which depends on the threshold). 
</p>
<p> 
   Debra will use the AUC to select the champion model to use in the next step.
</p>
</li>

<li> <strong>step4_prepare_new_data.R</strong> creates a new data which contains all the opened loans on a pay date which we do not know the status in next three month, the loans in this new data are not included in the training and testing dataset and have the same features as the loans used in training/testing dataset.
</li>

<li> <strong>step5_loan_prediction.R</strong> takes the new data created in the step4 and the champion model created in step3, output the predicted label and probability to be charge-off for each loan in next three months.
</li>

<li class="hdi">
After creating the model, Debra runs <strong>Copy_Dev2Prod.R</strong> to copy the model information from the <strong>dev</strong> folder to the <strong>prod</strong> folder, then runs <strong>loanchargeoff_scoring.R</strong> to create predictions for her new data. 
</li>
<li> Once all the above code has been executed, Debra will use PowerBI to visualize the recommendations created from her model. 

{% include pbix.md %}

She uses an ODBC connection to connect to the data, so that it will always show the most recently modeled and scored data.
  <img src="images/visualize1.png"> 
  <img src="images/visualize2.png"> 
  <div class="alert alert-info" role="alert">
  If you want to refresh data in your PowerBI Dashboard, make sure to <a href="Visualize_Results.html">follow these instructions</a> to setup and use an ODBC connection to the dashboard.
  </div>
</li>
<li>A summary of this process and all the files involved is described <a href="data-scientist.html">in more detail here</a>.
</li>
</div>