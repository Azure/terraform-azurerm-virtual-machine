package e2e

import (
	"fmt"
	"os"
	"testing"

	test_helper "github.com/Azure/terraform-module-test-helper"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestExamplesBasic(t *testing.T) {
	createPublicIp := []bool{
		false, true,
	}
	for _, publicIp := range createPublicIp {
		pip := publicIp
		t.Run(fmt.Sprintf("createPublicIp-%t", pip), func(t *testing.T) {
			vars := map[string]interface{}{
				"create_public_ip": pip,
			}
			managedIdentityId := os.Getenv("MSI_ID")
			if managedIdentityId != "" {
				vars["managed_identity_principal_id"] = managedIdentityId
			}
			test_helper.RunE2ETest(t, "../../", "examples/basic", terraform.Options{
				Upgrade: true,
				Vars:    vars,
			}, func(t *testing.T, output test_helper.TerraformOutput) {
				vmIdRegex := `/subscriptions/.+/resourceGroups/.+/providers/Microsoft.Compute/virtualMachines/.+`
				linuxVmId, ok := output["linux_vm_id"]
				assert.True(t, ok)
				assert.Regexp(t, vmIdRegex, linuxVmId)
				windowsVmId, ok := output["windows_vm_id"]
				assert.True(t, ok)
				assert.Regexp(t, vmIdRegex, windowsVmId)
				if pip {
					linuxPublicIp, ok := output["linux_public_ip"].(string)
					assert.True(t, ok)
					windowsPublicIp, ok := output["windows_public_ip"].(string)
					assert.True(t, ok)
					ipRegex := `((25[0-5]|(2[0-4]|1\d|[1-9]|)\d)\.?\b){4}`
					assert.Regexp(t, ipRegex, linuxPublicIp)
					assert.Regexp(t, ipRegex, windowsPublicIp)
				}
			})
		})
	}
}

func TestExamplesVmss(t *testing.T) {
	test_helper.RunE2ETest(t, "../../", "examples/vmss", terraform.Options{
		Upgrade: true,
	}, func(t *testing.T, output test_helper.TerraformOutput) {
		vmssIdRegex := `/subscriptions/.+/resourceGroups/.+/providers/Microsoft.Compute/virtualMachineScaleSets/.+`
		vmssId, ok := output["linux_vm_vmss_id"]
		require.True(t, ok)
		require.Regexp(t, vmssIdRegex, vmssId)
	})
}

func TestExamplesDedicatedHostGroup(t *testing.T) {
	t.Skip("skip since we don't have quota now")
	test_helper.RunE2ETest(t, "../../", "examples/dedicated_host", terraform.Options{
		Upgrade: true,
	}, func(t *testing.T, output test_helper.TerraformOutput) {
		dhgIdRegex := `/subscriptions/.+/resourceGroups/.+/providers/Microsoft.Compute/hostGroups/.+`
		dhgId, ok := output["dedicated_host_group_id"]
		require.True(t, ok)
		require.Regexp(t, dhgIdRegex, dhgId)
		dhIdRegex := `/subscriptions/.+/resourceGroups/.+/providers/Microsoft.Compute/hostGroups/.+/hosts/.+`
		dhId, ok := output["dedicated_host_id"]
		require.True(t, ok)
		require.Regexp(t, dhIdRegex, dhId)
	})
}

func TestExamplesAvailabilitySet(t *testing.T) {
	test_helper.RunE2ETest(t, "../../", "examples/availability_set", terraform.Options{
		Upgrade: true,
	}, func(t *testing.T, output test_helper.TerraformOutput) {
		asIdRegex := `/subscriptions/.+/resourceGroups/.+/providers/Microsoft.Compute/availabilitySets/.+`
		asId, ok := output["linux_vm_as_id"]
		require.True(t, ok)
		require.Regexp(t, asIdRegex, asId)
	})
}

func TestExamplesExtensions(t *testing.T) {
	test_helper.RunE2ETest(t, "../../", "examples/extensions", terraform.Options{
		Upgrade: true,
	}, nil)
}
