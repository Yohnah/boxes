variable "disk_size" {
    type = number
    default = 10240
}

variable "vm_name" {
    type = string
    default = "alpine"
}

variable "version" {
    type = string
    default = "3.14.2"
}

variable "output_directory" {
    type = string
    default = "."
}

locals {
    description = "Alpine linux vagrant box by Yohnah"
    boot_command = [
        "root<enter><wait>",
        "ifconfig eth0 up && udhcpc -i eth0<enter><wait5>",
        "wget http://{{ .HTTPIP }}:{{ .HTTPPort }}/answers<enter><wait>",
        "setup-apkrepos -1<enter><wait10s>",
        "ERASE_DISKS='/dev/sda' setup-alpine -f $PWD/answers<enter><wait5>",
        "${local.ssh_password}<enter><wait>",
        "${local.ssh_password}<enter><wait2m>",
        "mount /dev/sda3 /mnt<enter>",
        #"echo 'PermitRootLogin yes' >> /mnt/etc/ssh/sshd_config<enter>",
        "chroot /mnt adduser vagrant<enter><wait5s>",
        "${local.ssh_password}<enter><wait>",
        "${local.ssh_password}<enter><wait>",
        "echo http://dl-cdn.alpinelinux.org/alpine/v3.14/community >> /mnt/etc/apk/repositories<enter><wait>",
        "chroot /mnt apk update<enter><wait10s>",
        "chroot /mnt apk add sudo<enter><wait30s>",
        "chroot /mnt addgroup sudo<enter><wait>",
        "echo '%sudo ALL=(ALL) NOPASSWD:ALL' > /mnt/etc/sudoers.d/sudo<enter><wait>",
        "chroot /mnt adduser vagrant sudo<enter><wait>",
        "mkdir -p /mnt/home/vagrant/.ssh<enter><wait>",
        "wget -O - https://raw.githubusercontent.com/hashicorp/vagrant/master/keys/vagrant.pub > /mnt/home/vagrant/.ssh/authorized_keys<enter><wait10s>",
        "chmod 700 /mnt/home/vagrant/.ssh<enter><wait>",
        "chmod 644 /mnt/home/vagrant/.ssh/authorized_keys<enter><wait>",
        "chroot /mnt chown -R vagrant.vagrant /home/vagrant<enter><wait5s>",
        "chroot /mnt apk add linux-firmware-none<enter><wait10s>",
        "dd if=/dev/zero of=/mnt/borrar.img bs=1M; rm -f /mnt/borrar.img<enter><wait1m>",
        "umount /mnt ; reboot<enter>"
    ]
    iso_checksum = "d9ef1da16c40c47629bc9c828493dbb3c2a98899f29b2a1235d8014788ef9cb9"
    iso_checksum_type = "sha256"
    iso_urls = ["https://dl-cdn.alpinelinux.org/alpine/v3.14/releases/x86_64/alpine-standard-3.14.2-x86_64.iso"]
    vm_name = "alpine"
    ssh_password = "vagrant"
    ssh_username = "vagrant"
}

source "virtualbox-iso" "alpine" {
    vm_name = local.vm_name
    boot_command = local.boot_command
    boot_wait = "20s"
    communicator = "ssh"
    disk_size = var.disk_size
    guest_additions_mode = "disable"
    guest_os_type = "Linux26_64"
    headless = false
    http_directory = "${path.root}/http"
    iso_checksum = local.iso_checksum
    iso_urls = local.iso_urls
    shutdown_command = "sudo /sbin/poweroff"
    ssh_password = local.ssh_password
    ssh_timeout = "10m"
    ssh_username = local.ssh_username
    virtualbox_version_file = ".vbox_version"
    output_directory = "${var.output_directory}/output/${local.vm_name}/virtualbox-iso/output"
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
        "source.virtualbox-iso.alpine"
    ]

    provisioner "shell" {
        inline = [
            "sudo apk add virtualbox-guest-additions"
        ]
    }

    post-processors {
        post-processor "vagrant" {
          keep_input_artifact = false
          output = "${var.output_directory}/output/boxes/{{.Provider}}/{{.BuildName}}.box"
          vagrantfile_template = "${path.root}/../../Vagrantfiles/vagrantfile.rb"
        }

        post-processor "vagrant-cloud" {
            box_tag = "Yohnah/Alpine"
            version = var.version
            version_description = "Further information: https://alpinelinux.org/posts/Alpine-${var.version}-released.html"
        }
    }

}