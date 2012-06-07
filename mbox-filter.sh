#! /bin/bash

MBOX_NAME=""
WORKING_DIR=""

echo  "$@"

for mbox in "$@"
do

    echo "Step 1: setting up working subdirectory for $(basename $mbox)"
    MBOX_NAME=$(basename $mbox)
    echo $MBOX_NAME
    mkdir $MBOX_NAME

# descend into the working subdirectory
    pushd $MBOX_NAME
    WORKING_DIR=$(pwd)
   
    echo "Step 2: Generating the From: file for $MBOX_NAME"
    mbox-filter.py --file=$mbox --filter=header --op=From --exp=".*" --concise \
	| grep ^From: > "$MBOX_NAME-from"

    echo "Step 3: Generating the "Needles" file for $mbox"
    cat  "$MBOX_NAME-from" \
	| awk '{ gsub('/^From\:/',"",$0); \
                 gsub('/=.*=/', "", $0); \
                 gsub('/\"/',"",$0); \
                 gsub('/^[[:space:]]*/',"",$0); print $0}' \
	| sort -f | uniq -i > "$MBOX_NAME-needles"

    echo "Step 4: Generating the contributor's CSV file for $mbox"
    cat "$MBOX_NAME-needles" \
	|  awk '{ gsub('/^From\:/',"",$0) ; \
                 gsub('/^[[:space:]]{1}/',"",$0); \
                 gsub('/\"/',"",$0); print $0}' \
	| amat --csv --haystack "$MBOX_NAME-from" > "$MBOX_NAME-contributors.csv"

    echo "Step 5: Generating list of unique two-level domains for $mbox"
    cat "$MBOX_NAME-from" | astrip --domain 2 | sort -fb > "$MBOX_NAME-from-dom"

    echo "Step 6: Generating the "Needles" file per two-level domain for $mbox"
    cat  "$MBOX_NAME-from-dom" | sort -f | uniq -i > "$MBOX_NAME-needles-dom"

    echo "Step 7: Generating the CSV file per two-level domain for $mbox"
    cat "$MBOX_NAME-needles-dom" \
	|  awk '{ gsub('/^From\:/',"",$0) ; \
                 gsub('/^[[:space:]]{1}/',"",$0); \
                 gsub('/\"/',"",$0); print $0}' \
	| amat --csv --domain 2 --haystack "$MBOX_NAME-from-dom" > "$MBOX_NAME-domain.csv"


#  get back to our working root
    popd
done


exit 1
