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

## CLI

### Ways to Develop and Perform AWS Tasks
  * CLI on local computer
  * CLI on EC2 machine
  * SDK on local computer
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
  * or use cli to simulate api calls without actually making them (save $$$)
    * use --dry-run argument to test

### Decoding Error Messages with STS Decode

* `aws sts decode-authorization-message --encoded-message <value>`
* must have sts decode allowed in policy
* to format response `echo <result>`
* copy --> paste --> .JSON document -> format selection using "quick action >"

### EC2 Instance Metadata

* `curl http://169.254.169.254/latest/meta-data`
* only works from EC2 instance
* can retrieve IAM Role name but cannot retrieve the IAM Policy
* useful for automation

### Software Developer Kits (SDK)

* Allows you to perform actions on AWS directly from application code (Java, Python aka boto3, Node.js, etc)
* use default credential provider chain
* exponential backoff is implemented automatically for SDK api calls

### CLI Profile

* used for multiple aws accounts
* `aws configure --profile my-other-profile`
* `aws s3 ls --profile my-other-profile`

## Elastic BeanStalk

* architecture models
  * single instance deployment: dev
  * LB + ASG: production/pre-prod web apps
  * ASG only: non-web-apps in production (workers, etc)
* components
  * application
  * application version
  * environment name
* relies on CloudFormation
* can use EB cli for automated deployment pipelines
  * eb create, eb status, etc.
* code must be a zip file
* all parameters set in UI can be configured with code using files
* requirements must be in .ebextensions/ directory in root 
  * format must be YAML or JSON format
  * .config extensions (ex: logging.config)
  * able to modify default settings using: option_settings
  * can add resources such as RDS< ElastiCache, DynamoDB, etc
* optimize in case of long deployment: package dependencies with source code to improve deployment performance and speed
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

### BeanStalk with HTTPS
  * load ssl certificate onto LB 
    * from console
    * from code: .ebextensions/securelistener-alb.config
    * using ACM (AWS Certificate Manager) or CLI
    * must configure sg rule to allow incoming port 443 (HTTPS)
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

### Web Server vs Worker Environment

* offload tasks to worker environment (processing video, generating zip file, etc)
* can define periodic tasks in a cron.yaml file

### RDS + BeanStalk

* decouple RDS from BeanStalk
* if you need to decouple
  * take RDS DB snapshot
  * enable deletion protection
  * in BeanStalk create new env that points to existing RDS
  * swap new and old env
  * terminate old env
  * delete CloudFormation stack

## Continuous Integration/ Continuous Devliery (CICD)

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
* encryption: respo encrypted at rest using KMS
* encryption: in flight thorugh HTTPS or SSH 
* cross-acount access
  * do not share SSH keys!
  * do not share AWS creds!
  * use IAM role + AWS STS with AsumeRole API
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
  * cache: files to cache to S3 for future builds
* output logs to S3 and CloudWatch logs
* CloudWatch Alarms can be used to detect failed builds and trigger notifications
* CloudWatch Events/Lambda as a Glue
* ablity to reproduce CodeBuild locally to troubleshoot
  * run CodeBuild locally (need Docker)
  * do this by leveraging CloudBuild agent
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
* each EC2 MUST be running a CodeDeploy agent
* agent continuously polls for work to do
* CodeDeploy sends appspec.yml
* app is pulled from GitHub or S3
* EC2 runs deployment instructions
* agent reports back success/failure
* EC2 instances are grouped by deployment group
* can integrate with CodePipeline
* can reuse existing setup tools, works with any app, and has auto scaling integration
* can do Blue/Green deployments with EC2 instances (but not with premise)
* can do lambda deployments
* does NOT provision resources (instances must exist already)

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
* IAM instance profile: need to give EC2 permissions to pull from S3/GitHub
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
* detection using CloudWatch is recommendedcode
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
* upload template in S3
* can't edit templates - upload new version
* deleting a stack deletes all artifacts associated with it
* template helpers 
  * references and functions

### Deploying CloudFormation templates

* Manually
  * edit template in CloudFormation Designer
  * use console to input parameters
* Automated
  * edit templates in YAML file
  * use AWS CLI to deploy
  * recommended to fully automate

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
* enable resuing templates across apps
* if a resource configuration is likely to change in the future, use a parameter to avoid re-uploading template to change the content
* use Fn::Ref
  * !Ref
  * can reference parameters or resources
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
  * default: 5 minutes
    * can enable detailed monitoring for extra cost
    * can be used to decrease ASG response time
  * recall: EC2 Instance Memory usage not pushed by default.  Push from instance as custom metric
  * standard resolution for custom metric: 1 minute
    * can enable high resolution for up to 1 second
    * StorageResolution API parameter
    * increased $
  * send metric to CloudWatch with PutMetricData
  * use expontential bakoff in case of throttle errors
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
  * Can define log expiration policies (never, 30 days, etc)
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
    * x-ray integration on
    * IAM role is Lambda role
  * Elastic Beanstalk
    * set configuration on EB console
    * or use beanstalk ext: .ebextensions...
  * ECS/EKS/Fargate (docker)
    * create docker image that runs daemon or use official x-ray docker image
    * ensure port mappings and network settings are correct and IAM task roles are defined
  * ELB
  * API gatewat
  * EC2 instances or any app server (including on premise!)
    * linux system must run x-ray demon
    * IAM instance role if EC2, otherwise AWS creds on on-premise instance
* can add annotations to traces to provide extra info
* can trace
  * every request
  * sample request (% or rate per minute)
* security requires IAM for authorization and KMS for encryption at rest
* enablement
  * code: import AWS X-ray SDK
  * install x-ray daemon or enable x-ray aws integration
    * works as low level UDP packet interceptor
    * Lambda already runs x-ray for you
  * app must have IAM rights to write data to x-ray
* troubleshooting EC2
  * ensure EC2 IAM role has permissions
  * ensure instance is running x-ray daemon
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
* 

### Implementing X-Ray
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