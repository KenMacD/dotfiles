################################################################################
# Oh my zsh related:
################################################################################
# Path to your oh-my-zsh installation.
export ZSH=$HOME/.oh-my-zsh
ZSH_THEME="robbyrussell"

plugins=(git github git-extras pyenv archlinux fasd last-working-dir systemd supervisor vagrant safe-paste docker)

alias git.='git --git-dir=/home/kenny/src/dotfiles'

# Avr stuff:
alias avrdude='/usr/bin/avrdude -C/home/kenny/.platformio/packages/tool-avrdude/avrdude.conf'

# Temporary intel drm bug alias:
alias zz='/home/kenny/.screenlayout/relaptop.sh'
alias yy='sudo intel_gpu_top'

export EDITOR="vim"

################################################################################
# GPG related:
################################################################################

# Start the gpg-agent if not already running
if ! pgrep -x -u "${USER}" gpg-agent >/dev/null 2>&1; then
  gpg-connect-agent /bye >/dev/null 2>&1
fi

# Set SSH to use gpg-agent
unset SSH_AGENT_PID
if [ "${gnupg_SSH_AUTH_SOCK_by:-0}" -ne $$ ]; then
  export SSH_AUTH_SOCK="/run/user/$UID/gnupg/S.gpg-agent.ssh"
fi
# Set GPG TTY
export GPG_TTY=$(tty)

# Refresh gpg-agent tty in case user switches into an X session
gpg-connect-agent updatestartuptty /bye >/dev/null

################################################################################

if [ -f ~/.bashrc_private ]; then . ~/.bashrc_private ; fi

################################################################################
# Python related:
################################################################################
export PYENV_VIRTUALENVWRAPPER_PREFER_PYVENV="true"
export PATH=$PATH:"/home/kenny/.pyenv/bin"
eval "$(pyenv virtualenv-init -)"  # Auto-activate virtualenvs

export PYTHONDONTWRITEBYTECODE=1
export PYTHONSTARTUP=$HOME/.pythonrc
alias nopyc='find . -type f -name "*.py[co]" -delete -or -type d -name "__pycache__" -delete'

if [ -f ~/.exports ]; then . ~/.exports ; fi

#export GEM_HOME=$(ruby -e 'print Gem.user_dir')
#export PATH="$PATH:$GEM_HOME/bin"

eval "$(rbenv init -)"

alias pbcopy='xsel --clipboard --input'
alias pbpaste='xsel --clipboard --output'
alias docker-clean="docker ps -a | grep 'weeks ago' | awk '{print $1}' | xargs --no-run-if-empty docker rm"

# Encode videos for playing on an HP Touchpad:
function tpencode() {
	ffmpeg -i $1 -f mp4 -vcodec libx264 -b 800k -aspect 16:9 -s 1024x576 -x264opts level=41:weightp=2:me=umh:bframes=0:direct=auto:rc-lookahead=60:subme=9:partitions=all:trellis=2 -threads 4 -ab 96k -strict -2 $1.OUT
}

NPM_PACKAGES="${HOME}/.npm-packages"
NODE_PATH="$NPM_PACKAGES/lib/node_modules:$NODE_PATH"
export PATH="$PATH:$NPM_PACKAGES/bin"

#PATH="$PATH:$(ruby -e 'print Gem.user_dir')/bin"
#export LD_LIBRARY_PATH="${HOME}/opt/lib"
export PATH="$PATH:${HOME}/opt/bin/"

# Add thefuck
eval $(thefuck --alias)

source $ZSH/oh-my-zsh.sh
