#some tasks run in the VM as soon as the vm is up


echo 'pkg_scripts=""' >>/etc/rc.conf.local


while ps aux | grep "[m]ake newbsd"; do
  echo "reorder_kernel is running, just wait"
  sleep 5
done

echo "OK, start syspatch"
sleep 10

syspatch


ret="$?"
#0 means ok
#2 means no update
if [ "$ret" != "2" ] && [ "$ret" != "0" ]; then
  echo "update error"
  ps aux
  exit $ret
fi









