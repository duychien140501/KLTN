# KLTN
First time, the command "terraform init" need to be run to install terraform packet (<a href="https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli">terraform install</a>)
  

# Run command 
We can check error by using command
**terraform validate**

Run to create resources to aws 
**terraform apply -var-file="./0_values/values.tfvars"**

# Delete resources command 
Run to delete all resources on aws 
**terraform destroy -var-file="./0_values/values.tfvars"**