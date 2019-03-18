# dineshreddy_challenge
SED Challenge

I chose Terraform to create VPC, subnets, launch configuration, Autoscaling group, ELB on AWS and enabled ports 80 and 443 on the security groups to allow the traffic from anywhere.
The instances can scale between 2 to 5 depending on the Average CPU utilization and I also used the elastic load balancer for high availability and improve responsiveness.
I uploaded the self-signed SSL certificates to IAM using terraform. And ensured all the HTTP traffic is redirected to HTTPS through the load balancer.

Steps to run:
Main.tf has all the code to create the infrastructure and start the instances which are ready to serve the traffic on https.


1. Give your access-key and secret-key for the AWS account you would like to use in the “terraform.tfvars” file and save the file.
2. RUN “terraform apply” command to run the script.
3. Access the web page directly using the elastic load balanacer's dns name displayed after the successful execution
