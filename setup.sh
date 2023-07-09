#!/bin/bash

# V A R I A B L E S

base_url="https://github.com/"
repo="ArmoredGoat/config"
branch="main"
url="$base_url/$repo/$branch"

# F U N C T I O N S

main () {
    # Check if script is run with sudo privileges. If not, exit.
    check_if_root
    
    # Gather information about environment.
    get_user

    # Update system to be avoid problems by using old software.
    update_system

    # Install git and clone repository to get started.
    install_git
    clone_repository

    # Copy user files as fonts, backgrounds, etc. into corresponding
    # directories.
    copy_user_files
    # Copy user scripts into .local/bin and ensure it is on path during
    # installation.
    copy_user_scripts
    
    # Install general applications and programming languages.
    install_basic_packages
    install_python
    install_java
    install_bash
    install_go
    
    install_ssh

    # Install window manager and its various dependencies and extensions.
    install_window_manager
    install_neovim

    # Set ownership of all files created by root in home directory to user.
    set_ownership $username $home

    # Update system before exiting to make sure everything is up to date and
    # to remove unnecessary packages.
    update_system
} 2> stderror

# G E N E R A L   F U N C T I O N S

enable_service () {
    systemctl enable $1

    if [[ "$2" == "start" ]]; then
        systemctl start $1 
    fi
}

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

check_if_root () {
    # Read EUID (Effective User ID) to check if script is run with
    # super user privileges (ID = 0). If not, abort script and tell
    # user to use sudo.
    if [ "$EUID" -ne 0 ]; then 
        printf "Please run script as root with sudo.\n"
        exit
    fi
}

clone_repository () {
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

copy_user_files () {
    # Create directories in /usr/share (systemwide) and .local/share (user-only)
    # to store backgrounds, fonts, icons, themes, ...
    create_directory $home/.local/share/{fonts/ttf,backgrounds}
    create_directory /usr/share/backgrounds

    # Copy files to corresponding directories
    # Copy font
    cp $repo_path/files/fonts/ttf/DejaVuSansMono-Bront.ttf \
        $home/.local/share/fonts/ttf/DejaVuSansMono-Bront.ttf
    # Copy desktop background image
    cp $repo_path/files/backgrounds/hollow_knight_lantern.png \
        $home/.local/share/backgrounds/hollow_knight_lantern.png
    # Copy login manager background image (must be in a directory
    # which can be accessed by login manager)
    cp $repo_path/files/backgrounds/hollow_knight_view.jpg \
        /usr/share/backgrounds/hollow_knight_view.jpg
}

copy_user_scripts () {
    # Copy script to fix screen on login (vm)
    install -Dm 755 "$repo_path/scripts/fix-screen" -t "$home/.local/bin"

    # Ensure ~/.local/bin is on PATH
    export PATH="$PATH:$home/.local/bin"
}

create_directory () {
	# Check if directories exists. If not, create them.
	if [[ -d $@ ]]; then
        printf "Directory '$@': already existent.\n"
    else
        mkdir -p $@
        printf "Directory '$@': created.\n"
    fi

	# This script is run with privileged rights. Therefore, anything created
	# with it will be owned by root. To make sure that the permissions are set
	# correclty, the function checks if the directory lies in the home folder.
	# If so, it grants ownership to the user.
	if [[ "$@" = "$home/*" ]]; then
		# General permissions settings. If necessary, e.g. ssh keys, the
        # permissions will be set accordingly
        chmod 755 "$@"
		chown -R "$username":"$username"
	fi

    permissions=$(ls -la "$@" | sed -n '2 p' | awk '{print $1" "$3":"$4}')
    printf "Directory '$@': permissions $permissions set.\n"
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

install_bash () {
    # Make sure bash packages are installed.
    bash_packages="bash bash-completion bash-builtins bash-doc"
    install_package $bash_packages

    # Copy .bash* files for user into its home directory
    cp $repo_path/files/bash/{.bashrc,.bash_aliases} $home/

    # Copy .bashrc for root user in root directory
    cp $repo_path/files/bash/.bashrc_root /root/
}

install_basic_packages () {
    basic_packages="wget curl tar p7zip-full"
    install_package $basic_packages
}

install_bottom () {
    #TODO Impelent function to always fetch the latest version.
    # Download latest bottom .deb package
    curl -L https://github.com/ClementTsang/bottom/releases/download/0.9.3/bottom_0.9.3_amd64.deb \
        -o /tmp/bottom_0.9.3_amd64.deb
    # Install .deb package with dpkg
    sudo dpkg -i /tmp/bottom_0.9.3_amd64.deb
}

install_firefox () {
    # Download latest version of Firefox
    wget -O /tmp/firefoxsetup.tar.bz2 \
        "https://download.mozilla.org/?product=firefox-latest&os=linux64&lang=en-US"
    
    # Extract archive and move content into /opt for global installation
    tar -xf /tmp/firefoxsetup.tar.bz2 --directory=/opt

    # Copy desktop entry to be able to launch firefox from rofi or any other
    # application launcher
    cp $repo_path/files/firefox/firefox.desktop \
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

install_git () {
    # Install git and its documentation
    git_packages="git git-doc"
    install_package $git_packages

    # Create directory at user home for git repositories
    create_directory $home/git
}

install_go () {
    #TODO Implement function to always fetch latest stable version
    # Download latest stazble version
    wget https://go.dev/dl/go1.20.5.linux-amd64.tar.gz \
        -O /tmp/go1.20.5.linux-amd64.tar.gz
    # Remove any previous Go installation
    rm -rf /usr/local/go
    # Extract archive into /usr/local to create a fresh Go installation.
    tar -C /usr/local -xzf /tmp/go1.20.5.linux-amd64.tar.gz

    # Go is also added to path by adding 'export PATH=$PATH:/usr/local/go/bin'
    # to .profile or .bashrc
    export PATH=$PATH:/usr/local/go/bin
}

install_java () {
    # Install Java Runtime Environment to be able to run java applications.
    java_packages="openjdk-17-jre"
    install_package $java_packages
}

install_lazygit () {
    # Clone repository into git folder
    git clone https://github.com/jesseduffield/lazygit.git $home/git/lazygit
    cd $home/git/lazygit
    go install
}

install_neovim () {
    # Install dependencies
    neovim_packages="neovim ripgrep gdu nodejs npm"
    install_package $neovim_packages
    install_lazygit

    # Clone AstroNvim config into nvim directory
    create_directory $home/.config/nvim
    git clone --depth 1 https://github.com/AstroNvim/AstroNvim $home/.config/nvim
}

install_nitrogen () {
    install_package nitrogen

    backup_directory $home/.config/nitrogen
    create_directory $home/.config/nitrogen

    cp -r $repo_path/files/nitrogen/* \
        $home/.config/nitrogen
}

install_kitty () {
    install_package kitty

    backup_directory $home/.config/kitty
    create_directory $home/.config/kitty

    cp -r $repo_path/files/kitty/* \
        $home/.config/kitty
}

install_picom () {
    install_package picom

    backup_directory $home/.config/picom
    create_directory $home/.config/picom

    cp -r $repo_path/files/picom/* \
        $home/.config/picom
}

install_pipx () {
    # https://pypa.github.io/pipx/
    # pipx is like pip a general-purpose package installer for Python and uses
    # the same package index, PyPI. As it is specifacally made for application
    # installation, it adds isolation while maintaining availability and 
    # connectiity between apps and shell. By using virtual environments, pipx
    # addresses the problem that packages provided by apt and pip are mixed up.
    # Mixing two package managers is a bad idea. Therefor, your distro protects
    # you from doing that.
    # pipx runs with regular user permissions and installs packages in 
    # ~/.local/bin, so make sure that it is on PATH by either add an export to
    # your .bashrc or by calling 'pipx ensurepath'.
    install_package pipx
    #runuser -l "$username" -c "pipx ensurepath"
}

install_python () {
    # Install full Python 3 Suite and pip
    python_packages="python3-full python3-pip"
    install_package $python_packages

    # Install general-purpose package installer for Python
    install_pipx
}

install_pywal () {
    pywal_packages="imagemagick procps nitrogen"
    install_package $pywal_packages

    install_pip_package pywal
    
    # Generate colorscheme on basis of background image
    #runuser -l "$username" -c "wal -i $home/.local/share/backgrounds/hollow_knight_lantern.png"
}

install_qtile () {
    # Install dependencies for qtile
    qtile_packages="xserver-xorg xinit dbus-x11 libpangocairo-1.0-0 python3-xcffib python3-cairocffi playerctl psutils"
    install_package $qtile_packages

    # Install MyPy package to be able to test your qtile config with
    # 'qtile check'
    install_pip_package mypy

    # Install qtile. Currently, it is necessary to get qtile from
    # github due to a recent bug with cairocffi
    #runuser -l "$username" -c "pipx install qtile"
    install_pip_package "git+https://github.com/qtile/qtile@master"
    #runuser -l "$username" -c "qtile --version"


    backup_directory $home/.config/qtile
    create_directory $home/.config/qtile

    # Copy qtile configuration files into directory
    cp -r $repo_path/files/qtile/* \
        $home/.config/qtile
}

install_rofi () {
    install_package rofi

    backup_directory $home/.config/rofi
    create_directory $home/.config/rofi

    # Copy rofi configuration files into directory
    cp -r $repo_path/files/rofi/* \
        $home/.config/rofi
}

install_ssh () {
    # Install SSH meta package to be able to access and to be accessed remotely.
    install_package "ssh"

    # Enable and start ssh.service
    enable_service ssh.service start
}

install_lightdm () {
    lightdm_packages="lightdm slick-greeter xserver-xephyr"
    install_package $lightdm_packages

    enable_service lightdm

    create_directory /etc/lightdm

    cp $repo_path/files/lightdm/* \
        /etc/lightdm/

    install -Dm 755 "$repo_path/files/X11/.xinitrc" -t "$home"
    install -Dm 755 "$repo_path/scripts/xinitrcsession-helper" -t "/usr/bin/"
    install -Dm 644 "$repo_path/files/X11/xinitrc.desktop" \
        -t "/usr/share/xsessions"

}

install_window_manager () {
    echo "Installing qtile..."
    install_qtile

    install_picom

    install_nitrogen

    install_pywal

    install_rofi

    install_firefox

    install_kitty

#    install_package "ranger"

    install_lightdm
}

main