# Qemu-Wrap
Qemu-wrap is a wrapper script for creating and runing qemu Virtual Machines

## Installation

Clone the repo and make it available to the PATH
```
bash
mkdir -p $HOME/.local/{bin,share} > /dev/null 
cd $HOME/.local/share/
git clone https://github.com/hypnotics-dev/qemu-wrap.git
cd qemu-wrap
ln -s $(pwd)/qemu-wrap.sh $HOME/.local/bin/vm # replace vm with whatever you want to call the bin
```
If you cannot invoke the script try adding it to your PATH, to accomplish this open your shell config file,
if you're not sure what your shell is try running the command `ps | grep sh`
| Shell Name | Config File Name |
| ---------- | ---------------- |
| bash       | ~/.bashrc        |
| zsh        | ~/.zshrc         |

Add the command `PATH="$PATH:$HOME/.local/bin/vm"` to your relevant config file, replace vm with whatever you called the script at the
ln step.

If it still doesn't work, please open a github issue.

## Usage

Use vm help to list all commands.
Vms are stored `$XDG_CONFIG_HOME/qemu-wrap/vm`

