#some tasks run in the VM as soon as the vm is up


echo 'pkg_scripts=""' >>/etc/rc.conf.local

sleep 20
while ps aux | grep "[m]ake new"; do
  echo "reorder_kernel is running, just wait"
  sleep 5
done

echo "OK, start syspatch"

syspatch


ret="$?"
#0 means ok
#2 means no update
if [ "$ret" != "2" ] && [ "$ret" != "0" ]; then
  echo "update error"
  ps aux
  exit $ret
fi









