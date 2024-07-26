#!/usr/bin/env bash

show-help () {
    printf "    Usage $basename $0 [COMMAND] [OPTION]
    new:    Create a new VM
    list:   Print out all VMs
    start:  Start a VM [OPTIONS], if none given use fzf to choose
    delete: Removes a VM, same behaviour as start
    mod:    Opens $EDITOR for given VM, same behavious as start\n"
    exit 0
}

HOMEU="$( if [ -z ${XDG_CONFIG_DIR+x}];then echo "$HOME/.config/qemu-wrap";else echo "$XDG_CONFIG_HOME/qemu-wrap";fi)"

make-settings () {
    mkdir "$HOMEU" 2> /dev/null
    touch "$HOMEU/settings.sh"
}

source "$HOMEU/settings.sh" || make-settings 

new-vm () {
    # Get settings
    read -p "Enter the name of the VM: " fullname
    read -p "ISO name: " iso
    read -p "How many CPUs for the VM: " cpuc
    read -p "Amount of RAM in mb for VM: " ramn
    read -p "Size of disk in mb: " disks
    read -p "Should we use the host cpu, type [Y,N]: " cpuh
    read -p "Should the system use UEFI [Y,N]: " uefic

    mkdir -p $HOMEU/vm/$fullname
    cp /usr/share/OVMF/OVMF_VARS.fd $HOMEU/vm/$fullname/ 
    qemu-img create -f qcow2 $HOMEU/vm/$fullname/img.qcow $disks > /dev/null


    # Print out settings to a settings file
    echo "
CORE_COUNT=\"-smp $cpuc\"
NUM_RAM=\"-m $ramn\"
MACHINE=\"-machine type=q35,accel=kvm\"
DISPLAY=\"-display gtk\"
PROC="$( if [[ "${cpuh,,}" == "y" ]] ;then echo \"-cpu host \";fi)"
UEFI="$( if [[ "${uefic,,}" == "y" ]] ;then echo \"-drive if=pflash,format=raw,readonly=on,file=/usr/share/OVMF/OVMF_CODE.fd \
-drive if=pflash,format=raw,file=$HOMEU/vm/$fullname/OVMF_VARS.fd\";fi)"" > "$HOMEU/vm/$fullname/settings.sh"
# return vm name, and the iso name for start-vm
echo "$fullname:$iso"
}
start-vm () {
    # Input $1 is the name of the vm
    # Input $2 is for the name of the iso
    local NAME="$1"
    local ISO="$( if [ ${#2} -ne 0];then echo "-cdrom $2";fi )"
    local DEVICE="-drive file=$HOMEU/vm/$NAME/img.qcow,format=qcow2"
    echo $NAME

    source "$HOMEU/vm/$NAME/settings.sh"
    qemu-system-x86_64 $NUM_RAM  $MACHINE $CORE_COUNT $DISPLAY $PROC $UEFI $ISO $DRIVE
}
list-vm () {
    cd "$HOMEU/vm/"
    for i in $(ls) ;do
        echo "$i"
    done
}
delete-vm () {
    # $1 is dir to delete
    if [ ${#1} -eq 0 ];then exit 0;fi
    read -p "Do you want to delete: $1, [Y] or [N] " confirm
    if [[ $confirm = [Yy] ]];then rm -rf $HOMEU/vm/$1;fi
}
mod-vm () {
    # $1 is the name of the vm to edit
    $EDITOR $HOMEU/vm/$1 || vim $HOMEU/vm/$1
}

COMMAND="$1"

case $COMMAND in
    new)
        returned=$( new-vm )
        name=$( echo $returned |  awk -F ':' '{print $1}')
        iso=$( echo $returned | awk -F ':' '{print $2}')
        start-vm $name $iso
        exit 0
        ;;
    list)
        list-vm
        exit 0
        ;;
    start)
        if [ ${#2} -ne 0 ];then
            start-vm $2
        else
            cd $HOMEU/vm
            start-vm 
        fi
        ;;
    delete)
        if [ ${#2} -ne 0 ];then
            delete-vm $2
        else
            cd $HOMEU/vm
            delete-vm "$( find . -type d -print | fzf )"
        fi
        ;;
    mod)
        mod-vm
        exit 0
        ;;
    help)
        show-help
        exit 0
        ;;
    *)
        show-help
        exit 0
        ;;
esac


