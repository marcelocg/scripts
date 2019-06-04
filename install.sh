#!/bin/sh
# POSIX

die() {
  printf '%s\n' "$1" >&2
  exit 1
}

show_help() {
  printf '%s\n'   "Installs MCG's most used apps and configs for development purposes."
  printf '%s\n\n' "Usage: sudo ./install.sh [OPTION]..."
  printf '%s\n'   "  -p,  --proxy IP     IP address of the proxy server"
  printf '%s\n\n'   "       --port  PORT   Port number used by the proxy server. Defaults to 3128."
}

if [ ! "$(id -u)" -eq 0 ] ;then
  show_help
  die "Please run this script with: \$ sudo $0 $*"
fi

proxy_ip=
proxy_port="3128"

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

# Update everything
sudo apt update && sudo apt upgrade -y --fix-missing && sudo apt dist-upgrade -y && sudo apt autoremove -y
