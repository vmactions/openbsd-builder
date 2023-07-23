#!/usr/bin/env bash

set -e


_conf="$1"

if [ -z "$_conf" ] ; then
  echo "Please give the conf file"
  exit 1
fi


. "$_conf"


##############################################################
osname="$VM_OS_NAME"
ostype="$VM_OS_TYPE"
sshport=$VM_SSH_PORT


opts="$VM_OPTS"

vboxlink="${SEC_VBOX:-$VM_VBOX_LINK}"


vmsh="$VM_VBOX"


export VM_OS_NAME



##############################################################


waitForText() {
  _text="$1"
  $vmsh waitForText $osname "$_text"
}

#keys splitted by ;
#eg:  enter
#eg:  down; enter
#eg:  down; up; tab; enter


inputKeys() {
  $vmsh input $osname "$1"
}



if [ ! -e "$vmsh" ] ; then
  echo "Downloading $vboxlink"
  wget -O "$vmsh" "$vboxlink"
fi

chmod +x "$vmsh"


$vmsh addSSHHost  $osname $sshport



$vmsh setup 

if ! $vmsh clearVM $osname; then
  echo "vm does not exists"
fi

$vmsh createVM  $VM_ISO_LINK $osname $ostype $sshport

# Enable multi-processor so that the MP kernel gets installed.
$vmsh setCPU $osname 2


$vmsh startWeb $osname



$vmsh startCF


_sleep=20
echo "Sleep $_sleep seconds, please open the link in your browser."
sleep $_sleep

$vmsh startVM $osname

sleep 2


waitForText "$VM_LOGIN_TAG"

waitForText "Install, ("

$vmsh string s
$vmsh enter

$vmsh uploadFile $osname $VM_OPTS "/tmp/i/install.resp"

$vmsh string autoinstall
$vmsh enter



$vmsh shutdownVM $osname


$vmsh detachISO $osname

$vmsh startVM $osname



###############################################



waitForText "$VM_LOGIN_TAG"

sleep 10

waitForText "logi"


$vmsh enter  $osname
sleep 1

$vmsh enter  $osname
sleep 1

$vmsh enter  $osname
sleep 1

$vmsh enter  $osname
sleep 1

inputKeys "string root ; enter ; string openbsd ; enter"


cat enablessh.txt >enablessh.local


#add ssh key twice, to avoid bugs.
echo "echo '$(base64 ~/.ssh/id_rsa.pub)' | openssl base64 -d >>~/.ssh/authorized_keys" >>enablessh.local
echo "" >>enablessh.local

echo "echo '$(cat ~/.ssh/id_rsa.pub)' >>~/.ssh/authorized_keys" >>enablessh.local
echo "" >>enablessh.local


echo >>enablessh.local
echo "chmod 600 ~/.ssh/authorized_keys">>enablessh.local
echo "exit">>enablessh.local
echo >>enablessh.local


$vmsh inputFile $osname enablessh.local

ssh $osname sh <<EOF
echo 'StrictHostKeyChecking=accept-new' >.ssh/config

echo "Host host" >>.ssh/config
echo "     HostName  10.0.2.2" >>.ssh/config
echo "     User runner" >>.ssh/config
echo "     ServerAliveInterval 1" >>.ssh/config

EOF


###############################################################


if [ -e "hooks/postBuild.sh" ]; then
  echo "hooks/postBuild.sh"
  cat "hooks/postBuild.sh"
  ssh $osname sh<"hooks/postBuild.sh"
fi


ssh $osname 'cat ~/.ssh/id_rsa.pub' >$osname-$VM_RELEASE-id_rsa.pub


if [ "$VM_PRE_INSTALL_PKGS" ]; then
  echo "$VM_INSTALL_CMD $VM_PRE_INSTALL_PKGS"
  ssh $osname sh <<<"$VM_INSTALL_CMD $VM_PRE_INSTALL_PKGS"
fi

ssh $osname  "$VM_SHUTDOWN_CMD"

sleep 5

###############################################################

$vmsh shutdownVM $osname


##############################################################




ova="$osname-$VM_RELEASE.ova"


echo "Exporting $ova"
$vmsh exportOVA $osname "$ova"

cp ~/.ssh/id_rsa  $osname-$VM_RELEASE-mac.id_rsa


ls -lah





