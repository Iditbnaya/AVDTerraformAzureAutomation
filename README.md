# AVDTerraformAzureAutomation
Creating a non-persistent AVD environment by deploying and deleting the env every day using Terraform and Azure automation


Steps: 

####################################################################################
1. Create a resource group 
2. Create a VNet
3. Create a golden Image (If needed) 
https://learn.microsoft.com/en-us/azure/virtual-desktop/set-up-golden-image
https://learn.microsoft.com/en-us/azure/virtual-machines/generalize
4. Create a Service principal  and copy the result - choose the level of permissions (subscription or resource group/ Owner or Contributor)

Examples: 

az ad sp create-for-rbac --name terraformtest --role Contributor --scopes /subscriptions/<SubID>
  
az ad sp create-for-rbac --name SPAVDTF --role Contributor --scopes /subscriptions/<SubID>/resourcegroups/<RGname>
  
az ad sp create-for-rbac --name SPElbitAVD --role owner --scopes /subscriptions/<SubID>/resourcegroups/<RGname>

Save the resoult
{
  "appId": "XXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXX",
  "displayName": "SPAVD",
  "password": "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX",
  "tenant": "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
}

5. Create Key vault - if already created give permissions to the service principal on the key vault  - under access configuration create access policy 
  
6. Give Permissions to the Service principal to manage the AD groups: Add the SP to Groups Administrator role 
  
7. Create two secrets in the key vault One for the local admin --> "DefaultAdminUser" and one for the password "DefaultAdminPasword"
  
8. Edit the Terraform Varaiables File


For the Hybrid worker: 

10.Create a Linux VM  (I Used Ubuntu)
  
11. Connect to the VM and Install Terraform - https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli 
  
12. Install PowerShell
sudo apt-get install -y powershell
  
13. Install az cli
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
  
14. Create a folder for the Terraform Files
  
15. Copy the files to the folder (I used winscp)
  
16. From the folder with the tf files Run:
terraform init

For the automation: 
  
17. In azure portal create a new automation account
  
18. Create an Hybrid worker group and add the Linux VM
  
19.Create a PowerShell Runbook for the AVD Deployment:


#Login with the service principle
az login --service-principal -u 'XXXXXXXXXXXXXXXXXXXXXXXXXX' -p 'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXX' --tenant 'XXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX'
#Change the path to where the tf files are
cd /home/localadmin/avdtf  
#run Terraform
terraform plan -destroy -out main.destroy.tfplan
terraform apply main.destroy.tfplan

20. Start the runbook and check that everything worked

21.Create a PowerShell Runbook for Destroying the AVD Env 

#Login with the service principle
az login --service-principal -u 'XXXXXXXXXXXXXXXXXXXXXXXXXX' -p 'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXX' --tenant 'XXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX'
#Change the path to where the tf files are
cd /home/localadmin/avdtf
terraform plan -destroy -out main.destroy.tfplan
terraform apply main.destroy.tfplan![image](https://user-images.githubusercontent.com/47793710/224740837-fcb63e10-a00d-481b-9f33-7b6b5f8066a3.png)


22. Start the runbook and check that the AVD env Deleted 


Now schedule the deploy and destroy run books 

Good luck :)











