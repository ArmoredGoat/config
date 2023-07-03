#!/bin/bash

base_url="https://github.com/"
repo="ArmoredGoat/config"
branch="main"
url="$base_url/$repo/$branch"

main () {
    get_user
    update_system

    clone_repository
    
    install_python
    install_qtile

    update_system
}

clone_repository () {
    # Make sure that git is installed.
    install_packages git

    # Create directory for git repositories
    mkdir $home/git

    repo_path="$home/git/config"
    # Clone git repository to /home/git
    git clone $url repo_path
    # Move into repo directory
    cd repo_path
    # Get current branch
    current_branch=$(git status | grep 'On branch' | awk '{print $3}')

    # Compare current branch with working branch. If it does not match,
    # switch to working branch.
    if [[ ! "$current_branch" == "$branch" ]]; then
        git checkout $branch
    fi
}

create_directory () {
	# Check if directories exists. If not, create them.
	if [[ ! -d $@ ]]; then
	mkdir -pv $@
    fi
	# This script is run with privileged rights. Therefore, anything created
	# with it will be owned by root. To make sure that the permissions are set
	# correclty, the function checks if the directory lies in the home folder.
	# If so, it grants ownership to the user.
	if [[ $@ = $home/* ]]; then
		# General permissions settings. If necessary, e.g. ssh keys, the
        # permissions will be set accordingly
        chmod 755 $@
		chown -R "$username":"$username" $@
	fi
}

get_user () {
    # Get username by checking who called the sudo command
    username="$(env | grep SUDO_USER | awk -F "=" '{print $2}')"
    # As $HOME will return '/root', we will have to use $username from above
    home="/home/$username"
}

set_ownership () {
    # Set ownership recursivly for given directory.
    chown -R "$1":"$1" $2
}

install_packages () {
    apt install -y $@
}

install_python () {
    python_packages="python3 python3-pip python3-venv"
    install_packages $@

    # Install pipx, an alternative pip frontend which address the problem 
    # with '--break-system-packages'
    runuser -l "$username" -c "pip3 install --break-system-packages pipx"
}

install_pip_package () {
    runuser -l "$username" -c "pipx install $1"
}

install_qtile () {
    # Install dependencies for qtile
    qtile_dependencies="xserver-xorg xinit libpangocairo-1.0-0 python3-xcffib python3-cairocffi"
    install_packages $@

    #runuser -l "$username" -c "pipx install qtile"
    install_pip_package "git+https://github.com/qtile/qtile@master"
    runuser -l "$username" -c "qtile --version"

    mkdir 
}

update_system () {
    apt update && apt upgrade -y && apt autoremove -y && apt autoclean -y
}

main