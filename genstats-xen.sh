#! /bin/bash

# umbrella script to automate the generation of statistics for the xen
# project. Totally hard-coded. Edit the directories, repository locations, and 
# file names for a different project.

XEN_REPO="/Users/mdday/src/xen"
STATS_DIR="/Users/mdday/src/xen-community-analysis"
MAIL_DIR="/Users/mdday/mail/"

echo "preparing the directory structure"

mkdir $STATS_DIR >&/dev/null

for year in $@ ; 
do
    mkdir $STATS_DIR/$year &>/dev/null
done

echo "statistics will be stored in $STATS_DIR"

# start 

pushd $XEN_REPO
pwd
echo "updating the XEN repository"
git pull
git reset --hard origin/master

echo "Generating statistics for XEN for the years $@"

for year in $@ ;
do
    gitstat.sh $XEN_REPO $STATS_DIR/$year/$year-xen-devel-git.csv \
	$STATS_DIR/$year/$year-xen-devel-dom-git.csv \
	--since 01/01/$year --until 12/31/$year
done

popd

echo "Preparing to generate mail list statistics for XEN $@"

for year in $@ ;
do
    pushd $STATS_DIR/$year
    mbox-filter.sh $MAIL_DIR/xen-devel-$year
    popd
done

echo "XEN statistics are in $STATS_DIR"
