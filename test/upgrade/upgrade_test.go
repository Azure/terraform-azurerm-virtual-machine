package upgrade

import (
	"fmt"
	"testing"

	test_helper "github.com/Azure/terraform-module-test-helper"
	"github.com/gruntwork-io/terratest/modules/terraform"
)

func TestExampleUpgrade_basic(t *testing.T) {
	createPublicIp := []bool{
		false, true,
	}
	for _, create := range createPublicIp {
		t.Run(fmt.Sprintf("createPublicIp-%t", create), func(t *testing.T) {
			currentRoot, err := test_helper.GetCurrentModuleRootPath()
			if err != nil {
				t.FailNow()
			}
			currentMajorVersion, err := test_helper.GetCurrentMajorVersionFromEnv()
			if err != nil {
				t.FailNow()
			}
			test_helper.ModuleUpgradeTest(t, "Azure", "terraform-azurerm-virtual-machine", "examples/basic", currentRoot, terraform.Options{
				Upgrade: true,
				Vars: map[string]interface{}{
					"create_public_ip": create,
				},
			}, currentMajorVersion)
		})
	}
}
