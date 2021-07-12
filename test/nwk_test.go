// Use test-structure to skip certain steps
// SKIP_destroy=true go test -v -timeout 90m -run TestNameOfYourTest
// NO tests in this testsuite can be runned in Parallel due to number of VPC constraints.
// Therefore there is no t.Parallel() function in this test-suite.

package test

import (
	"fmt"
	test_structure "github.com/gruntwork-io/terratest/modules/test-structure"
	"strings"
	"testing"
	"time"

	"github.com/gruntwork-io/terratest/modules/aws"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/retry"
	"github.com/gruntwork-io/terratest/modules/ssh"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func testSSHAgentToPublicHost(t *testing.T, terraformOptions *terraform.Options, keyPair *aws.Ec2Keypair) {
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
}

func TestNwkBasic(t *testing.T) {
	// Create a random unique ID for the VPC
	name := random.UniqueId()
	workingDir := "../test/nwk_basic"

	defer test_structure.RunTestStage(t, "destroy", func() {
		terraformOptions := test_structure.LoadTerraformOptions(t, workingDir)
		terraform.Destroy(t, terraformOptions)
		// clean up saved options
		test_structure.CleanupTestDataFolder(t, workingDir)
	})

	test_structure.RunTestStage(t, "init", func() {
		terraformOptions := &terraform.Options{
			TerraformDir: workingDir,

			Vars: map[string]interface{}{
				"name":           name,
				"vpc_cidr":       "10.0.0.0/16",
				"subnets_byname": []string{"test-basic-nwk-one", "test-basic-nwk-two", "test-basic-nwk-three"},
			},
		}
		test_structure.SaveTerraformOptions(t, workingDir, terraformOptions)
		terraform.InitAndApply(t, terraformOptions)
	})

	test_structure.RunTestStage(t, "tests", func() {
		terraformOptions := test_structure.LoadTerraformOptions(t, workingDir)
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
		terraform.ApplyAndIdempotent(t, terraformOptions)
	})
}

func TestNwkHA(t *testing.T) {
	// Run test in Parallel
	t.Parallel()

	// Create a random unique ID for the VPC
	name := random.UniqueId()
	workingDir := "../test/nwk_ha"

	defer test_structure.RunTestStage(t, "destroy", func() {
		terraformOptions := test_structure.LoadTerraformOptions(t, workingDir)
		terraform.Destroy(t, terraformOptions)
		// clean up saved options
		test_structure.CleanupTestDataFolder(t, workingDir)
	})

	test_structure.RunTestStage(t, "init", func() {
		terraformOptions := &terraform.Options{
			TerraformDir: workingDir,

			Vars: map[string]interface{}{
				"name":           name,
				"vpc_cidr":       "10.0.0.0/16",
				"subnets_byname": []string{"Front-1", "Front-2", "Front-3", "Back-1", "Back-2", "Back-3", "TGW-1", "TGW-2", "TGW-3"},
				"public_subnets": []string{"Front-1", "Front-2", "Front-3", "Back-1", "Back-2", "Back-3"},
			},
		}
		test_structure.SaveTerraformOptions(t, workingDir, terraformOptions)
		terraform.InitAndApply(t, terraformOptions)
	})

	test_structure.RunTestStage(t, "tests", func() {
		terraformOptions := test_structure.LoadTerraformOptions(t, workingDir)
		// Run `terraform output` to get the value of an output variable
		vpcId := terraform.Output(t, terraformOptions, "vpc_id")

		// Get Subnets for VPC
		subnets := aws.GetSubnetsForVpc(t, vpcId, "eu-north-1")

		// Makes sure that all the subnets created is associated with the vpc, no more or less should be attached to it.
		require.Equal(t, 9, len(subnets))

		terraform.ApplyAndIdempotent(t, terraformOptions)
	})
}

func TestNwkBastion(t *testing.T) {
	// Run test in Parallel
	t.Parallel()

	// Create ssh key-pair
	uniqueID := random.UniqueId()
	keyPairName := fmt.Sprintf("terratest-ssh-example-%s", uniqueID)
	keyPair := aws.CreateAndImportEC2KeyPair(t, "eu-north-1", keyPairName)
	defer aws.DeleteEC2KeyPair(t, keyPair)
	// Create a random unique ID for the VPC
	name := random.UniqueId()
	// AWS Region
	awsRegion := "eu-north-1"
	workingDir := "../test/nwk_bastion_host"

	defer test_structure.RunTestStage(t, "destroy", func() {
		terraformOptions := test_structure.LoadTerraformOptions(t, workingDir)
		terraform.Destroy(t, terraformOptions)
		// clean up saved options
		test_structure.CleanupTestDataFolder(t, workingDir)
	})

	test_structure.RunTestStage(t, "init", func() {
		terraformOptions := &terraform.Options{
			TerraformDir: workingDir,

			Vars: map[string]interface{}{
				"name":            name,
				"vpc_cidr":        "10.0.0.0/16",
				"subnets_byname":  []string{"test-bastion-nwk-one", "test-bastion-nwk-two", "test-basic-bastion-three", "test-basic-bastion-four", "test-basic-bastion-five"},
				"public_subnets": "test-bastion-nwk-one",
				"key_pair_name":   keyPairName,
			},
		}
		test_structure.SaveTerraformOptions(t, workingDir, terraformOptions)
		terraform.InitAndApply(t, terraformOptions)
	})

	test_structure.RunTestStage(t, "tests", func() {
		terraformOptions := test_structure.LoadTerraformOptions(t, workingDir)
		testSSHAgentToPublicHost(t, terraformOptions, keyPair)
		// Run `terraform output` to get the value of an output variable
		vpcId := terraform.Output(t, terraformOptions, "vpc_id")
		bastionSubnet := terraform.Output(t, terraformOptions, "bastion_subnet")
		// Get Subnets for VPC
		subnets := aws.GetSubnetsForVpc(t, vpcId, awsRegion)
		// Makes sure that all the subnets created is associated with the vpc, no more or less should be attached to it.
		require.Equal(t, 5, len(subnets))
		// Check that bastion subnet is a public subnet
		assert.True(t, aws.IsPublicSubnet(t, fmt.Sprint(bastionSubnet), awsRegion))
		terraform.ApplyAndIdempotent(t, terraformOptions)
	})
}

func TestNwkByBits(t *testing.T) {
	// Create a random unique ID for the VPC
	name := random.UniqueId()
	workingDir := "../test/nwk_bybits"

	defer test_structure.RunTestStage(t, "destroy", func() {
		terraformOptions := test_structure.LoadTerraformOptions(t, workingDir)
		terraform.Destroy(t, terraformOptions)
		// clean up saved options
		test_structure.CleanupTestDataFolder(t, workingDir)
	})

	test_structure.RunTestStage(t, "init", func() {
		terraformOptions := &terraform.Options{
			TerraformDir: workingDir,

			Vars: map[string]interface{}{
				"name":     name,
				"vpc_cidr": "10.0.0.0/16",
			},
		}
		test_structure.SaveTerraformOptions(t, workingDir, terraformOptions)
		terraform.InitAndApply(t, terraformOptions)
	})

	test_structure.RunTestStage(t, "tests", func() {
		terraformOptions := test_structure.LoadTerraformOptions(t, workingDir)
		vpcId := terraform.Output(t, terraformOptions, "vpc_id")
		subnets := aws.GetSubnetsForVpc(t, vpcId, "eu-north-1")

		// Makes sure that all the subnets created is associated with the vpc, no more or less should be attached to it.
		require.Equal(t, 4, len(subnets))
		// Checks that all the subnets are marked as private subnets
		for subnet := range subnets {
			assert.False(t, aws.IsPublicSubnet(t, fmt.Sprint(subnet), "eu-north-1"))
		}
		terraform.ApplyAndIdempotent(t, terraformOptions)
	})
}

func TestNwkByCidr(t *testing.T) {
	// Run test in Parallel
	t.Parallel()

	// Create a random unique ID for the VPC
	name := random.UniqueId()
	workingDir := "../test/nwk_bycidr"

	defer test_structure.RunTestStage(t, "destroy", func() {
		terraformOptions := test_structure.LoadTerraformOptions(t, workingDir)
		terraform.Destroy(t, terraformOptions)
		// clean up saved options
		test_structure.CleanupTestDataFolder(t, workingDir)
	})

	test_structure.RunTestStage(t, "init", func() {
		terraformOptions := &terraform.Options{
			TerraformDir: workingDir,

			Vars: map[string]interface{}{
				"name":     name,
				"vpc_cidr": "10.0.0.0/16",
			},
		}
		test_structure.SaveTerraformOptions(t, workingDir, terraformOptions)
		terraform.InitAndApply(t, terraformOptions)
	})

	test_structure.RunTestStage(t, "tests", func() {
		terraformOptions := test_structure.LoadTerraformOptions(t, workingDir)
		vpcId := terraform.Output(t, terraformOptions, "vpc_id")
		subnets := aws.GetSubnetsForVpc(t, vpcId, "eu-north-1")

		// Makes sure that all the subnets created is associated with the vpc, no more or less should be attached to it.
		require.Equal(t, 4, len(subnets))

		// Checks that all the subnets are marked as private subnets
		for subnet := range subnets {
			assert.False(t, aws.IsPublicSubnet(t, fmt.Sprint(subnet), "eu-north-1"))
		}
		terraform.ApplyAndIdempotent(t, terraformOptions)
	})
}

func TestNwkPublicSubnet(t *testing.T) {
	// Run test in Parallel
	t.Parallel()

	// Create a random unique ID for the VPC
	name := random.UniqueId()
	// AWS Region
	awsRegion := "eu-north-1"
	workingDir := "../test/nwk_public_subnets"
	defer test_structure.RunTestStage(t, "destroy", func() {
		terraformOptions := test_structure.LoadTerraformOptions(t, workingDir)
		terraform.Destroy(t, terraformOptions)
		// clean up saved options
		test_structure.CleanupTestDataFolder(t, workingDir)
	})
	test_structure.RunTestStage(t, "init", func() {
		terraformOptions := &terraform.Options{
			TerraformDir: workingDir,

			Vars: map[string]interface{}{
				"name":           name,
				"vpc_cidr":       "10.0.0.0/25",
				"subnets_byname": []string{"test-service-publicsubnet-one", "test-service-publicsubnet-two"},
				"public_subnet":  "test-service-publicsubnet-one",
			},
		}
		test_structure.SaveTerraformOptions(t, workingDir, terraformOptions)
		terraform.InitAndApply(t, terraformOptions)
	})

	test_structure.RunTestStage(t, "tests", func() {
		terraformOptions := test_structure.LoadTerraformOptions(t, workingDir)
		// Run `terraform output` to get the value of an output variable
		vpcId := terraform.Output(t, terraformOptions, "vpc_id")
		publicSubnet := terraform.Output(t, terraformOptions, "public_subnet")
		// Get Subnets for VPC
		subnets := aws.GetSubnetsForVpc(t, vpcId, awsRegion)
		// Makes sure that all the subnets created is associated with the vpc, no more or less should be attached to it.
		require.Equal(t, 2, len(subnets))
		// Check that bastion subnet is a public subnet
		assert.True(t, aws.IsPublicSubnet(t, publicSubnet, awsRegion))
		terraform.ApplyAndIdempotent(t, terraformOptions)
	})
}

func TestNwkDenyAllACL(t *testing.T) {
	// Run test in Parallel
	t.Parallel()

	// Create a random unique ID for the VPC
	name := random.UniqueId()
	// AWS Region
	awsRegion := "eu-north-1"
	workingDir := "../test/nwk_deny_all_acl"
	defer test_structure.RunTestStage(t, "destroy", func() {
		terraformOptions := test_structure.LoadTerraformOptions(t, workingDir)
		terraform.Destroy(t, terraformOptions)
		// clean up saved options
		test_structure.CleanupTestDataFolder(t, workingDir)
	})
	test_structure.RunTestStage(t, "init", func() {
		terraformOptions := &terraform.Options{
			TerraformDir: workingDir,

			Vars: map[string]interface{}{
				"name":           name,
				"vpc_cidr":       "10.0.0.0/25",
				"subnets_byname": []string{"test-service-deny-all-acl-one", "test-service-deny-all-acl-two"},
				"public_subnet":  "test-service-deny-all-acl-one",
			},
		}
		test_structure.SaveTerraformOptions(t, workingDir, terraformOptions)
		terraform.InitAndApply(t, terraformOptions)
	})

	test_structure.RunTestStage(t, "tests", func() {
		terraformOptions := test_structure.LoadTerraformOptions(t, workingDir)
		// Run `terraform output` to get the value of an output variable
		vpcId := terraform.Output(t, terraformOptions, "vpc_id")
		publicSubnet := terraform.Output(t, terraformOptions, "public_subnet")
		// Get Subnets for VPC
		subnets := aws.GetSubnetsForVpc(t, vpcId, awsRegion)
		// Makes sure that all the subnets created is associated with the vpc, no more or less should be attached to it.
		require.Equal(t, 2, len(subnets))
		// Check that bastion subnet is a public subnet
		assert.True(t, aws.IsPublicSubnet(t, publicSubnet, awsRegion))
		terraform.ApplyAndIdempotent(t, terraformOptions)
	})
}
