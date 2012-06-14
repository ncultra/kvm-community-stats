#! /bin/bash

# output file
# get rid of here document, use command line parameter instead


#usage: gitstat.sh <git repo> <output file.csv> <output file per domain.csv> [paramters for gitstat.py...]





# By individual contributor
# reformat the output of gitstat into a CSV file that has fields
# for name, email, commits, lines added, lines removed. 
# You can load the resulting file into a spreadsheet program
# for analysis

GITSTATS=$(mktemp /tmp/gitstats.XXXXXXXXXX)
GITSTATS_DOMAIN=$(mktemp /tmp/gitstats-dom.XXXXXXXXXX)

# directory of git repository
GITREPO=$1
shift
# the csv file that contains the output of this program
OUTPUT_FILE=$1
shift
# the csv file containing the commits per domain
OUTPUT_FILE_DOM=$1
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

echo "gitstats first stage is complete, now processing the results"
cat $GITSTATS > $OUTPUT_FILE

echo "gitstats - now compiling results per third-level domain"

GITSTATHAYSTACK=$(mktemp /tmp/gitstats-dom-stripped.XXXXXXXXXX)

cat $GITSTATS | astrip --domain 3 |  awk '{gsub('/\,/', ""); print $0}' >  $GITSTATHAYSTACK

GITSTATNEEDLE=$(mktemp /tmp/gitstats-dom-needle.XXXXXXXXXX)
cat $GITSTATHAYSTACK | awk '{print $1}' | sort -fb | uniq -i > $GITSTATNEEDLE

echo "running gitmatch"
gitmatch --haystack $GITSTATHAYSTACK --needles $GITSTATNEEDLE --csv | sort -fb > $OUTPUT_FILE_DOM

popd
