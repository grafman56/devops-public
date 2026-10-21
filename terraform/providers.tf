provider "proxmox" {
  endpoint = var.proxmox_endpoint
  insecure = var.proxmox_insecure

  # The API token is read from PROXMOX_VE_API_TOKEN, format:
  #   terraform@pve!tf=<uuid secret>
  # It never appears in this repository, a tfvars file, or a plan file.
}
