#!/bin/sh
# POSIX

GIT_USERNAME="Marcelo Goncalves"                     
GIT_EMAIL="marcelocg@gmail.com"

JAVA_VERSION="14"
NODE_VERSION="14"

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
apt install build-essential git docker.io -y

# Config git
git config --global user.name $GIT_USERNAME
git config --global user.email $GIT_EMAIL

# Config docker
systemctl enable --now docker
usermod -aG docker $(logname)

if [ "$proxy_address" ]; then
  # Proxy for Git
  git config --global http.proxy $proxy_address
  git config --global https.proxy $proxy_address
fi

curl_proxy=
if [ "$proxy_address" ]; then
  curl_proxy="-x $proxy_address"
fi

## Install terminal stuff
apt install -y sakura tmux zsh silversearcher-ag fortune

curl -fsSL https://raw.githubusercontent.com/marcelocg/dotfiles/master/.config/sakura/sakura.conf $curl_proxy -o $user_home/.config/sakura/sakura.conf
chown $(logname):$(logname) $user_home/.config/sakura/sakura.conf

curl -fsSL https://raw.githubusercontent.com/marcelocg/dotfiles/master/.tmux.conf $curl_proxy -o $user_home/.tmux.conf
chown $(logname):$(logname) $user_home/.tmux.conf

# Install tmux plugin manaeger
git clone https://github.com/tmux-plugins/tpm $user_home/.tmux/plugins/tpm

## Config user default shell
chsh -s $(which zsh) $(logname)

### Install Oh My ZSH
curl -fL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh $curl_proxy -o $user_home/install_oh-my-zsh.sh
chown $(logname):$(logname) $user_home/install_oh-my-zsh.sh
chmod +x $user_home/install_oh-my-zsh.sh
su - $(logname) -c "./install_oh-my-zsh.sh --unattended" # unattended avoids running zsh after script ends
rm -f $user_home/install_oh-my-zsh.sh

CUSTOM_ZSH_DIR="$user_home/.oh-my-zsh/custom"

# Powerlevel10k oh-my-zsh theme
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git $CUSTOM_ZSH_DIR/themes/powerlevel10k

# Download Powerlevel10k theme recommended custom fonts
mkdir -p /usr/local/share/fonts
curl -fL https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Regular.ttf $curl_proxy -o /usr/local/share/fonts/MesloLGSNFRegular.ttf
curl -fL https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold.ttf $curl_proxy -o /usr/local/share/fonts/MesloLGSNFBold.ttf
curl -fL https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Italic.ttf $curl_proxy -o /usr/local/share/fonts/MesloLGSNFItalic.ttf
curl -fL https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold%20Italic.ttf $curl_proxy -o /usr/local/share/fonts/MesloLGSNFBoldItalic.ttf
# update fonts cache
fc-cache -f -v

# zsh plugins
git clone https://github.com/zsh-users/zsh-autosuggestions.git $CUSTOM_ZSH_DIR/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $CUSTOM_ZSH_DIR/plugins/zsh-syntax-highlighting

# zsh config files
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

## Install Node Current
curl -fsSL https://deb.nodesource.com/setup_$NODE_VERSION.x $curl_proxy -o $user_home/install_node_$NODE_VERSION.sh
sed -i "+s+curl -s+curl $curl_proxy -s+" $user_home/install_node_$NODE_VERSION.sh
chmod +x $user_home/install_node_$NODE_VERSION.sh
bash $user_home/install_node_$NODE_VERSION.sh
apt install -y nodejs
rm -f $user_home/install_node_$NODE_VERSION.sh

npm config set proxy $proxy_address
npm config set https-proxy $proxy_address

mkdir $user_home/.npm-global
npm config set prefix "$user_home/.npm-global"
sed -i "s_PATH=_PATH=$user_home/.npm-global/bin:_" $user_home/.zshrc
export PATH=$user_home/.npm-global/bin:$PATH

### Install Node version manager
npm i -g n
echo "export N_PREFIX=$user_home/.npm-global" >> $user_home/.zshrc
export N_PREFIX=$user_home/.npm-global

#### Install the LTS version of Node and set it as default
HTTP_PROXY=$proxy_address HTTPS_PROXY=$proxy_address n lts

chown $(logname):$(logname) -R $user_home/.npm-global
chown $(logname):$(logname) -R $user_home/.npm

## Install Java
mkdir -p $user_home/java
curl -fL "https://api.adoptopenjdk.net/v2/binary/releases/openjdk$JAVA_VERSION?openjdk_impl=hotspot&os=linux&arch=x64&release=latest&type=jdk" $curl_proxy -o $user_home/open_jdk_$JAVA_VERSION.tar.gz
tar -xf open_jdk_$JAVA_VERSION.tar.gz -C $user_home/java
rm -f open_jdk_$JAVA_VERSION.tar.gz
JAVA_HOME=$user_home/java/$(ls $user_home/java)
echo "export JAVA_HOME=$JAVA_HOME" >> $user_home/.zshrc
sed -i "s_PATH=_PATH=$JAVA_HOME/bin:_" $user_home/.zshrc
export PATH=$JAVA_HOME/bin:$PATH
chown $(logname):$(logname) -R $user_home/java
