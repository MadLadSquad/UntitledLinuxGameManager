#!/bin/bash
if [ "$1" == "--name" ] && [ "$2" != "" ] && [ "$3" == "--driver" ] && [ "$4" != "" ]; then
  if [ "$4" == "N" ]; then
    pro=true
    containerName="$2"
  elif [ "$4" == "M" ]; then
    pro=false
    containerName="$2"
  else
    echo "You're trying to do an automated install but didn't provide the right arguments!"
    exit
  fi
else
  read -rp "Enter your container's name: " containerName

  while true; do
      echo -e "What video drivers do you want to use Mesa(AMD/Intel) or NVidia?"
      read -rp "M(mesa)/N(NVidia): " yn
      case $yn in
          [Mm]* ) pro=false;break;;
          [Nn]* ) pro=true;break;;
          * ) echo "Please answer with M(Mesa) or N(NVidia)!";;
      esac
  done
fi

# Check if the container exists, that one space after the container name insertion is for checking if it is the full container name
lxc list | grep "${containerName} " &> /dev/null || (echo -e "\x1B[31mError: Container does not exist, run the following command to create it and rerun the script: \"lxc launch images:archlinux ${containerName}\"\x1B[0m" && exit)
which glxinfo &> /dev/null || (echo -e "\x1B[31mError: glxinfo not found! The glxinfo program is needed in order to install your GPU drivers!\x1B[0m" && exit)


echo -e "\x1B[32m---------------------------------------------------------------------------\x1B[0m"
echo -e "\x1B[32mStarting container installation!\x1B[0m"
echo -e "\x1B[32m---------------------------------------------------------------------------\x1B[0m"

lxc exec "${containerName}" -- bash -c "pacman -Syyu --noconfirm || pacman -Syu --noconfirm"
# Add 32 bit binary support and install useful utilities
lxc exec "${containerName}" -- bash -c "sed -i '/^#\[multilib\]$/ {N; s/#\[multilib\]\n#Include = \/etc\/pacman.d\/mirrorlist/\[multilib\]\nInclude = \/etc\/pacman.d\/mirrorlist/g}' /etc/pacman.conf"
lxc exec "${containerName}" -- bash -c "pacman -Syyu --noconfirm wget vim"

echo -e "\x1B[32m---------------------------------------------------------------------------\x1B[0m"
echo -e "\x1B[32mInstalling drivers!\x1B[0m"
echo -e "\x1B[32m---------------------------------------------------------------------------\x1B[0m"

if [ "${pro}" = false ]; then
  # TODO: Test this!
	lxc exec "${containerName}" -- bash -c "pacman -S --noconfirm mesa lib32-mesa"
else
	# get the nvidia driver version from glxinfo and then construct a new string with the version
	nversiontmp=$(glxinfo | grep "OpenGL version string: 4.6.0 NVIDIA ")
	nversion=${nversiontmp: -6}

  # Iterate the archive for the newest iteration of the 64 bit nvidia drivers
  up1=1
  for ((;;)); do
    stat1=$(curl -Is "https://archive.archlinux.org/packages/n/nvidia-utils/nvidia-utils-${nversion}-${up1}-x86_64.pkg.tar.zst" | head -n 1)

    if echo "${stat1}" | grep "200" &> /dev/null; then
      ((up1+=1))
    else
      ((up1-=1))
      break;
    fi
  done

  # Iterate the archive for the newest iteration of the 32bit nvidia drivers and libraries
  up2=1
  for ((;;)); do
    stat2=$(curl -Is "https://archive.archlinux.org/packages/l/lib32-nvidia-utils/lib32-nvidia-utils-${nversion}-${up2}-x86_64.pkg.tar.zst" | head -n 1)
    if echo "${stat2}" | grep "200" &> /dev/null; then
      ((up2+=1))
    else
      ((up2-=1))
      break;
    fi
  done

	# Install the nvidia driver and related libraries
	lxc exec "${containerName}" -- bash -c "pacman -U --noconfirm https://archive.archlinux.org/packages/n/nvidia-utils/nvidia-utils-${nversion}-${up1}-x86_64.pkg.tar.zst https://archive.archlinux.org/packages/l/lib32-nvidia-utils/lib32-nvidia-utils-${nversion}-${up2}-x86_64.pkg.tar.zst"
	echo -e "\x1B[32m---------------------------------------------------------------------------\x1B[0m"
  echo -e "\x1B[32mInstalling steam, firefox, lutris, wine, winetricks and python!\x1B[0m"
  echo -e "\x1B[32m---------------------------------------------------------------------------\x1B[0m"
  # Install steam, pulse, firefox, lutris, wine and a bunch of python dependencies
  lxc exec "${containerName}" -- bash -c "pacman -S --noconfirm pulseaudio steam lutris firefox wine winetricks python-pip python-pipx python-setuptools python-virtualenv"
	lxc exec "${containerName}" -- bash -c "sed -i 's/#IgnorePkg   =/IgnorePkg = lib32-nvidia-utils nvidia-utils/g' /etc/pacman.conf"
fi

# Create an ubuntu user on arch for compatibility reasons lmao
lxc exec "${containerName}" -- bash -c "useradd -m ubuntu && usermod -G wheel,audio,video ubuntu"

# Install protontricks trough pipx
lxc exec "${containerName}" -- bash -c "pipx install protontricks && pipx ensurepath"

# Restart
lxc stop "${containerName}"
lxc start "${containerName}"

lxc exec "${containerName}" -- bash -c "sed -i 's/; enable-shm = yes/enable-shm = no/g' /etc/pulse/client.conf"
lxc exec "${containerName}" -- bash -c "sed -i 's/autospawn = no/autospawn = yes/g' /etc/pulse/client.conf"

grep "\
  - container: $containerName
      pins:
" ~/.config/UntitledLinuxGameManager/config/layout.yaml &> /dev/null || (grep "containers:" ~/.config/UntitledLinuxGameManager/config/layout.yaml &> /dev/null && echo "\
  - container: $containerName
    pins:
      - steam
      - lutris
      - firefox
" >> ~/.config/UntitledLinuxGameManager/config/layout.yaml) || echo "\
containers:
  - container: $containerName
    pins:
      - steam
      - lutris
      - firefox
" >> ~/.config/UntitledLinuxGameManager/config/layout.yaml

lxc restart "${containerName}"

lxc config set "${containerName}" environment.PROTON_NO_ESYNC 1
lxc config set "${containerName}" environment.PULSE_SERVER unix:/pulse-native
lxc config set "${containerName}" environment.DISPLAY :0

if [ -z "${XDG_RUNTIME_DIR}" ]; then
  location="${XDG_RUNTIME_DIR}"
elif [ -z "${PULSE_SERVER}" ]; then
  # The PULSE_SERVER env variable starts with a "unix:" directive before the actual path
  location=${PULSE_SERVER:5}
else
  if [ -f "/var/run/user/1000/pulse/native" ]; then
	  location="/var/run/user/1000/pulse/native"
  elif [ -f "/run/user/1000/pulse/native" ]; then
    location="/run/user/1000/pulse/native"
  elif [ -f "/pulse-native" ]; then
    location="/pulse-native"
  elif [ -f "${HOME}/pulse-native" ]; then
    location="${HOME}/pulse-native"
  elif [ -f "${HOME}/.config/pulse/native" ]; then
    location="${HOME}/.config/pulse/native"
  elif [ -f "${HOME}/.pulse/native" ]; then
    location="${HOME}/.pulse/native"
  else
    pulsewarn=true
  fi
fi


# The pulse socket is stored under the XDG_RUNTIME_DIR environment variable, if your system doesn't have it then you're pretty much fucked fr fr
lxc config device add "${containerName}" PASocket1 proxy bind=container "connect=unix:${location}/pulse/native" listen=unix:/pulse-native uid=1000 gid=1000 mode=0777 security.uid=1000 security.gid=1000
lxc config device add "${containerName}" mygpu gpu
lxc config device add "${containerName}" X0 proxy bind=container connect=unix:/tmp/.X11-unix/X0 listen=unix:/tmp/.X11-unix/X0 uid=1000 gid=1000 mode=0777 security.uid=1000 security.gid=1000

echo -e "\x1B[32mContainer installation finished! You might experience network/audio problems, reboot and it should be fixed!\x1B[0m"
if "${pulsewarn}"; then
  echo -e "\x1B[31mError: pulseaudio socket not found, find the socket, called \"pulse-native\" or \"native\" if under a directory called \"pulse\" and run the following commands!"
  echo -e "    lxc config device add ${containerName} PASocket1"
  echo -e "    lxc config device add ${containerName} PASocket1 proxy bind=container connect=unix:<location to the socket here> listen=unix:/pulse-native uid=1000 gid=1000 mode=0777 security.uid=1000 security.gid=1000"
fi