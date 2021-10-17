variable "output_directory" {
    type = string
}

locals {
    vm_name = "debian"
    version = "11.1.0"
    http_directory = "${path.root}/http"
    iso_url = "https://cdimage.debian.org/debian-cd/${local.version}/amd64/iso-cd/debian-${local.version}-amd64-netinst.iso"
    iso_checksum = "sha256:8488abc1361590ee7a3c9b00ec059b29dfb1da40f8ba4adf293c7a30fa943eb2"
    shutdown_command = "echo 'vagrant' | sudo -S shutdown -P now"
    boot_command = [
        "<esc><wait>",
        "install <wait>",
        "preseed/url=http://{{ .HTTPIP }}:{{ .HTTPPort }}/preseed.cfg <wait>",
        "debian-installer=en_US.UTF-8 <wait>",
        "auto <wait>",
        "locale=en_US.UTF-8 <wait>",
        "kbd-chooser/method=us <wait>",
        "keyboard-configuration/xkb-keymap=us <wait>",
        "netcfg/get_hostname={{ .Name }} <wait>",
        "netcfg/get_domain=vagrantup.com <wait>",
        "fb=false <wait>",
        "debconf/frontend=noninteractive <wait>",
        "console-setup/ask_detect=false <wait>",
        "console-keymaps-at/keymap=us <wait>",
        "grub-installer/bootdev=/dev/sda <wait>",
        "<enter><wait>"    
    ]
}

source "virtualbox-iso" "debian" {
    boot_command = local.boot_command
    boot_wait = "6s"
    cpus = 2
    memory = 1024
    disk_size = 10240
    guest_additions_path = "VBoxGuestAdditions_{{.Version}}.iso"
    guest_additions_url = ""
    guest_os_type = "Debian_64"
    hard_drive_interface = "sata"
    headless = false
    http_content = {
         "/preseed.cfg" = templatefile("${path.root}/http/preseed.cfg.pkrtpl", {})
    }
    iso_checksum = local.iso_checksum
    iso_url = local.iso_url
    output_directory = "${var.output_directory}/packer-build/output/artifacts/${local.vm_name}/${local.version}/virtualbox/"
    shutdown_command = local.shutdown_command
    ssh_password = "vagrant"
    ssh_port = 22
    ssh_timeout = "10000s"
    ssh_username = "vagrant"
    virtualbox_version_file = ".vbox_version"
    vm_name = "${local.vm_name}"
    vboxmanage = [
        ["modifyvm", "{{.Name}}", "--vram", "128"],
        ["modifyvm", "{{.Name}}", "--graphicscontroller", "vmsvga"],
        ["modifyvm", "{{.Name}}", "--vrde", "off"],
        ["modifyvm", "{{.Name}}", "--rtcuseutc", "on"]
    ]
}

source "parallels-iso" "debian" {
    boot_command = local.boot_command
    boot_wait = "6s"
    cpus = 2
    memory = 1024
    disk_size = 10240
    guest_os_type = "debian"
    http_content = {
         "/preseed.cfg" = templatefile("${path.root}/http/preseed.cfg.pkrtpl", {})
    }
    iso_checksum = local.iso_checksum
    iso_url = local.iso_url
    output_directory = "${var.output_directory}/packer-build/output/artifacts/${local.vm_name}/${local.version}/parallels/"
    shutdown_command = local.shutdown_command
    parallels_tools_flavor = "lin"
    ssh_password = "vagrant"
    ssh_port = 22
    ssh_timeout = "10000s"
    ssh_username = "vagrant"
    prlctl_version_file = ".prlctl_version"
    vm_name = "${local.vm_name}"
}

source "vmware-iso" "debian" {
    boot_command = local.boot_command
    boot_wait = "6s"
    cpus = 2
    memory = 1024
    disk_size = 10240
    guest_os_type = "debian8-64"
    headless = false
    http_content = {
         "/preseed.cfg" = templatefile("${path.root}/http/preseed.cfg.pkrtpl", {})
    }
    iso_checksum = local.iso_checksum
    iso_url = local.iso_url
    output_directory = "${var.output_directory}/packer-build/output/artifacts/${local.vm_name}/${local.version}/vmware/"
    shutdown_command = local.shutdown_command
    ssh_password = "vagrant"
    ssh_port = 22
    ssh_timeout = "10000s"
    ssh_username = "vagrant"
    tools_upload_flavor = "linux"
    vm_name = "${local.vm_name}"
    vmx_data = {
        "cpuid.coresPerSocket": "1",
        "ethernet0.pciSlotNumber": "32"
      }
    vmx_remove_ethernet_interfaces = true
}

source "hyperv-iso" "debian" {
    boot_command = local.boot_command
    boot_wait = "6s"
    cpus = 2
    memory = 1024
    disk_size = 10240
    generation = 1
    headless = false
    http_content = {
         "/preseed.cfg" = templatefile("${path.root}/http/preseed.cfg.pkrtpl", {})
    }
    iso_checksum = local.iso_checksum
    iso_url = local.iso_url
    output_directory = "${var.output_directory}/packer-build/output/artifacts/${local.vm_name}/${local.version}/hyperv/"
    shutdown_command = local.shutdown_command
    ssh_password = "vagrant"
    ssh_port = 22
    ssh_timeout = "10000s"
    ssh_username = "vagrant"
    switch_name = "Default Switch"
    enable_virtualization_extensions = false
    enable_mac_spoofing = false
    vm_name = "${local.vm_name}"
}

build {
    name = "builder"

    sources = [
        "source.virtualbox-iso.debian",
        "source.parallels-iso.debian",
        "source.vmware-iso.debian",
        "source.hyperv-iso.debian"

    ]

    provisioner "shell" {
        environment_vars  = ["HOME_DIR=/home/vagrant"]
        execute_command   = "echo 'vagrant' | {{ .Vars }} sudo -S -E sh -eux '{{ .Path }}'"
        expect_disconnect = true
        scripts = [
            "${path.root}/provisioners/update.sh",
            "${path.root}/../provisioners/sshd.sh",
            "${path.root}/provisioners/networking.sh",
            "${path.root}/provisioners/sudoers.sh",
            "${path.root}/../provisioners/vagrant-conf.sh",
            "${path.root}/provisioners/systemd.sh"
        ] 
    }

    provisioner "shell" {
        only = ["virtualbox-iso.debian"]
        environment_vars  = ["HOME_DIR=/home/vagrant"]
        execute_command   = "echo 'vagrant' | {{ .Vars }} sudo -S -E sh -eux '{{ .Path }}'"
        expect_disconnect = true
        scripts = [
            "${path.root}/../provisioners/virtualbox.sh"
        ] 
    }

    provisioner "shell" {
        only = ["parallels-iso.debian"]
        environment_vars  = ["HOME_DIR=/home/vagrant"]
        execute_command   = "echo 'vagrant' | {{ .Vars }} sudo -S -E sh -eux '{{ .Path }}'"
        expect_disconnect = true
        scripts = [
            "${path.root}/../provisioners/parallels.sh"
        ] 
    }

    provisioner "shell" {
        only = ["vmware-iso.debian"]
        environment_vars  = ["HOME_DIR=/home/vagrant"]
        execute_command   = "echo 'vagrant' | {{ .Vars }} sudo -S -E sh -eux '{{ .Path }}'"
        expect_disconnect = true
        scripts = [
            "${path.root}/../provisioners/parallels.sh"
        ] 
    }

    provisioner "shell" {
        environment_vars  = ["HOME_DIR=/home/vagrant"]
        execute_command   = "echo 'vagrant' | {{ .Vars }} sudo -S -E sh -eux '{{ .Path }}'"
        expect_disconnect = true
        scripts = [
            "${path.root}/provisioners/cleanup.sh",
            "${path.root}/../provisioners/minimize.sh"
        ] 
    }

    post-processors {
        post-processor "vagrant" {
          keep_input_artifact = false
          output = "${var.output_directory}/packer-build/output/boxes/${local.vm_name}/${local.version}/{{.Provider}}/{{.BuildName}}.box"
          vagrantfile_template = "${path.root}/../../Vagrantfiles/vagrantfile.rb"
        }

        post-processor "vagrant-cloud" {
            box_tag = "Yohnah/Debian"
            version = local.version
            version_description = "Further information: https://www.debian.org/releases/stable/"
        }
    }

}