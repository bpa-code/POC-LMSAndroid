#!/usr/bin/env bash

# check tar shell is bash

if [ -z "$BASH_VERSION" ]; then
  echo "This script must be run with bash and not $0"
  exit 0
fi

# Bring Termux up to date 
echo "deb https://grimler.se/termux-packages-24 stable main" > $PREFIX/etc/apt/sources.list
echo "deb https://packages-cf.termux.dev/apt/termux-main stable main" >> $PREFIX/etc/apt/sources.list

apt update
apt upgrade -y -o Dpkg::Options::="--force-confnew"

# wget and jq are just necessary for the install. 
# perl and squeezelite for running LMS.
apt install -y -o Dpkg::Options::="--force-confnew"  perl wget jq squeezelite || pkg --check-mirror install -y -o Dpkg::Options::="--force-confnew" perl wget jq squeezelite

termux-setup-storage

# Check if previous install  $PREFIX/share/squeezeboxserver

if [ -d $PREFIX/share/squeezeboxserver ] ; then
  echo "Overwrite previous LMS installation & settings - confirm with Y "
  read -r -n 1 response
  case "\$response" in
    [yY])
        echo
        echo "Overwriting installation.... "
        ;;
    *)
        echo
	echo "Cancelled. Press enter to quit this terminal"
        ;;
   esac
fi

# Check if services installed and running.
if ! [ -x "$PREFIX/share/termux-services/svlogger" ]; then 
   echo "Installing Termux services"
   apt-get install -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" termux-services
fi


if ! [ -x "$(command -v jq)" ]; then
  echo 'Error: jq is not installed.' >&2
  exit 1
fi

if ! [ -x "$(command -v perl)" ]; then
  echo 'Error: perl is not installed.' >&2
  exit 1
fi

PERL_VERSION=`perl -MConfig -le '$Config{version} =~ /(\d+.\d+)\./; print $1'`
PERL_MINOR_VER=`echo "$PERL_VERSION" | sed 's/.*\.//g'`
RAW_ARCH=`perl -MConfig -le 'print $Config{archname}'`
ARCH=`echo $RAW_ARCH | sed 's/gnu-//' | sed 's/armv.*?-/arm-/' `

#VERBOSE="-v"
VERBOSE=""

#
# Expect TERMUX_VERSION 0.118.0 (NDK 23)
#
pushd $TMPDIR

####################################   Get LMS version #############################
mkdir $VERBOSE -p InstallLMS

# ask for latest version (should be last release) other version are dev and nightly

  rm servers.json
  wget https://lyrion.org/lms-server-repository/servers.json
  url=$(jq -r '.latest.nocpan.url' servers.json)
  lmsversion=$(jq -r '.latest.nocpan.version' servers.json)

# url=\$(jq -r '."8.5.2".nocpan.url' servers.json)
# url=\$(jq -r '."9.0.0".nocpan.url' servers.json)

  nocpan=${url##*/}
  package=$(echo $nocpan | cut -d'_' -f1)
  echo "Package $package   $nocpan "
  
  wget $url
#
#  Get Termux special files
#

LMS_TGZ="https://raw.githubusercontent.com/bpa-code/POC-LMSAndroid/main/"
wget --quiet $LMS_TGZ/termux-site_perl.tgz
wget --quiet $LMS_TGZ/termux-SlimBin.tgz
wget --quiet $LMS_TGZ/termux-SlimCPAN.tgz
wget --quiet $LMS_TGZ/termux-Slimfiles.tgz
wget --quiet $LMS_TGZ/termux-SlimService.tgz

tar xfC termux-Slimfiles.tgz   $TMPDIR/InstallLMS
tar xfC termux-SlimService.tgz $TMPDIR/InstallLMS


#
# Get Material skin
#
  rm extensions.xml
  wget --quiet https://lms-community.github.io/lms-plugin-repository/extensions.xml -O extensions.xml
#  wget $(xmllint --xpath 'string(//extensions/plugins/plugin[@name="MaterialSkin"]/@url)' extensions.xml) -O MaterialSkin.zip
  materialurl=$(grep MaterialSkin extensions.xml | perl -nE 'say /url="([^"]+)/') 
#  echo " Download Material URL=$materialurl"
  wget --quiet $materialurl  -O MaterialSkin.zip

  mkdir $VERBOSE -p $PREFIX/share/squeezeboxserver

  cd $PREFIX/share/squeezeboxserver
  tar xfz $TMPDIR/$package --strip=1 

  tar xfz $TMPDIR/termux-SlimBin.tgz   
  tar xfz $TMPDIR/termux-SlimCPAN.tgz   

# site_perl files was save including usr root.
  cd $PREFIX
  cd ..
  tar xfz $TMPDIR/termux-site_perl.tgz
 
  cd $PREFIX/share/squeezeboxserver
  cp $VERBOSE $TMPDIR/InstallLMS/gdresized.pl.termux ./gdresized.pl
  cp $VERBOSE $TMPDIR/InstallLMS/DNS.pm.termux       ./lib/AnyEvent/DNS.pm
  cp $VERBOSE $TMPDIR/InstallLMS/Misc.pm.termux      ./Slim/Utils/Misc.pm
  cp $VERBOSE $TMPDIR/InstallLMS/Custom.pm.termux    ./Slim/Utils/OS/Custom.pm

  mkdir $VERBOSE -p $PREFIX/var/lib/squeezeboxserver
  chmod -R 0777 $PREFIX/var/lib/squeezeboxserver/

  mkdir $VERBOSE -p $PREFIX/var/log/squeezeboxserver
  chmod -R 0777 $PREFIX/var/log/squeezeboxserver/

  chmod -R 0777 $PREFIX/var/squeezeboxserver/
  chmod -R 0777 $PREFIX/share/squeezeboxserver/

# Get Material  before first boot
  mkdir $VERBOSE -p $PREFIX/var/lib/squeezeboxserver/Cache/InstalledPlugins/Plugins/MaterialSkin
  unzip $TMPDIR/MaterialSkin.zip -d $PREFIX/var/lib/squeezeboxserver/Cache/InstalledPlugins/Plugins/MaterialSkin


#
#  Setup conf files
#
  mkdir $VERBOSE -p $PREFIX/etc/squeezeboxserver
  chmod -R 0777 $PREFIX/etc/squeezeboxserver
  cp $VERBOSE $PREFIX/share/squeezeboxserver/*.conf $PREFIX/etc/squeezeboxserver

#
# External storage setup
#
#i=0
#for cardpath in $(grep -o "/storage/[0-9|A-F|a-f|-]\+ " /proc/mounts); do
#   ln -svf $cardpath $PREFIX/storage/extern-$i
#   i=i+1
#done

#
# Termux squeezeboxserver service setup - service is called lyrion
#

SERVICENAME="lyrion"

mkdir $VERBOSE -p $PREFIX/var/service
cd  $PREFIX/var/service

mkdir $VERBOSE -p $SERVICENAME/log

cat <<EOF > $SERVICENAME/log/run
#! /data/data/com.termux/files/usr/bin/sh
  svlogger="/data/data/com.termux/files/usr/share/termux-services/svlogger"
  exec "${svlogger}" "$@"
EOF

chmod u+x $SERVICENAME/log/run


# Copy in default startup otpions. 
cp $VERBOSE $TMPDIR/InstallLMS/squeezeboxserver.conf    $PREFIX/etc/squeezeboxserver/squeezeboxserver.conf

# Create the service file that runs LMS.  Get command line options from $PREFIX/etc/squeezeboxserver/squeezeboxserver.conf 
cat <<EOF > $SERVICENAME/run
#! $PREFIX/bin/sh
  . $PREFIX/etc/squeezeboxserver/squeezeboxserver.conf 
  exec $PREFIX/share/squeezeboxserver/slimserver.pl \$SLIMOPTIONS 2>&1
EOF
chmod +x $SERVICENAME/run
touch    $SERVICENAME/down

# Make a Squeezelite service
mkdir $VERBOSE -p squeezelite/log
cat <<EOF > squeezelite/log/run
#! /data/data/com.termux/files/usr/bin/sh
  svlogger="/data/data/com.termux/files/usr/share/termux-services/svlogger"
  exec "${svlogger}" "$@"
EOF
chmod u+x squeezelite/log/run

# Create the service file that runs squeezleite.  Not sure if any option are needed for an in-device pulseaudio squeezelite
cat <<EOF > squeezelite/run
#! $PREFIX/bin/sh
  exec squeezelite -n "Squeezelite-termux" 2>&1
EOF
chmod +x squeezelite/run
touch    squeezelite/down

#
#  Termux widgets setup 
#  

if [  ! -d ~/.shortcuts/tasks ]; then
  mkdir -p ~/.shortcuts/tasks
  chmod 700 -R ~/.shortcuts/tasks
fi
if [  ! -d ~/.shortcuts/icons ]; then
  mkdir -p ~/.shortcuts/icons
  chmod -R a-x,u=rwX,go-rwx ~/.shortcuts/icons
fi

#if [  ! -d ~/.shortcuts/Advanced ]; then
#  mkdir -p ~/.shortcuts/Advanced
#  chmod 700 -R ~/.shortcuts/Advanced
#fi

cp $VERBOSE $TMPDIR/InstallLMS/lms-red-green.png  ~/.shortcuts/icons/"Restart LMS.png"
cp $VERBOSE $TMPDIR/InstallLMS/lms-red.png        ~/.shortcuts/icons/"Stop LMS.png"
cp $VERBOSE $TMPDIR/InstallLMS/lms-green.png      ~/.shortcuts/icons/"Start LMS.png"

cp $VERBOSE $TMPDIR/InstallLMS/StartLMS.txt   ~/.shortcuts/tasks/"Start LMS"
cp $VERBOSE $TMPDIR/InstallLMS/RestartLMS.txt ~/.shortcuts/tasks/"Restart LMS"
#cp $VERBOSE $TMPDIR/InstallLMS/UpdateLMS.txt  ~/.shortcuts/"Update LMS"
cp $VERBOSE $TMPDIR/InstallLMS/StopLMS.txt    ~/.shortcuts/tasks/"Stop LMS"

#
#  Tidy up
#

  cd $TMPDIR

  rm $VERBOSE -Rf ./InstallLMS

  rm $VERBOSE termux-site_perl.tgz
  rm $VERBOSE termux-SlimBin.tgz
  rm $VERBOSE termux-SlimCPAN.tgz
  rm $VERBOSE termux-Slimfiles.tgz
  rm $VERBOSE termux-SlimService.tgz

  rm $VERBOSE MaterialSkin.zip
  rm extensions.xml
  rm servers.json
  rm $package
  
 echo "*"
 echo "*              Termux-LMS Install complete "
 echo "*  "
 echo "*  Reboot Termux needed - type exit and press return. Then start from Termux app icon"
 echo "*  "
 echo "*  After reboot: to start LMS service -    sv up lyrion" 
 echo "*                to stop LMS  service -    sv down lyrion" 
 echo "*                to start squeezelite -    sv up squeezelite" 
 echo "*                to stop squeezelite  -    sv down squeezelite" 
 echo "* "
 echo "*  you can also use Termux Widgets to create widgets to start & stop LMS"
 echo "* "
 
popd
