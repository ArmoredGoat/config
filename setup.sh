#!/bin/bash

base_url="https://github.com/"
repo="ArmoredGoat/config"
branch="main"
url="$base_url/$repo/$branch"

main () {
    check_privilege
    get_user
    update_system

    clone_repository
    
    install_python
    install_wm

    update_system
}

# G E N E R A L   F U N C T I O N S

backup_directory () {
    # Check if directory already exists. If yes, create a directory to
    # store exisiting config files as backup. Then move old config files
    # into this directory.
    if [ -d "$1" ]; then
        if [ -d "$home/.config/.backup" ]; then
            create_directory "$home/.config/.backup"
        fi
        mv $1 $home/.config/.backup/
    fi
}

check_privilege () {
    if [ "$EUID" -ne 0 ]; then 
        echo "Please run script as root with sudo."
    exit
fi
}

clone_repository () {
    # Make sure that git is installed.
    install_package git

    # Create directory for git repositories
    mkdir $home/git

    repo_path="$home/git/config"
    # Clone git repository to /home/git
    git clone "$base_url/$repo.git" $repo_path
    # Move into repo directory
    cd $repo_path
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

install_package () {
    apt install -y $@
}

install_pip_package () {
    # Check if pipx is installed and if not, install it
    if  [ ! -n "$(pip list | grep pipx)" ]; then
        install_pipx
    fi
    runuser -l "$username" -c "pipx install $1"
}

update_system () {
    apt update && apt upgrade -y && apt autoremove -y && apt autoclean -y
}

# I N S T A L L A T I O N   F U N C T I O N S

install_firefox () {
    # Download latest version of Firefox
    wget -O /tmp/firefoxsetup.tar.bz2 \
        "https://download.mozilla.org/?product=firefox-latest&os=linux64&lang=en-US"
    
    # Extract archive and move content into /opt for global installation
    tar -xf /tmp/firefoxsetup.tar.bz2 --directory=/opt

    # Copy desktop entry to be able to launch firefox from rofi or any other
    # application launcher
    cp $repo_path/usr/share/applications/firefox.desktop \
        /usr/share/applications/firefox.desktop

    # Create symlink to be able to launch firefox from the CLI if needed
    ln -s /opt/firefox/firefox /usr/local/bin/firefox

    # Use this version as default browser (instead of firefox-esr
    update-alternatives --install /usr/bin/x-www-browser x-www-browser \
        /opt/firefox/firefox 200
    update-alternatives --set x-www-browser /opt/firefox/firefox

    # Remove firefox-esr as it is no longer needed
    # Your configuration and bookmarks are kept 
    # in .mozilla/firefox/*.default-esr
    apt remove firefox-esr

    # Remove archive as it is no longer needed
    rm /tmp/firefoxsetup.tar.bz2
}

install_kitty () {
    install_package kitty

    backup_directory $home/.config/kitty
    create_directory $home/.config/kitty

    cp -r $repo_path/.config/kitty/* \
        $home/.config/kitty
}

install_pipx () {
    # Install pipx, an alternative pip frontend which address the problem 
    # with '--break-system-packages'
    runuser -l "$username" -c "pip3 install --break-system-packages pipx"
    runuser -l "$username" -c "pipx ensurepath"
}

install_python () {
    python_packages="python3 python3-pip python3-venv"
    install_package $python_packages

    install_pipx
}

install_pywal () {
    pywal_dependencies="python3 imagemagick procps nitrogen"
    install_package $pywal_dependencies

    install_pip_package pywal

    create_directory $home/.local/share/backgrounds
    # Copy background image to appropriate directory
    cp $repo_path/.local/share/backgrounds/hollow_knight_lantern.png \
        $home/.local/share/backgrounds/hollow_knight_lantern.png
    
    # Generate colorscheme on basis of background image
    runuser -l "$username" -c "wal -i $home/.local/share/backgrounds/hollow_knight_lantern.png"
}

install_qtile () {
    # Install dependencies for qtile
    qtile_dependencies="xserver-xorg xinit libpangocairo-1.0-0 python3-xcffib \
        python3-cairocffi playerctl"
    install_package $qtile_dependencies

    #runuser -l "$username" -c "pipx install qtile"
    install_pip_package "git+https://github.com/qtile/qtile@master"
    runuser -l "$username" -c "qtile --version"


    backup_directory $home/.config/qtile
    create_directory $home/.config/qtile

    # Copy qtile configuration files into directory
    cp -r $repo_path/.config/qtile/* \
        $home/.config/qtile

    # Check if pywal is properly installed. If not, install it.
    if  [ ! -n "$(pipx list | grep pywal)" ]; then
        install_pywal
    fi
}

install_rofi () {
    install_package rofi

    backup_directory $home/.config/rofi
    create_directory $home/.config/rofi

    # Copy rofi configuration files into directory
    cp -r $repo_path/.config/rofi/* \
        $home/.config/rofi
}

install_wm () {
    install_qtile

    install_pywal

    install_rofi

    install_firefox

    install_kitty

    install_package "bottom ranger"
}

main