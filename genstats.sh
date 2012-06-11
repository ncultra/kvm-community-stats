#! /bin/bash

# umbrella script to automate the generation of statistics for the kvm and qemu
# projects. Totally hard-coded. Edit the directories, repository locations, and 
# file names for a different project.

KVM_REPO="/Users/mdday/src/kvm"
QEMU_REPO="/Users/mdday/src/qemu"
STATS_DIR="/Users/mdday/src/kvm-community-analysis"
MAIL_DIR="/Users/mdday/mail/"

echo "preparing the directory structure"

mkdir $STATS_DIR >&/dev/null

for year in 2008 2009 2010 2011 ; 
do
    mkdir $STATS_DIR/$year &>/dev/null
done

echo "statistics will be stored in $STATS_DIR"

# start with KVM

pushd $KVM_REPO
pwd
echo "updating the KVM repository"
git pull
git reset --hard origin/master


echo "Generating statistics for KVM for the years 2008-2011"

for year in 2008 2009 2010 2011 ;
do
    gitstat.sh $KVM_REPO $STATS_DIR/$year/$year-kvm-git.csv --since 01/01/$year --until 12/31/$year
done

popd

echo "Preparing to generate mail list statistics for KVM 2008-2011"

for year in 2008 2009 2010 2011 ;
do
    mbox-filter.sh $MAIL_DIR/kvm-devel-$year
done

echo "KVM statistics are in $STATS_DIR"


echo "Now working on Qemu.."
pushd $QEMU_REPO
pwd
echo "updating the Qemu repository"
git pull
git reset --hard origin/master


echo "Generating statistics for Qemu for the years 2008-2011"

GITSTATDIRSQEMU=$(mktemp /tmp/gitstats.XXXXXXXXXX)

cat > $GITSTATDIRSQEMU  <<EOF
QMP
audio
block
bsd-user
default-configs
docs
fpu
fsdev
gdb-xml
hw
include
libcacard
linux-headers
linux-user
net
pc-bios
qapi
qga
qom
roms
scripts
sysconfigs
target-i386
target-ppc
target-s390x
tests
trace
ui

EOF


for year in 2008 2009 2010 2011 ;
do
    gitstat.sh $QEMU_REPO $STATS_DIR/$year --since 01/01/$year --until 12/31/$year \
	-D $GITSTATDIRSQEMU

done

popd

rm $GITSTATDIRSQEMU >&/dev/null

echo "Preparing to generate mail list statistics for Qemu 2008-2011"


for year in 2008 2009 2010 2011 ;
do
    pushd $STATS_DIR/$year
    mbox-filter.sh $MAIL_DIR/qemu-$year
    popd
done

echo "qemu statistics are in $STATS_DIR"

