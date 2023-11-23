package upgrade

import (
	"fmt"
	"os"
	"testing"

	test_helper "github.com/Azure/terraform-module-test-helper"
	"github.com/gruntwork-io/terratest/modules/terraform"
)

func TestExampleUpgrade_basic(t *testing.T) {
	createPublicIp := []bool{
		false, true,
	}
	for _, create := range createPublicIp {
		pip := create
		t.Run(fmt.Sprintf("createPublicIp-%t", pip), func(t *testing.T) {
			currentRoot, err := test_helper.GetCurrentModuleRootPath()
			if err != nil {
				t.FailNow()
			}
			currentMajorVersion, err := test_helper.GetCurrentMajorVersionFromEnv()
			if err != nil {
				t.FailNow()
			}
			vars := map[string]interface{}{
				"create_public_ip": pip,
			}
			managedIdentityId := os.Getenv("MSI_ID")
			if managedIdentityId != "" {
				vars["managed_identity_principal_id"] = managedIdentityId
			}
			test_helper.ModuleUpgradeTest(t, "Azure", "terraform-azurerm-virtual-machine", "examples/basic", currentRoot, terraform.Options{
				Upgrade: true,
				Vars:    vars,
			}, currentMajorVersion)
		})
	}
}

func TestExampleUpgrade(t *testing.T) {
	examples := []string{
		"availability_set",
		"vmss",
	}
	for _, example := range examples {
		e := example
		t.Run(e, func(t *testing.T) {
			currentRoot, err := test_helper.GetCurrentModuleRootPath()
			if err != nil {
				t.FailNow()
			}
			currentMajorVersion, err := test_helper.GetCurrentMajorVersionFromEnv()
			if err != nil {
				t.FailNow()
			}
			test_helper.ModuleUpgradeTest(t, "Azure", "terraform-azurerm-virtual-machine", fmt.Sprintf("examples/%s", e), currentRoot, terraform.Options{
				Upgrade: true,
			}, currentMajorVersion)
		})
	}
}
