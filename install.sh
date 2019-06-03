#!/bin/sh

echo -n "Are you behind a proxy (y/n)? "
old_stty_cfg=$(stty -g)
stty raw -echo

# waiting explicitly for y or n:
behind_proxy=$( while ! head -c 1 | grep -i '[ny]' ;do true ;done )

if [ "$behind_proxy" != "${behind_proxy#[Yy]}" ] ;then
  echo -n "\n\rIs this a Virtual Machine (y/n)? "
  vm=$( while ! head -c 1 | grep -i '[ny]' ;do true ;done )

  if [ "$vm" != "${vm#[Yy]}" ] ;then
    echo -n "\n\rVM(W)are or Virtual(B)ox (W/w/B/b)? "
    hypervisor=$( while ! head -c 1 | grep -i '[bw]' ;do true ;done )

    # I use CNTLM or px proxy at the host machine
    if [ "$hypervisor" != "${hypervisor#[Ww]}" ] ;then
      proxy_ip="192.168.146.1"
    else
      proxy_ip="192.168.56.1"
    fi
    stty $old_stty_cfg
    echo "\n\r$proxy_ip"
    #sudo export https_proxy=http://$proxy_ip:3128 >> /etc/profile
    #sudo export http_proxy=http://$proxy_ip:3128 >> /etc/profile
  else # not a VM
    # next version will ask for an IP address to set as proxy
    stty $old_stty_cfg
    echo "\n\rWill ask  for an IP in the near future"
  fi
else
  stty $old_stty_cfg
  echo "\n\rOk, no proxy then! Going ahead."
fi
