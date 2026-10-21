# The API token comes from the environment, never from a file in this repo:
#   export PROXMOX_VE_API_TOKEN='terraform@pve!tf=<uuid secret>'
#
# The token needs VM.Allocate, VM.Config.*, VM.Audit and VM.PowerMgmt on /vms,
# and Datastore.AllocateSpace on the target datastore.
provider "proxmox" {
  endpoint = var.proxmox_endpoint
  insecure = var.proxmox_insecure
}
