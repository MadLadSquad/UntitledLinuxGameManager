# UntitledLinuxGameManager
A linux gaming system manager
## About
UntitledLinuxGameManager is a cli/gui program to help with managing a linux gaming system.

It automatically creates an Ubuntu container with the latest updates and software, and gives you a nice gui/cli interface to manage the programs in the container.

Using a container users can:
- isolate their gaming system from the host
- easily backup, redeploy or move their system
- increase game/program stability and compatibility
## Dependencies
The manager requires the following to be installed on your system:
- X
- PulseAudio
- glxinfo
- An AMD/Intel/Nvidia GPU with supported drivers
- The cli install scripts require bash, since for now they include bash isms and don't fully conform
## Install
### GUI install
The GUI installer is a GUI frontend for the scripts that we have in the cli install. 

You can build all the managers and the GUI installer using the `user $ ./buildall` script otherwise

1. Change into `Installers/GUI/`
2. Make a folder named `build` and change into it, `mkdir build && cd build`
3. Install `cmake`, `make`, `gcc` and all the packages that are needed for compiling C and C++ code with make and cmake
4. Run `cmake .. -G "Unix Makefiles"`
5. If you see errors for libraries that were not found download them from your package manager
6. Once `cmake ..` succeeds run `make -j <number of compile jobs here>`
7. Once it compiles, run `./ugm-gui-installer` and follow the setup
### [CLI install] Dependencies and host setup
First make sure you have the dependencies listed above!

Next, before we start with the automatic installation some manual work needs to be done.
1. Install lxd and lxc
  - Gentoo: `root # emerge lxd`
  - Arch: `root # pacman -S lxd`
  - Debian/Ubuntu: `root # apt install lxd`
2. Run the following script as `user $ ./copy-scripts.sh`, this will create folders and copy the needed scrips and resources
3. The following setup can be automated by running the following script `root # ./ugm-cli-prepare-install.sh`. Steps 3 trough 10 are for manual install, so if you're installing using the script skip to step 12 after you run the script!
4. Add the lxd daemon to start on startup
  - OpenRC: `root # rc-update add lxd default`
  - SystemD: `root # systemctl enable lxd.service`
  - runit: `root # ln -s /etc/sv/lxd /var/service`
5. Make sure that the `/etc/security/limits.conf` file has the following contents
  ```
  *       soft    nofile  1048576
  *       hard    nofile  1048576
  root    soft    nofile  1048576
  root    hard    nofile  1048576
  *       soft    memlock unlimited
  *       hard    memlock unlimited
  # End of file
  ```
6. Make sure that the `/etc/subuid` and `/etc/subgid` files have the following contents. If the files don't exist, create them!
  ```
  root:1000000:1000000000
  ```
7. Start lxd
  - OpenRC: `root # /etc/init.d/lxd start`
  - SystemD: `root # systemctl start lxd.service`
  - runit: `root # sv start lxd`
8. Add your non-root user to the lxd group `root # usermod -a -G lxd <your-username>`
9. Initialize lxd to look like the following
  ```
  root # lxd init
  Would you like to use LXD clustering? (yes/no) [default=no]: ↵
  Do you want to configure a new storage pool? (yes/no) [default=yes]: ↵
  Name of the new storage pool [default=default]: ↵
  Name of the storage backend to use (btrfs, dir, lvm) [default=btrfs]: dir ↵
  Would you like to connect to a MAAS server? (yes/no) [default=no]: ↵
  Would you like to create a new local network bridge? (yes/no) [default=yes]: ↵
  What should the new bridge be called? [default=lxdbr0]: ↵
  What IPv4 address should be used? (CIDR subnet notation, “auto” or “none”) [default=auto]: ↵
  What IPv6 address should be used? (CIDR subnet notation, “auto” or “none”) [default=auto]: none ↵
  Would you like LXD to be available over the network? (yes/no) [default=no]: ↵
  Would you like stale cached images to be updated automatically? (yes/no) [default=yes] ↵
  Would you like a YAML "lxd init" preseed to be printed? (yes/no) [default=no]: ↵
  root #
  ```
10. Run `lxc image list` and you should get the following output
```
+-------+-------------+--------+-------------+------+------+-------------+
| ALIAS | FINGERPRINT | PUBLIC | DESCRIPTION | ARCH | SIZE | UPLOAD DATE |
+-------+-------------+--------+-------------+------+------+-------------+
```
11. At the beginning we ran a script to set up our folders and scripts that we require. The last thing you need to do is to add `~/.config/UntitledLinuxGamingManager/scripts/` to path
```sh
export PATH=~/.config/UntitledLinuxGamingManager/scripts/:$PATH
```
12. Troubleshooting, skip this if you don't have any problems running steps 8 and 9
  - An error similar to or the same as this one `Error: Get "http://unix.socket/1.0": dial unix /var/lib/lxd/unix.socket: connect: connection refused`
    1. Run `lxd --debug --group lxd`
    2. If your output looks similar to this, where it mentions a bunch of segments
    ```
    Error: Failed to start dqlite server: raft_start(): io: load closed segment 0000000000000002-0000000000000002: unexpected format version 8095768602490157155
    ```
    3. Change into the `/var/lib/lxd/database/global` folder and delete all the segments mentioned in the error, and then rerun the commands
    4. Note: this error can also happen from regular usage, from time to time
13. The following 3 commands have been safely executed by the automated script, so you can skip these steps! The following 3 commands should only be run **once**, in order to set up the host! Do **NOT** repeat them, or you are going to break your system!
14. Next run the following command `user $ xhost +local:`, this will allow X connections
15. Now as root, run the following `root # sed -i "s/load-module module-native-protocol-unix/& auth-anonymous=1/" /etc/pulse/default.pa`
16. Now as a normal user `user $ killall pulseaudio` and start pulseaudio again, a restart is recommended since your audio setup might break for the current session
17. If you broke your audio system because you didn't read the text above, to fix it, edit `/etc/pulse/default.pa` and find the following line and delete any duplications of the `auth-anonymous=1` at the end until you are left with the line below
  ```
  load-module module-native-protocol-unix auth-anonymous=1
  ```
18. And you're now ready to install!
### CLI install
To install through the cli we have a handy script that you can run, otherwise do every step of the script if you have any specific configuration
1. If you have done all of that setup in a single terminal instance, it's recommended that you restart your terminal instance and start fresh
2. Run `user $ lxc launch images:archlinux <system-name-here>`, this will create a container, remember its name as it is needed for the next step
3. Next, run the following script with `user $ ./ugm-cli-install.sh`
4. You will be asked to put in your container's name, type it in and press `Enter` when you're ready to go to the next step
5. Next, you're going to need to select a graphics driver for your GPU, `N` for NVidia, `M` for Mesa(Intel/AMD)
6. Pressing enter will start installing all the necessary packages and features your gaming container needs
7. By the end of the installation your container should have the following software installed
  - Firefox(for managing links that come from the container)
  - Steam
  - Wine
  - Lutris
  - Winetricks
  - Protontricks
9. The installation is going to be slow, so leave the script to automatically handle installation, while all the packages download
10. Troubleshooting - visit the [wiki](https://github.com/MadLadSquad/UntitledLinuxGameManager/wiki)
## Managers
### Compilation
You can run a the `user $ ./buildall.sh` script to build all installers and managers otherwise

1. Change into the `Managers` directory
2. To compile the CLI manager do the following
```
user $ cd CLi/ && mkdir build && cd build && cmake -G "Unix Makefiles" ..
user $ make -j <number of compute jobs> 
user $ cp ugm-cli ../../../
```
3. To compile the GUI manager do the following
```
user $ cd GUI/ && mkdir build && cd build && cmake -G "Unix Makefiles" ..
user $ make -j <number of compute jobs> 
user $ cp ugm-gui ../../../
```
### GUI manager
To launch the GUI manager run `user $ ugm-gui` to launch it
### CLI manager
Running `user $ ugm-cli --help` will show a help message
