#!/usr/bin/python

'''
download an mbox archive from gmane

gmane-mine.py --list <listname> --start yyyymmdd --end yyyymmdd

   where <listname> is the gmane name of the list. For example, 
   gmane.comp.emulators.qemu is the gmane name of the qemu mailing list. 
   
   --start and --end are the beginning and ending (non-inclusive) of
     the date range in yyyymmdd format. For example, July 4, 1961 is
     19610704

     Here's an example showing how to download qemu messages from
     January 1, 2008 through January 9, 2008:

      gmane-mine.py --list gmane.comp.emulators.qemu --start 20080101 \
         --end 20080110

'''

import argparse, urllib, re, urlparse, time, sys

url_base = "http://blog.gmane.org/"
export_base = "http://download.gmane.org/"    #<list>/851/855

def get_msg_id(list, date):
    url = url_base + list + "/" + "day=" + date
    
    fp = urllib.urlopen(url)
    try:
        data = fp.readline()
        while data:
            match = re.search(r'href=\"http://permalink.gmane.org/([^\'" >]+)', data)
            if match:
                perm_url = match.group(0)
                break
            data = fp.readline()
    finally:
        fp.close()
    if perm_url:
        parsed = urlparse.urlparse(perm_url)
        path = parsed[2]
        pathlist = path.split("/")
        message_id = pathlist[-1]
        return message_id
    else:
        return 0


def download_messages(list, start_id, end_id):
    url = export_base + list + "/" + start_id + "/" + end_id
    fp = urllib.urlopen(url)
    try:
        data = fp.readline()
        while data:
            sys.stdout.write(data)
            data = fp.readline()
    finally:
        fp.close()


parser = argparse.ArgumentParser(description = "Mine gmane for mbox archive.")
parser.add_argument("--list", nargs=1, required=True, help="gmane list name", 
                    metavar="list name")
parser.add_argument("--start", help="starting date <yyyymmdd>", 
                    metavar="<yyyymmdd>")
parser.add_argument("--end", help="ending date <yyyymmdd>", 
                    metavar = "<yyyymmdd>")
parser.add_argument("--year", metavar="<yyyy>")


# convert to a dict. 
args = vars(parser.parse_args())

if args["year"] is not None:
    for i in range(1,13):
        start_id = get_msg_id(args["list"][0], args["year"] + str(i).rjust(2, "0") + "01")
        if i == 12:
            end_id = get_msg_id(args["list"][0], args["year"] + str(i).rjust(2, "0") + "32")
        else:
            end_id = get_msg_id(args["list"][0], args["year"] + str(i+1).rjust(2, "0") + "01")
        download_messages(args["list"][0], start_id, end_id)
        time.sleep(1)
else:
    start_id = get_msg_id(args["list"][0], args["start"])
    end_id = get_msg_id(args["list"][0], args["end"])
    download_messages(args["list"][0], start_id, end_id)
