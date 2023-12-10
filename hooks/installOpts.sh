
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

