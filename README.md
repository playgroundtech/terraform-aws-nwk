![terratest](https://github.com/playgroundcloud/terraform-aws-nwk/workflows/terratest/badge.svg)
![terraform fmt](https://github.com/playgroundcloud/terraform-aws-nwk/workflows/terraform-fmt/badge.svg)
![terraform validate](https://github.com/playgroundcloud/terraform-aws-nwk/workflows/terraform-validate/badge.svg)

# Terraform AWS Network
This module delivers the standard VPC for a solution environment.

## Provisional Instructions
```hcl
module "nwk" {
  source            = "git@github.com:playgroundcloud/terraform-aws-nwk.git?ref=vX.Y.Z"
  name              = "test"
  vpc_cidr          = "10.0.0.0/16"
  subnets_byname    = ["test", "test1", "test2"]
}
```

### Variables
* `name` | (Required) - String  
Name to be used on all the resources as identifier  

**VPC Variables:**
* `vpc_cidr` | (Required) - String  
The CIDR block for the VPC.  

* `instance_tenancy` | (Optional) - String  
A tenancy option for instances launched into the VPC.  
*Default: "default"*  

* `vpc_tags` (Optional) - Map(string)  
Additional tags for the VPC  
*Default: {}*  

**Subnet Variables**  
You can read up on different subnet sizing under [Additional Notes](#additional-notes)    
* `subnet_bits` | (Optional) - Number  
*Default: -1*  

One of `subnets_byname`, `subnets_bybits` or `subnets_bycidr` must be used:  
* `subnets_byname` | (Required/Optional) - List(string)   
*Default: []*  

* `subnets_bybits` | (Required/Optional) - List(object({name=string,bits=number,net=number}))   
*Default: []*  

* `subnets_bycidr` | (Required/Optional) - List(object({name=string,cidr=string}))     
*Default: []*  

* `subnets_without_stdsg` | (Optional) - List(string)  
If you want to specify any subnets that won't generate a standard security group.  
*Default: []*  

* `public_subnets` | (Optional) - List(string)  
The names of which subnets you want to set as public subnets.  
*Default: []*  

* `bastion_subnets` | (Optional) - List(string)  
The name of the subnet which you want to host your bastion host within.  
*Default: []*  

* `bastion_cidr_blocks` | (Optional) - List(string)  
The cidr that you want to be able to access the bastion host from. `0.0.0.0/0` is not recommended.    
*Default: ["0.0.0.0/0"]*  

* `operating_system` | (Optional) - String  
The Operating Systems that the machines within the subnets will run on. Opens traffic for SSH or RDP communication within the VPC.    
*Default: ""*  

* `aws_security_group_tags` | (Optional) - Map(string)  
Additional tags for subnets standard security groups.  
*Default: {}*    

**Internet Gateway**    
* `internet_gateway_tags` | (Optional) - Map(string)  
Additional tags for the Internet Gateway.  
*Default: {}*  

* `route_table_public_tags` | (Optional) - Map(string)  
Additional tags for the Public Route Table.  
*Default: {}*  

### Additional Notes  
#### Subnet Sizing  
There are 3 ways of specifying subnets: `subnets_byname` - a simple list; `subnets_bybits` - a list of maps with names, network numbers and bits; and `subnets_bycidr` - specifying the exact CIDR. The two first construct the subnets relative to the CIDR of the VPC regarding both size and ip-segment. The third is hard-coded.  

#### subnets_byname  
If you just do `subnets_byname`, then the VPC will be divided into 8 equally-sized parts and subnet CIDRs will be allocated to that. You can use `subnet_bits` to set how many additional bits used for subnets - the default is 3, which gives 2^3 = 8 subnets.  

#### subnets_bybits  
Here you get more flexibility, the subnets don't have to be of the same size, but you have to do the puzzle yourself.  

Let's say you want to use half the available space for application servers, 25% for frontend, and split the remains between database and admin hosts:  
`subnet_bits = [{name="App", bits=1, net=1},{name="Front", bits=2, net=1},{name="DB", bits=3, net=1},{name="Admin", bits=3, net=0}]`

#### subnets_bycidr
 Here you specify the exact CIDR you want for each subnet, but you now need to do this specifically for each environment as they have different VPC CIDR's. Using the same layout as above, this could be.  
 `subnets_bycidr = [{name="App", cidr="10.0.0.128/9"},{name="Front", cidr="10.0.0.64/10"},{name="DB", cidr="10.0.0.32/11"},{name="Admin", cidr="10.0.0.0/11"]`  
 
#### Adding it up
Internally, maps are constructed to the subnets and their CIDR's and then the maps are merged to provide the actual map which is used to generate subnets from.  
So, you can even combine the 3 methods if you want to. If you use the same names, then subnets defined by name will be overwritten by the two other methods, and subnets defined by bits will overwrite by subnets_bycidr.

#### Network numbers and bits
The diagram below tries to illustrate how additional subnetbits results in more subnets

![image](./picture/subnetsizes.PNG)
  
### Outputs
`vpc`  

`subnets`  
  
`security_groups`     
