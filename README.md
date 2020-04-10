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
* inbound rules default to port 22 and no incoming traffic
* outbound defaults to allowing ALL inbound traffic
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
To view this content in a web browser: http://PUBLIC_IP:80

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

## Load Balancing an EC2 with ELB (Elasitc Load Balancer)

* A load balancer is a server that fronts your application, forwarding internet traffic to instances downstream
* spread load across ultiple downstream instances
* expose a single point of access (DNS) to your application
* handle failures of downstream instances
* perform regular health checks on instances
* provide SSL termination (HTTPS) for your websites
* enforce stickiness with cookies
* high availability across zones
* separate public traffic from public traffic
* all load balancers have static host name (do not resolve and used underlying IP)
* can scale but not instantaneously (contact AWS for warm-up)
* 4xx errors: client-induced
* 5xx errors: application-induced
  * 503: at capacity OR no registered target
* TROUBLESHOOT: if LB can't connect to application, check security groups

### Classic Load Balancer v1
  * deprecated
  * support SSL certificates
  * provide SSL termination

### Application Load Balancer v2 (ALB)
  * layer 7
  * balance multiple HTTP applications across machines (target groups)
  * balance to multiple applications on the same machines (ex: containers)
  * balance based on route in URL or hostname in URL
  * ideal for microservices and container-based applications (ECS, docker)
  * has port mapping feature to redirect to a dynamic port
  * stickiness can be enabled at target group level - request assigned an instance
  * stickiness is generated by the ALB
  * support for HTTP/HTTPS & Websockets protocols
  * application servers don't see IP of client directly
    * IP inserted in X-Forwarded-For
  * get port and proto: X-Forwarded-Port and X-Forwarded-Proto
  * latency ~ 400ms
  * support SSL certiciates
  * provide SSL termination

#### ALB Implementation

  * scheme: internet-facing (public)
  * when active, go to DNS
  * DNS will not change.  
  * check listeners, target groups
  * default allows traffic from both IP address and routing through load balancer.
      * Add inbound rule to security group for instance
      * HTTP source type: custom
      * start typing sg
      * pick load balancer sg
      * can no longer access instance directly via public IP


### Network Load Balancer v2 (NLB)
  * layer 4
  * for TCP traffic (forwarding TCP traffic to your instances)
  * handle 10^6 requests per second
  * support static or elastic IP
  * low latency (100 ms)
  * used for extreme performance
  * can see client IP directly

### Health Checks

* supply port and route

## Auto Scaling Groups (ASG)

* scale out (add EC2 instances) to match increased load
* scale in to match decreased load
* set min/max machines
* automatically register new instances to a load balancer
* scale based on CloudWatch alarms
  * metrics are computed as avg across ASG instances
  * target avg CPU usage
  * #requests
  * avg network in/out
  * custom metric - send to CloudWatch with PutMetricAPI
* ASG is free
* restarts instance if terminated
* terminate instance if unhealthy

### ASG configuration

* launch configuration
  * AMI + instance type
  * EC2 user data
  * EBS volumes
  * security groups
    * choose security group attached to instance
    * it should already reference the load balancer
  * SSH key pair
* min/max size + initial capacity
* network and subnets info
  * add multiple subnets for reliability
* LB info
  * check "receive traffic from one or more load balancers"
  * use target groups (ALB)
  * health check: ELB
* scaling policies
* check Activity history to confirm instances have been created to match desired min

## Elastic Block Store Volume (EBS)

* EC2 machines can lose its root volume when it is manually terminated (can disable this)
* unexpected terminations happen
* store instance data somewhere
* EBS volume is a network drive you can attach to instances while they run
* facilitates instances persisting data
* can be detached and attached to instance
* locked to availability zone (AZ)
* to move a volume, snapshot first
  * back up
  * only uses space that is needed
  * can schedule snapshots
  * can use for volume migration
* have provisioned capacity (GBs and IOPs)
  * billed for capacity regardless of whether you use it
  * can increase provisioned capacity over time
  * repartition after increasing volume
* 4 types characterized by size, throughput, and IOPS
  * GP2 (SSD): general purpose
  * IOI (SSD): high performance, low latency, high throughput workloads
  * STI (HDD): low cost HDD volume for frequent access, throughout intensitve workloads (big data)
  * SCI (HHD): low cost, less frequently accessed workloads 
* EBS encryption
  * data at rest is encrypted inside volume
  * all data in flight b/w instance and volume is encrypted
  * all snapshots are encrypted
  * all volumes created by snapshots are encrypted
  * minimal impact on latency
  * leverages keys from KMS (AES-256)
  * copying an unencrypted snapshot can be encrypted
* EBS backups use I/O so don't run while app is receiving high traffic load

### EBS vs Instance Store

* Some instances do not come with Root EBS volume but rather with an instance store
* Instance store is physically attached to machine
* PRO: better I/O performance
* CON: on termination, instance store is lost
* CON: can't resize instance store
* CON: backups must be operated by user
