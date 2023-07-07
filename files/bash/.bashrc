#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

##########  PATH

# Add .local/bin to PATH for pip packages, personal scripts, and so on.
export PATH="${PATH}:${HOME}/.local/bin"

# B A S H   H I S T O R Y

HISTFILE=~/.bash_history.$HOSTNAME  # Guard history getting truncated to
                                    # default 500 lines if bash --norc is run

HISTTIMEFORMAT="%F %T "             # Add date and time formatting to bash 
                                    # history

HISTCONTROL=ignoredups              # Ignore duplicate commands in bash history
HISTSIZE=-1                         # Disable command limit of bash history
HISTFILESIZE=-1                     # Disable size limit of bash history file

shopt -s histappend     # Set bash history to append instead of overwriting
shopt -s checkwinsize   # Check the window size after each command and, if 
                        # necessary, update the values of LINES and COLUMNS.

# P R O M P T

function nonzero_return() {
	RETVAL=$?
	[ $RETVAL -ne 0 ] && printf "\033[1m${RETVAL} \033[0;2m| \033[0m"
}

# get current branch in git repo
function parse_git_branch() {
	BRANCH=`git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/\1/'`
	if [ ! "${BRANCH}" == "" ]
	then
		STAT=`parse_git_dirty`
		printf "\033[1m${BRANCH}${STAT} \033[0;2m| \033[0m"
	else
		echo ""
	fi
}

# get current status of git repo
function parse_git_dirty {
	status=`git status 2>&1 | tee`
	dirty=`echo -n "${status}" 2> /dev/null | grep "modified:" &> /dev/null; echo "$?"`
	untracked=`echo -n "${status}" 2> /dev/null | grep "Untracked files" &> /dev/null; echo "$?"`
	ahead=`echo -n "${status}" 2> /dev/null | grep "Your branch is ahead of" &> /dev/null; echo "$?"`
	newfile=`echo -n "${status}" 2> /dev/null | grep "new file:" &> /dev/null; echo "$?"`
	renamed=`echo -n "${status}" 2> /dev/null | grep "renamed:" &> /dev/null; echo "$?"`
	deleted=`echo -n "${status}" 2> /dev/null | grep "deleted:" &> /dev/null; echo "$?"`
	bits=''
	if [ "${renamed}" == "0" ]; then
		bits=">${bits}"
	fi
	if [ "${ahead}" == "0" ]; then
		bits="*${bits}"
	fi
	if [ "${newfile}" == "0" ]; then
		bits="+${bits}"
	fi
	if [ "${untracked}" == "0" ]; then
		bits="?${bits}"
	fi
	if [ "${deleted}" == "0" ]; then
		bits="x${bits}"
	fi
	if [ "${dirty}" == "0" ]; then
		bits="!${bits}"
	fi
	if [ ! "${bits}" == "" ]; then
		echo " ${bits}"
	else
		echo ""
	fi
}

PS1=' \[\e[1m\]\w \[\e[0;2m\]| \[\e[0m\]$(parse_git_branch)$(nonzero_return)\[\e[1m\]\\$ \[\e[0m\]'

# Colored GCC warnings and errors
export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

# A L I A S E S

# Import aliases from ~/.bash_aliases
if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

# Enable programmable completion features
if ! shopt -oq posix; then
    if [ -f /usr/share/bash-completion/bash_completion ]; then
        . /usr/share/bash-completion/bash_completion
    elif [ -f /etc/bash_completion ]; then
        . /etc/bash_completion
    fi
fi
