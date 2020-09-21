![terratest](https://github.com/playgroundcloud/terraform-aws-nwk/workflows/terratest/badge.svg)
![terraform fmt](https://github.com/playgroundcloud/terraform-aws-nwk/workflows/terraform-fmt/badge.svg)
![terraform validate](https://github.com/playgroundcloud/terraform-aws-nwk/workflows/terraform-validate/badge.svg)

# Terraform AWS Network
This module delivers the standard VPC for a solution environment.

## Provisional Instructions
#### Minimal
```hcl
module "nwk" {
  source            = "git@github.com:playgroundcloud/terraform-aws-nwk.git?ref=vX.Y.Z"
  name              = "test"
  vpc_cidr          = "10.0.0.0/16"
  subnets_byname    = ["test", "test1", "test2"]
  availability_zone = ["eu-north-1a"]
}
```
#### High Availability
```hcl
module "nwk" {
  source            = "git@github.com:playgroundcloud/terraform-aws-nwk.git?ref=vX.Y.Z"
  name              = "test"
  vpc_cidr          = "10.0.0.0/16"
  subnets_byname    = ["test", "test1", "test2"]
  availability_zone = ["eu-north-1a","eu-north-1b","eu-north-1c"]
}
```

#### 2-tier Public / Private with High Availability
```hcl
module "nwk" {
  source            = "git@github.com:playgroundcloud/terraform-aws-nwk.git?ref=vX.Y.Z"
  name              = "test"
  vpc_cidr          = "10.0.0.0/16"
  subnets_byname    = ["Front-1", "Front-2", "Front-3", "Back-1", "Back-2", "Back-3"]
  public_subnets    = ["Front-1", "Front-2", "Front-3"]
  availability_zone = ["eu-north-1a","eu-north-1b","eu-north-1c"]
}
```

#### 3-tier Public / Private with High Availability
```hcl
module "nwk" {
  source            = "git@github.com:playgroundcloud/terraform-aws-nwk.git?ref=vX.Y.Z"
  name              = "test"
  vpc_cidr          = "10.0.0.0/16"
  subnets_byname    = ["Front-1", "Front-2", "Front-3", "Back-1", "Back-2", "Back-3", "DB-1", "DB-2", "DB-3"]
  public_subnets    = ["Front-1", "Front-2", "Front-3"]
  availability_zone = ["eu-north-1a","eu-north-1b","eu-north-1c"]
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
Each instance that you launch into a VPC has a tenancy attribute. This attribute has the following values:  
`default` - Your instance runs on shared hardware.  
`dedicated` - Your instance runs on single-tenant hardware.  
`host` - Your instance runs on a Dedicated Host, which is an isolated server with configurations that you can control.  
After you launch an instance, there are some limitations to changing its tenancy.  
* You cannot change the tenancy of an instance from `default` to `dedicated` or `host` after you've launched it.  
* You cannot change the tenancy of an instance from `dedicated` or `host` to `default` after you've launched it.  
*Default: "default"*  

* `vpc_tags` (Optional) - Map(string)  
Additional tags for the VPC  
*Default: {}*  

**Subnet Variables**  
You can read up on different subnet sizing under [Additional Notes](#additional-notes)      
* `availability_zone` | (Required) - List(string)  
The AZ for the subnet  

* `subnet_bits` | (Optional) - Number  
*Default: -1*  

One of `subnets_byname`, `subnets_bybits` or `subnets_bycidr` must be used:  
* `subnets_byname` | (Required/Optional) - List(string)  
The name of the subnets you want to create. Each name will create a new subnet. The subnets will be divided into 8 equally-sized if `subnet_bits` isn't changed.  
*Default: []*  

* `subnets_bybits` | (Required/Optional) - List(object({name=string,bits=number,net=number}))      
List of object to create your subnet. This will create subnet based on bits and net set by the user.  
Please read more under [additional notes](#additional-notes).  
*Default: []*  

* `subnets_bycidr` | (Required/Optional) - List(object({name=string,cidr=string}))     
List of object to create your subnet. This will create subnets based cidr set by the user.   
Please read more under [additional notes](#additional-notes).   
*Default: []*  

* `public_subnets` | (Optional) - List(string)  
The names of which subnets you want to set as public subnets.  
*Default: []*  

* `bastion_subnets` | (Optional) - List(string)  
The name of the subnet which you want to host your bastion host within.  
*Default: []*  

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
`subnets_bybits = [{name="App", bits=1, net=1},{name="Front", bits=2, net=1},{name="DB", bits=3, net=1},{name="Admin", bits=3, net=0}]`

#### subnets_bycidr
Here you specify the exact CIDR you want for each subnet, but you now need to do this specifically for each environment as they have different VPC CIDR's. Using the same layout as above, this could be.  
`subnets_bycidr = [{name="App", cidr="10.0.0.128/26"},{name="Front", cidr="10.0.0.64/26"},{name="DB", cidr="10.0.0.32/27"},{name="Admin", cidr="10.0.0.0/27"}]`  
 
#### Adding it up
Internally, maps are constructed to the subnets and their CIDR's and then the maps are merged to provide the actual map which is used to generate subnets from.  
So, you can even combine the 3 methods if you want to. If you use the same names, then subnets defined by name will be overwritten by the two other methods, and subnets defined by bits will overwrite by subnets_bycidr.

#### Network numbers and bits
The diagram below tries to illustrate how additional subnet bits results in more subnets

![image](./picture/subnetsizes.PNG)
  
### Outputs
`vpc`  

`subnets`  
  
`security_groups`     
