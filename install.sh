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

if [ "$proxy_ip" ]; then
  # Global proxy
  echo "export http_proxy=http://$proxy_ip:$proxy_port"   >> /etc/profile
  echo "export https_proxy=https://$proxy_ip:$proxy_port" >> /etc/profile

  # Proxy for apt
  echo "Acquire::http::Proxy \"http://$proxy_ip:$proxy_port\";"   >> /etc/apt/apt.conf
  echo "Acquire::https::Proxy \"https://$proxy_ip:$proxy_port\";" >> /etc/apt/apt.conf
fi

if [ "$vbox" ]; then
  # Get the necessary permissions to read from/write to shared folders
  adduser $(logname) vboxsf
fi

# Update everything
# apt update && sudo apt upgrade -y --fix-missing && sudo apt dist-upgrade -y && sudo apt autoremove -y

# Install development basic stuff
# apt install build-essential git -y

if [ "$proxy_ip" ]; then
  # Proxy for Git
  git config --global http.proxy http://$proxy_ip:$proxy_port
  git config --global https.proxy https://$proxy_ip:$proxy_port
fi

# Terminal

## Install terminal stuff
apt install -y tmux zsh silversearcher-ag fonts-powerline

## Download tmux dotfile
curl_proxy=
if [ "$proxy_ip" ]; then
  curl_proxy="-x https://$proxy_ip:$proxy_port"
fi
curl https://raw.githubusercontent.com/marcelocg/dotfiles/master/.tmux.conf $curl_proxy #-o ~/.tmux.conf

## Config the shell
chsh -s $(which zsh) $(logname)
