
waitForText "nstall, ("

$vmsh string a
$vmsh enter


waitForText "Response file location"
$vmsh string "http://192.168.122.1:8000/$VM_OPTS"
$vmsh enter

sleep 2
waitForText "nstall or"

$vmsh string i
$vmsh enter

if [ "$VM_ARCH" = "aarch64" ] && [ "$VM_USE_CONSOLE_BUILD" ]; then
  #for openbsd 7.3/4,  it will reboot after the install.
  #but for 7.5/6, it will just shutdown after install,  so we force it to shutdown for 7.3/4 here.
  waitForText "Your OpenBSD install has been successfully completed"
  if $vmsh isRunning $VM_OS_NAME; then
    if ! $vmsh shutdownVM $VM_OS_NAME; then
      echo "shutdown error"
    fi
    if ! $vmsh destroyVM $VM_OS_NAME; then
      echo "destroyVM error"
    fi
  fi
fi


if [ "$VM_ARCH" = "riscv64" ]; then
  waitForText "Your OpenBSD install has been successfully completed"
  #halt
  $vmsh string h
  $vmsh enter
  sleep 10
  if $vmsh isRunning $VM_OS_NAME; then
    if ! $vmsh shutdownVM $VM_OS_NAME; then
      echo "shutdown error"
    fi
    if ! $vmsh destroyVM $VM_OS_NAME; then
      echo "destroyVM error"
    fi
  fi
fi

