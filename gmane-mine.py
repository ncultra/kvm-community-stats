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

import argparse, urllib

url_base = "http://blog.gmane.org/"

parser = argparse.ArgumentParser(description = "Mine gmane for mbox archive.")
parser.add_argument("--list", nargs=1, required=True, help="gmane list name", 
                    metavar="list name")
parser.add_argument("--start", required=True, help="starting date <yyyymmdd>", 
                    metavar="start")
parser.add_argument("--end", required=True, help="ending date <yyyymmdd>", 
                    metavar = "end")
# convert to a dict. 
args = vars(parser.parse_args())

start_url = url_base + args["list"][0] + "/" + args["start"]
end_url = url_base + args["list"][0] + "/" + args["end"]

fp = urllib.urlopen(start_url)
try:
    data = fp.read()
finally:
    fp.close()
print args
print start_url
print end_url
print data
