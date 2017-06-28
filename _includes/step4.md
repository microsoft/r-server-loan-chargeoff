
<h2> Step 4: Deploy and Visualize with Bernie the Business Analyst </h2>
<hr />

Now that the predictions are created and saved, we will meet our last persona - Bernie, the Business Analyst. Bernie will use the Power BI Dashboard to learn more about the loan chargeoff predictions (second tab). He will also review summaries of the loan data used to create the model (first tab).  

{% include pbix.md %}

Bernie will then let the Lending Institution know about the loans chargeoff predictions - the data in the loanchargeoff_predictions table contains the Score and Probability for each loan payment. The team uses these scores to take further business actions.

<div class="alert alert-info" role="alert">
Remember that before the data in this dashboard can be refreshed to use your scored data, you must <a href="Visualize_Results.html">configure the dashboard</a> as Debra did in step 2 of this workflow.
</div>