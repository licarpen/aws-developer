# aws-developer
Course work from the AWS Certified Developer Associate exam.  Includes notes, sandbox, sample apps, and more.  Course name on Udemy: aws-certified-developer-associate-dva-c01

## IAM - Identity Access Management

* consists of Users, Groups, Roles
* Policies are written in JSON
* Big enterprises can integrate their own repo of users   
  * Identity Federation uses SAML standard (active directory)

## EC2

Review Section 3.29 EC2 Good Things to Know and Checklist

### Services Summary

* Renting virtual machines (EC2)
* Storing data on virtual drives (EBS)
* Distributing load across machines (ELB)
* Scaling services using auto-scaling group (ASG)

### Launching an EC2 instance running linux

* choose an AMI (software/operating system to be launched on server)
  * use Amazon Linux 2
* choose type of machine (memory and vCPUs)
  * t2.micro is free-tier
* storage is needed to store the operating system
* tags: key 'Name' is displayed in UI
* right-click on instance state in instance dashboard to start, stop, reboot, or terminate
* by default, EC2 machine comes with a private IP for internal AWS network and a public IP for the www

### SSH

* SSH: mac, linux, windows >=10
  * copy Pv4 Public IP (example used below: 54.80.251.93)
  * check inbound rules for port and source
  * save key file (.pem)
  * change permissions for .pem
  ```chmod 0400 <your_key_file.pem>```
  ```ssh -i <your_key_file.pem> ec2-user@54.80.251.93```
  * Optional: check user with ```whoami```
  * Optional: ```sudo su``` gives root user access
  * Update machine: ```yum update -y```
  * exit with ```exit``` or ^C

* putty (alternative to SSH): windows  
* EC2 Instance Connect: all
  * choose connect option EC2 Instance Connect
  * only works with Amazon Linux 2 AMI
* SSH: can't use private IP!  Not in same network.  Need to use public IP. 

#### Troubleshooting
* connection timeout is a security group issue
  * ensure inbound port is 22 (SSH server port) and source is 0.0.0.00 and assigned to instance
* If firewall still prevents SSH, use EC2 Instance Connect
* ssh command not found: use Putty
* connection refused: instance is reachable but no SSH utility is running on it.  Restart and ensure Amazon Linux 2
* permission denied: wrong security key or wrong user (use ec2-user)
* working yesterday, but not today? Check Pv4 Public IP.  It changes when you restart instance.  

### Security Groups

* controls inbound and outbound traffic www <-> EC2 Machine (act as firewall)
* fundamental to troubleshooting network issues
* inbound rules default to port 22 and source 0.0.0.0/0
* outbound defaults to ALL traffic
* security groups can be attached to multiple instances and vice versa
* locked down to region/VPC combination
* best practice: maintain separate security group for SSH access
* REVIEW: Section 3.23 Security Groups
  * referencing other security groups
  * 4:30
* Private vs Public IPs 
  * IPv4: 1.160.10.240
  * most common
  * public IP can be identified on internet
  * machines in private IP range can all communicate but need a gateway (proxy) to connect to www
  * Elastic IP can be used to fix the public IP for your instance
    * can be attached to one instance at a time
    * can transfer to another instance if one fails
    * only 5 elastic IPs on AWS
    * avoid use
    * instead use a random public IP and register a DNS name to it
    * best: use load balancer

### Installing Apache (web server software)

* SSH into instance
```sudo su```
```yum update -y```
```yum install -y httpd.x86_64```
```systemctl start httpd.service```
Persist through reboots
```systemctl enable httpd.servie```
Test (curl loads content of url)
```curl localhost:80```
* add security rule for HTTP inbound port 80
To view this content in a web browser: http://<public ip address>:80

### User Data

* Add user data when launching an instance in "configure instance details -> advanced details"
* install updates and software, download common files from internet, etc.
* User data example (as text)

#!/bin/bash
yum update -y
yum install -y httpd.x86_64
systemctl start httpd.service
systemctl enable httpd.service
echo "Hello World!" > /var/www/html/index.html

### Instance Launch Types

* on demand: short workload, predictable pricing
  * pay for what you use
  * high cost but no upfront payment
  * no long term commitment
* reserved: long workloads (> 1yr)
  * up to 75% discount
  * pay upfront
  * 1-3 years
  * reserve specific instance type
  * think database
* convertible reserved: long workloads w/flexible instances
  * can change EC2 type
  * up to 54% dicsount
* scheduled reserved instance: launch within time window
* spot: short workloads, for cheap, can lose instances
  * 90% discount
  * bid a price and get the instance as long as it's under the price
  * 2 minute notification
  * batch jobs, Big Data analysis, workload resilient to failures
* dedicated instance: no other customer will share hardware
  * instance running on hardware dedicated to you
  * share hardware with other instances in same account
  * no control over instance placement
* dedicated host: book entire server and control instance placement
  * visibility into underlying sockets
  * 3 year commitment
  * $$$
  * strong compliance needs - only customer






