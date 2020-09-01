#!/bin/bash

# Say hi
echo "-------------------------------------------------------------------------"
echo "Tooloop OS - Tecné Collective Version for Ubuntu 20"
echo "-------------------------------------------------------------------------"
echo " "

# get the path to the script
SCRIPT_PATH="`dirname \"$0\"`"                  # relative
SCRIPT_PATH="`( cd \"$SCRIPT_PATH\" && pwd )`"  # absolutized and normalized
if [ -z "$SCRIPT_PATH" ] ; then
  # error; for some reason, the path is not accessible
  # to the script (e.g. permissions re-evaled after suid)
  exit 1  # fail
fi

#gets the current user
MYUSER=$SUDO_USER
#flag to be used in sed to replace the user
TOOLOOPFLAG="TOOLOOPFLAG"

# exit if we’re not root
if [ $EUID != 0 ]; then
  echo "This script must be run as root."
  exit $exit_code
    exit 1
fi

#check for the directory if the user prefers to use a single partition (default in ubuntu20)
if [ -d "/assets" ] 
then
    echo "Directory /assets exists." 
else
    mkdir /assets
    echo "Creating: /assets"
fi
sleep 3

# ------------------------------------------------------------------------------
# Update
# ------------------------------------------------------------------------------
echo " "
echo "-------------------------------------------------------------------------"
echo "1/3 --- Updating system"
echo "-------------------------------------------------------------------------"
echo " "
sleep 3

# Updating system first
apt update -y
apt dist-upgrade -y
sleep 3

# ------------------------------------------------------------------------------
# Packages
# ------------------------------------------------------------------------------
echo " "
echo "-------------------------------------------------------------------------"
echo "2/3 --- Installing base packages"
echo "-------------------------------------------------------------------------"
echo " "
sleep 3

# Install base packages
apt install -y \
  xorg \
  x11-xserver-utils \
  openbox \
  obconf \
  chromium-browser \
  ssh \
  x11vnc \
  pulseaudio \
  pavucontrol \
  unclutter \
  scrot \
  git \
  unzip \
  make \
  gcc \
  curl \
  htop \
  vainfo \
  augeas-doc \
  augeas-lenses \
  augeas-tools \
  bash-completion \
  nano \
  psmisc \
  pcregrep \
  mlocate \
  xterm \
  python3.8-dev \
  python3-pip \
  net-tools \
  thunar \
  dos2unix

#added a few tools taht we use constantly and a light weight file manager (thunar)
sleep 3


#INSTALL obmenu, with a rabnch for python 3.5 as ubuntu20 doesn't include python2 anymore
mkdir temp
cd temp
git clone https://github.com/keithbowes/obmenu.git
cd obmenu
python3 setup.py install
rm -rf temp
sleep 3

# ------------------------------------------------------------------------------
# Config
# ------------------------------------------------------------------------------
echo " "
echo "-------------------------------------------------------------------------"
echo "3/3 --- Configuring system"
echo "-------------------------------------------------------------------------"
echo " "
sleep 3

# Allow shutdown commands without password and add tooloop scripts path to sudo, now supports the user taht is installing the script
cat >/etc/sudoers.d/$MYUSER <<EOF
# find and autocomplete tooloop scripts using sudo
Defaults  secure_path="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/snap/bin:/opt/tooloop/scripts"
# make an alias for x11vnc start and stop commands
Cmnd_Alias VNC_CMNDS = /bin/systemctl start x11vnc, /bin/systemctl stop x11vnc
# allow these commands without using a password
$MYUSER     ALL=(ALL) NOPASSWD: /sbin/poweroff, /sbin/reboot, /sbin/shutdown, VNC_CMNDS
EOF
sleep 3

# Auto login
mkdir -p /etc/systemd/system/getty\@tty1.service.d
cat >/etc/systemd/system/getty\@tty1.service.d/autologin.conf <<EOF
[Service]
ExecStart=
ExecStart=/sbin/agetty --skip-login --noissue --autologin "$MYUSER" %I
EOF
sleep 3

#patch for autologin in ubuntu20
#TODO

# Create the /assets folder sctructure
mkdir -p /assets/presentation
mkdir -p /assets/data
mkdir -p /assets/screenshots
mkdir -p /assets/logs
mkdir -p /assets/apps
sleep 3

# Silent boot
augtool<<EOF
set /files/etc/default/grub/GRUB_DEFAULT 0
set /files/etc/default/grub/GRUB_TIMEOUT 0
set /files/etc/default/grub/GRUB_CMDLINE_LINUX \""console=tty12\""
set /files/etc/default/grub/GRUB_CMDLINE_LINUX_DEFAULT \""quiet loglevel=3 vga=current rd.systemd.show_status=false rd.udev.log-priority=3\""
save
EOF

update-grub2
sleep 3

# Nice SSH banner
augtool<<EOF
set /files/etc/ssh/sshd_config/Banner /etc/issue.net
save
EOF

cat >/etc/issue.net <<EOF




     |                         |
   --|--     _____     _____   |       _____     _____     _____
     |      /     \   /     \  |      /     \   /     \   /     \\
     |     |       | |       | |     |       | |       | |       |
     |     |       | |       | |     |       | |       | |       |
      \___  \____ /   \____ /   \___  \____ /   \____ /  |  ____/
                                                         |
                  Tooloop OS 0.9 alpha  |  Ubuntu 20.04  |


Hint: There's a bunch of convenient aliases starting with tooloop-...
E.g. tooloop-presentation-stop, tooloop-settings

-------------------------------------------------------------------------

EOF
sleep 3

# Get rid of the last login message
touch /home/$MYUSER/.hushlogin
chown $MYUSER:$MYUSER /home/$MYUSER/.hushlogin

# Hide verbose kernel messages
cat >/etc/sysctl.d/20-quiet-printk.conf <<EOF
kernel.printk = 3 3 3 3
EOF
sleep 3

# Copy bash config
cp "$SCRIPT_PATH"/files/bashrc /home/$MYUSER/.bashrc
chown $MYUSER:$MYUSER /home/$MYUSER/.bashrc
#replace username
sleep 3

# Copy Openbox theme
cp -R "$SCRIPT_PATH"/files/openbox-theme/* /usr/share/themes/
sleep 3

# Copy Openbox config
mkdir -p /home/$MYUSER/.config
mkdir -p /home/$MYUSER/.config/openbox
cp -R "$SCRIPT_PATH"/files/openbox-config/* /home/$MYUSER/.config/openbox/
sleep 3

# Copy Openbox menu icons
mkdir -p /home/$MYUSER/.config/icons
cp -R "$SCRIPT_PATH"/files/openbox-menu-icons/* /home/$MYUSER/.config/icons/

# Copy start- and stop-presentation scripts
cp "$SCRIPT_PATH"/files/start-presentation.sh /assets/presentation/
cp "$SCRIPT_PATH"/files/stop-presentation.sh /assets/presentation/

# Copy Clear Sans font
cp -R "$SCRIPT_PATH"/include/clearsans /usr/share/fonts/truetype
sleep 3

# Copy scripts (copying file to bin as paths are failing)
mkdir -p /opt/tooloop
cp -R "$SCRIPT_PATH"/files/scripts /opt/tooloop
cp -R "$SCRIPT_PATH"/files/scripts /usr/bin
chmod +x /opt/tooloop/scripts/*
chmod +x /usr/bin/tooloop*
sleep 3

# Get settings server
git clone https://github.com/Tecne-Collective/Tooloop-Settings-Server.git /opt/tooloop/settings-server
sleep 3

# Install dependencies
/bin/bash /opt/tooloop/settings-server/install-dependencies.sh
sleep 3

# Create a systemd service for settings server
mkdir -p /usr/lib/systemd/system/
cat > /usr/lib/systemd/system/tooloop-settings-server.service <<EOF
[Unit]
Description=Tooloop settings server
After=network.target

[Service]
Environment=DISPLAY=:0
Environment=XAUTHORITY=/home/$MYUSER/.Xauthority
ExecStart=/usr/bin/python /opt/tooloop/settings-server/tooloop-settings-server.py
Restart=always

[Install]
WantedBy=graphical.target
EOF

# Enable and start the service
systemctl daemon-reload
systemctl enable tooloop-settings-server
systemctl start tooloop-settings-server

sleep 3
# Get example apps
git clone https://github.com/Tecne-Collective/Tooloop-Examples.git /assets/apps

sleep 3

# Create a systemd target for Xorg
# info here: https://superuser.com/a/1128905
mkdir -p /usr/lib/systemd/user
cat > /usr/lib/systemd/user/xsession.target <<EOF
[Unit]
Description=XSession
BindsTo=graphical-session.target
EOF

# Create a systemd service for the VNC server
cat > /usr/lib/systemd/user/x11vnc.service <<EOF
[Unit]
Description=x11vnc screen sharing service

[Service]
Environment=DISPLAY=:0
Environment=XAUTHORITY=/home/$MYUSER/.Xauthority
Type=simple
ExecStart=/bin/sh -c '/usr/bin/x11vnc -shared -forever'
Restart=on-success
SuccessExitStatus=3

[Install]
WantedBy=xsession.target
EOF
sleep 3

# Create a cronjob to take a screenshot every minute
(crontab -u $MYUSER -l ; echo "* * * * * env DISPLAY=:0.0 /opt/tooloop/scripts/tooloop-screenshot") | crontab -u $MYUSER -
sleep 3

# Create a cronjob to clean up screenshots every day at 00:00
(crontab -u $MYUSER -l ; echo "0 0 * * * /opt/tooloop/scripts/tooloop-screenshots-clean") | crontab -u $MYUSER -
sleep 3

# make Enttec USB DMX devices accessable to the tooloop user
usermod -aG tty $MYUSER
usermod -aG dialout $MYUSER
cat > /etc/udev/rules.d/75-permissions-enttec.rules <<EOF
SUBSYSTEM=="usb", ACTION=="add|change", ATTRS{idVendor}=="0403", ATTRS{idProduct}=="6001", "MODE="0666"
EOF

# Chown things to the tooloop user
chown -R $MYUSER:$MYUSER /assets
chown -R $MYUSER:$MYUSER /home/$MYUSER
sleep 3

apt autoremove
updatedb

sleep 3

echo " "
echo "-------------------------------------------------------------------------"
echo "Done."
echo "-------------------------------------------------------------------------"
echo " "

sleep 3

echo "We will reboot now into your Tooloop OS installation."
echo "Enjoy ;-)"

sleep 5

reboot
