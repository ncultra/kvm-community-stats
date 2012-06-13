#! /bin/bash

# umbrella script to automate the generation of statistics for the kvm and qemu
# projects. Totally hard-coded. Edit the directories, repository locations, and 
# file names for a different project.


#####
# prepare haystack and needle for gitmatch
# break git domain csv into a separate file from git contributions csv
# strip commas, strip numbers, sort | uniq > git domain needles
# strip commas from git domain csv to generate haystack
# $ cat 2008-kvm-devel-git.csv | awk '{gsub('/\,/', ""); print $0}' > 2008-kvm-devel-git.csv
#####    emcraft.com 3 41 19


KVM_REPO="/Users/mdday/src/kvm"
QEMU_REPO="/Users/mdday/src/qemu"
STATS_DIR="/Users/mdday/src/kvm-community-analysis"
MAIL_DIR="/Users/mdday/mail/"

echo "preparing the directory structure"

mkdir $STATS_DIR >&/dev/null

for year in $@ ; 
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


echo "Generating statistics for KVM for the years $@"

for year in $@ ;
do
    gitstat.sh $KVM_REPO $STATS_DIR/$year/$year-kvm-devel-git.csv --since 01/01/$year --until 12/31/$year
done

popd

echo "Preparing to generate mail list statistics for KVM $@"

for year in $@ ;
do
    pushd $STATS_DIR/$year
    mbox-filter.sh $MAIL_DIR/kvm-devel-$year
    popd
done

echo "KVM statistics are in $STATS_DIR"


echo "Now working on Qemu.."
pushd $QEMU_REPO
pwd
echo "updating the Qemu repository"
git pull
git reset --hard origin/master


echo "Generating statistics for Qemu for the years $@"

GITSTATDIRSQEMU=$(mktemp /tmp/gitstatdirs.XXXXXXXXXX)

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


for year in $@ ;
do
    gitstat.sh $QEMU_REPO $STATS_DIR/$year/$year-qemu-git.csv --since 01/01/$year --until 12/31/$year -D $GITSTATDIRSQEMU
done

popd

rm $GITSTATDIRSQEMU >&/dev/null

echo "Preparing to generate mail list statistics for Qemu $@"


for year in $@ ;
do
    pushd $STATS_DIR/$year
    mbox-filter.sh $MAIL_DIR/qemu-$year
    popd
done

echo "qemu statistics are in $STATS_DIR"

