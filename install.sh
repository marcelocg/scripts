#!/bin/sh
# POSIX

die() {
  printf '%s\n' "$1" >&2
  exit 1
}

show_help() {
  printf '%s\n'   "Installs MCG's most used apps and configs for development purposes."
  printf '%s\n\n' "Usage: sudo ./install.sh [OPTION]..."
  printf '%s\n'   "  -p,  --proxy IP     IP address of the proxy server."
  printf '%s\n'   "       --port  PORT   Port number used by the proxy server. Defaults to 3128."
  printf '%s\n\n' "       --vbox         Indicate this is a virtual machine running in VirtuaBox."
}

if [ ! "$(id -u)" -eq 0 ] ;then
  show_help
  die "Please run this script with: \$ sudo $0 $*"
fi

user_home="/home/$(logname)"
proxy_ip=
proxy_port="3128"
vbox=

while :; do
  case $1 in
    -h|-\?|--help)
        show_help            # Display usage instructions
        exit
        ;;
    -p|--proxy)              # Ensure option argument has been specified
        if [ "$2" ]; then
          proxy_ip=$2
          shift
        else
          die 'ERROR: "-p,  --proxy" requires a non-empty option argument.'
        fi
        ;;
    --proxy=?*)
        proxy_ip=${1#*=}     # Delete everything up to "=" and assign the remainder.
        ;;
    --proxy=)                # Handle the case of an empty --proxy=
        die 'ERROR: "--proxy" requires a non-empty option argument.'
        ;;
    --port)                  # Takes an option argument; ensure it has been specified.
        if [ "$2" ]; then
          proxy_port=$2
          shift
        else
          die 'ERROR: "--port" requires a non-empty option argument.'
        fi
        ;;
    --port=?*)
        proxy_port=${1#*=}   # Delete everything up to "=" and assign the remainder.
        ;;
    --port=)                 # Handle the case of an empty --port=
        die 'ERROR: "--port" requires a non-empty option argument.'
        ;;
    --vbox)
        vbox=1
        ;;
    --)                      # End of all options.
        shift
        break
        ;;
    -?*)
        printf 'WARN: Unknown option (ignored): %s\n' "$1" >&2
        ;;
    *)                       # Default case: No more options, so break out of the loop.
        break
  esac

  shift
done

proxy_address=
if [ "$proxy_ip" ]; then
  proxy_address="http://$proxy_ip:$proxy_port"
  # Global proxy
  echo "export http_proxy=$proxy_address"   >> /etc/profile
  echo "export https_proxy=$proxy_address" >> /etc/profile

  # Proxy for apt
  echo "Acquire::http::Proxy \"$proxy_address\";"   >> /etc/apt/apt.conf
  echo "Acquire::https::Proxy \"$proxy_address\";" >> /etc/apt/apt.conf
fi

if [ "$vbox" ]; then
  # Get the necessary permissions to read from/write to shared folders
  adduser $(logname) vboxsf
fi

# Update everything
apt update && apt upgrade -y --fix-missing && apt dist-upgrade -y && apt autoremove -y

# Install development basic stuff
apt install build-essential git -y

if [ "$proxy_address" ]; then
  # Proxy for Git
  git config --global http.proxy $proxy_address
  git config --global https.proxy $proxy_address
fi

# Terminal

## Install terminal stuff
apt install -y tmux zsh silversearcher-ag fonts-powerline fortune

## Download tmux dotfile
curl_proxy=

if [ "$proxy_address" ]; then
  curl_proxy="-x $proxy_address"
fi

curl -fsSL https://raw.githubusercontent.com/marcelocg/dotfiles/master/.tmux.conf $curl_proxy -o $user_home/.tmux.conf
chown $(logname):$(logname) $user_home/.tmux.conf

# Install tmux plugin manaeger
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

## Config user default shell
chsh -s $(which zsh) $(logname)

### Install Oh My ZSH
curl -fL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh $curl_proxy -o $user_home/install_oh-my-zsh.sh
chown $(logname):$(logname) $user_home/install_oh-my-zsh.sh
chmod +x $user_home/install_oh-my-zsh.sh
su - $(logname) -c "./install_oh-my-zsh.sh --unattended" # unattended avoids running zsh after script ends
rm -f $user_home/install_oh-my-zsh.sh

CUSTOM_ZSH_DIR="$user_home/.oh-my-zsh/custom"

git clone https://github.com/denysdovhan/spaceship-prompt.git $CUSTOM_ZSH_DIR/themes/spaceship-prompt
git clone https://github.com/zsh-users/zsh-autosuggestions.git $CUSTOM_ZSH_DIR/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $CUSTOM_ZSH_DIR/plugins/zsh-syntax-highlighting

ln -s $CUSTOM_ZSH_DIR/themes/spaceship-prompt/spaceship.zsh-theme $CUSTOM_ZSH_DIR/themes/spaceship.zsh-theme

curl -fsSL https://raw.githubusercontent.com/marcelocg/dotfiles/master/.zshrc $curl_proxy -o $user_home/.zshrc
curl -fsSL https://raw.githubusercontent.com/marcelocg/dotfiles/master/.aliases $curl_proxy -o $user_home/.aliases

chown -R $(logname):$(logname) $user_home

# Now things start to get serious

## Install VSCode
if [ "$proxy_address" ]; then
  snap set system proxy.http=$proxy_address
  snap set system proxy.https=$proxy_address
fi
snap install --classic code

## Install Node
curl -fsSL https://deb.nodesource.com/setup_12.x $curl_proxy -o $user_home/install_node_12.sh
chmod +x $user_home/install_node_12.sh
bash $user_home/install_node_12.sh
apt install -y nodejs
rm -f $user_home/install_node_12.sh

mkdir $user_home/.npm-global
npm config set prefix "$user_home/.npm-global"
echo "export PATH=$user_home/.npm-global/bin:$PATH" >> $user_home/.zshrc
export PATH=$user_home/.npm-global/bin:$PATH

npm i -g n
echo "export N_PREFIX=$user_home/.npm-global" >> $user_home/.zshrc
export N_PREFIX=$user_home/.npm-global
n lts
chown $(logname):$(logname) -R $user_home/.npm-global
