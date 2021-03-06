/**
# London Design Festival 2016 

## Copying files to the PI 
(LOCAL MACHINE) $ scp -rp Instasketch2 pi@instacolour1.local:/home/pi/

## ultrasonic sensor 
https://www.modmypi.com/blog/hc-sr04-ultrasonic-range-sensor-on-the-raspberry-pi
http://www.instructables.com/id/Easy-ultrasonic-4-pin-sensor-monitoring-hc-sr04/

#### Overclocking 
https://www.raspberrypi.org/forums/viewtopic.php?f=66&t=138123

$ sudo nano /boot/config.txt

arm_freq=1350
over_voltage=5
gpu_freq=550

# sdram overclock
sdram_freq=550
sdram_schmoo=0x02000020
over_voltage_sdram_p=6
over_voltage_sdram_i=4
over_voltage_sdram_c=4

## Fixing resolution issues 
https://www.raspberrypi.org/forums/viewtopic.php?f=67&t=25933 // to find group and mode 
http://weblogs.asp.net/bleroy/getting-your-raspberry-pi-to-output-the-right-resolution // to set the above values in the config 

pi@instacolour1:~ $ tvservice -m CEA
Group CEA has 2 modes:
           mode 4: 1280x720 @ 60Hz 16:9, clock:74MHz progressive 
  (prefer) mode 16: 1920x1080 @ 60Hz 16:9, clock:148MHz progressive 
pi@instacolour1:~ $ tvservice -m DMT
Group DMT has 1 modes:
           mode 4: 640x480 @ 60Hz 4:3, clock:25MHz progressive 
                      
$ sudo nano /boot/config.txt 
hdmi_group=1 
hdmi_mode=3

NB: If your mode description contains “DMT”, the group should be 2, and if it contains “CEA”, it should be 1

## VNC (Remote Login)
https://www.raspberrypi.org/documentation/remote-access/vnc/
http://www.howtogeek.com/141157/how-to-configure-your-raspberry-pi-for-remote-shell-desktop-and-file-transfer/all/
https://www.raspberrypi.org/documentation/remote-access/vnc/mac.md

## To run Processing from Command line: 
$ export DISPLAY=":0" OR export DISPLAY=:0
$ processing-java --output=/tmp/processing --force --sketch=Instasketch2 --run
(PREFERED)$ processing-java --output=/tmp/processing --force --sketch=/home/pi/Instasketch2 --present --no-java

# AUTOBOOT 
https://learn.adafruit.com/adafruit-raspberry-pi-lesson-7-remote-control-with-vnc/running-vncserver-at-startup
$ cd /home/pi/.config/
IF DOESN'T ALREADY EXISTS 
  $ mkdir autostart
$ cd autostart 
$ nano instasketch.desktop
[Desktop Entry]
Type=Application
Name=Instasketch2
Exec=processing-java --output=/tmp/processing --force --sketch=/home/pi/Instasketch2 --present --no-java
StartupNotify=false

## Killing the running process 
$ ps aux | grep processing
$ sudo kill PID (first numerical value on table) 

### Copying to the PI
scp -rp Instasketch2 pi@instacolour1.local:/home/pi/

#### Copying .json file to the PI 
scp instacolour.json pi@instacolour1.local:/home/pi/

## Stopping the screen from going blank 
https://www.bitpi.co/2015/02/14/prevent-raspberry-pi-from-sleeping/


sudo nano /etc/lightdm/lightdm.conf

In that file, look for:
[SeatDefault]

and insert this line:
xserver-command=X -s 0 dpms

## Install Processing 
https://www.raspberrypi.org/blog/now-available-for-download-processing/
$ curl https://processing.org/download/install-arm.sh | sudo sh

## Backing up the PI and recovering (aka cloning)  
https://thepihut.com/blogs/raspberry-pi-tutorials/17789160-backing-up-and-restoring-your-raspberry-pis-sd-card
https://computers.tutsplus.com/articles/how-to-clone-raspberry-pi-sd-cards-using-the-command-line-in-os-x--mac-59911

## Multiple networks 
http://raspberrypi.stackexchange.com/questions/11631/how-to-setup-multiple-wifi-networks
https://www.mikestreety.co.uk/blog/use-a-raspberry-pi-with-multiple-wifi-networks
http://www.geeked.info/raspberry-pi-add-multiple-wifi-access-points/

**/