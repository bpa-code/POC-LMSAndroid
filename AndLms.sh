#!/usr/bin/env bash
pushd $PREFIX
pushd $TMPDIR
wget https://github.com/bpa-code/POC-LMSAndroid/raw/main/iosocketssl-perl.tgz
wget https://github.com/bpa-code/POC-LMSAndroid/raw/main/netssleay-perl.tgz
wget https://github.com/bpa-code/POC-LMSAndroid/raw/main/logitechmediaserver-8.5.0-aarch64-android.tgz
popd
cd ..
tar xvzf $TMPDIR/iosocketssl-perl.tgz
tar xvzf $TMPDIR/netssleay-perl.tgz
tar xvzf $TMPDIR/logitechmediaserver-8.5.0-aarch64-android.tgz

rm $TMPDIR/iosocketssl-perl.tgz
rm $TMPDIR/netssleay-perl.tgz
rm $TMPDIR/logitechmediaserver-8.5.0-aarch64-android.tgz

popd







