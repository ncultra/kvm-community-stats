#!/usr/bin/python

'''
download an mbox archive from gmane

1) find first permalink

2) extract url
import re
match = re.search(r'href=[\'"]?([^\'" >]+)', s)
if match:
    print match.group(0)
3 split and get message id

import urlparse
url = "http://example/url/being/used/to/show/problem"
parsed = urlparse.urlparse(url)
path = parsed[2] #this is the path element

pathlist = path.split("/")
I get the list:

['', 'url', 'being', 'used', 'to', 'show', 'problem']



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
        count = 1
        while data:
            sys.stdout.write(data)
            data = fp.readline()
            count += 1
            if not  count % 1000:
                if args["throttle"] is True:
                    time.sleep(1)
    finally:
        fp.close()


parser = argparse.ArgumentParser(description = "Mine gmane for mbox archive.")
parser.add_argument("--list", nargs=1, required=True, help="gmane list name", 
                    metavar="list name")
parser.add_argument("--start", required=True, help="starting date <yyyymmdd>", 
                    metavar="start")
parser.add_argument("--end", required=True, help="ending date <yyyymmdd>", 
                    metavar = "end")
parser.add_argument("--throttle", help="throttle the download so gname doesn't cut off the session.", 
                    action="store_true")
# convert to a dict. 
args = vars(parser.parse_args())

start_id = get_msg_id(args["list"][0], args["start"])
end_id = get_msg_id(args["list"][0], args["end"])

download_messages(args["list"][0], start_id, end_id)
