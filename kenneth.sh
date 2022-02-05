#!/bin/bash
# Set up macOS for terminal use

roottest() {
	if [ "$EUID" -ne 0 ]
		then echo "Please run as root. Try \"sudo ./kenneth.sh\""
		exit 13
	fi
}

error() { clear; printf "ERROR:\\n%s\\n569o9Please report this error message to Dan.\\n" "$2"; exit $1;}

welcomemsg() { \
	echo "This is going to set up direct file access over HTTPS."
	echo "This script does NOT guarantee failing safely. Errors must be reported to Dan."
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
	echo "Now updating 'dialog' to present you with better messages."
	apt-get -qq install dialog >/dev/null 2>&1 || error 65 "Error with dialog installation"
}

install_progs() {
	progsfile="https://danleonard.us/scripts/setup_kenneth_progs.csv"

	# Read all non-commented lines from progsfile (comment being a hash)
	curl -LS "$progsfile" | sed '/^#/d' > /tmp/setup_kenneth_progs.csv

	# Count the total number of programs to install
	total=$(wc -l < /tmp/setup_kenneth_progs.csv)

	while IFS=, read -r program comment; do
		n=$((n+1))
		dialog --title "Program installer" --backtitle "Dan's CyTube Access Setup" --infobox "Installing \`$(basename $program)\` ($n of $total). $program $comment" 7 70

		# Install the program with homebrew
		apt-get -qq install $program >/dev/null 2>&1 || error 65 "$program not installed."
	done < /tmp/setup_kenneth_progs.csv
}

configure_nginx() {
	dialog --title "Configuring nginx" --backtitle "Dan's CyTube Access Setup" --msgbox "We will now configure nginx to point to the Intra Gaming repository for read-only file access." 7 70
	exec 3>&1
	NGINX_OUTPUT=$(dialog --title "Configuring nginx" --backtitle "Dan's CyTube Access Setup" --inputbox "Please enter the full path (starting with /) of the Intra Gaming repository. Even if there are spaces, do NOT enter quote symbols." 7 70 2>&1 1>&3) || error $? "Error getting repository path"
	exec 3>&-
	
	if [[ -d "$NGINX_OUTPUT" ]]; then
		# echo "$NGINX_OUTPUT is a directory"
		ln -s "$NGINX_OUTPUT" "/usr/share/nginx/intra_repository"
	else
		error 125 "User entered \"$NGINX_OUTPUT\". Path is not a valid directory."
	fi

	printf "server {\n\tlisten [::]:80;\n\tlisten 80;\n\n\tserver_name intra.incel.us;\n\n\troot /usr/share/ngnix/intra_repository;\n}\n" > /etc/nginx/conf.d/intra.conf || error $? "Failed writing nginx configuration."
}

configure_certbot() {
	dialog --title "Certbot installer" --backtitle "Dan's CyTube Access Setup" --infobox "Installing Certbot. Certbot automatically adds HTTPS certificates to nginx servers." 7 70

	snap install core >/dev/null 2>&1 || error 65 "Error installing snapd core."
	snap refresh core >/dev/null 2>&1 || error 65 "Error refreshing snapd core."
	snap install --classic certbot >/dev/null 2>&1  || error 65 "Error installing certbot from snapd."

	ln -s /snap/bin/certbot /usr/bin/certbot >/dev/null 2>&1 || error $? "Error linking certbot to bin."

	dialog --title "Certbot installer" --backtitle "Dan's CyTube Access Setup" --msgbox "You will now have to accept the terms and conditions for SSL certificates. Make sure to require redirects to HTTPS if prompted. This will not affect Filestash." 7 70
	clear
	certbot --nginx -d intra.incel.us

	systemctl restart nginx || nginx -s reload
}

closing() {
	dialog --title "All done" --msgbox "Assuming there were no hidden errors in the install, you should be all set up.\\n\\n~ Dan" 8 60
}

main() {
	roottest
	welcomemsg
	whoareyou
	install_homebrew
	install_dialog
	install_progs
	change_shell
	dotfiles
	closing

	clear
	sudo -u $user neofetch
}

main
