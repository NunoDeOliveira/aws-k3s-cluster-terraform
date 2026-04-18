###########################################################
# Variable values file. Provides values for the input     #
# variables defined in variables.tf 
###########################################################


region   = "eu-west-2"
vpc_cidr = "10.0.0.0/16"

subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]

availability_zones = ["eu-west-2a", "eu-west-2b", "eu-west-2c"]

instance_count = 3
instance_type  = "t3.small"

ami_id   = "ami-xxxxxxxxxxxxxxxxx"
key_name = "tu-keypair-en-aws"
my_ip    = "TU_IP_PUBLICA/32"
