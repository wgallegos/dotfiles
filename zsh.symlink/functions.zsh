# Test whether a given command exists
# Adapted from http://stackoverflow.com/questions/592620/check-if-a-program-exists-from-a-bash-script/3931779#3931779
# NOTE: This function is duplicated in .zshrc so that it doesn't have to depend on this file,
# but this shouldn't cause any issues
function command_exists() {
  hash "$1" &> /dev/null
}

# Search for files by name
# Case-insensitive and allows partial search
# If on Mac OS X, will prompt to open the file if there is a single result
function search() {
  results=`find . -iname "*$1*"`
  echo $results
  if command_exists open; then
    resultLength=`echo $results | wc -l |  sed -e "s/^[ \t]*//"`
    if [ $resultLength -eq 1 ]; then
      while true; do
        echo "One result found! Open it? (y/n)?"
        read yn
        case $yn in
          [Yy]* ) open $results; break;;
          [Nn]* ) break;;
          * ) echo "Please answer (Y/y)es or (N/n)o.";;
        esac
      done
    fi
  fi
}

# To search for a given string inside every file with the given filename
# (wildcards allowed) in the current directory, recursively:
#   $ searchin filename pattern
#
# To search for a given string inside every file inside the current directory, recursively:
#   $ searchin pattern
function searchin() {
  if [ -n "$2" ]; then
    find . -name "$1" -type f -exec grep -l "$2" {} \;
  else
    find . -type f -exec grep -l "$1" {} \;
  fi
}

# Serves the current directory over HTTP, on an optionally-specified port
# If on Mac OS X, opens in the default browser
function serve() {
  port=$1
  if [ $# -ne  1 ]; then
    port=8000
  fi
  if command_exists open; then
    open http://localhost:$port/
  fi
  python -m SimpleHTTPServer $port
}

# Performs a system update on Debian-based and Arch Linux systems, updates Homebrew packages on OS X, updates all Git submodules
function update() {
  if command_exists apt-get; then
    echo "Updating packages via apt-get..."
    sudo apt-get update
    sudo apt-get upgrade
  elif command_exists pacman; then
    echo "Upadting packages via pacman..."
    sudo pacman -Syu
  fi

  # If the dotfiles location isn't the home directory,
  # assume it's a Git repository and update it and all submodules.
  local DOTFILES_LOCATION=${$(readlink ~/.zshrc)%/*.*}
  if [ $DOTFILES_LOCATION != $HOME ] && command_exists git; then
    pushd -q
    cd $DOTFILES_LOCATION
    echo "Updating dotfiles..."
    git pull
    echo "Updating git submodules..."
    # Adapted from code found at <http://stackoverflow.com/questions/1030169/git-easy-way-pull-latest-of-all-submodules>
    git submodule foreach 'git checkout master &> /dev/null; git checkout . &> /dev/null; git pull origin master'
    popd -q
  fi

  if command_exists brew; then
    echo "Updating/upgrading/cleaning up Homebrew packages..."
    brew update && brew upgrade && brew cleanup && brew linkapps
  fi
}

# On Mac OS X, SSH to another Mac by hostname via Back To My Mac (iCloud)
# The client and target machines must both have Back To My Mac enabled
# Adapted from code found at <http://onethingwell.org/post/27835796928/remote-ssh-bact-to-my-mac>
function sshicloud() {
  if [[ $# -eq 0 || $# -gt 2 ]]; then
    echo "Usage: $0 hostname [username]"
  elif ! command_exists scutil; then
    echo "$0 only works on Mac OS X! Aborting."
  else
    local _icloud_addr=`echo show Setup:/Network/BackToMyMac | scutil | sed -n 's/.* : *\(.*\).$/\1/p'`
    local _username=`whoami`
    if [[ $# -eq 2 ]]; then
      _username=$2
    fi
    ssh $_username@$1.$_icloud_addr
  fi
}

# Pushes local SSH public key to another box
# Adapted from code found at <https://github.com/rtomayko/dotfiles/blob/rtomayko/.bashrc>
function push_ssh_cert() {
  if [[ $# -eq 0 || $# -gt 3 ]]; then
    echo "Usage: push_ssh_cert host [port] [username]"
    return
  fi
  local _host=$1
  local _port=22
  local _user=$USER
  if [[ $# -ge 2 ]]; then
    _port=$2
  fi
  if [[ $# -eq 3 ]]; then
    _user=$3
  fi
  test -f ~/.ssh/id_dsa.pub || ssh-keygen -t dsa
  echo "Pushing public key to $_user@$_host:$_port..."
  ssh -p $_port $_user@$_host 'mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys' < ~/.ssh/id_*sa.pub
}

# Extracts archives
# Found at <http://pastebin.com/CTra4QTF>
function extract() {
  case $@ in
    *.tar.bz2) tar -xvjf "$@"  ;;
    *.tar.gz)  tar -xvzf "$@"  ;;
    *.bz2)     bunzip2 "$@"  ;;
    *.rar)     unrar x "$@"  ;;
    *.gz)      gunzip "$@" ;;
    *.tar)     tar xf "$@" ;;
    *.tbz2)    tar -xvjf "$@"  ;;
    *.tgz)     tar -xvzf "$@"  ;;
    *.zip)     unzip "$@"    ;;
    *.xpi)     unzip "$@"    ;;
    *.Z)       uncompress "$@" ;;
    *.7z)      7z x "$@" ;;
    *.ace)     unace e "$@"  ;;
    *.arj)     arj -y e "$@" ;;
    *)         echo "'$@' cannot be extracted via $0()" ;;
  esac
}

# Packs $2-$n into $1 depending on $1's extension
# Found at <http://pastebin.com/CTra4QTF>
function compress() {
  if [ $# -lt 2 ] ; then
    echo -e "\n$0() usage:"
    echo -e "\t$0 archive_file_name file1 file2 ... fileN"
    echo -e "\tcreates archive of files 1-N\n"
  else
    DEST=$1
    shift
    case $DEST in
      *.tar.bz2) tar -cvjf $DEST "$@" ;;
      *.tar.gz)  tar -cvzf $DEST "$@" ;;
      *.zip)     zip -r $DEST "$@" ;;
      *)         echo "Unknown file type - $DEST" ;;
    esac
  fi
}

# Poor-man's pgrep, for use on OS X where pgrep isn't available
function poorpgrep() {
  echo "Warning: using poor-man's pgrep. Consider installing the \"proctools\" package via Homebrew."
  ps ax | awk "/(^|[^)])$1/ { print \$1 }"
}

# Poor man's tree, for use on OS X where tree isn't available
function poortree() {
  echo "Warning: using poor-man's tree. Consider installing the \"tree\" package via Homebrew."
  ls -R | grep ":$" | sed -e 's/:$//' -e 's/[^-][^\/]*\//--/g' -e 's/^/   /' -e 's/-/|/'
}

# Shows how long processes have been up.
# No arguments shows all processes, one argument greps for a particular process.
# Found at <http://hints.macworld.com/article.php?story=20121127064752309>
function psup() {
  ps acxo etime,command | grep -- "$1"
}

# mkdir and cd into it - supports hierarchies and spaces
# Found at <http://onethingwell.org/post/586977440/mkcd-improved>
function mkcd() {
  mkdir -p "$*"
  cd "$*"
}

# Show useful information about domain names using dig.
# Found at <https://github.com/mathiasbynens/dotfiles/blob/master/.functions>
function digit() {
  dig +nocmd "$1" any +multiline +noall +answer
}

# Retrieve dictionary definitions of words.
# Adapted from code found at <http://onethingwell.org/post/25644890287/a-shell-function-to-define-words>
function define() {
  if [[ $# -ge 2 ]] then
    echo "$0: too many arguments" >&2
    return 1
  else
    curl "dict://dict.org/d:$1"
  fi
}

# Copy dotfiles to one or more remote machines.
function sync_home() {
  local DOTFILES_LOCATION=${$(readlink ~/.zshrc)%/*.*}
  if [ "$DOTFILES_LOCATION" = "$HOME" ]; then
    echo "$0 can only operate from inside a self-contained dotfiles repository."
    echo "It's likely that $0 was used to sync dotfiles to this machine."
    echo "Exiting."
    return 1
  fi

  test -z "$1" || echo "$@" | grep -q -- '--help' && {
    echo "Usage: $0 [user@]host ..."
    return 1
  }

  for host in "$@"; do
    echo "Now syncing: $host"
    rsync -avzL --exclude ".git*" --exclude "README.md" --exclude "install.sh" "$DOTFILES_LOCATION" "${host}:"
  done
}