#!/bin/bash

# Check if running as root
if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

DIST_OLD="stretch"
DIST_NEW="buster"

error() { printf "ERROR:\\n%s\\n" "$2"; exit $1;}

welcomemsg() { \
	echo "Welcome to Dan's Raspberry Pi updater."
	echo "This will update your Raspberry Pi software from $DIST_OLD to $DIST_NEW, it may take some time."
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
	echo "Now installing 'dialog' to present you with better messages"
	apt update >/dev/null 2>&1 || error $? "Error updating apt"
	apt -y -u install dialog >/dev/null 2>&1 || error $? "Error with dialog installation"
}

closing() {
	dialog --title "All done" --msgbox "Assuming there were no hidden errors in the install, you should now have up-to-date software.\\n\\n~ Dan" 8 60
}

rewrite() {
    dialog --title "Rewriting files" --infobox "Changing the file ‘$1’"
    sed -i "s/$DIST_OLD/$DIST_NEW/g" "$1" || error $? "Error rewriting $1"
    sleep 2
}

update() {
    rewrite '/etc/apt/sources.list'
    rewrite '/etc/apt/sources.list.d/raspi.list'
    dialog --title "Apt updating" --infobox "Running apt updating commands." 8 60
    apt-get -qy remove apt-listchanges >/dev/null 2>&1 || error $? "Error removing apt-listchanges"
    apt -qy update >/dev/null 2>&1 || error $? "Error running apt update"
    apt -qy dist-upgrade >/dev/null 2>&1 || error $? "Error running apt dist-upgrade"
}

remove_bad() {
    dialog --title "Purging" --infobox "Removing packages that should be removed"
    apt -qy purge timidity lxmusic gnome-disk-utility deluge-gtk evince wicd wicd-gtk clipit usermode gucharmap gnome-system-tools pavucontrol >/dev/null 2>&1 || error $? "Error purging"
    apt -qy autoremove >/dev/null 2>&1 || error $? "Error running autoremove"
    apt -qy autoclean >/dev/null 2>&1 || error $? "Error running autoclean"
}

# the actual code
run() {
    welcomemsg
    dialog >/dev/null 2>&1 || install_dialog
    update
    closing
}
run