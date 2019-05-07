# Clone dotfiles repository into $HOME/.config
git clone --bare git@github.com:CombustibleLemon/dotfiles.git $HOME/.dotfiles-config

# Create alias 'config' for git control of dotfiles in $HOME
alias config='/usr/bin/git --git-dir=$HOME/.dotfiles-config/ --work-tree=$HOME'

# Make backup folder for already-present config files
mkdir -p .dotfiles-config-backup && \
config checkout 2>&1 | egrep "\s+\." | awk {'print $1'} | \
xargs -I{} sh -c 'mkdir --parents .dotfiles-config-backup/$(dirname {}) && mv {} .dotfiles-config-backup/{}'

# Check out config files from $HOME/.config into $HOME 
config checkout

# Ignore irrelevant files in $HOME
config config --local status.showUntrackedFiles no
