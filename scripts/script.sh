
GATEWAY=$1
# Apply updates and cleanup Apt cache
echo "Starting post install steps..."
apt-get update ; apt-get -y dist-upgrade
apt-get -y autoremove
apt-get -y clean

timedatectl set-timezone "America/New_York"
# Disable swap - generally recommended for K8s, but otherwise enable it for other workloads
echo "Disabling Swap..."
swapoff -a
sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab



# Reset the machine-id value. This has known to cause issues with DHCP
#
echo "Reset Machine-ID..."
truncate -s 0 /etc/machine-id
rm /var/lib/dbus/machine-id
ln -s /etc/machine-id /var/lib/dbus/machine-id

rm /etc/netplan/00-installer-config.yaml

env
echo $GATEWAY
echo "Setting networking..."

# ---- Use your dns settings here ----
cat <<EOF > /etc/netplan/80-my.yaml
network:
  ethernets:
    ens192:
      link-local: []
      dhcp4: true
      nameservers:
        search: [companydomain.com
        addresses: [X.X.X.X]
      routes:
        - to: default
          via: $GATEWAY
  version: 2
EOF

# cat <<EOF > /etc/network/interfaces
# auto ens192
# iface ens192 inet dhcp
# EOF

rm -rf /etc/dhcp/dhcpd6.conf
rm -rf /var/lib/dhcp/*
#systemctl restart isc-dhcp-server

echo "Disabling ipv6..."
echo "net.ipv6.conf.all.disable_ipv6=1" >> /etc/sysctl.conf
echo "net.ipv6.conf.default.disable_ipv6=1" >> /etc/sysctl.conf
echo "net.ipv6.conf.lo.disable_ipv6=1" >> /etc/sysctl.conf


# adding docker
echo "Adding Docker..."
mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
systemctl enable docker
#apt-get install -y resolvconf

ln -sf /run/resolvconf/resolv.conf /etc/resolv.conf
rm -rf /run/resolvconf/interface

#systemctl start docker
systemctl stop cloud-init
#systemctl disable cloud-init
echo "Removing default cloud-init..."
rm -rf /etc/cloud/cloud.cfg.d/subiquity-disable-cloudinit-networking.cfg
rm -rf /etc/cloud/cloud.cfg.d/99-installer.cfg
rm -rf /etc/netplan/00-installer-config.yaml
rm -rf /etc/cloud/cloud.cfg
#"echo 'disable_vmware_customization: false' >> /etc/cloud/cloud.cfg"
#"echo 'datasource_list: [ VMware, OVF, None ]' > /etc/cloud/cloud.cfg.d/90_dpkg.cfg"
cat <<EOF > /etc/cloud/cloud.cfg
preserve_hostname: false
network: {config: disabled}
disable_vmware_customization: false

cloud_init_modules:
 - migrator
 - seed_random
 - bootcmd
 - write-files
 - growpart
 - resizefs
 - disk_setup
 - mounts
 - set_hostname
 - update_hostname
 - update_etc_hosts
 - ca-certs
 - rsyslog
 - users-groups
 - ssh

cloud_config_modules:
 - snap
 - ssh-import-id
 - keyboard
 - locale
 - set-passwords
 - grub-dpkg
 - apt-pipelining
 - apt-configure
 - ubuntu-advantage
 - ntp
 - timezone
 - disable-ec2-metadata
 - runcmd
 - byobu

cloud_final_modules:
 - package-update-upgrade-install
 - fan
 - landscape
 - lxd
 - ubuntu-drivers
 - write-files-deferred
 - puppet
 - chef
 - mcollective
 - salt-minion
 - reset_rmc
 - refresh_rmc_and_interface
 - rightscale_userdata
 - scripts-vendor
 - scripts-per-once
 - scripts-per-boot
 - scripts-per-instance
 - scripts-user
 - ssh-authkey-fingerprints
 - keys-to-console
 - install-hotplug
 - phone-home
 - final-message
 - power-state-change

EOF

echo "Setting ssh settings..."
cat << EOF > /etc/ssh/sshd_config
Include /etc/ssh/sshd_config.d/*.conf
Port 22
LogLevel Verbose
KbdInteractiveAuthentication no
UsePAM yes
X11Forwarding yes
PrintMotd no
AcceptEnv LANG LC_*
Subsystem sftp  /usr/lib/openssh/sftp-server
PasswordAuthentication yes
HostKeyAlgorithms +ssh-rsa
PubkeyAcceptedKeyTypes +ssh-rsa
AddressFamily inet
AllowTcpForwarding yes
EOF

cat << EOF > /etc/ssh/ssh_conig
Include /etc/ssh/ssh_config.d/*.conf
Port 22
Host *
SendEnv LANG LC_*
HashKnownHosts yes
GSSAPIAuthentication yes
ForwardX11Trusted yes
EOF

# ---- Use your dns settings here ----
echo "Setting DNS..."
cat << EOF > /etc/resolvconf/resolv.conf.d/head
domain company.com
nameserver X.X.X.X
nameserver X.X.X.X
EOF

# Reset any existing cloud-init state
#
echo "Reset Cloud-Init"
#touch /etc/cloud/cloud-init.disabled
rm /etc/cloud/cloud.cfg.d/*.cfg
#echo "disable_vmware_customization: true" >> /etc/cloud/cloud.cfg
cloud-init clean -s -l

#usermod -a -G docker packerbuilt
echo "Setting up users..."
useradd docker -m -G root,staff -s /bin/bash -g docker
useradd rancher -m -G docker,root,staff -s /bin/bash
usermod -G docker docker
mkdir /home/rancher/.ssh /home/docker/.ssh /etc/docker
chmod 700 /home/rancher/.ssh
chmod 700 /home/docker/.ssh
touch /home/rancher/.ssh/authorized_keys /home/docker/.ssh/authorized_keys
chmod 644 /home/rancher/.ssh/authorized_keys
chmod 644 /home/docker/.ssh/authorized_keys
chown -R docker:docker /etc/docker

chown -R rancher:docker /home/rancher
chown -R docker:docker /home/docker


echo "DONE."