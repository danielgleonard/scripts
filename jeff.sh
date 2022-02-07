#!/bin/bash
# Set up macOS for terminal use

roottest() {
	if [ "$EUID" -ne 0 ]
		then echo "Please run as root. Try \"sudo ./jeff.sh\""
		exit 13
	fi
}

error() { clear; printf "ERROR:\\n%s\\nPlease report this error message to Dan.\\n" "$2"; exit $1;}

welcomemsg() { \
	echo "This is going to set up nginx in /var/www with HTTPS."
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

install_dialog() {
	echo "Now updating 'dialog' to present you with better messages."
	apt-get -qq install dialog >/dev/null 2>&1 || error 65 "Error with dialog installation"
}

install_progs() {
	progsfile="https://scripts.danleonard.us/setup_jeff_progs.csv"

	# Read all non-commented lines from progsfile (comment being a hash)
	curl -LS "$progsfile" | sed '/^#/d' > /tmp/setup_jeff_progs.csv

	# Count the total number of programs to install
	total=$(wc -l < /tmp/setup_jeff_progs.csv)

	while IFS=, read -r program comment; do
		n=$((n+1))
		dialog --title "Program installer" --backtitle "Dan's Ngingx Setup" --infobox "Installing \`$(basename $program)\` ($n of $total). $program $comment" 7 70

		# Install the program with homebrew
		apt-get -qq install $program >/dev/null 2>&1 || error 65 "$program not installed."
	done < /tmp/setup_jeff_progs.csv
}

configure_nginx() {
	dialog --title "Configuring nginx" --backtitle "Dan's Ngingx Setup" --msgbox "We will now configure nginx to point to /var/www/y3f.dev." 7 70

	mkdir /var/www/y3f.dev; >/dev/null 2>&1 || error $? "Error configuring nginx.\nmkdir /var/www/y3f.dev"
	mkdir /var/www/y3f.dev/html; >/dev/null 2>&1 || error $? "Error configuring nginx.\nmkdir /var/www/y3f.dev/html"
	mkdir /var/www/y3f.dev/html/assets; >/dev/null 2>&1 || error $? "Error configuring nginx.\nmkdir /var/www/y3f.dev/html/assets"
	mkdir /var/www/y3f.dev/html/assets/css; >/dev/null 2>&1 || error $? "Error configuring nginx.\nmkdir /var/www/y3f.dev/html/assets/css"

	curl -fsSL "scripts.danleonard.us/jeff.nginx-error.xhtml" -o "/var/www/html/error.xhtml" >/dev/null 2>&1 || error $? "Error configuring nginx.\nscripts.danleonard.us/jeff.nginx-error.xhtml"
	curl -fsSL "scripts.danleonard.us/jeff.nginx-default-style.css" -o "/var/www/y3f.dev/html/assets/css/default-style.css" >/dev/null 2>&1 || error $? "Error configuring nginx.\nscripts.danleonard.us/jeff.nginx-default-style.css"
	curl -fsSL "scripts.danleonard.us/jeff.nginx-errorpages.inc" -o "/etc/nginx/errorpages.inc" >/dev/null 2>&1 || error $? "Error configuring nginx.\nscripts.danleonard.us/jeff.nginx-errorpages.inc"
	curl -fsSL "scripts.danleonard.us/jeff.nginx.conf" -o "/etc/nginx/nginx.conf" >/dev/null 2>&1 || error $? "Error configuring nginx.\nscripts.danleonard.us/jeff.nginx.conf"
	curl -fsSL "scripts.danleonard.us/jeff.nginx-y3f.dev.conf" -o "/etc/nginx/conf.d/y3f.dev" >/dev/null 2>&1 || error $? "Error configuring nginx.\nscripts.danleonard.us/jeff.nginx-y3f.dev.conf"
	curl -fsSL "scripts.danleonard.us/jeff.nginx-default.conf" -o "/etc/nginx/conf.d/default.conf" >/dev/null 2>&1 || error $? "Error configuring nginx.\nscripts.danleonard.us/jeff.nginx-default.conf"

}

configure_certbot() {
	dialog --title "Certbot installer" --backtitle "Dan's Ngingx Setup" --infobox "Installing Certbot. Certbot automatically adds HTTPS certificates to nginx servers." 7 70

	snap install core >/dev/null 2>&1 || error 65 "Error installing snapd core."
	snap refresh core >/dev/null 2>&1 || error 65 "Error refreshing snapd core."
	snap install --classic certbot >/dev/null 2>&1  || error 65 "Error installing certbot from snapd."

	ln -s /snap/bin/certbot /usr/bin/certbot >/dev/null 2>&1 || error $? "Error linking certbot to bin."

	dialog --title "Certbot installer" --backtitle "Dan's Ngingx Setup" --msgbox "You will now have to accept the terms and conditions for SSL certificates. Make sure to require redirects to HTTPS if prompted. This will not affect Filestash." 7 70
	clear
	certbot --nginx -d y3f.dev

	systemctl restart nginx || nginx -s reload
}

closing() {
	dialog --title "All done" --msgbox "Assuming there were no hidden errors in the install, you should be all set up.\\n\\n~ Dan" 8 60
}

main() {
	roottest
	welcomemsg
	install_dialog
	install_progs
	configure_nginx
	configure_certbot
	closing

	clear
	neofetch
}

main
