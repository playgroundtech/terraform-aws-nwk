package test

import (
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"testing"
)

// NO tests in this testsuite can be runned in Parallel due to number of VPC constraints.
// Therefore there is no t.Parallel() function in this test-suite.

func TestNwkBasic(t *testing.T) {

	name := random.UniqueId()

	terraformOptions := &terraform.Options{
		TerraformDir: "../test/nwk_basic",

		Vars: map[string]interface{}{
			"name":	name,
			"vpc_cidr": "10.0.0.0/16",
			"subnets_byname": []string{"test-basic-nwk-one", "test-basic-nwk-two", "test-basic-nwk-three"},
		},
	}
	defer terraform.Destroy(t, terraformOptions)
	terraform.InitAndApply(t, terraformOptions)
}

func TestNwkBastion(t *testing.T)  {

	testFolder := "../test/nwk_bastion_host"

	// Create a random unique ID for the VPC
	name := random.UniqueId()

	// Options that should be added to
	terraformOptions := &terraform.Options{
		TerraformDir: testFolder,

		Vars: map[string]interface{}{
			"name":	name,
			"vpc_cidr": "10.0.0.0/16",
			"subnets_byname": []string{"test-bastion-nwk-one", "test-bastion-nwk-two", "test-basic-bastion-three", "test-basic-bastion-four", "test-basic-bastion-five"},
			"bastion_subnets": "test-bastion-nwk-one",
			"operating_system": "linux",
		},
	}

	defer terraform.Destroy(t, terraformOptions)
	terraform.InitAndApply(t, terraformOptions)
}

func TestNwkNoStdsg(t *testing.T) {

	testFolder := "../test/nwk_no_stdsg"

	// Create a random unique ID for the VPC
	name := random.UniqueId()

	terraformOptions := &terraform.Options{
		TerraformDir: testFolder,

		Vars: map[string]interface{}{
			"name": name,
			"vpc_cidr": "10.0.0.0/24",
			"subnets_byname": []string{"test-service-no-stdsg-one", "test-service-stdsg-two"},
			"subnets_without_stdsg": []string{"test-service-stdsg-one"},
		},
	}

	defer terraform.Destroy(t, terraformOptions)
	terraform.InitAndApply(t, terraformOptions)
}

func TestNwkPublicSubnet(t *testing.T) {

	testFolder := "../test/nwk_public_subnets"

	// Create a random unique ID for the VPC
	name := random.UniqueId()

	terraformOptions := &terraform.Options{
		TerraformDir: testFolder,

		Vars: map[string]interface{}{
			"name": name,
			"vpc_cidr": "10.0.0.0/25",
			"subnets_byname": []string{"test-service-publicsubnet-one", "test-service-publicsubnet-two"},
			"public_subnet": "test-service-publicsubnet-one",
		},
	}

	defer terraform.Destroy(t, terraformOptions)
	terraform.InitAndApply(t, terraformOptions)
}