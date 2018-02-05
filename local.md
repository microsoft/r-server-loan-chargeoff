---
layout: default
title: Setup for Local Code Execution
---

<div class="alert alert-success" role="alert"> This page describes the 
<strong>
{{ site.cig_text }}
</strong>
solution.
</div> 

## Setup for Local Code Execution

You can execute code on your local computer and push the computations to the SQL Server on the VM  that was created by the Azure AI Gallery. But first you must perform the following steps. 

## On the VM: Configure VM for Remote Access

Connect to the VM to perform the following steps.

You must open the Windows firewall on the VM to allow a connection to the SQL Server. To open the firewall, execute the following command in a PowerShell window on the VM:

    netsh advfirewall firewall add rule name="SQLServer" dir=in action=allow protocol=tcp localport=1433 

SQL Server on the VM has been set up with username/password provided during deployment.  Once you open the firewall, you may also want to also change the password, as anyone who knows the IP address can now access the server.  To do so, log into SSMS with Windows Authentication and execute the following query:
    
        ALTER LOGIN <sql username> WITH PASSWORD = '<sql password>';  
       
## On your local computer:  Install R Client and Obtain Code

Perform these steps on your local computer.

If you use your local computer you will need to have a copy of R Client on your local machine.  If you use Visual Studio, you can add <a href="https://www.visualstudio.com/vs/rtvs/">R Tools for Visual Studio</a>.  Otherwise you might want to try <a href="rstudio.html">R Studio</a>.  

Also, on your local computer you will need a copy of the solution code.  Open a PowerShell window, navigate to the directory of your choice, and execute the following command:  

    git clone https://github.com/Microsoft/r-server-loan-chargeoff.git loanchargeoff

This will create a folder **loanchargeoff** containing the full solution package.

Finally, in the **chargeoff_batch_prediction.R** file, replace  `Server=.` in the connection_string with the DNS of the VM followed by ",1433".


<a href="CIG_Workflow.html#step2">Return to Typical Workflow for Azure AI Gallery Deployment<a>