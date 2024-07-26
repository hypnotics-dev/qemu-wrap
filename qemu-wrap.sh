#!/usr/bin/env bash

deps-check () {
    fzf --version > /dev/null || echo Missing fzf && exit 1

}

show-help () {
    printf "    Usage $basename $0 [COMMAND] [OPTION]
    new:    Create a new VM
    list:   Print out all VMs
    start:  Start a VM [OPTIONS], if none given use fzf to choose
    delete: Removes a VM, same behaviour as start
    edit:   Edits a paramatter of a VM, same behavious as start
    set:    Set a default settings for $basename $0
    mod:    Opens $EDITOR for given VM, same behavious as start\n"
    exit 0
}

HOMEU="$(echo $XDG_CONFIG_HOME || $HOME/.config)"

make-settings () {
    mkdir "$1/qemu-wrap/"
    touch "$1/qemu-wrap/settings.sh"
}

source "$HOMEU/qemu-wrap/settings.sh" || make-settings $HOMEU

# settings 
# Memory: 8G
# CPUs: 6
# use host cpu
# uefi firmaware location

new-vm () {
    # $1 is HOMEU
    # Get settings
    read -p "Enter the name of the VM: " fullname
    read -p "ISO name: " iso
    read -p "How many CPUs for the VM: " cpuc
    read -p "Amount of RAM in mb for VM: " ramn
    read -p "Size of disk in mb: " disks
    read -p "Should we use the host cpu, type [Y,N]: " cpuh
    read -p "Should the system use UEFI [Y,N]: " uefic

    HOMEU="$1/qemu-wrap"
    mkdir -p $HOMEU/vm/$fullname
    cp /usr/share/OVMF/OVMF_VARS.fd $HOMEU/vm/$fullname/ 
    qemu-img create -f qcow2 $HOMEU/vm/$fullname/img.qcow $disks


    # Print out settings to a settings file
    printf "
CORE_COUNT=\"-smp $cpuc\"
NUM_RAM=\"-m $ramn\"
MACHINE=\"-machine type=q35,accel=kvm\"
DISPLAY=\"-display gtk\"
PROC="$( if [["$cpuh" == [yY]]];then echo '-cpu host';fi)"
UEFI="$( if [["${uefic,,}" == 'uefi']];then echo "-drive if=pflash,format=raw,readonly=on,file=/usr/share/OVMF/OVMF_CODE.fd \
-drive if=pflash,format=raw,file=$HOMEU/vm/$fullname/OVMF_VARS.fd")"\n" > "$HOMEU/vm/$fullname/settings.sh"
# return vm name, and the iso name for start-vm
echo "$fullname:$HOMEU/iso/$iso"
}
start-vm () {
    # Input $1 is the name of the vm
    # Input $2 is for HOMEU
    # Input $3 is for the name of the iso
    NAME="$1"
    HOMEU="$1/qemu-wrap/vm"
    ISO="$( if [-n "$ISO"];then echo "-cdrom $3";fi)"
    DEVICE="-drive file=$HOMEU/$NAME/img.qcow,format=qcow2"

    source "$HOMEU/$NAME/settings.sh"
    qemu-system-x86_64 $NUM_RAM  $MACHINE $CORE_COUNT $DISPLAY $PROC $UEFI $ISO
}
list-vm () {}
delete-vm () {}
edit-vm () {}
mod-vm () {}

