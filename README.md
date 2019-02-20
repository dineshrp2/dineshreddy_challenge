# dineshreddy_challenge
SED Challenge

I chose Terraform to create VPC, subnets, launch configuration, Autoscaling group, ELB on AWS and enabled ports 80 and 443 on the security groups to allow the traffic from anywhere.
The instances can scale between 2 to 5 depending on the Average CPU utilization and I also used the elastic load balancer for high availability and improve responsiveness.
I uploaded the self-signed SSL certificates to IAM using terraform. And ensured all the HTTP traffic is redirected to HTTPS through the load balancer.


Main.tf has all the code to create the infrastructure and start the instances which are ready to serve the traffic on https.
Give your access-key and secret-key for the AWS account in the “terraform.tfvars” file and RUN “terraform apply” command to create. 
Access the web page directly using the elb dns name displayed after the successful execution
