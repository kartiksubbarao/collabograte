#! /bin/sh

# Create the Collabograte Virtual Machine image

if [ $EUID -ne 0 ]; then echo "$0 needs to run as root"; exit 1; fi
if [ ! -x "`which virt-install 2>/dev/null`" ]; then
	echo "$0: virt-install is not installed"
	exit 1
fi

# VM Name and disk path
name=collabograte diskpath=/srv/$name.img
# VM hostname
export VM_HOSTNAME=example.com
# Specify RAM size in megabytes and disk size in gigabytes
export RAM_MB=2000
export DISK_GB=3; export DISK_MB="${DISK_GB}000"
# Root password and collabograte user password
export ROOT_PW=collab123
export COLLABOGRATE_PW=collabograte

# The libvirt default IP address for virbr0 is 192.168.122.1, which will end 
# up setting VM_IP to 192.168.122.10. Feel free to change these parameters. 
export VIRBR0_IP=$(ifconfig virbr0 | perl -ane 'print /inet addr:(.*?) /')
export VIRBR0_NETMASK=$(ifconfig virbr0 | perl -ane 'print /Mask:(.*)/i')
export VM_IP=${VIRBR0_IP%.*}.10

export PLATFORM=$(uname -i)
export OS_RELEASE=6

# Generate the kickstart file from the template and the above variables
perl -pe 'foreach $var (keys %ENV) { s/\$$var/$ENV{$var}/g }' \
	kickstart.cfg.template > /tmp/kickstart.cfg

# Install the virtual machine
virt-install \
	-n $name \
	--connect qemu:///system \
	--ram $RAM_MB \
	--disk path=$diskpath,size=$DISK_GB \
	--os-variant=rhel${OS_RELEASE} \
	--accelerate \
	--location http://mirrors.kernel.org/centos/$OS_RELEASE/os/$PLATFORM/ \
	--initrd-inject=/tmp/kickstart.cfg \
	--extra-args ks=file:/kickstart.cfg
