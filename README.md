# aws-developer
Course work from the AWS Certified Developer Associate exam.  Includes notes, sandbox, sample apps, and more.  Course name on Udemy: aws-certified-developer-associate-dva-c01

## IAM - Identity Access Management

* consists of Users, Groups, Roles, Policies
* Policies are written in JSON
* Big enterprises can integrate their own repo of users   
  * Identity Federation uses SAML standard (active directory)
  * Security Assertion Markup Language
    * If your identity store is not compatible with SAML 2.0, then you can build a custom identity broker application to perform a similar function. The broker application authenticates users, requests temporary credentials for users from AWS, and then provides them to the user to access AWS resources.
    * The application verifies that employees are signed into the existing corporate network’s identity and authentication system, which might use LDAP, Active Directory, or another system. The identity broker application then obtains temporary security credentials for the employees
    * To get temporary security credentials, the identity broker application calls either AssumeRole or GetFederationToken to obtain temporary security credentials, depending on how you want to manage the policies for users and when the temporary credentials should expire. The call returns temporary security credentials consisting of an AWS access key ID, a secret access key, and a session token. The identity broker application makes these temporary security credentials available to the internal company application. The app can then use the temporary credentials to make calls to AWS directly. The app caches the credentials until they expire, and then requests a new set of temporary credentials.
* least privilege principle
**IAM users defined GLOBALLY**

## EC2 (Elastic Compute Cloud)

Review Section 3.29 EC2 Good Things to Know and Checklist
* custom AMI linked to specific region
* know how to SSH into EC2 and change .pem file permisions
* know how to properly use security groups
* fundamental differences b/w private vs public vs elastic IP
* use User Data to customize instance
* can build custom AMI to enhance your OS

### Services Summary

* Renting virtual machines (EC2)
* Storing data on virtual drives (EBS)
* Distributing load across machines (ELB)
* Scaling services using auto-scaling group (ASG)

### Launching an EC2 instance running linux

* choose an AMI (software/operating system to be launched on server) (AMI = Amazon Machine Image)
  * use Amazon Linux 2
* choose type of machine (memory and vCPUs)
  * t2.micro is free-tier
* storage is needed to store the operating system
* tags: key 'Name' is displayed in UI
* right-click on instance state in instance dashboard to start, stop, reboot, or terminate
* by default, EC2 machine comes with a private IP for internal AWS network and a public IP for the www

### SSH (Secure Shell)

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
* outbound defaults to allowing ALL traffic
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

* Using roles to grant permissions to applications that run on EC2 instances requires a bit of extra configuration. An application running on an EC2 instance is abstracted from AWS by the virtualized operating system. Because of this extra separation, an additional step is needed to assign an AWS role and its associated permissions to an EC2 instance and make them available to its applications. This extra step is the creation of an instance profile that is attached to the instance. The instance profile contains the role and can provide the role’s temporary credentials to an application that runs on the instance. Those temporary credentials can then be used in the application’s API calls to access resources and to limit access to only those resources that the role specifies. Note that only one role can be assigned to an EC2 instance at a time, and all applications on the instance share the same role and permissions.

* Using roles in this way has several benefits. Because role credentials are temporary and rotated automatically, you don’t have to manage credentials, and you don’t have to worry about long-term security risks. In addition, if you use a single role for multiple instances, you can make a change to that one role and the change is propagated automatically to all the instances.

* A task placement strategy is an algorithm for selecting instances for task placement or tasks for termination. Task placement strategies can be specified when either running a task or creating a new service. Amazon ECS supports the following task placement strategies:
    * binpack – Place tasks based on the least available amount of CPU or memory. This minimizes the number of instances in use.
    * random – Place tasks randomly.
    * spread – Place tasks evenly based on the specified value. Accepted values are attribute key-value pairs, instanceId, or host.

## Load Balancing an EC2 with ELB (Elasitc Load Balancer)

* A load balancer is a server that fronts your application, forwarding internet traffic to instances downstream
* spread load across multiple downstream instances
* expose a single point of access (DNS) to your application
* handle failures of downstream instances
* perform regular health checks on instances
* provide SSL termination (HTTPS) for your websites
* enforce stickiness with cookies
* high availability across zones
* separate public traffic from private traffic
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
  * HOSTNAME = different apps
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
* are these enabled by default?

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
* You can detach an Amazon EBS volume from an instance explicitly or by terminating the instance. However, if the instance is running, you must first unmount the volume from the instance.
* If an EBS volume is the root device of an instance, you must stop the instance before you can detach the volume.

* After you attach an Amazon EBS volume to your instance, it is exposed as a block device. You can format the volume with any file system and then mount it. After you make the EBS volume available for use, you can access it in the same ways that you access any other volume. Any data written to this file system is written to the EBS volume and is transparent to applications using the device. Thus, the correct answer is to create a file system on this volume.

* New volumes are raw block devices and do not contain any partition or file system. You need to login to the instance and then format the EBS volume with a file system, and then mount the volume for it to be usable. Volumes that have been restored from snapshots likely have a file system on them already; if you create a new file system on top of an existing file system, the operation overwrites your data. Use the sudo file -s device command to list down the information about your volume, such as file system type.

### EBS vs Instance Store

* Some instances do not come with Root EBS volume but rather with an instance store
* Instance store is physically attached to machine
* PRO: better I/O performance
* CON: on termination, instance store is lost
* CON: can't resize instance store
* CON: backups must be operated by user

## Route53 for Managed Domain Name System (DNS)

* GLOBAL
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
    * enforcement for MySQL: within DB: GRANT USAGE ON *.* TO 'mysqluser'@'%' REQUIRE SSL;
    * connection using SSL
      * provide SSL trust certificate (dl from AWS)
      * provide SSL options when connecting to DB
* monitoring
  * You can view the metrics for your DB instance using the console, or consume the Enhanced Monitoring JSON output from CloudWatch Logs in a monitoring system of your choice. By default, Enhanced Monitoring metrics are stored in the CloudWatch Logs for 30 days. To modify the amount of time the metrics are stored in the CloudWatch Logs, change the retention for the RDSOSMetrics log group in the CloudWatch console.
  * CloudWatch gathers metrics about CPU utilization from the hypervisor for a DB instance, and Enhanced Monitoring gathers its metrics from an agent on the instance. As a result, you might find differences between the measurements, because the hypervisor layer performs a small amount of work.
  * The differences can be greater if your DB instances use smaller instance classes because then there are likely more virtual machines (VMs) that are managed by the hypervisor layer on a single physical instance. Enhanced Monitoring metrics are useful when you want to see how different processes or threads on a DB instance use the CPU.
* read replicas for improved read performance
  * up to 5 read replicas in any AZ (across region)
  * master takes all writes
  * asynchronous replication - reads are eventually consistent after write
  * **applications must update SQL connection string to leverage read replicas**
* multi AZ setup for disaster recovery
  * writes to master DB are synchronously replicated to 1 standby in different AZ for failover
  * automatic
* scaling capability (vertical and horizontal)
* **cannot SSH into instances!**
* security  
  * usually deployed within a private subnet, not in a public one
  * use security groups for who can communicate with RDS
  * IAM policies control who can MANAGE RDS
  * Username/password can be used to login to DB
  * IAM can be used as well (now for MySQL/Aurora)
  * Amazon RDS supports using Transparent Data Encryption (TDE) to encrypt stored data on your DB instances running Microsoft SQL Server. TDE automatically encrypts data before it is written to storage, and automatically decrypts data when the data is read from storage.

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

  ElastiCache is an ideal front-end for data stores like Amazon RDS or DynamoDB, providing a high-performance middle tier for applications with extremely high request rates and/or low latency requirements.

  * basically an RDS for caching
  * get managed Redis or Memcached
  * in-memory DB with high performance, low-latency
  * reduce load on DB for load intensive workload
  * helps make app stateless
  * write scaling using sharding
  * read scaling use read replicas
    * You can create a read replica in minutes using a CreateReplicationGroup API or a few clicks of the Amazon ElastiCache Management Console. When creating a cluster, you specify the MasterCacheClusterIdentifier. The MasterCacheClusterIdentifier is the cache cluster Identifier of the “primary” node from which you wish to replicate. You then create the read replica cluster within the shard by calling the CreateCacheCluster API specifying the ReplicationGroupIdentifier and the CacheClusterIdentifier of the master node. As with a standard cluster, you can also specify the Availability Zone. When you initiate the creation of a read replica, Amazon ElastiCache takes a snapshot of your primary node in a shard and begins replication. As a result, you will experience a brief I/O suspension on your primary node as the snapshot occurs. The I/O suspension typically lasts on the order of one minute.
  * The read replicas are as easy to delete as they are to create; simply use the Amazon ElastiCache Management Console or call the DeleteCacheCluster API (specifying the CacheClusterIdentifier for the read replica you wish to delete).
  * If you have multiple read replicas, it is up to your application to determine how read traffic will be distributed amongst them.
  * Q: Can I promote my read replica into a “standalone” primary node?
    * No, this is not supported. Instead, you may snapshot your ElastiCache for Redis node (you may select the primary or any of the read-replicas). You can then use the snapshot to seed a new ElastiCache for Redis primary.
  * If you are using read replicas, you should be aware of the potential for lag between a read replica and its primary cache node, or “inconsistency”. You can monitor such lag potentially occuring via the "Replication Lag" CloudWatch metric, accessible through both the ElastiCache console and API, as well as those of the CloudWatch service.
  * multi AZ with failover capability
  * enable access with security groups
    * default network access turned off to clusters
    * To allow network access to your cluster, create a Security Group and link the desired EC2 security groups (which in turn specify the EC2 instances allowed) to it. The Security Group can be associated with your cluster at the time of creation, or using the "Modify" option on the AWS Management Console.
    * Please note that IP-range based access control is currently not enabled for clusters. All clients to a cluster must be within the EC2 network, and authorized via security groups as described above.
    * above does not apply for VPC
    * You can access an Amazon ElastiCache cluster from an application running in your data center providing there is connectivity between your VPC and the data center either through VPN or Direct Connect.
    * EC2 instances in a VPC can access Amazon ElastiCache if the ElastiCache cluster was created within the VPC.
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
    * supports snapshots
      * can specify window
      * upload to S3 to replicate a node to new region
  * Memcached
    * in-memory object store
    * no persistence
    * quick retrieval of objects
    * cache often-accessed objects
  * use DNS name to connect to nodes as underlying P addresses can change (not for VPC) (i.e. after cache node replacement)
  * nodes of an Amazon ElastiCache cluster can span multiple subnets as long as the subnets are part of the same Subnet Group that was associated with the ElastiCache Cluster at creation time.
  * changing subnet group of a deployed cluster is not currently allowed
  * you may not move an existing ElastiCache cluter from outside VPC to into or vice versa
  * A Parameter Group acts as a "container" for engine configuration values that can be applied to one or more clusters. If you create a cluster without specifying a Parameter Group, a default Parameter Group is used. This default group contains engine defaults and Amazon ElastiCache system defaults optimized for the cluster you are running. However, if you want your cluster to run with your custom-specified engine configuration values, you can simply create a new Parameter Group, modify the desired parameters, and modify the cluster to use the new Parameter Group. Once associated, all clusters that use a particular Parameter Group get all the parameter updates to that Parameter Group.
  * adding new nodes
    * You could add more nodes to your existing Memcached Cluster by using the "Add Node" option on "Nodes" tab for your Cache Cluster on the AWS Management Console or calling the ModifyCacheCluster API.

  ### ElastiChache Patterns

  * Lazy Loading
    * load only when necessary
    * cache is only filled with requested data
    * node failure is not fatal (just warm the cache)
    * cache miss penality of 3 round trips = noticeable delay
    * stale data: data could be outdated
  * Write Through
    * add or update cache when database is updated
    * data in cache is never stale
    * write penalty (two calls for each write)
    * cache will have a lot of data that is never read

### Global Data Store 

Global Datastore is a feature of Amazon ElastiCache for Redis that provides fully managed, fast, reliable and secure cross-region replication. With Global Datastore, you can write to your ElastiCache for Redis cluster in one region, and have the data available for read in two other cross-region replica clusters, thereby enabling low-latency reads and disaster recovery across regions.

Designed for real-time applications with a global footprint, Global Datastore for Redis supports cross-region replication latency of typically under one second, increasing the responsiveness of your applications by providing geo-local reads closer to end users. In the unlikely event of regional degradation, one of the healthy cross-region replica clusters can be promoted to become the primary cluster with full read/write capabilities. Once initiated, the promotion typically completes in less than a minute, allowing your applications to remain available.

* Q: How many AWS regions can I replicate to?
  * You can replicate to up to two secondary regions within a Global Datastore for Redis. The clusters in secondary regions can be used to serve low-latency local reads and for disaster recovery, in the unlikely event of a regional degradation.

## VPC and 3 Tier Architecture

* VPC lets you create a virtual networking environment in a private, isolated section of the Amazon Web Services (AWS) cloud, where you can exercise complete control over aspects such as private IP address ranges, subnets, routing tables and network gateways. With Amazon VPC, you can define a virtual network topology and customize the network configuration to closely resemble a traditional IP network that you might operate in your own datacenter.

* One of the scenarios where you may want to use Amazon ElastiCache in a VPC is if you want to run a public-facing web application, while still maintaining non-publicly accessible backend servers in a private subnet. You can create a public-facing subnet for your webservers that has access to the Internet, and place your backend infrastructure in a private-facing subnet with no Internet access. Your backend infrastructure could include RDS DB Instances and an Amazon ElastiCache Cluster providing the in-memory layer.

* Security Groups are not used when operating in a VPC. Instead they are used in the non VPC settings. When creating a cluster in a VPC you will need to use VPC Security Groups.

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
* can peer VPC w/i or across accounts to make it look like they are part of the same network
* to create an ElastiCache Cluters in VPC:
  * You need to have a VPC set up with at least one subnet. For information on creating Amazon VPC and subnets refer to the Getting Started Guide for Amazon VPC.
  * You need to have a Subnet Group (for Redis or Memcached) defined for your VPC.
  * You need to have a VPC Security Group defined for your VPC (or you can use the default provided).
  * In addition, you should allocate adequately large CIDR blocks to each of your subnets so that there are enough spare IP addresses for Amazon ElastiCache to use during maintenance activities such as cache node replacement.

## S3 (Simple Storage Service)

### Buckets
* globally unique name
* defined at regional level
* enable versioning at this level

### Objects
* objects have key: FULL path to file
* 5TB max
* >5GB must use multi-part upload
* >100 MB multi-part recommended
* metadata (system/user)
* tags (up to 10 for security/lifecycle)
* version ID
  * changed on every update
  * no version = null

### Encryption (SSE = Server Side Encryption)
* encryption in flight: via SSL/TLS using HTTPS
  * SSL: secyre socket layer
  * transport layer security
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
  * SSE-C (Server Side Encryption - Client)
    * manage own encryption keys
    * HTTPS must be used
    * S3 does NOT store encryption key
    * send data key in header
    * data is encrypted by amazon and then throws away key
    * aws stored a hashed version of the key
    * uses AES-256
    * When you upload an object, Amazon S3 uses the encryption key you provide to apply AES-256 encryption to your data and removes the encryption key from memory. It is important to note that Amazon S3 does not store the encryption key you provide. Instead, it is stored in a randomly salted HMAC value of the encryption key in order to validate future requests. The salted HMAC value cannot be used to derive the value of the encryption key or to decrypt the contents of the encrypted object. That means, if you lose the encryption key, you lose the object.
    * When you retrieve an object, you must provide the same encryption key as part of your request. Amazon S3 first verifies that the encryption key you provided matches, and then decrypts the object before returning the object data to you.
    * When using server-side encryption with customer-provided encryption keys (SSE-C), you must provide encryption key information using the following request headers:
      * x-amz-server-side-encryption-customer-algorithm – This header specifies the encryption algorithm. The header value must be “AES256”.
      * x-amz-server-side-encryption-customer-key – This header provides the 256-bit, base64-encoded encryption key for Amazon S3 to use to encrypt or decrypt your data.
      * x-amz-server-side-encryption-customer-key-MD5 – This header provides the base64-encoded 128-bit MD5 digest of the encryption key according to RFC 1321. Amazon S3 uses this header for a message integrity check to ensure the encryption key was transmitted without error.
  * Take note that kms:Decrypt is only one of the actions that you must have permissions to when you multi-part upload or download an Amazon S3 object encrypted with an AWS KMS key. You must also have permissions to kms:Encrypt, kms:ReEncrypt*, kms:GenerateDataKey*, and kms:DescribeKey actions.
  * Client side encryption
    * encrypting before sending to S3
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
    * You can use S3 Access Control Lists (ACLs) instead to manage permissions of S3 objects.
  * Bucket Access Control List (ACL) - less common
* networks
  * supports VPC endpoints (not connected to www)
  * logging and audit
    * S3 access logs can be stored in other S3 bucket
    * API calls can be logged in AWS CloudTrail
  * User security
    * MFA can be required in versioned buckets to delete objects
    * signed URLs: valid for limited time (ex: video access)
      * In Amazon S3, all objects are private by default. Only the object owner has permission to access these objects. However, the object owner can optionally share objects with others by creating a pre-signed URL, using their own security credentials, to grant time-limited permission to download the objects.
      * When you create a pre-signed URL for your object, you must provide your security credentials, specify a bucket name, an object key, specify the HTTP method (GET to download the object) and expiration date and time. The pre-signed URLs are valid only for the specified duration.

### S3 Website
* bucket permissions: allow public access
* properties: static website hosting
* need to add JSON bucket policy 
  * allow everyone to getObject
  * troubleshoot 403 

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
  * use CloudFront to cache S3 objects around the world
  * use S3 Transfer Acceleration (uses edge locations) 
    * **enables fast, easy, and secure transfers of files over long distances between your client and your Amazon S3 bucket. Transfer Acceleration leverages Amazon CloudFront’s globally distributed AWS Edge Locations. As data arrives at an AWS Edge Location, data is routed to your Amazon S3 bucket over an optimized network path.**
    * just need to change the endpoint you write to, not the code
  * SSE-KMS encryption: limited to AWS limits for KMS usage (~100s -1000s dls/uls /second)

### S3 Glacier - long term archival for files

### S3 Select
* use query to retrieve only data you need
* no subqueries or joins

### S3 Cross Region Replication
* Cross-region replication (CRR) enables automatic, asynchronous copying of objects across buckets in different AWS Regions. Buckets configured for cross-region replication can be owned by the same AWS account or by different accounts. Cross-region replication is enabled with a bucket-level configuration. You add the replication configuration to your source bucket.
* **To enable the cross-region replication feature in S3, the following items should be met:**
  * The source and destination buckets must have versioning enabled.
  * The source and destination buckets must be in different AWS Regions.
  * Amazon S3 must have permissions to replicate objects from that source bucket to the destination bucket on your behalf.

## CLI (Command Line Interface)

### Ways to Develop and Perform AWS Tasks
  * CLI on local computer
  * CLI on EC2 machine
  * SDK on local computer (software development kit)
  * SDK on EC2 machine
  * AWS Instance Metadata Service for EC2


### Setting up CLI for user on computer

* for target user on IAM: CREATE ACCESS KEY
* In terminal `aws configure`
* follow command line prompts
* no default output format needed
* confirm configuration: `aws configure`
* to see files generated: `ls ~/.aws`
* to see content of files: `cat ~/.aws/config` and `cat ~/.aws/credentials`

### S3 CLI on Personal Computer

google 'aws s3 cli' for documentation

* `aws s3 ls` lists all buckets
* `aws s3 ls s3://carpentercode` lists contents of bucket
* `aws s3 cp help` displays documentation for cp command 
* `q` to quit help
* `aws s3 cp s3://carpentercode/bmc.jpg bmc.jpg` copies file from s3 bucket to current folder
* `aws s3 mb s3://carpentercode2` makes bucket

### CLI on EC2

* NEVER RUN `aws configure` on EC2!!!  Personal credentials do not belong here.
* use IAM roles
* ssh into instance `ssh -i EC2Tutorial.pem ec2-user@54.158.176.234`
* aws configure
  * leave credentials blank
  * enter region
* go to IAM roles and create new role
* attach to EC2
* attach permision policy (ex: S3 read only)
* go to EC2 and right click instance
  * instance settings -> attach/replace IAM Role
  * check in instance details
  * test in terminal (ex: aws s3 ls)
  * can add inline policies
  * use aws policy simulator to test
    * With the IAM policy simulator, you can test and troubleshoot IAM and resource-based policies in the following ways:
      * Test policies that are attached to IAM users, groups, or roles in your AWS account. If more than one policy is attached to the user, group, or role, you can test all the policies, or select individual policies to test. You can test which actions are allowed or denied by the selected policies for specific resources.
      * Test policies that are attached to AWS resources, such as Amazon S3 buckets, Amazon SQS queues, Amazon SNS topics, or Amazon S3 Glacier vaults.
      * If your AWS account is a member of an organization in AWS Organizations, then you can test the impact of service control policies (SCPs) on your IAM policies and resource policies.
      * Test new policies that are not yet attached to a user, group, or role by typing or copying them into the simulator. These are used only in the simulation and are not saved. Take note that you cannot type or copy a resource-based policy into the simulator. To use a resource-based policy in the simulator, you must include the resource in the simulation and select the checkbox to include that resource’s policy in the simulation.
      * Test the policies with selected services, actions, and resources. For example, you can test to ensure that your policy allows an entity to perform the ListAllMyBuckets, CreateBucket, and DeleteBucket actions in the Amazon S3 service on a specific bucket.
      * Simulate real-world scenarios by providing context keys, such as an IP address or date, that are included in Condition elements in the policies being tested.
      * Identify which specific statement in a policy results in allowing or denying access to a particular resource or action.
  * or use cli to simulate api calls without actually making them (save $$$)
    * use --dry-run argument to test

### Decoding Error Messages with STS Decode

* `aws sts decode-authorization-message --encoded-message <value>`
* **must have sts decode allowed in policy**
* to format response `echo <result>`
* copy --> paste --> .JSON document -> format selection using "quick action >"

### EC2 Instance Metadata

* `curl http://169.254.169.254/latest/meta-data`
* **only works from EC2 instance**
* can retrieve IAM Role name but cannot retrieve the IAM Policy
* useful for automation

### Software Developer Kits (SDK)

* Allows you to perform actions on AWS directly from application code (Java, Python aka boto3, Node.js, etc)
* use default credential provider chain
* **exponential backoff is implemented automatically for SDK api calls**

### CLI Profile

* used for multiple aws accounts
* `aws configure --profile my-other-profile`
* `aws s3 ls --profile my-other-profile`

**** Quiz 5 Question 3
* **YOU CANNOT ATTACH EC2 IAM ROLES TO ON-PREMISE SERVERS**

## Elastic BeanStalk

* AWS Elastic Beanstalk lets you manage all of the resources that run your application as environments where each environment runs only a single application version at a time. When an environment is being created, Elastic Beanstalk provisions all the required resources needed to run the application version.

* architecture models
  * single instance deployment: dev
  * LB + ASG: production/pre-prod web apps
  * ASG only: non-web-apps in production (workers, etc)
* components
  * application
  * version
  * environment name
* relies on CloudFormation
* can use EB cli for automated deployment pipelines
  * eb create, eb status, etc.
* **code must be a zip file**
* all parameters set in UI can be configured with code using files
* requirements must be in .ebextensions/ directory in root 
  * format must be YAML or JSON format
  * .config extensions (ex: logging.config)
  * able to modify default settings using: option_settings
  * can add resources such as RDS, ElastiCache, DynamoDB, etc
* optimize in case of long deployment: **package dependencies with source code to improve deployment performance and speed**
* deployment options for updates
  * all at once (instances not available to serve traffic during downtime)
    * no additional $
  * rolling: update a few instances (a bucket) at a time
    * can set bucket size
    * app running both versions simultaneously
    * app running below capacity for period of time
    * no additional cost
    * long deployment
  * rolling with additional batches: new instances are created while moving a batch
    * small additional cost
    * app continues to run at capacity
    * long deployment
    * good for prod
    * additional batch is removed at end
  * immutable: spin up new instances in new ASG, deploy versions to these instances, then swap all instances when everything is healthy
    * high additional cost
    * longest deployment
    * no downtime
    * quick rollback in case of failure
    * great for prod
  * Blue/Green
    * zero downtime and release facility
    * create a NEW stage environment and deploy new version there
    * Route 53 can use weighted policies to redirect some traffic to stage environment
    * swap URLs 
    * manual

### BeanStalk with HTTPS
  * load ssl certificate onto LB 
    * from console
    * from code: .ebextensions/securelistener-alb.config
    * using ACM (AWS Certificate Manager) or CLI
  * **must configure sg rule to allow incoming port 443 (HTTPS)**
  * redirect from http to https
    * configure your instances (look up)
    * or configure ALB with a rule
    * make sure health checks are not redirected

### BeanStalk Lifecycle Policy

* can store at most 1000 application versions
* need to phase out old app versions using lifecycle policy
  * based on time
  * based on space
* option not to delete source code bundle

**Customize runtime of EB by providing a custom platform**

### Web Server vs Worker Environment

* offload tasks to worker environment (processing video, generating zip file, etc)
* can define periodic tasks in a cron.yaml file
* AWS resources created for a worker environment tier include an Auto Scaling group, one or more Amazon EC2 instances, and an IAM role. For the worker environment tier, Elastic Beanstalk also creates and provisions an Amazon SQS queue if you don’t already have one. When you launch a worker environment tier, Elastic Beanstalk installs the necessary support files for your programming language of choice and a daemon on each EC2 instance in the Auto Scaling group.
* The daemon is responsible for pulling requests from an Amazon SQS queue and then sending the data to the web application running in the worker environment tier that will process those messages. If you have multiple instances in your worker environment tier, each instance has its own daemon, but they all read from the same Amazon SQS queue.
* You can define periodic tasks in a file named cron.yaml in your source bundle to add jobs to your worker environment’s queue automatically at a regular interval. For example, you can configure and upload a cron.yaml file which creates two periodic tasks: one that runs every 12 hours and a second that runs at 11pm UTC every day.

### RDS + BeanStalk

* decouple RDS (database) from BeanStalk
* if you need to decouple
  * take RDS DB snapshot
  * enable deletion protection
  * in BeanStalk create new env that points to existing RDS
  * swap new and old env
  * terminate old env
  * delete CloudFormation stack

* To decouple your database instance from your environment, you can run a database instance in Amazon RDS and configure your application to connect to it on launch. This enables you to connect multiple environments to a database, terminate an environment without affecting the database, and perform seamless updates with blue-green deployments.

* To allow the Amazon EC2 instances in your environment to connect to an outside database, you can configure the environment’s Auto Scaling group with an additional security group. The security group that you attach to your environment can be the same one that is attached to your database instance, or a separate security group from which the database’s security group allows ingress.

* You can connect your environment to a database by adding a rule to your database’s security group that allows ingress from the autogenerated security group that Elastic Beanstalk attaches to your environment’s Auto Scaling group. However, doing so creates a dependency between the two security groups. Subsequently, when you attempt to terminate the environment, Elastic Beanstalk will be unable to delete the environment’s security group because the database’s security group is dependent on it.

## Continuous Integration/ Continuous Devliery (CICD)

* *"CodeDeploy" : You can deploy nearly unlimited variety of application content, such as code, serverless AWS Lambda functions, web and configuration files, executables, packages, scripts, multimedia files, and so on.

* "CodeBuild" - AWS CodeBuild is a fully managed continuous integration service that compiles source code, runs tests, and produces software packages that are ready to deploy

* * "CodeCommit" - CodeCommit eliminates the need to operate your own source control system or worry about scaling its infrastructure

"CodePipeline" - CodePipeline automates the build, test, and deploy phases of your release process every time there is a code change, based on the release model you define

### CodeCommit: Storing code

#### Summary
* allows for version control
* private git repos
* no size limits
* fully managed, highly available
* only in Cloud account - high security
* secure
* integrated with Jenkins, CodeBuild, etc
* authentication with SSH keys or HTTPS through AWS CLI Authentication helper
* can enable MFA
* authorization: IAM Policies manage user/roles rights to repos
* encryption: repo encrypted at rest using KMS
* encryption: in flight thorugh HTTPS or SSH 
* cross-account access
  * do not share SSH keys!
  * do not share AWS creds!
  * use IAM role + AWS STS with AsumeRole API (security token system)
* notification options
  * SNS (simple notification service)
  * Lambda
  * CloudWatch Event Rule
  * Use case SNS/Lambda
    * deletion of branch
    * trigger for push happens in master
    * notify external Build System
    * trigger Lambda function to perform codebase analysis (check for creds in code)
  * Use case CloudWatch
    * trigger for pull requests (create, update, delete, comment)
    * commit comment events
    * trigger notication into SNS topic

#### CodeCommit implementation

* create repo
* settings
  * notifications
  * triggers
* to make commits
  * IAM users
  * security credentials
  * use HTTPS Git credentials for AWS CodeCommit
  * generate credentials
  * git clone and input credentials
  * work and git ACP!  (git push)


### CodeBuild: build and test code

* fully managed build service
* continous scaling
* pay for usage: time it takes to complete builds
* leverages Docker for reproducible builds
* can extend capabilities using our own Docker images
* integration with KMS for build artifacts, IAM for build permissions, VPC network security, CloudTrail for logging
* can source code from Github, CodeCommit
* Build instructions can be defined in code (buildspec.yml file)
  * root
  * define env variables
  * use SSM parameter store for secret keys
  * phases: define commands to run 
    * install dependencies
    * pre build: final commands to run before build
    * build commands
    * post build: zip files, etc
  * artifacts: what files to upload to S3
  * **cache: files to cache to S3 for future builds**
* output logs to S3 and CloudWatch logs
* **CloudWatch Alarms can be used to detect failed builds and trigger notifications**
* CloudWatch Events/Lambda as a Glue
* ablity to reproduce CodeBuild locally to troubleshoot
  * run CodeBuild locally (need Docker)
  * **do this by leveraging CloudBuild agent**
* builds can be definied either with CodePipeline or CodeBuild itself

### Implementing CodeBuild

* CodeBuild -> Build project
* choose source provider and repo
* environment: ubuntu
* runtime: standard
* image: use latest (standard:4.0)
* timeout: how long to run before timeout
* add buildspec.yml
* add codebuild to pipeline

### CodeDeploy: deploy and provision code to EC2 fleets (not BeanStalk)

* deploy to many EC2 instances
* instances not managed by Elastic Beanstalk
* **each EC2 MUST be running a CodeDeploy agent**
* agent continuously polls for work to do
* **CodeDeploy sends appspec.yml**
* app is pulled from GitHub or S3
* EC2 runs deployment instructions
* agent reports back success/failure
* **EC2 instances are grouped by deployment group**
* can integrate with CodePipeline
* can reuse existing setup tools, works with any app, and has auto scaling integration
* can do Blue/Green deployments with EC2 instances (but not with on-premise)
* can do lambda deployments
* **does NOT provision resources (instances must exist already)**

* CodeDeploy provides two deployment type options:

  * In-place deployment: The application on each instance in the deployment group is stopped, the latest application revision is installed, and the new version of the application is started and validated. You can use a load balancer so that each instance is deregistered during its deployment and then restored to service after the deployment is complete. Only deployments that use the EC2/On-Premises compute platform can use in-place deployments. AWS Lambda compute platform deployments cannot use an in-place deployment type.

* Blue/green deployment: The behavior of your deployment depends on which compute platform you use:
  * Blue/green on an EC2/On-Premises compute platform: The instances in a deployment group (the original environment) are replaced by a different set of instances (the replacement environment). If you use an EC2/On-Premises compute platform, be aware that blue/green deployments work with Amazon EC2 instances only.
  * Blue/green on an AWS Lambda compute platform: Traffic is shifted from your current serverless environment to one with your updated Lambda function versions. You can specify Lambda functions that perform validation tests and choose the way in which the traffic shift occurs. All AWS Lambda compute platform deployments are blue/green deployments. For this reason, you do not need to specify a deployment type.
  * Blue/green on an Amazon ECS compute platform: Traffic is shifted from the task set with the original version of a containerized application in an Amazon ECS service to a replacement task set in the same service. The protocol and port of a specified load balancer listener are used to reroute production traffic. During deployment, a test listener can be used to serve traffic to the replacement task set while validation tests are run.

* The CodeDeploy agent is a software package that, when installed and configured on an instance, makes it possible for that instance to be used in CodeDeploy deployments. **The CodeDeploy agent communicates outbound using HTTPS over port 443.**

* **It is also important to note that the CodeDeploy agent is required only if you deploy to an EC2/On-Premises compute platform. The agent is not required for deployments that use the Amazon ECS or AWS Lambda compute platform.**

**research ON PREMISE instance**

### CodeDeploy Components

* Application (unique name)
* Compute platform (EC2/On-premise or Lambda)
* Deployment configuration
  * rules for success/failure
  * can specify min number of healthy instances for deployment
  * can specify how many instances to deploy at a time
    * 1
    * 50%
    * all at once (dev)
    * custom
  * for Lambda: how traffic is routed to functions
  * new deployments will be deployed to failed instances first
  * deployment targets: set of EC2 instances with tags
* Deployment group: group of tagged instances
* Deployment type: in-place or Blue/Green
* **IAM instance profile: need to give EC2 permissions to pull from S3/GitHub**
* Application revision
* Service role: role for CodeDeploy to perform
* Target revision

### Implementing CodeDeploy

* create app in codedeploy
* create IAM service role for CodeDeploy
  * roles -> create new role -> AWS service -> CodeDeploy
* create IAM EC2 service role 
  * needs S3 read access
* instance needs IAM role of EC2
* configure sg: http
* ssh into instance
* install agent
#!/bin/bash

```# Installing CodeDeploy Agent
sudo yum update
sudo yum install ruby

# Download the agent (replace the region)
wget https://aws-codedeploy-eu-west-3.s3.eu-west-3.amazonaws.com/latest/install
chmod +x ./install
sudo ./install auto
sudo service codedeploy-agent status
```

* add a tag to EC2 instance (ex: env: dev)
* create deployment group
  * add service role (service role for code deploy)
  * add tag created on instance
  * choose deployment settings
* create deployment
  * choose where it is stored
* upload app to s3 bucket
* copy path to content
* in CodeDeploy, use path as revision path

#### appspec.yml

* File section: how to source and copy from S3/GitHub
* Hooks: set of instructions to deploy new version
  * ApplicationStop
  * DownloadBundle
  * BeforeInstall
  * AfterInstall
  * ApplicationStart
  * ValidateService: health check

### CodePipeline: automate pipeline from code to ElasticBeanStalk

* continuous delivery
* visual workflow
* source: GitHub, CodeCommit, Amazon S3
* Build: CodeBuild, etc
* Load Testing: 3rd party tools
* Deploy: AWS CodeDeploy, Beanstalk, CloudFormation, ECS, etc
* made of stages
  * sequential and/or parallel (ex: build, test, etc...)
  * manual approval can be defined at any stage
  * each stage creates 'artifacts' stored in S3 and retrieved from S3 bucket for next stage
* troubleshooting
  * state change generates CloudWatch event -> trigger SNS notification
  * can create events for failed pipelines, cancelled stages, etc
  * pipeline stops at failed stage - can get info in console
  * can audit API calls using CloudTrail
  * check IAM Service Role for permissions (IAM Policy)
* detection using CloudWatch is recommended
* can add multiple action groups to stage sequentially or parallel (ex: manual approval and then deploy to prod)

### CodeStar

* integrated solution that regroups GitHub, CodeCommit, CodeBuild, CodeDeploy, CloudFormation, CodePipeline, CloudWatch
* ability to integrate with Cloud9 to obtain web IDE
* one dashboard
* limited customization

## CloudFormation

Managing infrastructure as code

* code with create, update, delete, etc infrastructure
* can estimate cost of resources using CloudFormation template
* savings strategy: automate deletion of templates at 5pm and recreate at 8am
* declarative: don't need to order or orchestrate
* creates many stacks for many apps (ex: VPC stack, network stacks, app stacks)
* leverage existing templates and documentation
* **upload template in S3**
* **can't edit templates - upload new version**
* **deleting a stack deletes all artifacts associated with it**
* template helpers 
  * references and functions
* Any resources created as part of your .ebextensions is part of your CloudFormation template and will get deleted if the environment is terminated
* AWS CloudFormation StackSets extends the functionality of stacks by enabling you to create, update, or delete stacks across multiple accounts and regions with a single operation. Using an administrator account, you define and manage an AWS CloudFormation template, and use the template as the basis for provisioning stacks into selected target accounts across specified regions.
* After you’ve defined a stack set, you can create, update, or delete stacks in the target accounts and regions you specify. When you create, update, or delete stacks, you can also specify operational preferences, such as the order of regions in which you want the operation to be performed, the failure tolerance beyond which stack operations stop, and the number of accounts in which operations are performed on stacks concurrently. Remember that a stack set is a regional resource so if you create a stack set in one region, you cannot see it or change it in other regions.

### Deploying CloudFormation templates

* Manually
  * edit template in CloudFormation Designer
  * use console to input parameters
* Automated
  * edit templates in YAML file
  * use AWS CLI to deploy
  * recommended to fully automate

* AWS CloudFormation provides the following Python helper scripts that you can use to install software and start services on an Amazon EC2 instance that you create as part of your stack:
  * cfn-init: Use to retrieve and interpret resource metadata, install packages, create files, and start services.
  * cfn-signal: Use to signal with a CreationPolicy or WaitCondition, so you can synchronize other resources in the stack when the prerequisite resource or application is ready.
  * cfn-get-metadata: Use to retrieve metadata for a resource or path to a specific key.
  * cfn-hup: Use to check for updates to metadata and execute custom hooks when changes are detected.
* You call the scripts directly from your template. The scripts work in conjunction with resource metadata that’s defined in the same template. The scripts run on the Amazon EC2 instance during the stack creation process. The scripts are not executed by default. You must include calls in your template to execute specific helper scripts.

### CloudFormation Building Blocks

#### Resources
* mandatory
* can reference each other (sg & instance)
* identifier: AWS::aws-product-name::data-type-name
* see AWS resource types references
* each resource must have type and properties
* cannot create dynamic amount of resources
* can work around unsupported resources using custom Lambda

#### Parameters
* way to provide inputs to your AWS CloudFormation template
* enable reusing templates across apps
* if a resource configuration is likely to change in the future, use a parameter to avoid re-uploading template to change the content
* use Fn::Ref
  * !Ref
  * can reference parameters or resources
    * returns value of parameter or id of resources
* pseudo parameters
  * AWS::AccountId
  * AWS::NotificationARNs

#### Mappings
* fixed variables within your CloudFormation Template
* can be used to differentiate between different environments (dev vs. prod), AWS regions, AMI types, etc
* ex:
```Mappings:
    Mapping01:
      Key01:
        Name: Value01
    Mapping02:
      Key02:
        Name: Value02
```
* use Fn::FindInMap to return value from specific key
* !FindInMap [Mapname, TopLevelKey, SecondLevelKey]

#### Outputs
* values that can be exported from stack that can be imported to other stacks
* can be viewed in AWS console or AWS CLI
* ex: could define network CloudFormation and output variables such as VPC ID and Subnet IDs
* enables collaboration cross-stack 
* can't delete stack that has outputs being referenced elsewhere
* exported output name must be unique within your region
* export example: 
``` Outputs:
      StackSSHSecurityGroup:
        Description: fjdkslkdjf
        Value: !Ref sdfkldkj
        Export:
          Name: SSHSecurityGroup 
```
* import example: 
  ```Resources:
      MySecureInstance:
        Type: AWS::sdflkj
        Properties:
          sdkflkj
          sdlfkj
          sdflkj
          SecurityGroups:
            - !ImportValue SSHSecurityGroup
  ```

#### Conditions
* used to control creation of resources or outputs based on condition
* And, Equals, If, Not, Or
* Define condition Example: 
```Conditions:
    CreateProdResources: !Equals [ !Ref EnvType, prod ]
```
* Apply condition example:
```Resources:
    MountPoint:
      Type: sdlfkdjklkj
      Condition: CreateProdResources
```

#### Intrinsic Functions
* Ref
  * Parameter: returns value of parameter
  * Resources: returns physical ID of resource
* Fn::GetAtt (uses dot notation to reference attributes)
* Fn::FindInMap
* Fn::ImportValue
* Fn::Join
  * example: !Join [ ":", [a, b, b]] => "a:b:c"
* Fn:Sub
  * substitute values in string
  * example: 
  ```!Sub
        - String
        - { Var1Name: Var1Value, Var2Name: Var2Value }
* Conditions

#### Metadata

#### CloudFormation Rollbacks
* Stack create failures
  * default is to roll back (gets deleted)
  * option to disable roll back and troubleshoot
* Stack update fails
  * stack auto rolls back to previous known working state
  * update_fails
  * check log for error messages

## Monitoring & Audit

### CloudWatch
* Metrics
  * variable to moniter (CPUUtilization, NetworkIn, etc)
  * belong to namespace
    * dimension is an attribute (instance id, etc)
    * up to 10 dimensions per metric
  * have timestamps
  * dashboard
  * default: once every 5 minutes
    * can enable detailed monitoring for extra cost
    * can be used to decrease ASG response time
  * recall: EC2 Instance Memory usage not pushed by default.  Push from instance as custom metric
  * standard resolution for custom metric: 1 minute
    * can enable high resolution for up to 1 second
    * StorageResolution API parameter
    * increased $
  * send metric to CloudWatch with PutMetricData
  * use expontential backoff in case of throttle errors
* Logs
  * apps can send logs to CloudWatch using SDK
  * CloudWatch can collect log from 
    * Elastic BeanStalk
    * ECS: collections from containers
    * Lambda
    * VPC Flow Logs
    * API gateway
    * CloudTrail based on filter
    * CloudWatch log agents (ex: on EC2 machine)
    * Route 53: log DNS queries
  * can be exported to S3
  * can be streamed to ElasticSearch
  * can use filter expresions
  * architecture
    * groups (represent app)
    * stream (instances within app/logfiles/containers)
  * can define log expiration policies (never, 30 days, etc)
  * to send logs, ensure IAM permissions
  * can encrypt logs using KMS at rest at group level
* Events
  * schedule with Cron jobs
  * Event pattern: define event rule to react to a service doing something
    * ex: CodePipeline state changes
  * trigger to Lambda functions, SQS/SNS/Kinesis messages
  * creates small JSON doc to give info about change
* Alarms
  * trigger notification for any metric
  * send to auto scaling, EC2 actions, SNS notifications
  * various options (sample, %, max, min, etc)
  * Alarm States: OK, INSUFFICIENT DATA, ALARM
  * period: length of time in seconds to evaluate metric
    * high resolution custom metrics: can only choose 10 sec or 30 sec

### X-ray
* troubleshoot app performance and errors
* distributed tracing of microservices
* compatible with
  * Lambda
    * check x-ray integration
    * IAM role is Lambda role
  * Elastic Beanstalk
    * set configuration on EB console
    * or use beanstalk ext: .ebextensions/xray-demon.config
  * ECS/EKS/Fargate (docker)
    * create docker image that runs demon or use official x-ray docker image
    * ensure port mappings and network settings are correct and IAM task roles are defined
  * ELB
  * API gateway
  * EC2 instances or any app server (including on premise!)
    * linux system must run x-ray demon
    * IAM instance role if EC2, otherwise AWS creds on on-premise instance
* can add annotations to traces to provide extra info
* can trace
  * every request
  * sample request (% or rate per minute)
  * By default, the X-Ray SDK records the first request each second, and five percent of any additional requests.
* Annotations are simple key-value pairs that are indexed for use with filter expressions. Use annotations to record data that you want to use to group traces in the console, or when calling the GetTraceSummaries API. X-Ray indexes up to 50 annotations per trace.
* Metadata are key-value pairs with values of any type, including objects and lists, but that are not indexed. Use metadata to record data you want to store in the trace but don’t need to use for searching traces. You can view annotations and metadata in the segment or subsegment details in the X-Ray console.
* security requires IAM for authorization and KMS for encryption at rest
* implementation
  * code: import AWS X-ray SDK
  * install x-ray daemon or enable x-ray aws integration
    * works as low level UDP packet interceptor
    * Lambda already runs x-ray for you
  * app must have IAM rights to write data to x-ray
* troubleshooting EC2
  * ensure EC2 IAM role has permissions
  * ensure instance is running x-ray demon
* troubleshooting Lambda
  * IAM execution role with proper policy (AWSX-RayWriteOnlyAccess)
  * x-ray imported in code
* x-ray deamon/agent has config to send traces across accounts
  * segments: each app/service will send them
  * trace: segments collected together to form end-to-end trace
  * sampling: can reduce traces to a %
  * annotations: key/value pairs used to index traces and use with filters
  * metadata is NOT indexed, not used for searches
* code must be instrumented to used x-ray SDK
* X-Ray uses the data that your application sends to generate a service graph. Each AWS resource that sends data to X-Ray appears as a service in the graph. Edges connect the services that work together to serve requests. Edges connect clients to your application, and your application to the downstream services and resources that it uses.

### X-ray details

You can send trace data to X-Ray in the form of segment documents. A segment document is a JSON formatted string that contains information about the work that your application does in service of a request. Your application can record data about the work that it does itself in segments or work that uses downstream services and resources in subsegments.

### X-ray Segment Summary
A segment document conveys information about a segment to X-Ray. A segment document can be up to 64 kB and contain a whole segment with subsegments, a fragment of a segment that indicates that a request is in progress, or a single subsegment that is sent separately. You can send segment documents directly to X-Ray by using the PutTraceSegments API.

An alternative is, instead of sending segment documents to the X-Ray API, you can send segments and subsegments to an X-Ray daemon, which will buffer them and upload to the X-Ray API in batches. The X-Ray SDK sends segment documents to the daemon to avoid making calls to AWS directly. 

X-Ray compiles and processes segment documents to generate queryable trace summaries and full traces that you can access by using the GetTraceSummaries and BatchGetTraces APIs, respectively. In addition to the segments and subsegments that you send to X-Ray, the service uses information in subsegments to generate inferred segments and adds them to the full trace. Inferred segments represent downstream services and resources in the service map.

X-Ray provides a JSON schema for segment documents. You can download the schema here: xray-segmentdocument-schema-v1.0.0. The fields and objects listed in the schema are described in more detail in the following sections.

A subset of segment fields are indexed by X-Ray for use with filter expressions. For example, if you set the user field on a segment to a unique identifier, you can search for segments associated with specific users in the X-Ray console or by using the GetTraceSummaries API.

Below are the optional subsegment fields:

namespace – aws for AWS SDK calls; remote for other downstream calls.

http – http object with information about an outgoing HTTP call.

aws – aws object with information about the downstream AWS resource that your application called.

error, throttle, fault, and cause – error fields that indicate an error occurred and that include information about the exception that caused the error.

annotations – annotations object with key-value pairs that you want X-Ray to index for search.

metadata – metadata object with any additional data that you want to store in the segment.

subsegments – array of subsegment objects.

precursor_ids – array of subsegment IDs that identifies subsegments with the same parent that completed prior to this subsegment.

* AWS Lambda uses environment variables to facilitate communication with the X-Ray daemon and configure the X-Ray SDK.

    * _X_AMZN_TRACE_ID: Contains the tracing header, which includes the sampling decision, trace ID, and parent segment ID. If Lambda receives a tracing header when your function is invoked, that header will be used to populate the _X_AMZN_TRACE_ID environment variable. If a tracing header was not received, Lambda will generate one for you.

    * AWS_XRAY_CONTEXT_MISSING: The X-Ray SDK uses this variable to determine its behavior in the event that your function tries to record X-Ray data, but a tracing header is not available. Lambda sets this value to LOG_ERROR by default.

    * AWS_XRAY_DAEMON_ADDRESS: This environment variable exposes the X-Ray daemon’s address in the following format: IP_ADDRESS:PORT. You can use the X-Ray daemon’s address to send trace data to the X-Ray daemon directly, without using the X-Ray SDK.

#### Implementing X-Ray
* on Elastic BeanStalk
  ```
  # .ebextensions/xray-daemon.config
  option_settings:
      aws:alsticveanstalk:xray:
        XRayEnabled: true
  ```

### CloudTrail
* internal monitering of API calls
* audit changes to AWS resources made by users
* enabled by default
* get history of events/API calls 
* if a resource is deleted, check CloudTrail first!

## Integration and Messaging

* when deploying multiple apps, they need to communicate.
* two patterns of app communication
  * synchronous: app to app
  * asynchronous/event-based: app to queue to app

### SQS: queue
* producers send messages to SQS queue
* consumers poll messages from SQS queue

* Q: Does Amazon SQS guarantee delivery of messages?
    * Standard queues provide at-least-once delivery, which means that each message is delivered at least once.
    * FIFO queues provide exactly-once processing, which means that each message is delivered once and remains available until a consumer processes it and deletes it. Duplicates are not introduced into the queue.
* You can tag and track your queues for resource and cost management using cost allocation tags. A tag is a metadata label comprised of a key-value pair. For example, you can tag your queues by cost center and then categorize and track your costs based on these cost centers.
* To determine the time-in-queue value, you can request the SentTimestamp attribute when receiving a message. Subtracting that value from the current time results in the time-in-queue value.
* sharing queues
  * associate an access policy statement with queue to be shared
  * provide user with full URL for queue (response in CreateQueue and ListQueues)
* cannot share messages between queues in different regions - each queue is independent within a region
* use SetQueueAttributes to restrict access to message queue by IP address, time of day

#### Standard Queue
* fully managed
* enable SSE using KMS
  * can set Customer Master Key
  * can set data key reuse period b/w 1 minute and 24 hours (default 5 minutes)
  * SSE only encrypts body (not metadata)
* IAM policy must allow usage of SQS
* SQS queue access policy
  * finer grain control over IP
  * control over the time the requests come in
* No VPC Endpoint - must have interet access to access SQS
* API
  * CreateQueue, DeleteQueue
  * PurgeQueue: deletes all messages in queue
  * SendMessage, RecevieMessage, DeleteMessage
  * ChangeMessageVisibility: change timeout
  * BatchDeleteMessage, etc.... decreases cost  
  * no BatchReceiveMessage as you can receive up to 10 messages at a time by default
  * WaitTimeSeconds: long polling
* scales from 1 message per second to 10,000 per second
* default retention of messages for 4 days/Min 1 minute/Max 14 days
  * MessageRetentionPeriod (in seconds)
* no message limit
* low latency (<10 ms on publish/receive)
* horizontal scaling for consumers
* can have duplicate messages
* can have out of order messages
* 256KB limit per message
  * SetQueueAttributes method -> MaximumMessageSize attribute
  * 1KB to 256KB of XML, JSON, unformatted text
* delay: none by default
* can delay up to 15 minutes before consumers can see
  * set default at queue level or use DelaySeconds parameter
* message anatomy
  * message body (string)
  * add optional message attributes (metadata)
    * An Amazon SQS message can contain up to 10 metadata attributes. You can use message attributes to separate the body of a message from the metadata that describes it. This helps process and store information with greater speed and efficiency because your applications don't have to inspect an entire message before understanding how to process it.
    * Amazon SQS message attributes take the form of name-type-value triples. The supported types include string, binary, and number (including integer, floating-point, and double).
  * get back message identifier and MD5 hash of body
* consumers poll for up to 10 messages at a time
  * must proccess within visibility timeout
    * once consumer polls the message, it will be INVISIBLE to other consumers
    * between 0s and 12 hours
    * defaults to 30 seconds
    * consumer can use ChangeMessageVisibility API to change visibility while processing a message
    * DeleteMessage API to tell SQS to delete using message ID and receipt handle
      * When you issue a DeleteMessage request on a previously-deleted message, Amazon SQS returns a success response
* Dead Letter Queue
  * can set threshold of how many times a message can go back to queue
  * redrive policy
  * send message to DeadLetterQueue and be sure to process before it expires!
  * DLQ must be created first and designated as DLQ
* Long Polling
  * can wait for messages to arrive if there are no messages in the queue
  * decreases the number of API calls
  * increase efficiency and latency
  * wait time can be between 1 sec to 20 sec
  * enable at queue level or consumer can poll with WaitTimeSeconds API
  * console: You can configure long polling to your SQS queue by simply setting the “Receive Message Wait Time” field to a value greater than 0.
* SQS CLI
  * aws sqs list-queues
  * aws sqs list-queues --region us-east-1 

#### FIFO Queue
* Firt in first out (not available in all regions)
* naming convention: myqueue.fifo
* lower throughput: up to 3,000 per second with batching, 300/s without
* messages are processed in order by consumer
* messages are sent exactly once
* no per message delay (only per queue delay)
* deduplication: do not send message twice!
  * provide MessageDeduplicationId with your message
  * dedup interval is 5 minutes
  * content-based dedup: the DedubID is generated as the SHA-256 of message body
* to ensure strict-ordering, specify a MessageGroupId
* messages with same group will be sent to same consumercode
  * If multiple hosts (or different threads on the same host) send messages with the same message group ID are sent to a FIFO queue, Amazon SQS delivers the messages in the order in which they arrive for processing. To ensure that Amazon SQS preserves the order in which messages are sent and received, ensure that multiple senders send each message with a unique message group ID.
* Can I convert my existing standard queue to a FIFO queue?
  * No. You must choose the queue type when you create it. However, it is possible to move to a FIFO queue.
* Some AWS or external services that send notifications to Amazon SQS might not be compatible with FIFO queues, despite allowing you to set a FIFO queue as a target:
  * Auto Scaling Lifecycle Hooks
  * AWS IoT Rule Actions
  * AWS Lambda Dead Letter Queues
* use FIFO DLQ with FIFO queue

#### SQS Extended Client
* for sending large messages
* use SQS Extended Client and send message straight to S3
* message is then sent with info about where to find message in S3

### SNS: pub/sub
* send one message to many recipients
* event producer only sends message to SNS topic
* event receivers (subscriptions) listen to SNS topic notifications
* up to 10,000,000 subscriptions per topic
* subscriber types
  * SQS
  * HTTP/HTTPS
  * email
  * Lambda
  * SMS messages
  * mobile notifications
* integrates with CloudWatch (alarms), ASG notifications, CloudFormation (failures, etc)

#### Publish
* review
* Topic Publish
  * create topic
  * create subscription(s)
  * publish to topic
* Direct Publish
  * create platform app and endpoints 

#### SNS + SQS:Fan Out
* push once in SNS
* have many SQS subscriptions
* fully decoupled
* no data loss
* scalable - can add receivers
* allows for delayed processing and retries

### Kinesis: real-time streaming
* polling
* alternative to Apache Kafka
* great for app logs, metrics, IoT, clickstreams
* good for real-time big data
* good for streaming processing frameworks
* automatically replicated to 3 AZ
* security
  * control/access using IAM policies
  * encryption in flight: HTTPS
  * encryption at rest: KMS
  * VPC endpoints

#### Kinesis Streams
* low latency streaming ingest at scale
* streams divided into ordered shards/partitions
* shards: think of like queues
  * write at 1 MB/s or 1000 records/second
    * PutRecord or PutRecords 
  * read at 2 MB/s
  * billing is per shard
  * can batch per message calls
  * number of shards can evolve (reshard or merge)
  * records are ordered per shard
* data retention: default 1 day/up to 7 days
* Kinesis Producer Library: helps with putting data into stream
* Kinesis Agent: Java app that helps with collecting and sending data to stream
* max data blob size: 1MB
* ability to reprocess and replay data
* multiple apps can consume same stream
* enables real-time processing with scale of throughput
* once data is inserted, it can't be deleted (immutable)
* PutRecord API + partition key that gets hashed to determine shard ID
  * same key goes to same partition
  * message gets sequence number when sent to shard
  * partition key needs to be highly distributed to ensure that data is spread out amoung shards (user_id is good, country_id bad = HOT partition)
* can use batching 
* ProvisionedThroughputExceeded exception
  * sending too much data to one shard
  * retry with backoff
  * increase shards
  * ensure good partition key
  * check CloudWatch to see changed in data stream's input data rate and occurrence of ProvisionedThroughputExceeded exceptions
* consumers
  * can use normal consumer (CLI, SDK, etc)using Kinesis API
  * can use Kinesis Client Library
    * helps you easily buid Kinesis Apps for reading and processing data from stream
    * KCL uses DynamoDB to checkout offsets and track other workers and share work amongst shards
    * each shard can only be read by one KCL instance
    * progress is checkpointed into DynamoDB (needs IAM access)
    * KCL can run on EC2, Elastic Beansalk, on premise app
    * read in-order on shard level
    * call GetRecord on loop to iterate through data stream
* enhanced fan-out (parallel consumption of stream): utilize by retrieving data with SubscribeToShard API and Kinesis Data Streams Service
* Kinesis Connector Library enables connetors to DynamoDB, Redshift, S3, Elasticsearch
* Using the Kinesis Adapter is the recommended way to consume Streams from DynamoDB. The DynamoDB Streams API is intentionally similar to that of Kinesis Streams, a service for real-time processing of streaming data at massive scale. You can write applications for Kinesis Streams using the Kinesis Client Library (KCL). The KCL simplifies coding by providing useful abstractions above the low-level Kinesis Streams API. As a DynamoDB Streams user, you can leverage the design patterns found within the KCL to process DynamoDB Streams shards and stream records. To do this, you use the DynamoDB Streams Kinesis Adapter. The Kinesis Adapter implements the Kinesis Streams interface, so that the KCL can be used for consuming and processing records from DynamoDB Streams.

#### Kinesis Analytics
* perform real-time analytics on streams using SQL
* pay for consumption rate
* can create streams out of real-time queries

#### Kinesis Firehose
* load streams into S3, etc
* near real-time
* pay for data conversion from one format to another
* pay for amount of data going through Firehose
* can dump data to S3, ElasticSearch, Redshift, Splunk

## Lambda

* Instead of managing servers, developers just deploy functions.
* easy monitoring with CloudWatch
* node, python, c#, go, java
* integrate with CloudWatch Events to trigger lambda functions on regular basis
* You can create rules that match selected events in the stream and route them to your AWS Lambda function to take action. For example, you can automatically invoke an AWS Lambda function to log the state of an EC2 instance or AutoScaling Group. You maintain event source mapping in Amazon CloudWatch Events by using a rule target definition.
* easy to get more resources per function (up to 3GB of RAM)
* integrated with API Gateway, Kinesis, DynamoDB, S3, SNS, SQS, Cognito, IoT, CloudWatch Events and Logs
* You can implement an AWS Lambda runtime in any programming language. A runtime is a program that runs a Lambda function’s handler method when the function is invoked. You can include a runtime in your function’s deployment package in the form of an executable file named bootstrap.

  * A runtime is responsible for running the function’s setup code, reading the handler name from an environment variable, and reading invocation events from the Lambda runtime API. The runtime passes the event data to the function handler, and posts the response from the handler back to Lambda.

  * Your custom runtime runs in the standard Lambda execution environment. It can be a shell script, a script in a language that’s included in Amazon Linux, or a binary executable file that’s compiled in Amazon Linux.

* To create a Lambda function, you need a deployment package and an execution role. The deployment package contains your function code. The execution role grants the function permission to use AWS services, such as Amazon CloudWatch Logs for log streaming and AWS X-Ray for request tracing. You can use the CreateFunction API via the AWS CLI or the AWS SDK of your choice.
  * A function has an unpublished version, and can have published versions and aliases. The unpublished version changes when you update your function’s code and configuration. A published version is a snapshot of your function code and configuration that can’t be changed. An alias is a named resource that maps to a version, and can be changed to map to a different version.
  * The InvalidParameterValueException will be returned if one of the parameters in the request is invalid. For example, if you provided an IAM role in the CreateFunction API which AWS Lambda is unable to assume. 

* To create a Lambda function, you first create a Lambda function deployment package, a .zip or .jar file consisting of your code and any dependencies. When creating the zip, include only the code and its dependencies, not the containing folder. You will then need to set the appropriate security permissions for the zip package.

* If you are using a CloudFormation template, you can configure the AWS::Lambda::Function resource which creates a Lambda function. To create a function, you need a deployment package and an execution role. The deployment package contains your function code. The execution role grants the function permission to use AWS services, such as Amazon CloudWatch Logs for log streaming and AWS X-Ray for request tracing.

* Under the AWS::Lambda::Function resource, you can use the Code property which contains the deployment package for a Lambda function. For all runtimes, you can specify the location of an object in Amazon S3.

* For Node.js and Python functions, you can specify the function code inline in the template. Changes to a deployment package in Amazon S3 are not detected automatically during stack updates. To update the function code, change the object key or version in the template.

* When you connect your Lambda function to a VPC, the function loses its default internet access. If you require external internet access for your function, make sure that your security group allows outbound connections and that your VPC has a NAT gateway.

* **no scheduling feature of Lambda! Integrate with CloudWatch Events to schedule based on rule**

### Lambda Functions

* virtual functions = no servers to manage
* limited by time = short executions
* run on-demand
* scaling is automated
* best practices
  * Separate the Lambda handler (entry point) from your core logic.
  * Take advantage of Execution Context reuse to improve the performance of your function
  * Use AWS Lambda Environment Variables to pass operational parameters to your function.
  * Control the dependencies in your function’s deployment package.
  * Minimize your deployment package size to its runtime necessities.
  * Reduce the time it takes Lambda to unpack deployment packages
  * Minimize the complexity of your dependencies
  * Avoid using recursive code

### Lambda Pricing
* pay per request and compute time 
* 10^6 requests -> $0.2/10^6 after
* 400,000 GBs compute time => $1.0/600,000 GBs

### Lambda Configurations
* timeout: default 3 s/ max 15 minutes (900s)
* environment variables
* allocated memory (128MB to 3GB)
* can deploy within a VPC and assign SGs
* IAM role must be attached 
* research interaction between VPC and Lambda Function
* edit code
  * inline
  * upload .zip
  * upload from S3

### Lambda Concurrency and Throttling
* concurrency
  * up to 1000 executions at a time
  * can be increased with ticket
  * can set "reserved concurrency" at function level
    * unreserved account concurrency cannot go below 100!
  * each invocation over the concurrency limit will trigger a "throttle"
  * when integrating lambda with kinesis or dynamoDB stream, # of concurrent executions = # kinesis shards
* throttle
  * if synchronous invocation: return ThrottleError 429
  * if asynchronous: retry automatically 2x and then go to DLQ (Dead Letter Queue)
    * ensure IAM execution role is set for DLQ (SNS topic or SQS DLQ)
    * set up in "Asynchronous invocation" section of config
      * specify the Amazon Resource Name of the SQS Queue in the Lambda function’s DeadLetterConfig parameter

### Lambda Logging, Monitoring, and Tracing
* Lambda execution logs are stored in CloudWatch Logs
* Lambda metrics are displayed in CloudWatch Metrics
* Lambda function must have execution role with IAM policy that authorizes writes to CloudWatch
* X-Ray
  * enable X-ray tracing (Lambda runs X-ray demon for you)
  * use AWS SDK in code
  * ensure Lambda Function has correct IAM execution role!

### Lambda Limits
* execution
  * memory execution: 128MB - 3008MB (64MB increments)
  * time: 15 minutes
  * disc capacity in function container: 512MB
  * concurrency limits: 1000
* deployment
  * function deployment size: 50MB max (compressed .zip)
  * uncompressed deployment size: (code + dependencies): 250MB
  * can use /tmp directory to load other files at startup
  * environment variables: 4KB 
  * You can configure your Lambda function to pull in additional code and content in the form of layers. A layer is a ZIP archive that contains libraries, a custom runtime, or other dependencies. With layers, you can use libraries in your function without needing to include them in your deployment package.
  * Layers let you keep your deployment package small, which makes development easier. You can avoid errors that can occur when you install and package dependencies with your function code. For Node.js, Python, and Ruby functions, you can develop your function code in the Lambda console as long as you keep your deployment package under 3 MB.
  * A function can use up to 5 layers at a time. The total unzipped size of the function and all layers can’t exceed the unzipped deployment package size limit of 250 MB.
  * You can create layers, or use layers published by AWS and other AWS customers. Layers support resource-based policies for granting layer usage permissions to specific AWS accounts, AWS Organizations, or all accounts. Layers are extracted to the /opt directory in the function execution environment. Each runtime looks for libraries in a different location under /opt, depending on the language. Structure your layer so that function code can access libraries without additional configuration.

### Lambda Versions and Aliases
* when working on a function, we work on $LATEST, which is mutable
* once published, it is versioned and IMMUTABLE
* each version gets own ARN (Amazon Resource Name)
* each version includes code + configuration
* can use aliases to point to Lambda versions
  * ex: DEV alias points to $LATESET
  * ex: Users might interact with DEV alias
  * ex: TEST alias points at V2
  * ex: PROD alias points to V1
  * aliases are mutable
  * can do BLUE/GREEN deployment by weighting traffic to different aliases

* By default, an alias points to a single Lambda function version. When the alias is updated to point to a different function version, incoming request traffic in turn instantly points to the updated version. This exposes that alias to any potential instabilities introduced by the new version. To minimize this impact, you can implement the routing-config parameter of the Lambda alias that allows you to point to two different versions of the Lambda function and dictate what percentage of incoming traffic is sent to each version.
* For example, you can specify that only 2 percent of incoming traffic is routed to the new version while you analyze its readiness for a production environment, while the remaining 98 percent is routed to the original version. As the new version matures, you can gradually update the ratio as necessary until you have determined that the new version is stable. You can then update the alias to route all traffic to the new version.
* You can point an alias to a maximum of two Lambda function versions. In addition:

 * Both versions must have the same IAM execution role.
 * Both versions must have the same AWS Lambda Function Dead Letter Queues configuration, or no DLQ configuration.
 * When pointing an alias to more than one version, the alias cannot point to $LATEST.


### Lambda Function Dependencies
* if lambda function depends on external libraries (AWS X-ray SDK, Database Clients, etc), install packages alongside your code and zip it together
  * Node.js: use npm and "node-modules" directory
  * Python: use pip --target options
  * Java: include .jar files
* upload zip straight to Lambda (less than 50MB) else S3 first
* can use native libraries.  compile on Amazon Linux first

#### Terminal Commands
```
npm install aws-xray-sdk
chmod a+r *
zip -r function.zip
```
### Using Lambda with CloudFormation
* store Lambda zip in S3
* refer to S3 zip location in CloudFOrmation
* example of CloudFormation yaml
```
Parameters: 
  S3BucketParam:
    Type: String
  S3KeyParam:
    Type: String
Resources:
  LambdaExecutionRole:
    ...
  LambdaWithXRay:
   ...
```

### Lambda Function /tmp space
* if function needs to dl big file or needs disk space to perform operations...
* use /tmp directory
* max 512MB
* content remains when execution context is frozen, providing transient cache that can be used for multiple invocations
* for permanent persistence of objects, use S3

### Lambda Best Practices
* perform heavy-duty work OUTSIDE of function handler
  * connect to databases outside of function handler
  * initialize AWS SDK outside of function handler
  * pull in dependencies or datasets outside of function handler
* used environment variables 
  * for database connection strings, S3 bucket, etc.
  * passwords, sensitive values, etc and encrypt with KMS
* minimize deployment package size to its runtime necessities
  * break down function
  * remember Lambda limits
* never use recursive code!!! 
* don't put Lambda function into VPC unless you have to - takes longer to initialize

### Lamabda@Edge
* you deployed a Content Delivery Network using CloudFront
* to run a global AWS Lambda alongside or implement request filtering before reaching app...
* use Lambda@Edge
  * build more responsive apps
  * you don't manage servers; Lambda is deployed globally
  * customize CDN content by modifying the following:
    * viewer/origin request
    * viewer/origin response
* use cases
  * website security and privacy
  * dynamic web app at edge
  * SEO 
  * intelligently route across origins and data centers
  * bot mitigation at edge
  * real time image transforms
  * A/B testing
  * user authorization and authentication
  * user prioritization
  * user tracking and analytics
* CloudFront: If you use the Adobe Media Server RTMP protocol to distribute media files on demand, your origin server is always an Amazon S3 bucket.

## DynamoDB

* Amazon DynamoDB is a no relational database that delivers reliable performance at any scale. It is a fully managed, multi-region, multi-master database that provides consistent single-digit millisecond latency.
* all data needed for a query must be present in one row
* available across 3 AZ
* NoSQL DB
* scales massive workloads, distributed database
* 10^6 requests per second
* fast and consistent performance (low latency on retrieval)
* integrated wih IAM for security, authorization, administration
* enables event-driven programming with DynamoDB streams

### DynamoDB Basics
* constructed of tables
* each table has primary key
  * Option 1: Primary key only (this key is hashed to determine partition placement)
    * must be unique for each item
    * must be 'diverse' so data is distributed
    * ex: user id
  * option 2: Partition key + Sort Key
    * combination must be unique
    * data is grouped by partition key
    * sort key == range key
* partition keys go through hashing algorithm to know which partition to go to
* infinite # items/rows
* items can have attributes (can be added over time and can be null)
* maximum size of item: 400KB (very big)
* data types:
  * Scalar types: string, number, binary, boolean, Null
  * Document types: List, Map
  * Set: String set, number set, binary set
* choose between strongly consistent reads and eventually consistent reads
  * default: eventually consistent for GetItem, Query, and Scan.
  * set ConsistentRead = True
* DynamoDB Security
  * VPC endpoints available
  * access fully controlled by IAM
* backup/restore feature available
  * point-in-time like RDS
  * no performance impact
* Global Tables
  * multi-region, fully replicated, high performance, rely on streams
* Amazon Data Management System can be used to migrate from Mongo, Oracle, MySQL, S3, etc.
* can launch locally on your own machine for dev
* To create, update, or delete an item in a DynamoDB table, use one of the following operations: PutItem, UpdateItem, DeleteItem
  * For each of these operations, you need to specify the entire primary key, not just part of it. For example, if a table has a composite primary key (partition key and sort key), you must supply a value for the partition key and a value for the sort key.
  * To return the number of write capacity units consumed by any of these operations, set the ReturnConsumedCapacity parameter to one of the following:
    * TOTAL — returns the total number of write capacity units consumed.
    * INDEXES — returns the total number of write capacity units consumed, with subtotals for the table and any secondary indexes that were affected by the operation.
    * NONE — no write capacity details are returned. (This is the default.)

### DynamoDB Privisioned Throughput
* free tier applies at account level!
  * 25 WCU/RCU
* tables must have provisioned read and write capacity units
  * minimum: 1 WCU/RCU
* In order to preconfigure the read/write capacity of your DynamoDB table, you have to disable Auto Scaling first.
* Read Capacity Units (RCU): throughput for reads
  * 1 RCU = 1 strongly consistent read per second for UP TO 4KB
  * 1 RCU = 2 eventually consistent reads per second for UP TO 4KB
  * rounds up to nearest multiple of 4KB
* Write Capacity Units (WCU): throughout for writes
  * 1 write per second for an item UP TO 1 KB in size
  * rounds up to nearest KB
* WCU and RCU are spread evenly between partitions
* option to setup aut-scaling of throughput to meet demand
* can temporarily use 'burst credit' if exceed throughput
  * reasons
    * hot key: one partition key being read a lot (popular item)
    * hot partition: large items! 
* if burst credits are empty: "ProvisionedThroughputException"
* use exponential back-off retry
* if RCU issue, use DynamoDB Accelerator (DAX)

### DynamoDB Writing Data
* you can use the PutItem or BatchWriteItem APIs to insert items. Then, you can use the GetItem, BatchGetItem, or, if composite primary keys are enabled and in use in your table, the Query API to retrieve the items you added to the table.
* the Query operation finds items based on primary key values (partition key + sort key) 
  * use KeyConditionExpression parameter to provide specific value for partition key
  * narrow scope by specifying a sort key value and a comparison operator in KeyConditionExpression

* PutItem (FULL REPLACE)
* UpdateItem (only updates fields)
  * can implement Atomic Counters and increase them
  * increases a counter each time an update occurs 
* Conditional Writes: 
  * accept a write/update only if certain conditions are met
  * helps with concurrent access to items
  * no impact on performaces
* DeleteItem
  * delete individual row
  * conditional delete
* DeleteTable
  * faster than calling delete on each item
* BatchWriteItem
  * up to 25 PutItem/DeleteItem
  * up to 16MB data written
  * up to 400KB data per item
  * allows you to save latency by reducing API calls
  * operations done in parallel for better efficiency!
  * part of batch can fail: retry failed items using exponential back-off
* GetItem
  * based on primary key (HASH or HASH-RANGE)
  * eventually consistent by default
  * ProjectionExpression can be used to get only certain attributes (save in network bandwidth)
* BatchGetItem:
  * up to 100 items
  * up to 16MB data
  * items retrieved in parallel
* Queries
  * PartitionKey = my_partition_key
  * SortKey value (<=, =, >, etc) optional
  * FilterExpression to further filter (client side filtering)
  * returns up to 1 MB data
  * can specify Limit for number of items or size of items
  * can paginate results
  * can query table, local secondary index, or global secondary index
* Scan
  * no!
  * scans the entire table and filters out data
  * consumes a lot of RCU
  * returns up to 1MB of data at a time using pagination
  * Limit impact by using Limit to reduce size of result
  * decrease page size to minimze impact on provisioned throughput
  * for faster performace, use parallel scans
    * multiple instances scan multiple partitions at the same time
  * use ProjectionExpression + FilterExpression

### DynamoDB Local Secondary Index (LSI)
* alternate range key for your table, local to the hash key
* up to five local secondary indexes per table
* sort key consists of exactly one scalar attribute (String, Number, or Binary)
* LSI MUST be defined at table creation time
* hash key of LSI is the same as the hash key of the main table

### DynamoDB Global Secondary Index (GSI)
* to speed up queries on non-key attributes
* GSI = partition key + optional sort key
* index is a new 'table' and attributes can be projected onto it
  * partition key and sort key are ALWAYS projected: KEYS_ONLY
  * can specify additional attributes to project: INCLUDE
  * ALL attributes from main table: ALL
* must define RCU/WCU for the index
* can add/modify GSI 
* queries support eventual consistency only
* queries on this index consume capacity units from the index, not from the base table

### DynamoDB Indexes and Throttling
* If writes are throttled on GSI, the main table will be throttled!
* choose GSI partition keys carefully
* assign your WCU capacity carefully 
* not a concern for LSI (uses the main table)

### DynamoDB Optimistic Concurrency
* conditional updates/deletes
* can ensure an item hasn't changed before altering it
* also called an optimistic locking/concurrency database
* exceptions
  * DynamoDB global tables use a “last writer wins” reconciliation between concurrent updates. If you use Global Tables, last writer policy wins. So in this case, the locking strategy does not work as expected.
  * DynamoDBMapper transactional operations do not support optimistic locking.

### DynamoDB Accelerator (DAX)
* Seamless cache
* no application rewrite (just enable DAX)
* items live for 5 minutes in cache by default
* multi AZ
* up to 10 nodes in cluster (recommended 3 min for production)
* enable on DAX dashboard
* not free tier

### DynamoDB Stream
* changes in DynamoDB can end up in a Stream
* stream can be read by Lambda (use trigger to push to Lambda function)
  * react to changes in real time
  * analytics
  * create derivative tables/views
  * insert into ElasticSearch
* can implement cross-region replication using streams
* 24 hours data retention

### DynamoDB Time To Live (TTL)
* automatically delete an item after an expiration date
* provided at no extra cost/does not use WCU/RCU
* enabled per row (add a TTL column and add a date there)
* deletes within 48 hours
* Streams can help recover deleted items

### DynamoDB CLI
* --projection-expression : attributes to receive
* --filter-expression : filter results
* general CLI pagination
  * --page-size : full dataset but less data with each API call (to avoid timeouts)
  * --max-items : pagination : max number of results returned by CLI.  Returns NextToken
  * --starting-token : specifiy the last received NextToken to get next page
* see file in resources for examples of command line prompts!

### DynamoDB Transactions
* ability to create/update/delete multiple rows in different tables at the same time
* all or nothing transaction (either everything happens or nothing does)
* consumes 2x WCU/RCU

## API Gateway & Cognito

Build, deploy, and manage a serverless API to the cloud

### API Gateway integration
* outside VPC
  * Lambda
  * Endpoints on EC2
  * Load balancers
  * any AWS service
  * external and publicly accessible HTTP endpoints
* inside VPC
  * AWS Lambda in VPC
  * EC2 Endpoints in VPC
* private API: API exposed through interface VPC endpoints and isolated from the public internet
* private integration: API Gateway integration type for a client to access resrouces inside a customer's VPS through private API endpoint without exposing resources to public
* proxy integration: set up proxy integration as an HTTP proxy integration type or Lambda proxy integration
  * HTTP Proxy integration: API Gateway passes request and response b/w frontend and HTTP backend
  * Lambda Proxy integration:  API Gateway sends request as an input toa  backend Lambda function
* All of the APIs created with Amazon API Gateway expose HTTPS endpoints only. Amazon API Gateway does not support unencrypted (HTTP) endpoints. By default, Amazon API Gateway assigns an internal domain to the API that automatically uses the Amazon API Gateway certificate. When configuring your APIs to run under a custom domain name, you can provide your own certificate for the domain.
* The following are the Gateway response types which are associated with the HTTP 504 error in API Gateway:

  * INTEGRATION_FAILURE – The gateway response for an integration failed error. If the response type is unspecified, this response defaults to the DEFAULT_5XX type.

  * INTEGRATION_TIMEOUT – The gateway response for an integration timed out error. If the response type is unspecified, this response defaults to the DEFAULT_5XX type.

  * For the integration timeout, the range is from 50 milliseconds to 29 seconds for all integration types, including Lambda, Lambda proxy, HTTP, HTTP proxy, and AWS integrations.

  * In this scenario, there is an issue where the users are getting HTTP 504 errors in the serverless application. This means the Lambda function is working fine at times but there are instances when it throws an error. Based on this analysis, the most likely cause of the issue is the INTEGRATION_TIMEOUT error since you will only get an INTEGRATION_FAILURE error if your AWS Lambda integration does not work at all in the first place.

### API Gateway Deployment
* changes in API Gateway are not always effective right away
* need to make a 'deployment' of changes for them to be in effeect
* changes are deployed to stages (dev, test, prod, etc)
* each stage has config parameters
* each stage can be rolled back using history of deployments
* stage variables
  * like env variables for API Gateway
  * can change them and config changes as a result
  * can be used in Lambda function ARN, HTTP Endpoint, Parameter mapping template
  * use cases
    * configure HTTP endpoints your stages talk to (dev, prod)
    * pass config parameters to Lambda functions using mapping templates
    * are passed to "context" object in Lambda
  * use stage variable to point to Lambda alias
* canary deployments
  * choose % of traffic that canary channel receives
    * can keep logs and metrics separate for better monitoring
    * can override stage variables for canary

### Mapping Templates
* can be used to modify requests and responses
  * rename parameters
  * modify body content
  * add headers
  * map JSON to XML for sending to backend or back to client
  * filter output results
* uses Velocity Template Language (VTL): for loops, if, etc...
* implementation
  * resources
  * choose on section you want to change
    * example: integration response to convert response from JSON to XML
  * click down arrow by response
  * mapping template
  * application/json
  * generate template: EMPTY
  * inputRoot is response
  ```
  #set($inputRoot = $input.path('$'))
<xml>
    <response>
        <body>
            $inputRoot.body
        </body>
        <statusCode>
            $inputRoot.statusCode
        </statusCode>
    </response>
</xml>
  ```

### Gateway Swagger / Open API Spec
* common way of defining REST APIs, using API definition as code
* import existing Swagger / openAPI 3.0 spec to API Gateway
  * method
  * method request
  * intergration request
  * method response
  * AWS extensions
* can EXPORT current API as Swagger
* can be written in YAML or JSON
* using Swagger, can generate SDK for apps

### Caching API Responses
* default time in cache is 300s: max time 3600s
* caches are defined by stage (dev, prod, etc)
* capacity between 0.5GB to 237GB
* possible to control settings for specific methods (GET, etc)
* ability to flush entire cache (invalidate it) immediately
* encryption available
* CLIENTS CAN INVALIDATE CACHE using header Cache-Control:max-age=0 if they have IAM authorization to do so

### API Gateway Logging, Monitoring, Tracing
* CloudWatch logs
  * enable CloudWatch logging at stage level with log level
  * can override settings on a per API basis (ex: error, debug, info)
  * log contains info about request/response body
  * careful with logging full requests/responses data if sensitive info
* CloudWatch Metrics
  * metrics are by stage
  * possible to enable detailed metrics
* X-Ray
  * enable tracing to get extra info about requests
  * X-Ray API Gateway + AWS Lambda gives you complete info
* implementation
  * go to settings in API Gateway and provide CloudWatch log role ARN

### API Gateway CORS
* must enable CORS when you receive API calls from another domain
* OPTIONS preflight request must contain headers
  * Access-Control-Allow-Methods
  * Access-Control-Allow-Headers
  * Access-Control-Allow-Origin
* enable in console

### API Gateway Usage Plans and API Keys
* limit customers' usage of API
* Usage plans
  * throttling: set overall capacity and burst capacity
  * Quotas: set number of requests made per day/week/month
  * associate with stages
* API Keys
  * generate 1 per customer
  * associate with usage plans
  * can bill clients for use

### API Gateway Security
* IAM Permissions
  * create IAM policy authorization and attach User/Role
  * API Gateway will verify IAM permissions passed by calling app
  * can provide access internally
  * leverages Sig V4 where IAM credentials are in headers
  * no additional cost
  * handles authorization and authentication
  * great for users already in your account
* Lambda Authorizer (formerly Custom Authorizers)
  * "Lambda Authorizer" : An Amazon API Gateway Lambda authorizer (formerly known as a custom authorizer) is a Lambda function that you provide to control access to your API. A Lambda authorizer uses bearer token authentication strategies, such as OAuth or SAML. Before creating an API Gateway Lambda authorizer, you must first create the AWS Lambda function that implements the logic to authorize and, if necessary, to authenticate the caller.
  * uses Lambda to validate token in header being passed
  * option to cache result of authentication
  * helps with use of OAuth/SAML/3rd party auth
  * Lambda returns IAM policy for user that is either valid or invalid
  * can handle authorization and authentication (IAM policy is returned)
  * two kinds
     * A token-based Lambda authorizer (also called a TOKEN authorizer) receives the caller’s identity in a bearer token, such as a JSON Web Token (JWT) or an OAuth token.
     * A request parameter-based Lambda authorizer (also called a REQUEST authorizer) receives the caller’s identity in a combination of headers, query string parameters, stageVariables, and $context variables.
* Cognito User Pools
  * YOU manage your own user pool
  * fully manages user lifecycle
  * no custom implmentation
  * ONLY HELPS WITH AUTHENTICATION (no authorization)
  * you need to implement authorization in the backend (google, etc)
  * You can add multi-factor authentication (MFA) to a user pool to protect the identity of your users. MFA adds a second authentication method that doesn’t rely solely on user name and password. You can choose to use SMS text messages, or time-based one-time (TOTP) passwords as second factors in signing in your users. You can also use adaptive authentication with its risk-based model to predict when you might need another authentication factor. It’s part of the user pool advanced security features, which also include protections against compromised credentials.


* "Cognito User Pools" : After successfully authenticating a user, Amazon Cognito issues JSON web tokens (JWT) that you can use to secure and authorize access to your own APIs, or exchange for AWS credentials.

* "API Gateway" - If you are processing tokens server-side and using other programming languages not supported in AWS it may be a good choice other than that go with a service already providing the functionality

* "Cognito Identity Pools" - A way to authorize your users to use the various AWS services vs authorization in your application

* "Cognito Sync" - You can use it to synchronize user profile data across mobile devices and the web without requiring your own backend

### AWS Cognito

User pools are user directories that provide sign-up and sign-in options for your app users. Identity pools enable you to grant your users access to other AWS services. You can use identity pools and user pools separately or together.

* used when we want to give users an identity so that they can interact with our application
* Cognito User Pools
  * Sign in functionality for app users
  * intergrate with API Gateway
  * serverless database of users for your mobile apps
  * simple login: username, password
  * possibility to verify emails, phones, etc, and add MFA
  * can enable Federated Identities (google, facebook, etc)
  * get back JSON Web Token (JWT)
  * can be integrated with API Gateway for authentication
* Cognito Identity Pools (Federated Identity) 
  * Provide AWS credentials to users so they can access AWS resources directly
  * integrate with Cognito User Pools as an identity provider
  * goal is to provide direct access to AWS resources from the client side
  * log in to federated identity provider (or remain anonymous)
  * get temp AWS credentials back from Federated Identity Pool
  * creds come with pre-defined IAM policy stating permissions
  * ex: povide temp access to write to S3 bucket using Facebook login
* Cognito Sync
  * synchronize data from device to Cognito
  * deprecated and replaced by AppSync
    * AWS AppSync is quite similar with Amazon Cognito Sync and extends these capabilities by allowing multiple users to synchronize and collaborate in real time on shared data.
  * cross-device synchronization
  * offline capability
  * requires Federated Identity Pool
  * Amazon Cognito Sync is an AWS service and client library that enables cross-device syncing of application-related user data. You can use it to synchronize user profile data across mobile devices and the web without requiring your own backend. The client libraries cache data locally so your app can read and write data regardless of device connectivity status. When the device is online, you can synchronize data, and if you set up push sync, notify other devices immediately that an update is available.
  * Amazon Cognito lets you save end user data in datasets containing key-value pairs. This data is associated with an Amazon Cognito identity, so that it can be accessed across logins and devices. To sync this data between the Amazon Cognito service and an end user’s devices, invoke the synchronize method. Each dataset can have a maximum size of 1 MB. You can associate up to 20 datasets with an identity.
  * The Amazon Cognito Sync client creates a local cache for the identity data. Your app talks to this local cache when it reads and writes keys. This guarantees that all of your changes made on the device are immediately available on the device, even when you are offline. When the synchronize method is called, changes from the service are pulled to the device, and any local changes are pushed to the service. At this point the changes are available to other devices to synchronize.
  * Amazon Cognito automatically tracks the association between identity and devices. Using the push synchronization, or push sync, feature, you can ensure that every instance of a given identity is notified when identity data changes. Push sync ensures that, whenever the sync store data changes for a particular identity, all devices associated with that identity receive a silent push notification informing them of the change.

### Serverless Application Model (SAM)
* framework for developing and deploying serverless apps
* all config is YAML code (or JSON)
* generate complex CloudFormation from simple SAM YAML file
* supports anything from CloudFormation (Outputs, Mappings, Parameters, Resources, etc)
  * For serverless applications (also referred to as Lambda-based applications), the Transform section of a CloudFormation template specifies the version of the AWS Serverless Application Model (AWS SAM) to use. When you specify a transform, you can use AWS SAM syntax to declare resources in your template. The model defines the syntax that you can use and how it is processed.  More specifically, the AWS::Serverless transform, which is a macro hosted by AWS CloudFormation, takes an entire template written in the AWS Serverless Application Model (AWS SAM) syntax and transforms and expands it into a compliant AWS CloudFormation template.
* 2 commands to deploy to AWS
* can use CodeDeploy to deploy Lambda functions
* can help you run Lambda, API Gateway, DynamoDB locally
* transform header indicates it's a SAM template
  * Transform: 'AWS::Serverless-2016-10-31'
* Write code
  * AWS::Serverless::Function
  * AWS::Serverless::Api
  * AWS::Serverless::SimpleTable
* Package and Deploy
  * aws cloudformation package / sam package
  * aws cloudformation deploy / sam deploy
* see commands.sh file and template.yaml 
* set environment variables in template.yaml
* use CloudFormation Designer to explore
* AWS serverless application repos contains sourcecode for a variety of SAM templates
* SAM policy templates
  * templates to apply permissions to Lambda functions
  * examples
    * S3ReadPolicy
      * read only permissions to objects in S3
    * SQSPollerPolicy
      * allows to poll an SQS queue
    * DynamoDBCrudPolicy
      * create, read, update, delete
* SAM can simplify the deployment of the serverless application by deploying all related resources together as a single, versioned entity (DIFFERENT FROM CLOUDFORMATION)
* To deploy an application that contains one or more nested applications, you must include the CAPABILITY_AUTO_EXPAND capability in the sam deploy command.

## Elastic Container Service (ECS)

* Amazon ECS lets you easily build all types of containerized applications, from long-running applications and microservices to batch jobs and machine learning applications. You can migrate legacy Linux or Windows applications from on-premise to the cloud and run them as containerized applications using Amazon ECS.

### Docker
* software development platform for deploying apps
* apps are packaged in containers that can be run on any OS
* images stored in Docker repos
  * Public: Docker Hub (hub.docker.com)
  * Private: Amazon ECR (Elastic Container Registry)
* docker vs virtual machines
  * all resources are shared with a host
  * can have many containers on one server
* need a container management platform
  * ECS: Amazon's own platform
  * Fargate: Amazon's serverless
  * EKS: Amazon's managed Kubernetes (open source)

### ECS Clusters
* logical grouping of EC2 instances
* EC2 instances run ECS agent
* ECS agents register the instance to the ECS cluster
* EC2 instances run special AMI made specifically for ECS

### ECS Task Definitions
* metadata in JSON form that tell ECS how to run a Docker Container
* information
  * image name
  * port binding for container and host
  * memory and CPU required
  * environment variables
  * networking info

### ECS Service
* define tasks that should run and how they should run
* ensures that number of tasks desired are running across fleet

### ECS Service with Load Balancers
* can't run multiple tasks on one EC2 instance if host/port is defined
* run multiple tasks on the same EC2 instance using dynamic port forwarding
* leave host port empty (will result in random host port)
  * now can run two tasks on same EC2 instance
  * but this is insecure! Need a load balancer
* ALB uses dynamic host port mapping, allowing multiple tasks per container instance.  Multiple services can use the same listener port on a single load balancer with rule-based routing and paths
* ALB need sg to allow inbound traffic from all traffic from the ALB sg (i.e. allow ALB to talk to any ports on EC2 instance for dynamic port feature on ECS)

### ECR
* been using Docker images form Docker Hub (public)
* ECR is private Docker image repo
* access is controlled through...
  * you guessed it!  IAM (permission errors -> policy)
* run commands to push/pull
  * $(aws ecr get-login --no-include-email --region eu-west-1)
  * docker push your-ecs-url
  * docker pull your-ecs-url
* see Dockerfile in ecs folder
* see bootstrap.sh to review commands to push/pull

### Fargate
* serverless 
* just create task definitions and AWS will run containers
* to scale, just increase task number

### ECS & X-Ray
* options for implementation
  * use container as x-ray demon (task)
  * use side car pattern: run 1 x-ray demon container alongside each application container
  * Fargate task with x-ray sidecar 
    * map container port of x-ray port to 2000 udp
    * set env var 
    * link two containers from network

* The AWS X-Ray SDK does not send trace data directly to AWS X-Ray. To avoid calling the service every time your application serves a request, the SDK sends the trace data to a daemon, which collects segments for multiple requests and uploads them in batches. Use a script to run the daemon alongside your application.

* To properly instrument your applications in Amazon ECS, you have to create a Docker image that runs the X-Ray daemon, upload it to a Docker image repository, and then deploy it to your Amazon ECS cluster. You can use port mappings and network mode settings in your task definition file to allow your application to communicate with the daemon container.

* The AWS X-Ray daemon is a software application that listens for traffic on UDP port 2000, gathers raw segment data, and relays it to the AWS X-Ray API. The daemon works in conjunction with the AWS X-Ray SDKs and must be running so that data sent by the SDKs can reach the X-Ray service.

### Elastic Beanstalk + ECS
* can run Elastic Beanstalk in Single or Multi Docker Container mode
* Multi Docker helps run multiple containers per EC2 instance in EB which creates
  * ECS cluster
  * EC2 instance, configured to use the ECS cluster
  * Load Balancer in high availability mode
  * task definitions and executions
* requires config file Dockerrun.aws.json at root
* your Docker images must be pre-built and stored in ECR for example

### ECS Summary
* used to run Docker containers
* integrates with CloudWatch logs - setup logging at task definition level
* each container will have a different log stream
* three flavors
  * ECS Classic: provision EC2 Instances to run containers onto
    * create EC2 Instances
    * must configure /etc/ecs/ecs.config with cluster name
      * allow tasks to endorse IAM roles using ECS_ENABLE_TASK_IAM_ROLE
    * EC2 Instance must run ECS agent
    * can run multiple containers by not specifying host port and using ALB with dynamic port mapping
    * EC2 instance sg must all traffic from ALB on all ports
    * ECS tasks can have IAM roles to execute actions against AWS
    sg operates at instance level, not task level
  * Fargate: serverless
    * AWS provisions containers and assignes them ENI
    * Fargate tasks can have IAM roles
  * EKS: managed Kubernetes by AWS
* ECR
  * to push/pull: $(aws ecr get-login-password....) & docker push/pull
  * troubleshooting: check IAM permissions
* task placement strategies include binpack, random, spread
  * The spread strategy, contrary to the binpack strategy, tries to put your tasks on as many different instances as possible. It is typically used to achieve high availability and mitigate risks, by making sure that you don’t put all your task-eggs in the same instance-baskets. Spread across Availability Zones, therefore, is the default placement strategy used for services.
  * When using the spread strategy, you must also indicate a field parameter. It is used to indicate the bins that you are considering. The accepted values are instanceID, host, or a custom attribute key:value pairs such as attribute:ecs.availability-zone to balance tasks across zones. There are several AWS attributes that start with the ecs prefix, but you can be creative and create your own attributes.
  * Hence, the task placement configuration which has a value of "field": "attribute:ecs.availability-zone", "type": "spread" is correct, because this is using the appropriate strategy for task placement.

* Cluster queries are expressions that enable you to group objects. For example, you can group container instances by attributes such as Availability Zone, instance type, or custom metadata. You can add custom metadata to your container instances, known as attributes. Each attribute has a name and an optional string value. You can use the built-in attributes provided by Amazon ECS or define custom attributes.

* After you have defined a group of container instances, you can customize Amazon ECS to place tasks on container instances based on group. Running tasks manually is ideal in certain situations. For example, suppose that you are developing a task but you are not ready to deploy this task with the service scheduler. Perhaps your task is a one-time or periodic batch job that does not make sense to keep running or restart when it finishes.


* Amazon Elastic Container Service (Amazon ECS) is a highly scalable, fast, container management service that makes it easy to run, stop, and manage Docker containers on a cluster. You can host your cluster on a serverless infrastructure that is managed by Amazon ECS by launching your services or tasks using the Fargate launch type. For more control, you can host your tasks on a cluster of Amazon Elastic Compute Cloud (Amazon EC2) instances that you manage by using the EC2 launch type.

* You can also use Elastic Beanstalk to host Docker applications in AWS. It is an application management platform that helps customers easily deploy and scale web applications and services. It keeps the provisioning of building blocks (e.g., EC2, RDS, Elastic Load Balancing, Auto Scaling, CloudWatch), deployment of applications, and health monitoring abstracted from the user so they can just focus on writing code. You simply specify which container images are to be deployed, the CPU and memory requirements, the port mappings, and the container links. Elastic Beanstalk will automatically handle all the details such as provisioning an Amazon ECS cluster, balancing load, auto-scaling, monitoring, and placing your containers across your cluster.

* Elastic Beanstalk is ideal if you want to leverage the benefits of containers but just want the simplicity of deploying applications from development to production by uploading a container image. You can work with Amazon ECS directly if you want more fine-grained control for custom application architectures.

  ## Security
  
  ### Encryption in Flight
  * SSL
  * Data is encrypted before sending and decrypted after receiving
  * SSL certificate helps with encryption (HTTPS)
  
  ### Encryption at Rest - Server Side
  * data is encrypted after being received by server and decrypted before being sent
  * server manages a key for encryption/decryption

  ### Encryption at Rest - Client side
  * data is never decrypted by server
  * client leverages Envelope Encryption to encrypt before sending to server
  * data must be decrypted by a receiving client with access to key

### Temporary Access Using MFA
  * The GetSessionToken API returns a set of temporary credentials for an AWS account or IAM user. The credentials consist of an access key ID, a secret access key, and a security token. Typically, you use GetSessionToken if you want to use MFA to protect programmatic calls to specific AWS API operations like Amazon EC2 StopInstances. MFA-enabled IAM users would need to call GetSessionToken and submit an MFA code that is associated with their MFA device.
  * Using the temporary security credentials that are returned from the call, IAM users can then make programmatic calls to API operations that require MFA authentication. If you do not supply a correct MFA code, then the API returns an access denied error.

  ### Key Management Service (KMS)
  * AWS manages keys for client
  * Fully integrated with IAM for authorization
  * Customer Master Key (CMK) used to encrypt data can never be retrieved by client
  * rotate it for extra security
  * never store secrets in plain text
  * encrypt secrets first then store in code/environment variables
  * KMS can only encrypt up to 4KB of data per call
  * for data > 4KB, use envelope encryption
  * to grant access to KMS to user:
    * ensure Key Policy allows user
    * ensure IAM policy allows API calls
  * able to fully manage keys and policies
    * create, rotate, disable, enable
  * can audit key usage using CloudTrail
  * 3 types CMK
    * AWS Managed Service Default CMK: free
    * to create User Key (custom) $1/month
    * import User Keys $1/month
  * pay for API calls to KMS ($0.03/10000 calls)

### Encrypt/Decrypt API
* client wants to encrypt a secret
* sends it to KMS via Encrypt API
* API checks IAM permissions and performs encryption using CMK
* API sends back encrypted secret
* client wants to decrypt: opposite of above

### Example
* instead of putting db password directly in lambda function or as environment variable, use 'encryption configuration' when setting up lambda function
* enter environment variable for string you want to encrypt
* enable helpers for encryption in transit
* create CMK in KMS
* in lambda, choose KMS key to encrypt at rest (default aws/lambda or customer master key)
* choose encrypt for environment variable and choose CMK
  * click Decrypt secrets snippet for code to include in lambda function
* add code snippet to lambda function
* modify IAM role for lambda function to allow decrypt calls
  * go to role
  * add inline policy
  * choose KMS
  * filter actions 'decrypt'
  * choose Decrypt
  * add ARN resource
    * go to KMS to get full ARN for key

### Encryption SDK
* AWS Encryption SDK helps with implementation of Envelope Encryption
* difference from the S3 Encryption SDK!
* Encryption SDK also exists as CLI tool that can be installed
* for encryption of data over 4 KB, use Encryption SDK/Envelope Encryption via GenerateDataKey API
  * When you encrypt your data, your data is protected, but you have to protect your encryption key. One strategy is to encrypt it. Envelope encryption is the practice of encrypting plaintext data with a data key, and then encrypting the data key under another key.

  * You can even encrypt the data encryption key under another encryption key, and encrypt that encryption key under another encryption key. But, eventually, one key must remain in plaintext so you can decrypt the keys and your data. This top-level plaintext key encryption key is known as the master key.

  * It is recommended that you use the following pattern to encrypt data locally in your application:

1. Use the GenerateDataKey operation to get a data encryption key.

2. Use the plaintext data key (returned in the Plaintext field of the response) to encrypt data locally, then erase the plaintext data key from memory.

3. Store the encrypted data key (returned in the CiphertextBlob field of the response) alongside the locally encrypted data.

To decrypt data locally:

1. Use the Decrypt operation to decrypt the encrypted data key. The operation returns a plaintext copy of the data key.

2. Use the plaintext data key to decrypt data locally, then erase the plaintext data key from memory.

### Parameter Store
* secure storage for configuration and secrets
* optional seamless encryption using KMS
* serverless, scalable, durable, easy SDK
* free tier
  * 10,000 parameters for free
  * up to 4KB for parameter value size
  * no parameter policies available
* paid tier
  * unlimited parameters
  * up to 8KB parameter value size
  * parameter policies available
* version tracking of configurations/secrets
* configuration management using path and IAM
* notifications via CloudWatch Events
* integration with CloudFormation
* uses API to get parameters fro hierarchy tree: GetParameters or GetParametersByPath
* Use a secure, scalable, hosted secrets management service (No servers to manage).
* Improve your security posture by separating your data from your code.
* Store configuration data and secure strings in hierarchies and track versions.
* Control and audit access at granular levels.
* Configure change notifications and trigger automated actions.
* Tag parameters individually, and then secure access from different levels, including operational, parameter, Amazon EC2 tag, or path levels.
* Reference AWS Secrets Manager secrets by using Parameter Store parameters.

#### Implementation
* go to services -> Systems Manager -> Parameter Store
* add all parameters you want
* CLI: 
  * aws ssm get-parameters --names /my-app/dev/db-url /my-app/dev/db-password --with-decryption
  * aws ssm get-parameters-by-path --path /my-app/ --recursive
* using Lambda
  * lecture 200

### AWS Secrets Manager

AWS Secrets Manager helps you protect secrets needed to access your applications, services, and IT resources. The service enables you to easily rotate, manage, and retrieve database credentials, API keys, and other secrets throughout their lifecycle. Users and applications retrieve secrets with a call to Secrets Manager APIs, eliminating the need to hardcode sensitive information in plain text. Secrets Manager offers secret rotation with built-in integration for Amazon RDS, Amazon Redshift, and Amazon DocumentDB. Also, the service is extensible to other types of secrets, including API keys and OAuth tokens. In addition, Secrets Manager enables you to control access to secrets using fine-grained permissions and audit secret rotation centrally for resources in the AWS Cloud, third-party services, and on-premises.

* Secrets Manager offers built-in integration for Amazon RDS, Amazon Redshift, and Amazon DocumentDB and rotates these database credentials on your behalf automatically. 
* You can customize Lambda functions to extend Secrets Manager rotation to other secret types, such as API keys and OAuth tokens.
* you can help secure secrets by encrypting them with encryption keys that you manage using AWS Key Management Service (KMS). 
* It also integrates with AWS’ logging and monitoring services for centralized auditing. For example, you can audit AWS CloudTrail logs to see when Secrets Manager rotates a secret or configure AWS CloudWatch Events to notify you when an administrator deletes a secret. 
* you can configure Secrets Manager to automatically rotate the secret for you according to a schedule that you specify

## IAM Best Practices 
* never use root credentials
* enable MFA for root
* grant least privilege
* never store IAM key credentials on any machine but on personal computer or on-premise server
* on-premise: call STS to get temp cred
* EC2 machines should have own roles
* Lambda functons should have own roles
* ECS Tasks should have own roles
  * ECS_ENABLE_TASK_IAM_ROLE=true
* CodeBuild should have its own service
* create least-privileges role for any service
* create roles per application (do not reuse roles)
* define IAM role for other accounts to access
I define which accounts can access the IAM role
* use AWS STS (Security Token Service) to retrieve creds and impersonate the IAM Role you have access to (AssumeRoleAPI)
  * not a feature of API Gateway
* temp creds valid b/w 15 min and 1 hr
* Q: A corporate web application is deployed within an Amazon VPC, and is connected to the corporate data center via IPSec VPN. The application must authenticate against the on-premise LDAP server.
Once authenticated, logged-in users can only access an S3 keyspace specific to the user. Which two approaches can satisfy the objectives?
  * The application authenticates against LDAP, and retrieves the name of an IAM role associated with the user. The application then calls the IAM Security Token Service to assume that IAM Role. The application can use the temporary credentials to access the appropriate S3 bucket.
  * Develop an identity broker which authenticates against LDAP, and then calls IAM Security Token Service to get IAM federated user credentials. The application calls the identity broker to get IAM federated user credentials with access to the appropriate S3 bucket.
* A resource policy can be used to grant API access to one AWS account to users in a different AWS
account using Signature Version 4 (SigV4) protocols
  * Create an IAM permission policy and attach it to each IAM user. Set the APIs method authorization type
to AWS_IAM. Use Signature Version 4 to sign the API requests.
  * Create a resource policy for the APIs that allows access for each IAM user only.

  * If you have resources which are running inside AWS, that needs programmatic access to various AWS services, then the best practice is to always use IAM roles. However, for applications running outside of an AWS environment, these will need access keys for programmatic access to AWS resources. For example, monitoring tools running on-premises and third-party automation tools will need access keys.
    * Go to the AWS Console and create a new IAM user with programmatic access. In the application server, create the credentials file at ~/.aws/credentials with the access keys of the IAM user.

## Advanced IAM
* Authorization Model Evaluation of Policies
  * if explicit DENY, DENY
  * if there's ALLOW, ALLOW
  * else: DENY
* IAM policies + S3 Bucket Policies
  * the UNION of both policies will be evaluated
* Dynamic Policies with IAM
  * how do assign each use a /home/user folder in S3 bucket?
    * option 1: create one IAM policy per user (not scalable!)
    * option 2: create one dynamic policy and leverage policy variable ${aws.username}
* inline vs managed policies
  * managed policies
    * maintained by AWS
    * good for power users and admin
    * updated in case of new services/new APIs
  * customer managed policy
    * best practice, reusable, can be applied to many principals
    * version controlled + roll back (central change in management)
  * inline
    * strict one-to-one relationship between policy and principal
    * policy is deleted if you delete IAM principal
    * no versions
    * size restriction

## CloudFront
* content delivery network (CDN)
* content is cached at edge - improved read performance
* 136 point of presence globally
* popular with S3 but works also with EC2, ALB
* can help protect against network attaches
* can provide SSL encryption
* supports RTMP Protocol (videos/media)
* although CloudFront can provide caching and for CDN, it is not suitable to be used for database caching.

## Step Functions
* build serverless visual workflow to orchestrate your Lambda functions
* represent flow as a JSON state machine
* features: sequence, parallel, conditions, timeouts, error handling, etc
* can integrate with EC2, ECS, on-premise servers, API Gateway
* max execution time 1 yr
* can implement human approval features
* use cases: order fulfillment, data processing, web apps, etc

## Simple Workflow Service (SWS)
* coodinate work amongst apps
* code runs on EC2
* 1 yr max runtime
* has been mostly replaced by Step Functions except:
  * you need external signals to intervene in processes
  * you need child processes to return values to parent processes

## Simple Email Service (SES)
* send emails using SMTP interface or AWS SDK
* integrates with S3, SNS, Lambda
* Inegrated with IAM for allowing to send emails

## Summary of Databases
* RDS: relational databases, OLTP
  * provisioned
* DynamoDB: noSQL
  * managed Key Value, Document
  * serverlss
* ElastiCache: in memory DB
  * Redis/Memcached
  * cache capability
  * Redis and Memcached are popular, open-source, in-memory data stores. Although they are both easy to use and offer high performance, there are important differences to consider when choosing an engine. Memcached is designed for simplicity while Redis offers a rich set of features that make it effective for a wide range of use cases.
  * Redis can provide a much more durable and powerful cache layer to the prototype distributed system
  * Redis is mostly a single-threaded server. It is not designed to benefit from multiple CPU cores unlike Memcached, however, you can launch several Redis instances to scale out on several cores if needed.
  * Memcached is a more suitable choice when the system will run large nodes with multiple cores or threads which Memcached can adequately provide. 
  * Choose Memcached over Redis if you have the following requirements:
    * You need the simplest model possible.
    * You need to run large nodes with multiple cores or threads.
    * You need the ability to scale out and in, adding and removing nodes as demand on your system increases and decreases.
    * You need to cache objects, such as a database.


* Redshift: OLAP - analytic processing
  * a petabyte scale warehouse service and you have to manually change settings for scaling
  * data warehousing/data lake
  * analytics queries
* Neptune: graph database
* DMS: database migration service

## Amazon Certificate Management (ACM)
* used to host public SSL certificates in AWS
  * can buy your own and upload them using CLI
  * can have ACM provision and renew public SSL certificates for you for free
* ACL loads SSL certificates on Load Balancers, CloudFrints, APIs of API Gateways
* SSL certificates are a pain to manage on your own - use AWS!
* To enable HTTPS connections to your website or application in AWS, you need an SSL/TLS server certificate. For certificates in a Region supported by AWS Certificate Manager (ACM), it is recommended that you use ACM to provision, manage, and deploy your server certificates. In unsupported Regions, you must use IAM as a certificate manager.

### Autoscaling AWS Resources

* EC2 instances
* Amazon ECS
* Amazon EC2 Spot Fleets
* Amazon EMR clusters
* Amazon AppStream 2.0 stacks and fleets
* Amazon DynamoDB

### Account Alias

* An account alias substitutes for an account ID in the web address for your account. You can create and manage an account alias from the AWS Management Console, AWS CLI, or AWS API. Your sign-in page URL has the following format, by default:

https://Your_AWS_Account_ID.signin.aws.amazon.com/console/

* If you create an AWS account alias for your AWS account ID, your sign-in page URL looks like the following example.

https://Your_Alias.signin.aws.amazon.com/console/

* The original URL containing your AWS account ID remains active and can be used after you create your AWS account alias. For example, the following create-account-alias command creates the alias tutorialsdojo for your AWS account:

aws iam create-account-alias --account-alias tutorialsdojo

## CloudHSM

* AWS CloudHSM provides hardware security modules in AWS Cloud. A hardware security module (HSM) is a computing device that processes cryptographic operations and provides secure storage for cryptographic keys.
* When you use an HSM from AWS CloudHSM, you can perform a variety of cryptographic tasks:
  * Generate, store, import, export, and manage cryptographic keys, including symmetric keys and asymmetric key pairs.
  * Use symmetric and asymmetric algorithms to encrypt and decrypt data.
  * Use cryptographic hash functions to compute message digests and hash-based message authentication codes (HMACs).
  * Cryptographically sign data (including code signing) and verify signatures.
  * Generate cryptographically secure random data.

* You should consider using AWS CloudHSM instead of AWS KMS if you require:
  * Keys stored in dedicated, third-party validated hardware security modules under your exclusive control.
  * FIPS 140-2 compliance.
  * Integration with applications using PKCS#11, Java JCE, or Microsoft CNG interfaces.
  * High-performance in-VPC cryptographic acceleration (bulk crypto).

* AWS WAF is a web application firewall that lets you monitor the HTTP and HTTPS requests that are forwarded to an Amazon API Gateway API, Amazon CloudFront or an Application Load Balancer. AWS WAF also lets you control access to your content. Based on conditions that you specify, such as the IP addresses that requests originate from or the values of query strings, API Gateway, CloudFront or an Application Load Balancer responds to requests either with the requested content or with an HTTP 403 status code (Forbidden). You also can configure CloudFront to return a custom error page when a request is blocked.

## SWF

* You can use markers to record events in the workflow execution history for application specific purposes. Markers are useful when you want to record custom information to help implement decider logic. For example, you could use a marker to count the number of loops in a recursive workflow.

* signals enable you to inject information into a running workflow execution. Take note that in this scenario, you are required to record information in the workflow history of a workflow execution.

* timers enable you to notify your decider when a certain amount of time has elapsed and does not meet the requirement in this scenario.

* tags enable you to filter the listing of the executions when you use the visibility operations, which once again does not meet the requirement in this scenario.

* instances launched into a private subnet in a VPC can't communicate with internet unless you use a NAT

* You need an internet gateway and a route in the route table to talk to the internet

### Errors

* 504: integration time_out, integration_failure, usage plan qutoa exceeded
* 502: large number of incoming requests
* 403: authentication issue (AWS Cognito)