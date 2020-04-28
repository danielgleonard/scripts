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

check_system() {
    grep 'buster' '/etc/apt/sources.list' || bash -c "$(curl -fsSL danleonard.us/scripts/updatepi.sh)"
}

install_dialog() {
	echo "Now installing 'dialog' to present you with better messages"
	apt update >/dev/null 2>&1 || error $? "Error updating apt"
	apt -y -u install dialog >/dev/null 2>&1 || error $? "Error with dialog installation"
}

closing() {
	dialog --title "All done" --msgbox "Assuming there were no hidden errors in the install, you should be all set up. If it doesn’t seem to work, consult docs.mopidy.com\\n\\n~ Dan" 8 60
}

install () {
	dialog --title "Installing ‘$1’" --infobox "The package ‘$1’ $2" 8 60
	apt -qy install "$1" >/dev/null 2>&1 || error $? "Error installing $1"
}

install_mopidy_repo() {
	dialog --title "Repository configuration" --infobox "Setting up an APT repository for ‘mopidy’ packages" 8 60
	wget -q -O - https://apt.mopidy.com/mopidy.gpg | apt-key add - >/dev/null 2>&1 || error $? "Error adding mopidy GPG key"
	wget -q -O /etc/apt/sources.list.d/mopidy.list https://apt.mopidy.com/buster.list >/dev/null 2>&1 || error $? "Error adding mopidy repository to apt"
	apt update >/dev/null 2>&1 || error $? "Error updating apt"
}

usermod() {
	dialog --title "Adding user ‘mopidy’" --infobox "This allows the music to be partitioned into a separate user with its own permissions. It will be added to group ‘video’ to allow use of HDMI audio." 8 60
	adduser mopidy video >/dev/null 2>&1 || error $? "Error adding user ‘mopidy’"
	sleep 5
}

install_packages() {
	install 'mopidy' 'is a backend server for music playing'
	install 'mopidy-spotify' 'connects the mopidy backend to Spotify'
}

credentials() {
	S_USERNAME=$(dialog --title "Spotify username" --inputbox "Please go to https://www.spotify.com/us/account/set-device-password/ and set a device password. Enter the provided username here." 8 60 2>&1 1>/dev/tty); 
	S_PASSWORD=$(dialog --title "Spotify password" --passwordbox "Enter the device password you just made here. The text should not display as you type." 8 60 2>&1 1>/dev/tty); 
	S_ID=$(dialog --title "Mopidy client ID" --inputbox "Now go to https://mopidy.com/ext/spotify/ and log into Spotify. Paste the ‘client_id’ here." 8 60 2>&1 1>/dev/tty); 
	S_SECRET=$(dialog --title "Mopidy secret" --inputbox "Add the ‘client_secret’ here." 8 60 2>&1 1>/dev/tty); 

	CONFIG=$(echo -e "[spotify]\nusername = $S_USERNAME\npassword = $S_PASSWORD\nclient_id = $S_ID\nclient_secret = $S_SECRET\n")
	dialog --title "Saving configuration" --msgbox "The following will be appended to /etc/mopidy/mopidy.conf:\n$CONFIG" 8 60
	echo -e "$CONFIG" >> /etc/mopidy/mopidy.conf
}

service() {
	dialog --title "Running as service" --infobox "Enabling mopidy as a system service so it no longer needs to be manually operated." 8 60
	systemctl enable mopidy
	systemctl start mopidy
	sleep 5
	systemctl status mopidy
	sleep 5
}

# the actual code
run(){
	welcomemsg
	check_system
	dialog >/dev/null 2>&1 || install_dialog
	install_mopidy_repo
	install_packages
	usermod
	credentials
	service
	closing
}
run