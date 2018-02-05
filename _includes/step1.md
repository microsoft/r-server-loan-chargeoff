
<h2>Step 1: Server Setup and Configuration with 
<span class="sql">Danny the DB Analyst</span>
<span class="hdi">Ivan the IT Administrator</span>
</h2>
<hr/>

<div class="sql">
Let me introduce you to Danny, the Database Analyst. Danny is the main contact for SQL Server database administration and application integration. Danny was responsible for installing and configuring the SQL Server. He has added a user named with all the necessary permissions to execute R scripts on the server and modify the LoanChargeOff database. This was done through the createuser.sql file. 

This step has already been done on your deployed Azure AI Gallery VM. 
Alternatively, Danny could also run LoanChargeOff.ps1 to run the end to end workflow that includes setting up of SQL Server user login, import raw data to SQL Server tables, view creation, training and testing and prediction.
</div>

<div class="hdi">
Let me introduce you to Ivan, the IT Administrator. Ivan is responsible for implementation as well as ongoing administration of the Hadoop infrastructure at his company, which uses <a href="https://azure.microsoft.com/en-us/solutions/hadoop/">Hadoop in the Azure Cloud</a> from Microsoft. 

Ivan created the <a href="https://docs.microsoft.com/en-us/azure/hdinsight/hdinsight-hadoop-r-server-get-started">HDInsight cluster with R Server</a> for Debra. He also uploaded the data onto the storage account associated with the cluster. 
</div>


