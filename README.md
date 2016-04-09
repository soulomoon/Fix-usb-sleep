Fix "Disk not ejected properly" Issue on OS X/Mac OS X
============

Hola, this is an ongoing project aims at fixing the issue of disk not ejected properly upon sleep. This issue has a really long history since Maviricks(Mac OS X 10.9) even on a real Mac. Without the help of Bernhard Baehr (bernhard.baehr@gmx.de)'s great sleepwatcher dameon, this project will not be created. 

I've tested on my DELL Precision M3800. Wish you all enjoy it. Any feedback is welcomed! 

How to use fixUSB.sh?
----------------
Download the latest fixUSB.sh by entering the following command in a terminal window:

``` sh
git clone https://github.com/syscl/Fix-usb-sleep
```


This will download fixUSB.sh to your current directory (./) and the next step is to change the permissions of the file (add +x) so that it can be run.
 
``` sh
chmod +x ./Fix-usb-sleep/fixUSB.sh
```


Run the script in a terminal window by:

``` sh
cd ./Fix-usb-sleep
./fixusb.sh
```

Once you finish the procedures, reboot your OS X and see if the issue is fixed.

How to use ramdisk?
----------------
Download the latest fixUSB.sh by entering the following command in a terminal window:

``` sh
curl -o ./ramdisk https://raw.githubusercontent.com/syscl/Fix-usb-sleep/master/ramdisk.sh
```

This will download ramdisk to your current directory (./) and the next step is to change the permissions of the file (add +x) so that it can be run.

``` sh
chmod +x ./ramdisk
```

Run the script in a terminal window by:

``` sh
./ramdisk
```
Reboot your OS X to see the change. If you have any problem about the script, try to run deploy in DEBUG mode by
```sh
./ramdisk -d
```
or
```sh
./ramdisk -debug
```

Change Log
----------------

2016-4-9

- Added RAMDISK function for users who want to boost their appliacations by fully using hardware resources (c) syscl/lighting/Yating Zhou.

2016-3-19

- Huge update, use "eject" command line to boost the mount upon sleep. Faster than ever!
- Fixed two key command lines.
- Change the permissions of the script (add +x) so that it can be run before sleep.

2016-3-18

- First version of fixUSB.sh

////