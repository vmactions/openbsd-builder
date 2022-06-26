const core = require('@actions/core');
const exec = require('@actions/exec');
const tc = require('@actions/tool-cache');
const io = require('@actions/io');
const fs = require("fs");
const path = require("path");


async function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms))
}


async function vboxmanage(imgName, cmd, args = "") {
  await exec.exec("sudo  vboxmanage " + cmd + "   " + imgName + "   " + args);
}

async function pressEnter(imgName) {
  await vboxmanage(imgName, "controlvm", "keyboardputscancode 1c 9c");//Press Enter
}


async function getScreenText(imgName) {
  let png = path.join(__dirname, "/screen.png");
  await vboxmanage(imgName, "controlvm", "screenshotpng  " + png);
  await exec.exec("sudo chmod 666 " + png);
  let output = "";
  await exec.exec("pytesseract  " + png, [], {
    listeners: {
      stdout: (s) => {
        output += s;
      }
    }
  });
  return output;
}

async function waitFor(imgName, tag, timeout=300) {

  let slept = 0;
  while (true) {
    slept += 1;
    if (slept >= timeout) {
      return false
    }
    await sleep(1000);

    let output = await getScreenText(imgName);

    if (tag) {
      if (output.includes(tag)) {
        core.info("OK");
        await sleep(1000);
        return true;
      } else {
        core.info("Checking, please wait....");
      }
    } else {
      if (!output.trim()) {
        core.info("OK");
        return true;
      } else {
        core.info("Checking, please wait....");
      }
    }

  }

  return false;
}

// most @actions toolkit packages have async methods
async function run() {
  try {

    let sshport = 2223;
    fs.appendFileSync(path.join(process.env["HOME"], "/.ssh/config"), "Host openbsd " + "\n");
    fs.appendFileSync(path.join(process.env["HOME"], "/.ssh/config"), " User root" + "\n");
    fs.appendFileSync(path.join(process.env["HOME"], "/.ssh/config"), " HostName localhost" + "\n");
    fs.appendFileSync(path.join(process.env["HOME"], "/.ssh/config"), " Port " + sshport + "\n");
    fs.appendFileSync(path.join(process.env["HOME"], "/.ssh/config"), "StrictHostKeyChecking=accept-new\n");


    if (process.env["DEBUG"]) {
      await exec.exec("brew install --cask virtualbox-extension-pack");

      let ng = await tc.downloadTool("https://bin.equinox.io/c/4VmDzA7iaHb/ngrok-stable-darwin-amd64.zip");

      let token = process.env["NGROK_TOKEN"];
      await io.mv(ng, "./ngrok-stable-darwin-amd64.zip");
      await exec.exec("unzip -o ngrok-stable-darwin-amd64.zip");
      await exec.exec("./ngrok authtoken " + token);
      exec.exec("./ngrok  tcp   3390").catch((e) => {
        //
      });
    }


    core.info("Install tesseract");
    await exec.exec("brew install tesseract");
    await exec.exec("pip3 install pytesseract");


    let rootPassword = "vmactions.org";
    let imgName = "openbsd";
    let iso = imgName + ".iso";

    let part0 = "https://cdn.openbsd.org/pub/OpenBSD/6.9/amd64/install69.iso";


    {
      core.info("Downloading image: " + part0);
      let img = await tc.downloadTool(part0);
      core.info("Downloaded file: " + img);
      await io.mv(img, "./" + iso);

    }


    core.info("Create VM");

    let vhd = imgName + ".vdi";
    await exec.exec("sudo vboxmanage  createhd --filename " + vhd + " --size 100000");

    await exec.exec("sudo vboxmanage  createvm  --name " + imgName + " --ostype OpenBSD_64  --default   --basefolder openbsd --register");

    //await vboxmanage(imgName, "storagectl", "  --name SATA --add sata  --controller IntelAHCI ")
    await vboxmanage(imgName, "storageattach", "    --storagectl IDE --port 0  --device 1  --type hdd --medium " + vhd);

    await vboxmanage(imgName, "storageattach", "    --storagectl IDE --port 0  --device 0  --type dvddrive  --medium " + iso);

    //await vboxmanage(imgName, "modifyvm ", " --ioapic on");
    await vboxmanage(imgName, "modifyvm ", " --boot1 dvd --boot2 disk --boot3 none --boot4 none");


    await vboxmanage(imgName, "modifyvm ", " --vrde on  --vrdeport 3390");

    await vboxmanage(imgName, "modifyvm ", "  --natpf1 'guestssh,tcp,," + sshport + ",,22'");

    await vboxmanage(imgName, "startvm", " --type headless");

    await waitFor(imgName, "Install, (Upgrade, (A)utoinstall");
    await sleep(1000);
    await vboxmanage(imgName, "controlvm", "keyboardputscancode 17 97");//Press I
    await pressEnter(imgName);

    await sleep(1000); //choose the keyboard layout
    await pressEnter(imgName);


    //hostname
    await waitFor(imgName, "System hostname");
    await sleep(1000);
    await vboxmanage(imgName, "controlvm", "keyboardputstring  " + imgName);
    await sleep(1000);
    await pressEnter(imgName);


    //em0
    await waitFor(imgName, "Which network interface do you wish to configure");
    await sleep(1000);
    await pressEnter(imgName);

    //IPv4
    await waitFor(imgName, "IPv4 address for");
    await sleep(1000);
    await pressEnter(imgName);


    //IPv6
    await waitFor(imgName, "autoconf");
    await sleep(1000);
    await pressEnter(imgName);


    await waitFor(imgName, "Which network interface do you wish to configure");
    await sleep(1000);
    await pressEnter(imgName);

    if (await waitFor(imgName, "DNS domain name", 10)) {
      await sleep(1000);
      await pressEnter(imgName);
    }


    await waitFor(imgName, "Password for root");
    await sleep(1000);
    await vboxmanage(imgName, "controlvm", "keyboardputstring  " + rootPassword);
    await pressEnter(imgName);
    await sleep(1000);
    await vboxmanage(imgName, "controlvm", "keyboardputstring  " + rootPassword);
    await pressEnter(imgName);


    await waitFor(imgName, "Start sshd");
    await sleep(1000);
    await pressEnter(imgName);

    await waitFor(imgName, "Do you expect to run the X Window System");
    await sleep(1000);
    await vboxmanage(imgName, "controlvm", "keyboardputstring  no");
    await pressEnter(imgName);

    await waitFor(imgName, "Setup a user");
    await sleep(1000);
    await pressEnter(imgName);


    await waitFor(imgName, "Allow root ssh login");
    await vboxmanage(imgName, "controlvm", "keyboardputstring  yes");
    await pressEnter(imgName);

    await waitFor(imgName, "Which disk is the root disk");
    await sleep(1000);
    await pressEnter(imgName);
    
    await waitFor(imgName, "whole disk");
    await sleep(1000);
    await pressEnter(imgName);
    
    
    await waitFor(imgName, "layout");
    await sleep(1000);
    await pressEnter(imgName);

    await waitFor(imgName, "Location of sets");
    await sleep(1000);
    await pressEnter(imgName);

    await waitFor(imgName, "Pathname to the sets");
    await sleep(1000);
    await pressEnter(imgName);

    await waitFor(imgName, "Set name");
    await vboxmanage(imgName, "controlvm", "keyboardputstring  -comp69*");
    await pressEnter(imgName);
    await sleep(1000);
    await pressEnter(imgName);


    await waitFor(imgName, "Directory does not contain SHAZ56.sig");
    await vboxmanage(imgName, "controlvm", "keyboardputstring  yes");
    await pressEnter(imgName);


    await waitFor(imgName, "Location of sets");
    await sleep(1000);
    await pressEnter(imgName);

    await waitFor(imgName, "What timezone are you in");
    await sleep(1000);
    await pressEnter(imgName);


    await waitFor(imgName, "Your OpenBSD install has been successfully completed");
    await sleep(1000);
    await vboxmanage(imgName, "controlvm", "keyboardputstring  h");
    await pressEnter(imgName);
    await sleep(10000);

    await vboxmanage(imgName, "controlvm", "poweroff soft");
    await sleep(5000);

    await vboxmanage(imgName, "storageattach", "    --storagectl IDE --port 0  --device 0  --type dvddrive  --medium none");

    await vboxmanage(imgName, "startvm", " --type headless");
    await sleep(5000);

    //check booting
    await waitFor(imgName, "Installing: intel");
    await sleep(10000);

    await waitFor(imgName, "logi");
    await sleep(1000);


    await exec.exec("bash ", [], { input: "[ ! -e ~/.ssh/id_rsa ] && ssh-keygen -f  ~/.ssh/id_rsa" });
    await exec.exec("bash ", [], { input: "echo \"echo '$(cat ~/.ssh/id_rsa.pub)' >>~/.ssh/authorized_keys\" >>enablessh.txt" });


    await vboxmanage(imgName, "controlvm", "keyboardputfile  enablessh.txt");
    core.info("setup ssh finished");


    let sshkey = "";
    await exec.exec("ssh openbsd", [], {
      input: 'cat ~/.ssh/id_rsa.pub', listeners: {
        stdout: (s) => {
          sshkey += s;
        }
      }
    });

    core.info("sshkey:" + sshkey);

    fs.writeFileSync(__dirname + "/id_rsa.pub", sshkey);





//    core.info("run init.sh");
//    let init = __dirname + "/init.sh";
//    await exec.exec("ssh openbsd", [], { input: fs.readFileSync(init) });

    core.info("Power off");
    await exec.exec("ssh openbsd", [], { input: 'shutdown -y -i5 -g0' });

    while (true) {
      core.info("Sleep 2 seconds");
      await sleep(2000);
      let std = "";
      await exec.exec("sudo vboxmanage list runningvms", [], {
        listeners: {
          stdout: (s) => {
            std += s;
            core.info(s);
          }
        }
      });
      if (!std) {
        core.info("shutdown OK continue.");
        await sleep(2000);
        break;
      }
    }

    core.info("Export " + ova);
    await io.rmRF(ova);
    await vboxmanage(imgName, "export", "--output " + ova);
    await exec.exec("sudo chmod 666 " + ova);

    core.info("Split file");
    await io.rmRF(ova + ".zip");
    
    await exec.exec("cp ~/.ssh/id_rsa  " + __dirname + "/mac.id_rsa");
    
    await exec.exec("zip -0 -s 2000m " + ova + ".zip " + ova + " id_rsa.pub  mac.id_rsa");
    await exec.exec("ls -lah");

  } catch (error) {
    core.setFailed(error.message);
  } finally {
    if (process.env["DEBUG"]) {
      await exec.exec("killall -9 ngrok", [], { ignoreReturnCode: true });
    }
  }
}

run();
