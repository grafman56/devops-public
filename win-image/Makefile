SHELL := /bin/bash
BUILD := build

.DEFAULT_GOAL := help

help:
	@echo "make init       install the pinned Packer plugin"
	@echo "make answer-iso build $(BUILD)/win2025-autounattend.iso (needs ADMIN_PASSWORD)"
	@echo "make validate   packer fmt -check and packer validate"
	@echo "make build      run the image build (needs the ISO uploaded to Proxmox)"
	@echo "make clean      remove $(BUILD)/"
	@echo
	@echo "Required environment for build:"
	@echo "  ADMIN_PASSWORD         local Administrator password, 12+ chars"
	@echo "  PROXMOX_TOKEN_ID       for example packer@pve!packer"
	@echo "  PROXMOX_TOKEN_SECRET"
	@echo "Optional: PROXMOX_URL, PROXMOX_NODE, STORAGE_POOL, BRIDGE, VLAN_TAG,"
	@echo "          WINDOWS_ISO, VIRTIO_ISO, ANSWER_ISO, TEMPLATE_NAME"

# --------------------------------------------------------------------------
# Answer ISO
# --------------------------------------------------------------------------

check-password:
	@if [ -z "$$ADMIN_PASSWORD" ]; then \
		echo "ADMIN_PASSWORD is not set"; exit 1; fi
	@if [ "$${#ADMIN_PASSWORD}" -lt 12 ] 2>/dev/null; then \
		echo "ADMIN_PASSWORD must be at least 12 characters"; exit 1; fi

$(BUILD)/answer-root/autounattend.xml: answer/autounattend.xml check-password
	@mkdir -p $(BUILD)/answer-root
	sed 's|__ADMIN_PASSWORD__|'"$$ADMIN_PASSWORD"'|g' $< > $@
	@if grep -q '__ADMIN_PASSWORD__' $@; then \
		echo "placeholder survived substitution in $@"; exit 1; fi

$(BUILD)/answer-root/unattend-deploy.xml: answer/unattend-deploy.xml check-password
	@mkdir -p $(BUILD)/answer-root
	sed 's|__ADMIN_PASSWORD__|'"$$ADMIN_PASSWORD"'|g' $< > $@
	@if grep -q '__ADMIN_PASSWORD__' $@; then \
		echo "placeholder survived substitution in $@"; exit 1; fi

answer-iso: $(BUILD)/answer-root/autounattend.xml $(BUILD)/answer-root/unattend-deploy.xml
	cp scripts/bootstrap.ps1 $(BUILD)/answer-root/bootstrap.ps1
	if command -v xorriso >/dev/null 2>&1; then \
		xorriso -as mkisofs -quiet -volid ANSWER -J -R \
			-o $(BUILD)/win2025-autounattend.iso $(BUILD)/answer-root; \
	elif command -v genisoimage >/dev/null 2>&1; then \
		genisoimage -quiet -volid ANSWER -J -R \
			-o $(BUILD)/win2025-autounattend.iso $(BUILD)/answer-root; \
	else \
		echo "need xorriso or genisoimage"; exit 1; fi
	@echo "built $(BUILD)/win2025-autounattend.iso"
	@echo "upload it to the Proxmox ISO store as win2025-autounattend.iso"

# --------------------------------------------------------------------------
# Packer
# --------------------------------------------------------------------------

init:
	packer init .

validate:
	packer fmt -check -recursive .
	packer validate .

build: answer-iso
	@if [ -z "$$PROXMOX_TOKEN_SECRET" ]; then \
		echo "PROXMOX_TOKEN_SECRET is not set"; exit 1; fi
	PKR_VAR_admin_password="$$ADMIN_PASSWORD" \
	PKR_VAR_proxmox_token_id="$$PROXMOX_TOKEN_ID" \
	PKR_VAR_proxmox_token_secret="$$PROXMOX_TOKEN_SECRET" \
	PKR_VAR_proxmox_url="$${PROXMOX_URL:-https://pve.example.internal:8006/api2/json}" \
	PKR_VAR_proxmox_node="$${PROXMOX_NODE:-pve}" \
	PKR_VAR_storage_pool="$${STORAGE_POOL:-local-lvm}" \
	PKR_VAR_bridge="$${BRIDGE:-vmbr0}" \
	PKR_VAR_vlan_tag="$${VLAN_TAG:-}" \
	PKR_VAR_windows_iso="$${WINDOWS_ISO:-local:iso/Windows_Server_2025_Eval_x64.iso}" \
	PKR_VAR_virtio_iso="$${VIRTIO_ISO:-local:iso/virtio-win.iso}" \
	PKR_VAR_answer_iso="$${ANSWER_ISO:-local:iso/win2025-autounattend.iso}" \
	PKR_VAR_template_name="$${TEMPLATE_NAME:-tpl-win2025-dc}" \
	packer build . 2>&1 | tee $(BUILD)/packer.log

clean:
	rm -rf $(BUILD)

.PHONY: help check-password answer-iso init validate build clean
