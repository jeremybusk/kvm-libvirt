#!/bin/bash
set -e

vm_name="jtest"
ova_src_url="https://cloud-images.ubuntu.com/releases/bionic/release/ubuntu-18.04-server-cloudimg-amd64.ova"
ova_src_file="ubuntu-18.04-server-cloudimg-amd64.ova"
vm_storage="$vm_name/"

# Preclean
virsh destroy ubuntu-bionic-18.04-cloudimg-20190131 || true
virsh undefine ubuntu-bionic-18.04-cloudimg-20190131 || true
rm -rf $vm_storage || true
mkdir -p $vm_name
 
if [[ ! -f "${ova_src_file}" ]]; then
    curl -q -o $ova_src_file $ova_src_url
fi

virt-v2v -i ova $ova_src_file -o local -os $vm_storage -of qcow2

xmlstarlet ed --inplace -u /domain/devices/interface/source/@bridge -v 'virbr0' $vm_storage/ubuntu-bionic-18.04-cloudimg-20190131.xml
# xmlstarlet ed --inplace -u "/domain/devices/disk[@device='cdrom']" -v "${xml_disk_cdrom}"  $vm_storage/ubuntu-bionic-18.04-cloudimg-20190131.xml # auto escapes values

virsh define $vm_storage/ubuntu-bionic-18.04-cloudimg-20190131.xml

virsh update-device ubuntu-bionic-18.04-cloudimg-20190131 cdrom_init.xml


vm_userpass="ubuntu1234"
sed "s/{{vm_userpass}}/${vm_userpass}/g" \
    user-data.template > user-data
sed "s/{{vm_name}}/${vm_name}/g" \
    meta-data.template > meta-data
genisoimage -input-charset utf-8 -output init.iso -volid cidata -joliet -rock user-data meta-data


virsh start ubuntu-bionic-18.04-cloudimg-20190131

virsh console ubuntu-bionic-18.04-cloudimg-20190131

# Shutdown and remove cloud init cdrom
virsh shutdown $vm_name
virsh update-device ubuntu-bionic-18.04-cloudimg-20190131 cdrom_empty.xml


#### NOTES
# virsh attach-disk ubuntu-bionic-18.04-cloudimg-20190131 /tmp/init.iso hda --type cdrom --mode readonly

# virt-v2v -i ova ubuntu-18.04-server-cloudimg-amd64.ova -o local -os os/ -of raw
