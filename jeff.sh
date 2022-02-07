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

# upgrade_system() {
# 	dialog --title "System upgrade" --backtitle "Dan's Ngingx Setup" --msgbox "Performing a full system upgrade." 7 70
# 	apt-get -qq update >/dev/null 2>&1 || error $? "Error running apt update."
# 	clear
# 	apt-get -qq upgrade || error $? "Error running apt upgrade."
# }

sshd_configure() {
	dialog --title "sshd settings" --backtitle "Dan's Nginx Setup" --msgbox "Configuring sshd to disable passwords and require public key authentication." 7 70
	sed "s/PubkeyAuthentication no/PubkeyAuthentication yes/g" -i /etc/ssh/sshd_config || error $? "Error enabling pubkey authentication"
	sed "s/PasswordAuthentication yes/PasswordAuthentication no/g" -i /etc/ssh/sshd_config || error $? "Error disabling password authentication"
	sed "s/ChallengeResponseAuthentication yes/ChallengeResponseAuthentication no/g" -i /etc/ssh/sshd_config || error $? "Error disabling keyboard authentication"
	sed "/PubkeyAuthentication yes/s/^#//" -i /etc/ssh/sshd_config || error $? "Error uncommenting pubkey authentication"
	sed "/PasswordAuthentication no/s/^#//" -i /etc/ssh/sshd_config || error $? "Error uncommenting password authentication"
	sed "/ChallengeResponseAuthentication no/s/^#//" -i /etc/ssh/sshd_config || error $? "Error uncommenting keyboard authentication"
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

add_jeff() {
	if [ ! -d "/home/jeff/.ssh" ]; then
		mkdir "/home/jeff/.ssh" || error $? "Error making .ssh directory in /home/jeff."
	fi
	if [ ! -f "/home/jeff/.ssh/authorized_keys" ]; then
		printf "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCwGJ9J3kwMiusr7B19zgbay/cSiiq7aQ5dceG9JahC2EGtgGOhRlXZl19TgZzMsKKC46t7E8bOQfyX5taUoHewKEqF4x12hSHvddqrGST3pmrwgedX5LZJYd7aMS0aP3sXypr9YF5RCUIDucbX2QWAQBakCLilcCsXc2/p+MwI2Evb4w022mrT7zLT+93wC7s5UsIVezp9HY4sHd+mv2IyfgSPfhJFtkujK0q6s0BUnPi5CHcBXoRRcNtNGdvdRwbKpTr6IUC6aPIV5Ij4AWNCMjnKTpg1b3fYV+jaYNyGhDQyVlzR9kylu7+98YNi/RTdHxIgapnLLv9pqIvoRJOwvXSXj/jq6Q7tN/HQog/PinsG6UK99Kms5iWwVJl5H0dnBTGkXixul2U9dPQVpik3tzUgs9ZHRK5l5syarWl0ibLdwx+e7X1n/UCFbj49f5Zo4okMWfJnL0BsIB9gmjk418BXHImBMJCwuPZRWvZp0GRQOrldKUjhqzqCACtB+uk= jeffv@DESKTOP-C7J071R\n" > "/home/jeff/.ssh/authorized_keys" || error $? "Error writing public key to /home/jeff/.ssh."
	fi

	chown -R jeff:jeff "/home/jeff" || error $? "Error giving jeff ownership over /home/jeff"
	chmod 755 "/home/jeff/.ssh" || error $? "Error setting permissions on /home/jeff/.ssh"
	chmod 644 "/home/jeff/authorized_keys" || error $? "Error setting permissions on /home/jeff/.ssh/authorized_keys"
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

	python3 -m venv /opt/certbot/ || error $? "Error making a Python virtual environment."
	/opt/certbot/bin/pip install --upgrade pip || error $? "Error upgrading Python pip."

	/opt/certbot/bin/pip install certbot certbot-nginx || error $? "Error installing certbot from pip."

	ln -s /opt/certbot/bin/certbot /usr/bin/certbot || error $? "Error preparing the certbot command."

	dialog --title "Certbot installer" --backtitle "Dan's Ngingx Setup" --msgbox "You will now have to accept the terms and conditions for SSL certificates. Make sure to require redirects to HTTPS if prompted. This will not affect Filestash." 7 70
	clear
	certbot --nginx -d y3f.dev

	echo "0 0,12 * * * root /opt/certbot/bin/python -c 'import random; import time; time.sleep(random.random() * 3600)' && sudo certbot renew -q" | sudo tee -a /etc/crontab > /dev/null

	nginx -s reload
}

closing() {
	dialog --title "All done" --msgbox "Assuming there were no hidden errors in the install, you should be all set up.\\n\\n/home/ Dan" 8 60
}

main() {
	roottest
	welcomemsg
	install_dialog
	# upgrade_system
	sshd_configure
	install_progs
	add_jeff
	configure_nginx
	configure_certbot
	closing

	clear
	neofetch
}

main
