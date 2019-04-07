#!/bin/sh
# Set up macOS for terminal use

if [ "$EUID" -ne 0 ]
  then echo "Please run as root. Try \"sudo ./setup_macos.sh\""
  exit 1
fi

# Install Homebrew (package manager)
echo "Now installing Homebrew, a package manager to download and update *nix command-line programs on macOS"
/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

# Programs to be installed
declare -a progs=("curl"
		"wget"
		"vim"
		"macvim"
		"fish"
		"zsh"
		"dialog"
		"ffmpeg"
		)
