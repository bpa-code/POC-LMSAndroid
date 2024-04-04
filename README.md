Proof of concept

Build of LMS for Termux for Andrpoid 7+ aarch64 

Architecture is known as aarch64-android  (Pi might be aarch64-Linux) 

Termux compiler uses clang vs Linux gcc also file system is different so LSM packges & Perl modules had to be built for this enviurment. Also some LMS files had to be changed (Custom.pm, gdresizer.pl etc)

LMS Perl modules are built for Termux 23 and not run under Debian.
Build of aarch64 faad, flax, sox and wvunpack.  
sox (14.4.2) came from Termux package as building LMS version (14.4.3) of sox has problems.

This LMS build uses Termux Perl package which is 5.38.2

This POC is intended for experienced users.
Phone/Table must have Termux installed (usually from F-Droid).
At Termux prompt "uname -m" command returns "aarch64"  only this architecture is supported in this POC.

Assuming a clean new Termux install.
Run the following.
1. termux-setup-storage
2. apt update
3. apt upgrade (needs about 6 manusl "ues " inputs) 
4. pkg install perl (needs 1 Yes) 
5. pkg install wget (needs 1 Yes) 

Download the AndLMS.sh script and run

To run LMS change to usr/squeezeboxerserver and run slimserver.pl script





