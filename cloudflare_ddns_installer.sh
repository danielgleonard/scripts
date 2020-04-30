#!/usr/bin/env bash

# Check if running as root
if [ "$EUID" -ne 0 ]
	then echo "Please run as root"
	exit 13
fi

error() {rm -r $DIR; >&2 printf "ERROR:\\n%s\\n" "$2"; exit $1;}

DIR='/usr/bin/cloudflare-ddns'

welcomemsg() { \
	echo "Welcome to Dan's setup script for dynamically updating Cloudflare DNS."
	echo "This will set up a script for regulary checking your IP address and updating the global DNS."
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
	apt update >/dev/null 2>&1 || error $? "Error updating apt"
	apt -y -u install dialog >/dev/null 2>&1 || error $? "Error with dialog installation"
}

closing() {
	dialog --title "All done" --msgbox "Assuming there were no hidden errors in the install, you should be all set up. If it doesn’t seem to work, consult docs.mopidy.com\\n\\n~ Dan" 8 60
	clear
}

getdirectory() {
	DIR=$(dialog --title "Set configuration directory" --inputbox "This is the place where the script and all configuration files are stored. Do not change unless for good reason" 8 60 "$DIR" 2>&1 1>/dev/tty);
	if [ -d "$DIR" ]; then
		error 17 "Directory '$DIR' already exists. Please try again."
	fi
}

permissions() {
	dialog --title "Adding user ‘cloudflare’" --infobox "This is a user with no login permissions, only able to execute the script. This is necessary for security reasons." 8 60
	/usr/sbin/useradd -d "$DIR" -N -s "/usr/sbin/nologin" -m cloudflare >/dev/null 2>&1 || error $? "Error adding cloudflare user"
	sleep 5
	dialog --title "Creating $DIR" --infobox "Creating $DIR for the new user cloudflare to be restricted to." 8 60
	touch "$DIR/credentials.txt" >/dev/null 2>&1 || error $? "Error creating '$DIR/credentials.txt'"
	touch "$DIR/domain.txt" >/dev/null 2>&1 || error $? "Error creating '$DIR/domain.txt"
	curl -o "$DIR/updater.sh" -fsSL 'danleonard.us/scripts/cloudflare_ddns.sh' >/dev/null 2>&1 || error $? "Error creating '$DIR/updater.sh"
	chown -R cloudflare "$DIR" >/dev/null 2>&1 || error $? "Error setting ownership of '$DIR'"
	chmod 0555 "$DIR" >/dev/null 2>&1 || error &? "Error changing mode of '$DIR'"
	chmod 0400 "$DIR/credentials.txt" >/dev/null 2>&1 || error $? "Error changing mode of '$DIR/credentials.txt'"
	chmod 0444 "$DIR/domain.txt" >/dev/null 2>&1 || error $? "Error changing mode of '$DIR/domain.txt'"
	chmod 0544 "$DIR/updater.sh" >/dev/null 2>&1 || error $? "Error changing mode of '$DIR/updater.sh'"
}

credentials() {
	C_EMAIL=$(dialog --title "Cloudflare email" --inputbox "Please input the email address you use to sign into Cloudflare." 8 60 2>&1 1>/dev/tty); 
	C_APIKEY=$(dialog --title "Cloudflare API key" --inputbox "Please insert the API key from your Cloudflare account." 8 60 2>&1 1>/dev/tty); 
	C_DOMAIN=$(dialog --title "Domain zone" --inputbox "Enter the domain name which you are managing with Cloudflare, such as ‘danleonard.us’ or ‘penis.org’." 8 60 2>&1 1>/dev/tty); 
	C_SUBDOMAIN=$(dialog --title "Subdomain" --inputbox "Enter the subdomain name that uniquely and unambiguously refers to this computer, without the domain from the previous step, such as ‘server.momshouse’ or ‘raspberrypi.apartment’." 8 60 'server.static' 2>&1 1>/dev/tty); 
	
	dialog --title "Confirm settings" --yesno "This will set up logging into Cloudflare with the following settings:\\nEmail:   $C_EMAIL\\nAPI key: $C_APIKEY\\n\\nTo manage this computer as the hostname\\n$C_SUBDOMAIN.$C_DOMAIN" 12 60 2>&1 1>/dev/tty || rm -r $DIR; error 69 'User declined'

	dialog --title "Saving configuration" --msgbox "The passwords will be added to $DIR/credentials.txt and $DIR/domain.txt" 8 60
	printf "$C_EMAIL\\n$C_APIKEY\\n" > $DIR/credentials.txt || error $? "Error writing $DIR/credentials.txt"
	printf "$C_SUBDOMAIN\\n$C_DOMAIN\\n" > $DIR/domain.txt || error $? "Error writing $DIR/domain.txt"
}

service() {
	dialog --title "Running as service" --infobox "Enabling cloudflare-ddns as a system service so it no longer needs to be manually operated." 8 60
	printf "[Unit]\\nDescription=Updates Cloudflare DNS with the IP address of this machine\\nAfter=network-online.target\\nWants=network-online.target\\n\\n[Service]\\nUser=cloudflare\\nType=oneshot\\nExecStart=$DIR/updater.sh\\nWorkingDirectory=$DIR\\n\\n[Install]WantedBy=multi-user.target\\n" > /etc/systemd/system/cloudflare-ddns.service || error $? "Error writing /etc/systemd/system/cloudflare-ddns.service"
	printf "[Unit]\\nDescription=Update Cloudflare every minute\\nRequires=cloudflare-ddns.service\\n\\n[Timer]\\nUnit=cloudflare-ddns.service\\nOnUnitInactiveSec=1m\\n\\n[Install]\\nWantedBy=timers.target\\n" > /etc/systemd/system/cloudflare-ddns.timer || error $? "Error writing /etc/systemd/system/cloudflare-ddns.timer"
	systemctl enable cloudflare-ddns.service >/dev/null 2>&1 || error $? "Error enabling cloudflare-ddns service"
	systemctl enable cloudflare-ddns.timer >/dev/null 2>&1 || error $? "Error enabling cloudflare-ddns timer"
	systemctl start cloudflare-ddns.timer >/dev/null 2>&1 || error $? "Error starting cloudflare-ddns timer"
	sleep 5
	clear
	systemctl status cloudflare-ddns.service || error $? "Error getting cloudflare-ddns status"
	sleep 5
}

# the actual code
run(){
	welcomemsg
	dialog >/dev/null 2>&1 || install_dialog
	getdirectory
	permissions
	credentials
	service
	closing
}
run