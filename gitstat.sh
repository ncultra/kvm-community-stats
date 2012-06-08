#! /bin/bash




# By individual contributor
# reformat the output of gitstat into a CSV file that has fields
# for name, email, commits, lines added, lines removed. 
# You can load the resulting file into a spreadsheet program
# for analysis

GITSTATS=$(mktemp /tmp/gitstats.XXXXXXXXXX)

echo "Preparing to run gitstats"
awk '{print}'  > $GITSTATS   <<EOF
Name, Email, Commits, Lines Added, Lines Removed
EOF

gitstat.py --one-line -f  $@\
    | awk '{gsub('/[\(\)]/',"",$0); \
            gsub('/\\+/', "", $0); \
            gsub('/\\//'," ", $0); \
            gsub('/\\-/',"", $0) ;   \
            gsub('/[[\<\>]]?/',"",$0) ; \
            print $0 }' \
    | awk '{ if (NF == 7) printf "\"%s %s\", %s, %s, %s, %s\n", $1, $2, $3, $4, $6, $7 ; \
             else if (NF == 8) printf "\"%s %s %s\", %s, %s, %s, %s\n", $1, $2, $3, $4, $5, $7, $8 }' \
    | tee -a $GITSTATS

echo "gitstats is complete, now processing the results"
echo >> $GITSTATS
echo >> $GITSTATS
awk '{print}'  >> $GITSTATS   <<EOF
Domain, Commits, Lines Added, Lines Removed
EOF
cat $GITSTATS | astrip --domain 2 | tee -a $GITSTATS
cat $GITSTATS
rm $GITSTATS
