variable "output_directory" {
    type = string
}

locals {
    vm_name = "ubuntu"
    version = "20.04.3"
    http_directory = "${path.root}/http"
    iso_url = "http://releases.ubuntu.com/20.04/ubuntu-${local.version}-live-server-amd64.iso"
    iso_checksum = "f8e3086f3cea0fb3fefb29937ab5ed9d19e767079633960ccb50e76153effc98"
    shutdown_command = "echo 'vagrant' | sudo -S shutdown -P now"
    boot_command = [
        " <wait1s>",
        "<esc><wait>",
        "<f6><wait>",
        "<esc><wait>",
        "<bs><bs><bs><bs><wait>",
        " autoinstall<wait5>",
        " ds=nocloud-net<wait5>",
        ";s=http://<wait5>{{.HTTPIP}}<wait5>:{{.HTTPPort}}/<wait5>",
        " ---<wait5>",
        "<enter><wait5>"       
    ]
}

source "virtualbox-iso" "ubuntu" {
    boot_command = local.boot_command
    boot_wait = "6s"
    cpus = 2
    memory = 1024
    disk_size = 10240
    guest_additions_path = "VBoxGuestAdditions_{{.Version}}.iso"
    guest_additions_url = ""
    guest_os_type = "Ubuntu_64"
    hard_drive_interface = "sata"
    headless = false
    http_content = {
         "/meta-data" = templatefile("${path.root}/http/meta-data.pkrtpl", {})
         "/user-data" = templatefile("${path.root}/http/user-data.pkrtpl", {packages=[]})
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
    vm_name = "${local.vm_name}-cli"
    vboxmanage = [
        ["modifyvm", "{{.Name}}", "--vram", "128"],
        ["modifyvm", "{{.Name}}", "--graphicscontroller", "vmsvga"],
        ["modifyvm", "{{.Name}}", "--vrde", "off"],
        ["modifyvm", "{{.Name}}", "--rtcuseutc", "on"]
    ]
}

build {
    name = "builder"

    sources = [
        "source.virtualbox-iso.ubuntu"
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
    }

}