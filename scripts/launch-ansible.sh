#!/bin/bash

# Small script to check if Ansible is installed and provisioning with configs and main playbook
# Without that sometimes cloud-init has an irritating hiccup where Ansible isn't installed at all

OPTS=$(getopt -a -o r:p: --long repository:,playbook: -n 'launch-ansible' -- "$@")
eval set -- "$OPTS"

REPO=
PLAYBOOK=

while true; do
    case "$1" in
        -r | --repository) REPO=$2; shift 2;;
        -p | --playbook) PLAYBOOK=$2; shift 2;;
        --) shift; break ;;
        *) exit 1 ;;
    esac
done

# Check if arguments are given 
if [[ -z $REPO || -z $PLAYBOOK ]]; then
    echo -e "\nUsage: $0 --repository <git_repository_url> --playbook <ansible_remote_path>\n"
    exit 1
fi

# Step one: check if Ansible is installed correctly
check=$(which ansible-playbook 2> /dev/null)
rc=$?
if [[ $rc -ne 0 ]]
then
    echo "Command ansible-playbook is not found! Installing..."
    sudo apt-get update && sudo apt-get install -y ansible git
else
    echo "Command ansible-playbook is found!"
fi

# Step two: clone repository
git clone -b kubernetes $REPO
rc=$?
if [[ $rc -ne 0 ]]
then
    echo "Something went wrong with cloning repository!"
    #sudo apt-get update && sudo apt-get install -y ansible git
else
    echo "Repository has been cloned successfully!"
fi

# Step three: launch initial playbook
ansible-playbook $PLAYBOOK
