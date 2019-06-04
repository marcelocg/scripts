#!/bin/sh
# POSIX

die() {
  printf '%s\n' "$1" >&2
  exit 1
}

if [ ! "$(id -u)" -eq 0 ] ;then
  die "Please run this script with: \$ sudo $0 $*"
fi

printf '%s' "Are you behind a proxy (y/n)? "
old_stty_cfg=$(stty -g)
stty -icanon -echo

# waiting explicitly for y or n:
behind_proxy=$( while ! head -c 1 | grep -i '[ny]' ;do true ;done )

if [ "$behind_proxy" != "${behind_proxy#[Yy]}" ] ;then
  printf '\n\r%s' "Is this a Virtual Machine (y/n)? "
  vm=$( while ! head -c 1 | grep -i '[ny]' ;do true ;done )

  if [ "$vm" != "${vm#[Yy]}" ] ;then
    printf '\n\r%s' "VM(W)are or Virtual(B)ox (W/w/B/b)? "
    hypervisor=$( while ! head -c 1 | grep -i '[bw]' ;do true ;done )

    # I use CNTLM or px proxy at the host machine
    proxy_port="3128"

    if [ "$hypervisor" != "${hypervisor#[Ww]}" ] ;then
      proxy_ip="192.168.146.1" #VirtualBox
    else
      proxy_ip="192.168.56.1"  #VMWare
    fi
    stty $old_stty_cfg

  else # not a VM
    stty $old_stty_cfg
    printf '\n\r%s' "Please enter the proxy server IP address: "
    read -r proxy_ip
    printf '\n\r%s' "Please enter the proxy server port number: "
    read -r proxy_port
  fi

  printf '\n\r%s' "Defining global proxy IP and port as $proxy_ip:$proxy_port"
  #echo "export http_proxy=http://$proxy_ip:3128" >> /etc/profile
  #echo "export https_proxy=https://$proxy_ip:3128" >> /etc/profile

else
  stty $old_stty_cfg
  printf '\n\r%s\n' "Ok, no proxy then! Going ahead."
fi
