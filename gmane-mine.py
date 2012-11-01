#!/usr/bin/python

'''
download an mbox archive from gmane

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
parser.add_argument("--start", required=True, help="starting date <yyyymmdd>", 
                    metavar="<yyyymmdd>")
parser.add_argument("--end", required=True, help="ending date <yyyymmdd>", 
                    metavar = "<yyyymmdd>")

# convert to a dict. 
args = vars(parser.parse_args())

start_id = get_msg_id(args["list"][0], args["start"])
end_id = get_msg_id(args["list"][0], args["end"])

download_messages(args["list"][0], start_id, end_id)
