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

vboxlink="$VM_VBOX_LINK"


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
  wget -O "$vmsh" "$vboxlink"
fi

chmod +x "$vmsh"


$vmsh addSSHHost  $osname $sshport



$vmsh setup 

if ! $vmsh clearVM $osname; then
  echo "vm does not exists"
fi

$vmsh createVM  $VM_ISO_LINK $osname $ostype $sshport



$vmsh startWeb $osname



$vmsh startCF


_sleep=20
echo "Sleep $_sleep seconds, please open the link in your browser."
sleep $_sleep

$vmsh startVM $osname

sleep 2


$vmsh  processOpts  $osname  "$opts"



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




echo '

sed -i "s/PermitRootLogin no/PermitRootLogin yes/" /etc/ssh/sshd_config

sed -i "s/#PermitEmptyPasswords no/PermitEmptyPasswords yes/" /etc/ssh/sshd_config

sed -i "s/#PubkeyAuthentication no/PubkeyAuthentication yes/" /etc/ssh/sshd_config


echo "AcceptEnv   *"  >> /etc/ssh/sshd_config

mkdir -p ~/.ssh

chmod -R 600 ~/.ssh

ssh-keygen -t rsa -f ~/.ssh/id_rsa -q -N ""

echo "StrictHostKeyChecking=accept-new" >>~/.ssh/config




' >enablessh.txt


echo "echo '$(base64 ~/.ssh/id_rsa.pub)' | openssl base64 -d >>~/.ssh/authorized_keys" >>enablessh.txt


echo >>enablessh.txt
echo >>enablessh.txt
echo >>enablessh.txt


$vmsh inputFile $osname enablessh.txt

###############################################################


ssh $osname 'cat ~/.ssh/id_rsa.pub' >id_rsa.pub


ssh $osname  "/sbin/shutdown -p now"

sleep 5

###############################################################

$vmsh shutdownVM $osname


##############################################################


ova="$VM_OVA_NAME.ova"

$vmsh exportOVA $osname "$ova"

cp ~/.ssh/id_rsa  mac.id_rsa

zip -0 -s 2000m $ova.zip  $ova id_rsa.pub mac.id_rsa




