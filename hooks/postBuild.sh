#some tasks run in the VM as soon as the vm is up


echo 'pkg_scripts=""' >>/etc/rc.conf.local



syspatch

ret="$?"
#0 means ok
#2 means no update
if [ "$ret" != "2" ] && [ "$ret" != "0" ]; then
  echo "update error"
  exit $ret
fi






