# Clone dotfiles repository into $HOME/.config
git clone --bare git@github.com:CombustibleLemon/dotfiles.git $HOME/.config

# Create alias 'config' for git control of dotfiles in $HOME
alias config='/usr/bin/git --git-dir=$HOME/.config/ --work-tree=$HOME'

# Make backup folder for already-present config files
mkdir -p .config-backup && \
config checkout 2>&1 | egrep "\s+\." | awk {'print $1'} | \
xargs -I{} mv {} .config-backup/{}

# Check out config files from $HOME/.config into $HOME 
config checkout

# Ignore irrelevant files in $HOME
config config --local status.showUntrackedFiles no
