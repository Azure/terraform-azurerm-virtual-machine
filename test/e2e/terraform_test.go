package e2e

import (
	"fmt"
	"testing"

	test_helper "github.com/Azure/terraform-module-test-helper"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

func TestExamplesBasic(t *testing.T) {
	createPublicIp := []bool{
		false, true,
	}
	for _, publicIp := range createPublicIp {
		t.Run(fmt.Sprintf("createPublicIp-%v", createPublicIp), func(t *testing.T) {
			test_helper.RunE2ETest(t, "../../", "examples/basic", terraform.Options{
				Upgrade: true,
				Vars: map[string]interface{}{
					"create_public_ip": publicIp,
				},
			}, func(t *testing.T, output test_helper.TerraformOutput) {
				vmIdRegex := `/subscriptions/.+/resourceGroups/.+/providers/Microsoft.Compute/virtualMachines/.+`
				linuxVmId, ok := output["linux_vm_id"]
				assert.True(t, ok)
				assert.Regexp(t, vmIdRegex, linuxVmId)
				windowsVmId, ok := output["windows_vm_id"]
				assert.True(t, ok)
				assert.Regexp(t, vmIdRegex, windowsVmId)
				if publicIp {
					linuxPublicIps, ok := output["linux_public_ips"].([]string)
					assert.True(t, ok)
					assert.Equal(t, 1, len(linuxPublicIps))
					windowsPublicIps, ok := output["windows_public_ips"].([]string)
					assert.True(t, ok)
					assert.Equal(t, 1, len(windowsPublicIps))
					ipRegex := `((25[0-5]|(2[0-4]|1\d|[1-9]|)\d)\.?\b){4}`
					ips := append(linuxPublicIps, windowsPublicIps...)
					for _, ip := range ips {
						assert.Regexp(t, ipRegex, ip)
					}
					nsgIdRegex := `/subscriptions/.+/resourceGroups/.+/providers/Microsoft.Network/networkSecurityGroups/.+`
					linuxNsgId, ok := output["linux_network_security_group_id"].(string)
					assert.True(t, ok)
					assert.Regexp(t, nsgIdRegex, linuxNsgId)
					windowsNsgId, ok := output["windows_network_security_group_id"].(string)
					assert.True(t, ok)
					assert.Regexp(t, nsgIdRegex, windowsNsgId)
				}
			})
		})
	}
}
