package test

import (
	"fmt"
	"github.com/gruntwork-io/terratest/modules/aws"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/retry"
	"github.com/gruntwork-io/terratest/modules/ssh"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"strings"
	"sync"
	"testing"
	"time"
)

// NO tests in this testsuite can be runned in Parallel due to number of VPC constraints.
// Therefore there is no t.Parallel() function in this test-suite.
// Test TestNwkBastion is taking advantage of goroutines to speed up testing.

func testSSHAgentToPublicHost(t *testing.T, terraformOptions *terraform.Options, keyPair *aws.Ec2Keypair, wg *sync.WaitGroup) {
	// Run `terraform output` to get the value of an output variable
	publicInstanceIP := terraform.Output(t, terraformOptions, "public_instance_ip")

	// start the ssh agent
	sshAgent := ssh.SshAgentWithKeyPair(t, keyPair.KeyPair)
	defer sshAgent.Stop()

	publicHost := ssh.Host{
		Hostname:         publicInstanceIP,
		SshUserName:      "ubuntu",
		OverrideSshAgent: sshAgent,
	}

	// It can take a minute or so for the Instance to boot up, so retry a few times
	maxRetries := 30
	timeBetweenRetries := 5 * time.Second
	description := fmt.Sprintf("SSH with Agent to public host %s", publicInstanceIP)

	// Run a simple echo command on the server
	expectedText := "Hello, World"
	command := fmt.Sprintf("echo -n '%s'", expectedText)

	// Verify that we can SSH to the Instance and run commands
	retry.DoWithRetry(t, description, maxRetries, timeBetweenRetries, func() (string, error) {

		actualText, err := ssh.CheckSshCommandE(t, publicHost, command)

		if err != nil {
			return "", err
		}

		if strings.TrimSpace(actualText) != expectedText {
			return "", fmt.Errorf("expected SSH command to return '%s' but got '%s'", expectedText, actualText)
		}

		return "", nil
	})

	wg.Done()
}

func TestNwkBasic(t *testing.T) {

	name := random.UniqueId()

	terraformOptions := &terraform.Options{
		TerraformDir: "../test/nwk_basic",

		Vars: map[string]interface{}{
			"name":           name,
			"vpc_cidr":       "10.0.0.0/16",
			"subnets_byname": []string{"test-basic-nwk-one", "test-basic-nwk-two", "test-basic-nwk-three"},
		},
	}
	defer terraform.Destroy(t, terraformOptions)
	terraform.InitAndApply(t, terraformOptions)

	// Run `terraform output` to get the value of an output variable
	vpcId := terraform.Output(t, terraformOptions, "vpc_id")

	// Get Subnets for VPC
	subnets := aws.GetSubnetsForVpc(t, vpcId, "eu-north-1")
	
	// Makes sure that all the subnets created is associated with the vpc, no more or less should be attached to it.
	require.Equal(t, 3, len(subnets))

	// Checks that all the subnets are marked as private subnets
	for subnet := range subnets {
		assert.False(t, aws.IsPublicSubnet(t, fmt.Sprint(subnet), "eu-north-1"))
	}
}

func TestNwkBastion(t *testing.T) {

	testFolder := "../test/nwk_bastion_host"

	// Create ssh key-pair
	uniqueID := random.UniqueId()
	keyPairName := fmt.Sprintf("terratest-ssh-example-%s", uniqueID)
	keyPair := aws.CreateAndImportEC2KeyPair(t, "eu-north-1", keyPairName)
	defer aws.DeleteEC2KeyPair(t, keyPair)

	// Create a random unique ID for the VPC
	name := random.UniqueId()

	// AWS Region
	awsRegion := "eu-north-1"

	// Options that should be added to
	terraformOptions := &terraform.Options{
		TerraformDir: testFolder,

		Vars: map[string]interface{}{
			"name":             name,
			"vpc_cidr":         "10.0.0.0/16",
			"subnets_byname":   []string{"test-bastion-nwk-one", "test-bastion-nwk-two", "test-basic-bastion-three", "test-basic-bastion-four", "test-basic-bastion-five"},
			"bastion_subnets":  "test-bastion-nwk-one",
			"key_pair_name":    keyPairName,
		},
	}

	defer terraform.Destroy(t, terraformOptions)
	terraform.InitAndApply(t, terraformOptions)

	// Create goroutine for checking that it's possible to ssh to the machine in the bastion_subnet
	var wg sync.WaitGroup
	wg.Add(1)
	go testSSHAgentToPublicHost(t, terraformOptions, keyPair, &wg)

	// Run `terraform output` to get the value of an output variable
	vpcId := terraform.Output(t, terraformOptions, "vpc_id")

	bastionSubnet := terraform.Output(t, terraformOptions, "bastion_subnet")

	// Get Subnets for VPC
	subnets := aws.GetSubnetsForVpc(t, vpcId, awsRegion)

	// Makes sure that all the subnets created is associated with the vpc, no more or less should be attached to it.
	require.Equal(t, 5, len(subnets))

	// Check that bastion subnet is a public subnet
	assert.True(t, aws.IsPublicSubnet(t, fmt.Sprint(bastionSubnet), awsRegion))

	// Make sure that all goroutines has closed before ending the test.
	wg.Wait()
}

func TestNwkByBits(t *testing.T) {

	name := random.UniqueId()

	terraformOptions := &terraform.Options{
		TerraformDir: "../test/nwk_bybits",

		Vars: map[string]interface{}{
			"name":           name,
			"vpc_cidr":       "10.0.0.0/16",
		},
	}
	defer terraform.Destroy(t, terraformOptions)
	terraform.InitAndApply(t, terraformOptions)

	// Run `terraform output` to get the value of an output variable
	vpcId := terraform.Output(t, terraformOptions, "vpc_id")

	// Get Subnets for VPC
	subnets := aws.GetSubnetsForVpc(t, vpcId, "eu-north-1")

	// Makes sure that all the subnets created is associated with the vpc, no more or less should be attached to it.
	require.Equal(t, 4, len(subnets))

	// Checks that all the subnets are marked as private subnets
	for subnet := range subnets {
		assert.False(t, aws.IsPublicSubnet(t, fmt.Sprint(subnet), "eu-north-1"))
	}
}

func TestNwkByCidr(t *testing.T) {

	name := random.UniqueId()

	terraformOptions := &terraform.Options{
		TerraformDir: "../test/nwk_bycidr",

		Vars: map[string]interface{}{
			"name":           name,
			"vpc_cidr":       "10.0.0.0/16",
		},
	}
	defer terraform.Destroy(t, terraformOptions)
	terraform.InitAndApply(t, terraformOptions)

	// Run `terraform output` to get the value of an output variable
	vpcId := terraform.Output(t, terraformOptions, "vpc_id")

	// Get Subnets for VPC
	subnets := aws.GetSubnetsForVpc(t, vpcId, "eu-north-1")

	// Makes sure that all the subnets created is associated with the vpc, no more or less should be attached to it.
	require.Equal(t, 4, len(subnets))

	// Checks that all the subnets are marked as private subnets
	for subnet := range subnets {
		assert.False(t, aws.IsPublicSubnet(t, fmt.Sprint(subnet), "eu-north-1"))
	}
}

func TestNwkPublicSubnet(t *testing.T) {

	testFolder := "../test/nwk_public_subnets"
	// Create a random unique ID for the VPC
	name := random.UniqueId()

	// AWS Region
	awsRegion := "eu-north-1"

	terraformOptions := &terraform.Options{
		TerraformDir: testFolder,

		Vars: map[string]interface{}{
			"name":           name,
			"vpc_cidr":       "10.0.0.0/25",
			"subnets_byname": []string{"test-service-publicsubnet-one", "test-service-publicsubnet-two"},
			"public_subnet":  "test-service-publicsubnet-one",
		},
	}

	defer terraform.Destroy(t, terraformOptions)
	terraform.InitAndApply(t, terraformOptions)

	// Run `terraform output` to get the value of an output variable
	vpcId := terraform.Output(t, terraformOptions, "vpc_id")

	publicSubnet := terraform.Output(t, terraformOptions, "public_subnet")

	// Get Subnets for VPC
	subnets := aws.GetSubnetsForVpc(t, vpcId, awsRegion)

	// Makes sure that all the subnets created is associated with the vpc, no more or less should be attached to it.
	require.Equal(t, 2, len(subnets))

	// Check that bastion subnet is a public subnet
	assert.True(t, aws.IsPublicSubnet(t, publicSubnet, awsRegion))
}
