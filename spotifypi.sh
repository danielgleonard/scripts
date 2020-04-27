#!/bin/bash

# Check if running as root
if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

error() { printf "ERROR:\\n%s\\n" "$2"; exit $1;}

welcomemsg() { \
	echo "Welcome to Dan's setup script for Spotify on Linux."
	echo "This will install a Spotify streaming server on this device."
	while true; do
		read -p "Shall we begin? (y/n) " yn
		case $yn in
			[Yy]* ) break;;
			[Nn]* ) error 125 "User declined";;
			* ) echo "Please answer yes or no.";;
		esac
	done
}

whoareyou() {
	PS3='Who are you? Please enter a number: '
	options=$(users)
	select opt in "${options[@]}"
	do
		users | grep $opt >/dev/null 2>&1 && user=$opt && break
	done
	echo "Welcome, $user"
}

install_dialog() {
	echo "Now installing 'dialog' to present you with better messages"
	apt update || error $? "Error updating apt"
	apt -y -u install dialog || error $? "Error with dialog installation"
}

closing() {
	dialog --title "All done" --msgbox "Assuming there were no hidden errors in the install, you should be all set up.\\n\\n~ Dan" 8 60
}

install () {
	dialog --title "Installing ‘$1’" --infobox "The package ‘$1’ $2" 8 60
	aptitude -y install "$1" >/dev/null 2&>1 || error $? "Error installing $1"
}

install_mopidy_repo() {
	dialog --title "Repository configuration" --infobox "Setting up an APT repository for ‘mopidy’ packages" 8 60
	wget -q -O - https://apt.mopidy.com/mopidy.gpg | apt-key add - || error $? "Error adding mopidy GPG key"
	wget -q -O /etc/apt/sources.list.d/mopidy.list https://apt.mopidy.com/buster.list || error $? "Error adding mopidy repository to apt"
	apt update || error $? "Error updating apt"
}

usermod() {
	dialog --title "Adding user ‘mopidy’" --infobox "This allows the music to be partitioned into a separate user with its own permissions. It will be added to group ‘video’ to allow use of HDMI audio." 8 60
	adduser mopidy video || error $? "Error adding user ‘mopidy’"
}

install_packages() {
	install 'mopidy' 'is a backend server for music playing'
	install 'mopidy-spotify' 'connects the mopidy backend to spotify'
}

# the actual code
welcomemsg
whoareyou
install_dialog
install_mopidy_repo
install_packages
usermod
closing
