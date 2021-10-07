variable "region" {
  default = "us-east-2"
}

variable "bucket_1" {
  default = "main-bucket123456123"
}

variable "bucket_1_name" {
  default = "main-bucket123456123"
}

variable "bucket_2" {
  default = "log-bucket123456123"
}

variable "bucket_2_name" {
  default = "log-bucket123456123"
}

variable "environment_1" {
  default = "test1"
}

variable "environment_2" {
  default = "test2"
}

variable "key_pair" {
  default = ""
}
//vpc 
variable "cidr_block" {
  default = "10.0.0.0/16"
}
variable "vpc_name" {
  default = "test-vpc"
}

variable "public_sub_cidr" {
  default = "10.0.1.0/24"
}

variable "private_sub_cidr" {
  default = "10.0.0.0/24"
}
variable "dbsubgrpname" {
  default = "dbsubgrpname"
}
//eks

variable "clustername" {
  default = "sample-cluster"
}
variable "external_allowed_cidrs" {
  type        = list(string)
  description = "List of CIDRs which can access the bastion"
  default     = ["0.0.0.0/0"]
}
//instance
variable "custom_ami" {
  description = "Provide your own AWS AMI to use - useful if you need specific tools on the bastion"
  default     = "ami-2e90b24b"
}
variable "name_prefix" {
  description = "Prefix to be applied to names of all resources"
  default     = "bstn"
}
variable "tags_default" {
  type        = list
  description = "Tags to apply to all resources"
  default     = ["batsion", "host"]
}
variable "tags_asg" {
  type        = map(string)
  description = "Tags to apply to the bastion autoscaling group"
  default     = {
      Name = "asg"
  }
}
//security
variable "internal_ssh_port" {
  type        = number
  description = "Which port the bastion will use to SSH into other private instances"
  default     = 22
}
variable "external_ssh_port" {
  type        = number
  description = "Which port to use to SSH into the bastion"
  default     = 22
}