### What this project is about

In this project all the steps should be achieved using terraform modules. All the variable values should be centralized and create terraform templates in such a way that we can deploy same modules in dev, staging and prod environments with different set of values.


Steps:
1. Create a VPC with 2 public and two private subnets.
2. Private connectivity should be via NAT Gateway, Add autoscaling group in private subnets and install nginx on VM using userdata.
3. Create an internet facing application load balancer and forward traffic to autoscaling group in private subnets.


Notes:

What is lifecycle check?
Before destroying any instances, make sure we have sufficient instances in our ASG.
Dont delete anything before creating a new one.