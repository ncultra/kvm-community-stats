#! /bin/bash



#"From:" headers of all messages, to be used as haystack input to amat

~/src/mbox-filter.py --file=/Users/mdday/mail/qemu-2011 --filter=header --op=From --exp='.*\..*' --concise | grep ^From:


# build a needles file that can be used by amat - it expects canonical
# email addresses
$ cat ~/src/kvm-community-analysis/qemu-2011-from |   awk '{ gsub('/^From\:/',"",$0); gsub('/=.*=/', "", $0); gsub('/^[[:space:]]*/',"",$0); gsub('/\"/',"",$0); print $0}' | sort -f | uniq -i > ~/src/kvm-community-analysis/qemu-2011-needles

# uniqiue contributors to the mailing list, sorted
~/src/mbox-filter.py --file=/Users/mdday/mail/qemu-2011 \
    --filter=header --op=From --exp='.*@.*ibm\.com' \
    --concise | grep ^From: | \
    awk '{ gsub('/^From\:/',"",$0); gsub('/=.*=/', "", $0); gsub('/^[[:space:]]*/',"",$0); gsub('/\"/',"",$0); print $0}' \
    | sort -f | uniq -i


# CSV file of contributors and message counts per contributor
$ cat ~/src/kvm-community-analysis/qemu-2011-needles |  awk '{ gsub('/^From\:/',"",$0) ; gsub('/^[[:space:]]{1}/',"",$0); gsub('/\"/',"",$0); print $0}' | amat --csv --domain 2 --haystack ~/src/kvm-community-analysis/qemu-2011-from > ~/src/kvm-community-analysis/qemu-2011-contributors.csv 



# unique organizations (domains) contributing to the mailing list, sorted
# stripped to 2nd level domain, e.g. "ibm.com"

# TODO: need to strip trailing characters (can only be up to three characters after the 
# top level domain
cat ~/mail/qemu-2011 | grep ^From\: | astrip --domain 2 - | sort -fub


#l get a count of messages sent per organization (domain)
cat ~/mail/qemu-2011 | grep ^From\: | amat --needles /tmp/montana-qemu.txt --domain 2 -

# get a count of individuals sending messages to the list
amat --needles /tmp/qemu-2011-needles --domain 2 --haystack /tmp/qemu-2011-from  | uniq -i | sort -fbnr | wc -l


# numerically sorted ranking of individual contributors to development email list
cat ~/src/kvm-community-analysis/qemu-2011-needles |  awk '{ gsub('/^From\:/',"",$0) ; gsub('/^[[:space:]]{1}/',"",$0); gsub('/\"/',"",$0); print $0}' | amat --domain 2 --haystack ~/src/kvm-community-analysis/qemu-2011-from | sort -fbnr
# same as above, but output in CSV format
 cat ~/src/kvm-community-analysis/qemu-2011-needles |  awk '{ gsub('/^From\:/',"",$0) ; gsub('/^[[:space:]]{1}/',"",$0); gsub('/\"/',"",$0); print $0}' | amat --csv --domain 2 --haystack ~/src/kvm-community-analysis/qemu-2011-from | sort -fb

#
# remove wide char-encoded names
awk '{ gsub('/=.*=/', "", $0); print $0 }'
