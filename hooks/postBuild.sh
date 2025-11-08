#some tasks run in the VM as soon as the vm is up


echo 'pkg_scripts=""' >>/etc/rc.conf.local


#openbsd doesn't support syspatch for riscv64
#https://cdn.openbsd.org/pub/OpenBSD/syspatch/7.8/
if [ "$(uname -m)" != "riscv64" ] || [ "$VM_RELEASE" != "7.8" ]; then
  sleep 20
  while ps aux | grep "[m]ake new"; do
    echo "reorder_kernel is running, just wait"
    sleep 5
  done
  
  echo "OK, start syspatch"
  
  syspatch
  syspatch
  
  ret="$?"
  #0 means ok
  #2 means no update
  if [ "$ret" != "2" ] && [ "$ret" != "0" ]; then
    echo "update error"
    ps aux
    exit $ret
  fi
fi








