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

## Route53 for Managed Domain Name System (DNS)

* Types
  * A: URL to APv4
  * AAAA: URL to APv6
  * CNAME: URL to URL
  * Alias: URL to AWS resource
* Information is cached on your machine for future reference
* can use public domain names you own
* private domain names that can be resolved by your instances in your VPCs
* offers load balancing through DNS (client load balancing)
* health checks (limited)
* routing policy: simple, failover, geolocation, geoproximity, latency, weighted
* Prefer Alias over CNAME for AWS resources for performance
* services -> Route 53 -> DNS Management -> Create hosted zone -> domain name (need to have registered domain on sidebar) -> create record set -> choose A record -> alias

## Relational Database Service (RDS)

* use SQL as query language
* Postgres, Oracle, MySQL, Oracle, Microsoft SQL, mariaDB, Aurora
* Provides OS patching
* continuous backups and restore
  * daily full snapshot 
  * capture transaction logs in real time
  * can restore to any point in time
  * 7 days retention (can increase to 35 days)
  * can trigger manual snapshot and save for any amount of time
  * encryption at rest with KMS
  * SSL certificates to encrypt data to RDS in flight
    * enforcement for postgreSQL: rds.force_ssl=1 in AWS RDS console in paramter groups
    * enforcement for MySQL: within DB: GRANT USAGE ON *.* TO 'mysqluser'@'%' REQUIRE SLL;
    * connection using SSL
      * provide SSL trust certificate (dl from AWS)
      * provide SSL options when connecting to DB
* monitoring dashboards
* read replicas for improved read performance
  * up to 5 read replicas in any AZ (across region)
  * master takes all writes
  * asynchronous replication - reads are eventually consistent after write
  * applications must update connection string to leverage read replicas
* multi AZ setup for disaster recovery
  * writes to master DB are synchronously replicates to 1 standby in different AZ for failover
  * automatic
* scaling capability (vertical and horizontal)
* cannot SSH into instances!
* security  
  * usually deployed within a private subnet, not in a public one
  * use security groups for who can communicate with RDS
  * IAM policites control who can MANAGE RDS
  * Username/password can be used to login to DB
  * IAM can be used as well (now for MySQL/Aurora)

* Aurora
  * proprietary tech from AWS
  * Postgres and MySQL supported
  * cloud optimized: 5x performance of MySQL, 3x performance of postgres
  * storage autoscales in increments of 10GB up to 64TB
  * 15 replicas (MySQL: 5) at sub 10ms replica lag
  * failover instantaneous (High availability native)
  * costs 20% more but more efficient

  Checkout sqlelectron as resource for DB gui

  ## ElastiCache

  * basically an RDS for caching
  * get managed Redis or Memcached
  * in-memory DB with high performance, low-latency
  * reduce load on DB for load intensive workload
  * helps make app stateless
  * write scaling using sharding
  * read scaling use read replicas
  * multi AZ with failover capability
  * AWS takes care of OS maintenance, patching, monitoring, config, failure recovery, backups, etc.
  * user session store
    * user signs into instance
    * session sent to ElasiChache
    * user hits another instance
    * instance checks cache for user session
  * redis
    * during setup, change node type to t2.micro and # replicas to 0
    * in-memory key-value store
    * super low latency (sub ms)
    * cache survives reboot (persistence)
    * great to host 
      * user sessions
      * distributed states
      * leaderboard for gaming
      * relieve pressure on DB
      * pub/sub for messaging
    * multi AZ
    * support for read replicas
  * Memcached
    * in-memory object store
    * no persistence
    * quick retrieval of objects
    * cache often-accessed objects

  ### ElastiChache Patterns

  * Lazy Loading
    * load only when necessary
    * cache is only filled with requested data
    * node failute is not fatal (just warm the cache)
    * cache miss penality of 3 round trips = noticeable delay
    * stale data: data could be outdated
  * Write Through
    * add or update cache when database is updated
    * data in cache is never stale
    * write penalty (two calls for each write)
    * cache will have a lot of data that is never read

## VPS and 3 Tier Architecture

* Public Subnet
  * load balancers
  * static websites
  * files
  * public authentication layers
* Private Subnet
  * web app servers
  * databases
* can talk to each other if on same VPC
* VPC flow logs allow you to monitor traffic i/o of VPC
* VPC per account per region
* subnets per VPC per AZ
* can peer VPC w/i or accross accounts to make it look like they are part of the same network

## S3

### Buckets
* globally unique name
* defined at regional level
* enable versioning at this level

### Objects
* objects have key: FULL path to file
* 5TB max
* >5GB must use multi-part upload
* metadata (system/user)
* tags (up to 10 for security/lifecycle)
* version ID
  * changed on every update
  * no version = null

### Encryption
* encryption in flight: SSL/TLS use HTTPS
* 4 types (IMPORTANT)
  * SSE-S3
    * encrypts objects using keys handled and managed by AWS
    * encrypted server side
    * AES-256 encryption type
    * set header: "x-amz-server-side-encryption":"AES256"
    * key is managed by S3
  * SSE-KMS
    * leverage AWS Key Management Service to manage encryption keys
    * more control over rotation of key
    * access to audit trail
    * set header: "x-amz-server-side-encryption":"AWS:kms"
    * key used is an AWS customer master key
  * SSE-C
    * manage own encryption keys
    * HTTPS must be used
    * S3 does NOT store encryption key
    * send data key in header
    * data is encrypted by amazon and then throws away key
  * Client side encryption
    * encryptiong before sending to S3
    * decryption when retrieving

### Security

* User Based
  * use IAM policies
* Bucket Policies (Resource Based)
  * use bucket-wide rules from S3 console
  * JSON based policies
    * resources: buckets and objects
    * actions: set of API to allow/deny
    * effect: allow/deny
    * principal: the account or user to apply the policy to
    * use the policy generator for bucket policy
    * ex: to ensure encryption of new objects:
      * bucket policy
      * principal: *
      * Action: putObject
      * ARN: arn:aws:s3:::carpentercode/*
      * add conditions: string aws-encrption-key-header != AES256
  * Object Access Control List (ACL)
  * Bucket Access Control List (ACL) - less common
* networking
  * supports VPC endpoints (not connected to www)
  * logging and audit
    * S3 access logs can be stored in other S3 bucket
    * API calls can be logged in AWS CloudTrail
  * User security
    * MFA can be required in versioned buckets to delete objects
    * signed URLs: valid for limited time (ex: video access)

### S3 Website
* bucket permissions: allow public access
* properties: static website hosting
* need to add JSON bucket policy 
  * allow everyone to getObject

### S3 CORS
* if you request data from another S3 bucket, enable CORS
* Cross Origin Resource Sharing allows you to limit the number of websites that can request your files in S3

### S3 Consistency Model
* read after write consistency for PUTS of new objects
  * NOT TRUE if you did GET before to see if the object existed (failed GET was cached)
* Put object -> Put object -> get object:  might get 1st object!
* delete object -> might still get it!

### S3 Performance
  * historically, key names for objects should include random prefix to partition
  * do NOT use dates - very close and partitions would be too close
  * not anymore! 
  * to upload large objects quickly (>100MB)
    * multipart upload
    * parallelizes PUTs
    * maximize network bandwidth and efficiency
    * decrease time to retry for part if fail
    * MUST use if >5GB
  * use CLoudFront to cache S3 objects around the world
  * S3 Transfer Acceleration (uses edge locations) just need to change the endpoint you write to, not the code
  * SSE-KMS encryption: limited to AWS limits for KWS usage (~100s -1000s dls/uls /second)

### S3 Glacier - long term archival for files

### S3 Select
* use query to retrieve only data you need
* no subqueries or joins
