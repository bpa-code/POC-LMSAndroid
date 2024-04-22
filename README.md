Proof of concept

Build of LMS latest (8.5.1) for Termux for Android 7+ aarch64 & arm

To test 

Expects a clean install of Termux on Android device. If there has been previous use of Termux, from Android Settings, stop Termux App and clear storage. Restart Termux.

On Android, Open browser at url for Command.txt 
Open the command line in Command.txt and pasted into Termux encuorment (it should be line below)
curl https://github.com/bpa-code/POC-LMSAndroid/raw/main/InstallLMS.sh -o lms && bash lms

Run the command which will install Termux-LMS files.
After install, reboot Termux (e.g. type exit & return and then restart App Termux)

Both LMS and squeezelite have been configured as Termux services lyrion and squeezleite respectively.
so use "sv up" and "sv down" to start and stop the services

e.g. 
sv up lyrion
sv up squeezelite.








