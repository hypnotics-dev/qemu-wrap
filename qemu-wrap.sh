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
    mod:    Opens $EDITOR for given VM, same behavious as start\n"
    exit 0
}
    #set:    Set a default settings for $basename $0
    #edit:   Edits a paramatter of a VM, same behavious as start

HOMEU="$( if [ -z ${XDG_CONFIG_DIR+x}];then echo "$HOME/.config";else echo "$XDG_CONFIG_HOME";fi)"

make-settings () {
    mkdir "$HOMEU"
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
    qemu-img create -f qcow2 $HOMEU/vm/$fullname/img.qcow $disks


    # Print out settings to a settings file
    printf "
CORE_COUNT=\"-smp $cpuc\"
NUM_RAM=\"-m $ramn\"
MACHINE=\"-machine type=q35,accel=kvm\"
DISPLAY=\"-display gtk\"
PROC="$( if [["$cpuh" == [yY]]];then echo '-cpu host';fi)"
UEFI="$( if [["${uefic,,}" == 'uefi']];then echo "-drive if=pflash,format=raw,readonly=on,file=/usr/share/OVMF/OVMF_CODE.fd \
-drive if=pflash,format=raw,file=$HOMEU/vm/$fullname/OVMF_VARS.fd";fi)"\n" > "$HOMEU/vm/$fullname/settings.sh"
# return vm name, and the iso name for start-vm
echo "$fullname:$HOMEU/iso/$iso"
}
start-vm () {
    # Input $1 is the name of the vm
    # Input $2 is for the name of the iso
    NAME="$1"
    ISO="$( if [-n "$ISO"];then echo "-cdrom $2";fi)"
    DEVICE="-drive file=$HOMEU/vm/$NAME/img.qcow,format=qcow2"

    source "$HOMEU/vm/$NAME/settings.sh"
    qemu-system-x86_64 $NUM_RAM  $MACHINE $CORE_COUNT $DISPLAY $PROC $UEFI $ISO $DRIVE
}
list-vm () {
    # $1 is HOMEU
    for i in $1/qemu-wrap/vm/*;do
        echo "$i"
    done
}
delete-vm () {
    # $1 is dir to delete
    read -p "Do you want to delete: $1, [Y] or [N]" confirm
    if [[ $confirm = [Yy] ]];then rm -rf $HOMEU/vm/$1;fi
}
mod-vm () {
    # $1 is the name of the vm to edit
    $EDITOR $HOMEU/vm/$1 || vim $HOMEU/vm/$1
}

COMMAND="$1"

case COMMAND in
    new)
        local returned=new-vm
        local name=$( echo $returned |  awk -F ':' '{$1}')
        local iso=$( echo $returned | awk -F ':' '{$2}')
        start-vm $name $iso
        exit 0
        ;;
    list)
        list-vm
        exit 0
        ;;
    start)
        if [-n $2];then
            start-vm $2
        else
            cd $HOMEU/vm
            start-vm "$( fzf )"
        fi
        ;;
    delete)
        if [-n $2];then
            delete-vm $2
        else
            cd $HOMEU/vm
            delete-vm "$( fzf )"
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


