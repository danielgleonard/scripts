#!/bin/sh
# Set up macOS for terminal use

if [ "$EUID" -ne 0 ]
  then echo "Please run as root. Try \"sudo ./setup_macos.sh\""
  exit 13
fi

error() { printf "ERROR:\\n%s\\n" "$2"; exit $1;}

welcomemsg() { \
	echo "                         ____  _____              __            ";
	echo "   ____ ___  ____ ______/ __ \/ ___/   ________  / /___  ______ ";
	echo "  / __ \`__ \/ __ \`/ ___/ / / /\__ \   / ___/ _ \/ __/ / / / __";
	echo " / / / / / / /_/ / /__/ /_/ /___/ /  (__  )  __/ /_/ /_/ / /_/ /";
	echo "/_/ /_/ /_/\__,_/\___/\____//____/  /____/\___/\__/\__,_/ .___/ ";
	echo "                                                       /_/      ";
	echo "Welcome to Dan's setup script for macOS. This will install basic software for using the terminal."
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

# Install Homebrew (package manager)
install_homebrew() {
	echo "Now installing Homebrew, a package manager to download and update *nix command-line programs on macOS"
	sudo -u $user /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)" || error 65 "Error with Homebrew installation"
}

install_dialog() {
	echo "Now installing 'dialog' to present you with better messages"
	sudo -u $user brew install dialog || error 65 "Error with dialog installation"
}

install_progs() {
	progsfile="https://danleonard.us/scripts/setup_macos_progs.csv"
	curl -LS "$progsfile" | sed '/^#/d' > /tmp/setup_macos_progs.csv
	total=$(wc -l < /tmp/setup_macos_progs.csv)

	while IFS=, read -r program comment; do
		n=$((n+1))
		dialog --title "Dan's macOS Installer" --infobox "Installing \`$(basename $program)\` ($n of $total). $program $comment" 5 70
		sudo -u $user brew install $program >/dev/null 2>&1 || error 65 "$program not installed"
	done < /tmp/setup_macos_progs.csv
}

change_shell() {
	grep "zsh"  /etc/shells || echo "/usr/local/bin/zsh">>/etc/shells
	grep "fish" /etc/shells || echo "/usr/local/bin/fish">>/etc/shells

	shell_choice=$(dialog --title "Change your shell" --menu "Choose one of the installed shells (I can't recommend 'fish' enough)" 10 75 3 bash "The Bourne-Again Shell, everyone's got it" zsh "The Z Shell, backwards-compatable with the Bourne shell" fish "The Friendly Interactive Shell, which comes with autocomplete" 2>&1 >/dev/tty)
	case $shell_choice in
		"bash")
			chsh -s "$(grep -m 1 -Z bash /etc/shells)" $user
			;;
		"zsh")
			chsh -s "$(grep -m 1 -Z zsh  /etc/shells)" $user
			;;
		"fish")
			chsh -s "$(grep -m 1 -Z fish /etc/shells)" $user
			;;
	esac
}

dotfiles() {
	usr_home=$(eval echo -n ~$user)
	dialog --title "Configuration" --yes-label "Sounds good" --no-label "I'll go in nude" --yesno "This script can also install configuration files for your shell if you don't already have them" 10 40 || { clear; return; }

	# grml-zsh-config
	sudo -u $user curl -o $usr_home/.zshrc -fsSL https://git.grml.org/f/grml-etc-core/etc/zsh/zshrc || error 65 "Error curling .zshrc"

	# Oh my fish
	sudo -u $user fish -c "$(curl -fsSL https://get.oh-my.fish) --noninteractive --yes >/dev/null 2>&1" || error 65 "Error with oh-my-fish installation"

	# Bash settings
	sudo -u $user echo "export PS1=\"\\[\$(tput bold)\\]\\[\$(tput setaf 1)\\][\\[\$(tput setaf 3)\\]\\\u\\[\$(tput setaf 2)\\]@\\[\$(tput setaf 4)\\]\\h \\[\$(tput setaf 5)\\]\\W\\[\$(tput setaf 1)\\]]\\[\$(tput setaf 7)\\]\\\\\\$ \\[\$(tput sgr0)\\]\"" >> $usr_home/.bash_profile
	sudo -u $user printf "\n#Aliases\nsource \$HOME/.config/aliases.sh" >> $usr_home/.bash_profile

	# Fish settings
	sudo -u $user fish -c "omf install plain >/dev/null 2>&1" || error 65 "Error installing fish \'plain\' theme"
	sudo -u $user printf "\n#Aliases\nsource \$HOME/.config/aliases.sh" >> $usr_home/.config/fish/config.fish

	# Aliases
	sudo -u $user printf "alias grep=\"grep --color=auto\"\nalias hgrep=\"fc -El 0 | grep\"\t#Grep history\nalias diff=\"diff --color=auto\"\n" >> $usr_home/.config/aliases.sh
}

closing() {
	dialog --title "All done" --msgbox "Assuming there were no hidden errors in the install, you should be all set up.\\nbash:\\n  • small prompt change in ~/.bash_profile\\n  • some aliases added\\nzsh:\\n  • copied well-liked config file to ~/.zshrc\\n  • check out aliases for 'l','ll', and more\\nfish:\\n  • installed customization tool 'oh-my-fish'\\n  • check out 'omf --help'\\n\\n ~ Dan" 17 60
}

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
