#====================================================
# custom bindings / functions
#====================================================

alias title="setGnomeTerminalTitle";

#====================================================
# Sudo and admin related commands
#====================================================
alias sudol='sudo l'
alias s='sudo l'
alias sl='sudo l'
alias audol='sudo l'
alias audok='sudo l'
alias sudok='sudo l'
alias sudp='sudo'
alias audo='sudo'
alias audp='sudo'
alias fucking='sudo'
alias fuck='sudo $(history -p \!\!)'
alias su!='sudo -i'
alias root='sudo -i'

alias hist='history'
alias histoff="setGnomeTerminalTitle 'Incognito Window' && set +o history"
alias histon="setGnomeTerminalTitle \"$USER@$HOSTNAME:\${PWD//\${HOME//\\//\\\\\\/}/\\~}\" && set -o history"

#====================================================
# Search related commands
#====================================================
#grep aliases
alias grepa='alias|grep -Pi'
alias agrep='alias|grep -Pi'

alias listfunctions="grep -P '^\s*function\s' $HOME/.bash_functions|sed -E 's/^\s*function\s+(\w+)\W.*$/\1/g'|sort"
alias listfunc="grep -P '^\s*function\s' $HOME/.bash_functions|sed -E 's/^\s*function\s+(\w+)\W.*$/\1/g'|sort"

#grep dirs
alias grepd='ls -GAhclips1 | grep -P -i -e '
alias dgrep='ls -GAhclips1 | grep -P -i -e '

alias f='find . -not -iwholename "*.git/*" '

#====================================================
# System Info related commands
#====================================================
# os info + sys specs
alias pcinfo='echo -e "Mint Info:\n=====================";cat /etc/linuxmint/info;echo -e "\nUpstream Ubuntu Info:\n=====================";cat /etc/upstream-release/lsb-release;echo -e "\nUpstream Debian Info:\n=====================";cat /etc/debian_version;echo -e "\nDetailed System Info:\n=====================";inxi -F;';
alias sysinfo='echo -e "Mint Info:\n=====================";cat /etc/linuxmint/info;echo -e "\nUpstream Ubuntu Info:\n=====================";cat /etc/upstream-release/lsb-release;echo -e "\nUpstream Debian Info:\n=====================";cat /etc/debian_version;echo -e "\nDetailed System Info:\n=====================";inxi -F;';

#specs only
alias pcspecs='inxi -F;';
alias specs='inxi -F;';

#os info only
alias osinfo='echo -e "Mint Info:\n=====================";cat /etc/linuxmint/info;echo -e "\nUpstream Ubuntu Info:\n=====================";cat /etc/upstream-release/lsb-release;echo -e "\nUpstream Debian Info:\n=====================";cat /etc/debian_version;';
alias osversion='echo -e "Mint Info:\n=====================";cat /etc/linuxmint/info;echo -e "\nUpstream Ubuntu Info:\n=====================";cat /etc/upstream-release/lsb-release;echo -e "\nUpstream Debian Info:\n=====================";cat /etc/debian_version;';
alias version='echo -e "Mint Info:\n=====================";cat /etc/linuxmint/info;echo -e "\nUpstream Ubuntu Info:\n=====================";cat /etc/upstream-release/lsb-release;echo -e "\nUpstream Debian Info:\n=====================";cat /etc/debian_version;';

alias mintinfo='cat /etc/linuxmint/info;';
alias mintversion='cat /etc/linuxmint/info;';
alias whichmint='cat /etc/linuxmint/info;';

alias ubuntuinfo='cat /etc/upstream-release/lsb-release'
alias ubuntuversion='cat /etc/upstream-release/lsb-release'
alias whichubuntu='cat /etc/upstream-release/lsb-release'

alias debianinfo='cat /etc/debian_version'
alias debianversion='cat /etc/debian_version'
alias whichdebian='cat /etc/debian_version'

#====================================================
# Package related commands
#====================================================
alias asearch='apt search'
alias apt-search='apt search'

#Unfortunately, bash complains about alias names starting with hyphens so no '--' for sudo apt remove ...
alias ++='sudo apt install'
alias ++y='sudo apt install -y'
alias +++='sudo apt install --install-recommends '
alias +++y='sudo apt install --install-recommends -y'
alias ++++='sudo apt install --install-recommends --install-suggests '

# techically the alias 'install' blocks '/usr/bin/install' but i dont really care
alias install='sudo apt install'
alias remove='sudo apt remove'
alias uninstall='sudo apt remove'
alias purge='sudo apt purge'
alias destroyitwithfire='sudo apt purge'

alias update='sudo apt update'
alias stfupdate='sudo apt-get update 2>&1 >/dev/null'
alias dist-upgrade='sudo apt dist-upgrade'
alias distro-update='sudo apt dist-upgrade'
alias upgrade='sudo apt dist-upgrade'

#====================================================
# Process and Service related commands
#====================================================
alias plist='echo "use ps aux" or "pgrep" or alias "pg"'
alias tasklist='echo "use ps aux or ps -ef or pgrep" or alias "pg"'
alias taskkill='echo "use kill -9 processname*" or "pkill -9 processname" or alias "pk"'
alias taskill='echo "use kill -9 processname*" or "pkill -9 processname" or alias "pk"'

alias killspot='killall -9 spotify';

alias pskill='pkill --signal 9 --full --ignore-case'
alias pslist='pgrep --list-full --full --ignore-case'
alias psgrep='pgrep --list-full --full --ignore-case'

alias pk='pkill --signal 9 --full --ignore-case'
alias p9='pkill --signal 9 --full --ignore-case'
alias pg='pgrep --list-full --full --ignore-case'

#override pgrep to automatically list all without having to specify args
alias pgrep='pgrep --list-full'

#====================================================
# Archive related commands
#====================================================
alias tardir='echo "dirname=\"foo\";";echo "tar -czf \"\${dirname}.tar.gz\" \"\${dirname}\";";'

#====================================================
# Network related commands
#====================================================
alias ipaddr='ifconfig -a | grep -v "127.0.0.1" | egrep "\.[0-9]+\." | perl -p -n -e "s/^.*inet addr:([\d\.]+).*$/\$1/g"'
alias showip='ifconfig -a | grep -v "127.0.0.1" | egrep "\.[0-9]+\." | perl -p -n -e "s/^.*inet addr:([\d\.]+).*$/\$1/g"'
alias myip='ifconfig -a | grep -v "127.0.0.1" | egrep "\.[0-9]+\." | perl -p -n -e "s/^.*inet addr:([\d\.]+).*$/\$1/g"'
alias wanip='curl https://ipinfo.io/ip'
alias whatsmyip='curl https://ipinfo.io/ip'
alias publicip='curl https://ipinfo.io/ip'
alias pubip='curl https://ipinfo.io/ip'

alias mac='ifconfig -a|grep "HWaddr"| perl -p -n -e "s/^.*HWaddr ([a-f\d:]+).*$/\$1/g"'
alias macaddr='ifconfig -a|grep "HWaddr"| perl -p -n -e "s/^.*HWaddr ([a-f\d:]+).*$/\$1/g"'
alias showmac='ifconfig -a|grep "HWaddr"| perl -p -n -e "s/^.*HWaddr ([a-f\d:]+).*$/\$1/g"'
alias mymac='ifconfig -a|grep "HWaddr"| perl -p -n -e "s/^.*HWaddr ([a-f\d:]+).*$/\$1/g"'

alias netscan="sudo ls >/dev/null;echo -e '\nip addr\t\tmac addr\t\thostname\n=================================================';ETH0=\$(ifconfig | grep -P '^e\\w+0:' | sed 's/^\\(e[A-Za-z0-9]*0\\):.*\$/\\1/g');sudo arp-scan --localnet --interface=\"\$ETH0\" | grep -P '\\d\\.\\d\\.\\d' | sort";

alias stopsmb='sudo systemctl stop smbd; sudo systemctl stop nmbd;'
alias startsma'sudo systemctl start smbd; sudo systemctl start nmbd;'
alias restartsmb='sudo systemctl restart smbd; sudo systemctl restart nmbd;'

alias stopsamba='sudo systemctl stop smbd; sudo systemctl stop nmbd;'
alias startsamba='sudo systemctl start smbd; sudo systemctl start nmbd;'
alias restartsamba='sudo systemctl restart smbd; sudo systemctl restart nmbd;'

alias ufwoff='sudo ufw disable'
alias ufwon='sudo ufw enable'
alias ufwstat='sudo ufw status numbered'

alias nettype="internetType='ETHERNET';isVpnUp=\$(ifconfig -a|grep -P '^tun\d+: .*<.*\bUP\b'|wc -l); [[ '1' == \"\$isVpnUp\" ]] && internetType='VPN';echo \"Connected to internet via: \$internetType\""
alias connection="internetType='ETHERNET';isVpnUp=\$(ifconfig -a|grep -P '^tun\d+: .*<.*\bUP\b'|wc -l); [[ '1' == \"\$isVpnUp\" ]] && internetType='VPN';echo \"Connected to internet via: \$internetType\""
alias onvpn="internetType='ETHERNET';isVpnUp=\$(ifconfig -a|grep -P '^tun\d+: .*<.*\bUP\b'|wc -l); [[ '1' == \"\$isVpnUp\" ]] && internetType='VPN';echo \"Connected to internet via: \$internetType\""
alias vpn="internetType='ETHERNET';isVpnUp=\$(ifconfig -a|grep -P '^tun\d+: .*<.*\bUP\b'|wc -l); [[ '1' == \"\$isVpnUp\" ]] && internetType='VPN';echo \"Connected to internet via: \$internetType\""

#====================================================
# Multimedia related commands
#====================================================
alias ytdl="youtube-dl -f 'bestvideo[ext=mkv][height <=? 480]+bestaudio/bestvideo[ext=mp4][height <=? 480]+bestaudio/bestvideo+bestaudio/best' -o '%(title)s.%(ext)s' --restrict-filenames --quiet --no-warnings --ignore-errors --prefer-free-formats "
alias ytv="youtube-dl -f 'bestvideo[ext=mkv][height <=? 480]+bestaudio/bestvideo[ext=mp4][height <=? 480]+bestaudio/bestvideo+bestaudio/best' -o '%(title)s.%(ext)s' --restrict-filenames --quiet --no-warnings --ignore-errors --prefer-free-formats "
alias yt="youtube-dl -f 'bestvideo[ext=mkv][height <=? 480]+bestaudio/bestvideo[ext=mp4][height <=? 480]+bestaudio/bestvideo+bestaudio/best' -o '%(title)s.%(ext)s' --restrict-filenames --quiet --no-warnings --ignore-errors --prefer-free-formats "
alias yta="youtube-dl -f 'bestaudio[ext=mp3]/bestaudio[ext=m4a]/bestaudio[ext=ogg]/bestaudio' -o '%(title)s.%(ext)s' --restrict-filenames --quiet --no-warnings --ignore-errors --prefer-free-formats "
alias ytupdate="sudo youtube-dl -U";

alias ytvl="youtube-dl -f 'worst' -o '%(title)s.%(ext)s' --restrict-filenames --quiet --no-warnings --ignore-errors --prefer-free-formats "

alias ss='scrot --silent ~/Pictures/Screenshots/$(date +'%Y-%m-%d--%H%M%S').png';

alias ss2='scrot --delay 2 --silent --count ~/Pictures/Screenshots/$(date +'%Y-%m-%d--%H%M%S').png && echo "Saved to ~/Pictures/Screenshots/"';
alias ss3='scrot --delay 3 --silent --count ~/Pictures/Screenshots/$(date +'%Y-%m-%d--%H%M%S').png && echo "Saved to ~/Pictures/Screenshots/"';
alias ss4='scrot --delay 4 --silent --count ~/Pictures/Screenshots/$(date +'%Y-%m-%d--%H%M%S').png && echo "Saved to ~/Pictures/Screenshots/"';
alias ss5='scrot --delay 5 --silent --count ~/Pictures/Screenshots/$(date +'%Y-%m-%d--%H%M%S').png && echo "Saved to ~/Pictures/Screenshots/"';
alias ss6='scrot --delay 6 --silent --count ~/Pictures/Screenshots/$(date +'%Y-%m-%d--%H%M%S').png && echo "Saved to ~/Pictures/Screenshots/"';
alias ss7='scrot --delay 7 --silent --count ~/Pictures/Screenshots/$(date +'%Y-%m-%d--%H%M%S').png && echo "Saved to ~/Pictures/Screenshots/"';
alias ss8='scrot --delay 8 --silent --count ~/Pictures/Screenshots/$(date +'%Y-%m-%d--%H%M%S').png && echo "Saved to ~/Pictures/Screenshots/"';
alias ss9='scrot --delay 9 --silent --count ~/Pictures/Screenshots/$(date +'%Y-%m-%d--%H%M%S').png && echo "Saved to ~/Pictures/Screenshots/"';
alias ss10='scrot --delay 10 --silent --count ~/Pictures/Screenshots/$(date +'%Y-%m-%d--%H%M%S').png && echo "Saved to ~/Pictures/Screenshots/"';
alias ss15='scrot --delay 15 --silent --count ~/Pictures/Screenshots/$(date +'%Y-%m-%d--%H%M%S').png && echo "Saved to ~/Pictures/Screenshots/"';
alias ss20='scrot --delay 20 --silent --count ~/Pictures/Screenshots/$(date +'%Y-%m-%d--%H%M%S').png && echo "Saved to ~/Pictures/Screenshots/"';
alias ss25='scrot --delay 25 --silent --count ~/Pictures/Screenshots/$(date +'%Y-%m-%d--%H%M%S').png && echo "Saved to ~/Pictures/Screenshots/"';
alias ss30='scrot --delay 30 --silent --count ~/Pictures/Screenshots/$(date +'%Y-%m-%d--%H%M%S').png && echo "Saved to ~/Pictures/Screenshots/"';
alias ss35='scrot --delay 35 --silent --count ~/Pictures/Screenshots/$(date +'%Y-%m-%d--%H%M%S').png && echo "Saved to ~/Pictures/Screenshots/"';
alias ss40='scrot --delay 40 --silent --count ~/Pictures/Screenshots/$(date +'%Y-%m-%d--%H%M%S').png && echo "Saved to ~/Pictures/Screenshots/"';
alias ss45='scrot --delay 45 --silent --count ~/Pictures/Screenshots/$(date +'%Y-%m-%d--%H%M%S').png && echo "Saved to ~/Pictures/Screenshots/"';
alias ss50='scrot --delay 50 --silent --count ~/Pictures/Screenshots/$(date +'%Y-%m-%d--%H%M%S').png && echo "Saved to ~/Pictures/Screenshots/"';
alias ss55='scrot --delay 55 --silent --count ~/Pictures/Screenshots/$(date +'%Y-%m-%d--%H%M%S').png && echo "Saved to ~/Pictures/Screenshots/"';
alias ss60='scrot --delay 60 --silent --count ~/Pictures/Screenshots/$(date +'%Y-%m-%d--%H%M%S').png && echo "Saved to ~/Pictures/Screenshots/"';

alias scrot2='scrot --delay 2 --silent --count ~/Pictures/Screenshots/$(date +'%Y-%m-%d--%H%M%S').png && echo "Saved to ~/Pictures/Screenshots/"';
alias scrot3='scrot --delay 3 --silent --count ~/Pictures/Screenshots/$(date +'%Y-%m-%d--%H%M%S').png && echo "Saved to ~/Pictures/Screenshots/"';
alias scrot4='scrot --delay 4 --silent --count ~/Pictures/Screenshots/$(date +'%Y-%m-%d--%H%M%S').png && echo "Saved to ~/Pictures/Screenshots/"';
alias scrot5='scrot --delay 5 --silent --count ~/Pictures/Screenshots/$(date +'%Y-%m-%d--%H%M%S').png && echo "Saved to ~/Pictures/Screenshots/"';
alias scrot6='scrot --delay 6 --silent --count ~/Pictures/Screenshots/$(date +'%Y-%m-%d--%H%M%S').png && echo "Saved to ~/Pictures/Screenshots/"';
alias scrot7='scrot --delay 7 --silent --count ~/Pictures/Screenshots/$(date +'%Y-%m-%d--%H%M%S').png && echo "Saved to ~/Pictures/Screenshots/"';
alias scrot8='scrot --delay 8 --silent --count ~/Pictures/Screenshots/$(date +'%Y-%m-%d--%H%M%S').png && echo "Saved to ~/Pictures/Screenshots/"';
alias scrot9='scrot --delay 9 --silent --count ~/Pictures/Screenshots/$(date +'%Y-%m-%d--%H%M%S').png && echo "Saved to ~/Pictures/Screenshots/"';
alias scrot10='scrot --delay 10 --silent --count ~/Pictures/Screenshots/$(date +'%Y-%m-%d--%H%M%S').png && echo "Saved to ~/Pictures/Screenshots/"';
alias scrot15='scrot --delay 15 --silent --count ~/Pictures/Screenshots/$(date +'%Y-%m-%d--%H%M%S').png && echo "Saved to ~/Pictures/Screenshots/"';
alias scrot20='scrot --delay 20 --silent --count ~/Pictures/Screenshots/$(date +'%Y-%m-%d--%H%M%S').png && echo "Saved to ~/Pictures/Screenshots/"';
alias scrot25='scrot --delay 25 --silent --count ~/Pictures/Screenshots/$(date +'%Y-%m-%d--%H%M%S').png && echo "Saved to ~/Pictures/Screenshots/"';
alias scrot30='scrot --delay 30 --silent --count ~/Pictures/Screenshots/$(date +'%Y-%m-%d--%H%M%S').png && echo "Saved to ~/Pictures/Screenshots/"';
alias scrot35='scrot --delay 35 --silent --count ~/Pictures/Screenshots/$(date +'%Y-%m-%d--%H%M%S').png && echo "Saved to ~/Pictures/Screenshots/"';
alias scrot40='scrot --delay 40 --silent --count ~/Pictures/Screenshots/$(date +'%Y-%m-%d--%H%M%S').png && echo "Saved to ~/Pictures/Screenshots/"';
alias scrot45='scrot --delay 45 --silent --count ~/Pictures/Screenshots/$(date +'%Y-%m-%d--%H%M%S').png && echo "Saved to ~/Pictures/Screenshots/"';
alias scrot50='scrot --delay 50 --silent --count ~/Pictures/Screenshots/$(date +'%Y-%m-%d--%H%M%S').png && echo "Saved to ~/Pictures/Screenshots/"';
alias scrot55='scrot --delay 55 --silent --count ~/Pictures/Screenshots/$(date +'%Y-%m-%d--%H%M%S').png && echo "Saved to ~/Pictures/Screenshots/"';
alias scrot60='scrot --delay 60 --silent --count ~/Pictures/Screenshots/$(date +'%Y-%m-%d--%H%M%S').png && echo "Saved to ~/Pictures/Screenshots/"';

#====================================================
# Misc commands
#====================================================
alias cls='reset'
alias nocaps="SYM_GROUP_NAME='none';setxkbmap -layout us -option;setxkbmap -layout us -option caps:\${SYM_GROUP_NAME};gsettings set org.gnome.desktop.input-sources xkb-options \"['caps:\${SYM_GROUP_NAME}']\";"

alias c='clear'
alias l='ls -Ahclp1 --group-directories-first'

alias mkdir='mkdir -p'

#====================================================
# GIT
#====================================================
#git CLI commands without 'git' prefix
alias add='git add'
alias branch='git branch'
alias checkout='git checkout';
alias clone='git clone'
alias commit='git commit -m'
alias commita='git add -A; git commit -a -m'
alias commitall='git add -A; git commit -a -m'
#this would block /usr/bin/diff which is used for comparing files
#alias diff='git diff'
alias log='GIT_PAGER=cat git log --format="%H  %cn  %cd  %s" --date=format:"%Y-%m-%d %H:%M:%S"';
alias prune='git remote prune origin'
alias pull='git pull --all'
alias reflog='git reflog'
#this would block /usr/bin/stat which is used for determining filesizes
#alias stat='git status'

#git CLI abbreviated commands
alias ga='git add'
alias gaa='git add .'
alias gaaa='git add --all'
alias gadd='git add'
alias gau='git add --update'
alias gb='git branch'
alias gbd='git branch --delete '
alias gc='git commit'
alias gcm='git commit --message'
alias gco='git checkout'
alias gcob='git checkout -b'
alias gd='git diff'
alias gdiff='git diff'
alias gi='git init'
alias gl='GIT_PAGER=cat git log --format="%H  %cn  %cd  %s" --date=format:"%Y-%m-%d %H:%M:%S"';
alias glg='GIT_PAGER=cat git log --graph --oneline --decorate --all'
alias gld='GIT_PAGER=cat git log --pretty=format:"%h %ad %s" --date=short --all'
alias glog='GIT_PAGER=cat git log --format="%H  %cn  %cd  %s" --date=format:"%Y-%m-%d %H:%M:%S"';
alias gp='git pull --all'
alias gprune='git remote prune origin'
alias gpull='git pull --all'
alias greset='git reset --hard'
alias gss='git status --short'
alias gst='git status'
alias gstat='git status'

#git CLI commands without space
alias gitadd='git add'
alias gitclone='git clone'
alias gitcommit='git commit -m'
alias gitcommitall='git add -A; git commit -a -m'
alias gitdiff='git diff'
alias gitlog='GIT_PAGER=cat git log --format="%H  %cn  %cd  %s" --date=format:"%Y-%m-%d %H:%M:%S"';
alias gitprune='git remote prune origin'
alias gitpull='git pull --all'
alias gitreset='git reset --hard'
alias gitstat='git status'

#gitext (GUI) commands
alias browse='gitext';
alias ge='gitext';
alias gebrowse='gitext';
alias gecheckout='gitext checkoutbranch';
alias geclone='gitext clone';
alias gecommit='gitext commit';
alias gepull='gitext pull --all';
alias gestash='gitext stash';

#====================================================
# navigation
#====================================================
alias back='cd -'

alias h='cd ~/'
alias r='cd /'

alias @='nemo .'
alias explorer='nemo'

alias up='cd ..'
alias up1='cd ..'
alias up2='cd ../..'
alias up3='cd ../../..'
alias up4='cd ../../../..'
alias up5='cd ../../../../..'
alias up6='cd ../../../../../..'
alias up7='cd ../../../../../../..'
alias up8='cd ../../../../../../../..'
alias up9='cd ../../../../../../../../..'

#====================================================
# Handle my common typos / bad spelling
#====================================================
alias dc='cd'
alias ls-acl='ls -acl --group-directories-first'

alias echp='echo'
alias eco='echo'

# when I hit 'K' instead of 'L'
alias k='ls -Ahclp1 --group-directories-first'

alias qhich='which'
alias mna='man'
alias mzn='man'
alias mnt='mount'
alias umnt='umount'

alias fepw='grep'
alias gre[='grep'
alias grpe='grep'
alias greo='grep'
alias greio='grep'

