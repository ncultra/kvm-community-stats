#! /bin/bash

# output file
# get rid of here document, use command line parameter instead


#usage: gitstat.sh <git repo> <output file.csv> [paramters for gitstat.py...]





# By individual contributor
# reformat the output of gitstat into a CSV file that has fields
# for name, email, commits, lines added, lines removed. 
# You can load the resulting file into a spreadsheet program
# for analysis

GITSTATS=$(mktemp /tmp/gitstats.XXXXXXXXXX)


# directory of git repository
GITREPO=$1
shift
# the csv file that contains the output of this program
OUTPUT_FILE=$1
shift

# These are the directories we want to measure for the qemu project
# we do not want to measure some of the platform directories, slirp, and 
# the tiny code generator (tcg)
echo "Preparing to run gitstats $@"

pushd $GITREPO

awk '{print}'  > $GITSTATS   <<EOF
Name, Email, Commits, Lines Added, Lines Removed
EOF

gitstat.py --one-line -f $@ | awk '{gsub('/[\(\)]/',"",$0); \
            gsub('/\\+/', "", $0); \
            gsub('/\\//'," ", $0); \
            gsub('/\\-/',"", $0) ;   \
            gsub('/[[\<\>]]?/',"",$0) ; \
            print $0 }' \
    | awk '{ if (NF == 7) printf "\"%s %s\", %s, %s, %s, %s\n", $1, $2, $3, $4, $6, $7 ; \
             if (NF == 8) printf "\"%s %s %s\", %s, %s, %s, %s\n", $1, $2, $3, $4, $5, $7, $8 ;\
             if (NF == 6) printf "\"%s\", %s, %s, %s, %s\n", $1, $2, $3, $5, $6}' \
    >> $GITSTATS

echo "gitstats is complete, now processing the results"
echo >> $GITSTATS
echo >> $GITSTATS
awk '{print}'  >> $GITSTATS   <<EOF
Domain, Commits, Lines Added, Lines Removed
EOF
cat $GITSTATS | astrip --domain 3 >> $GITSTATS
mv $GITSTATS $OUTPUT_FILE

popd
