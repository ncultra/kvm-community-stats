#!/usr/bin/env python
"""
/*****************************************************************
 *  copyright (c) 2010, Michael D. Day
 *
 *  This work is licensed under the GNU GPL, version 2. See 
 *  http://www.gnu.org/licenses/gpl-2.0.txt
 *
 ****************************************************************/

This is an mbox filter. It scans through an entire mbox style mailbox
and writes the messages to a new file. Each message is passed
through a filter function which may modify the document or ignore it.

The passthrough_filter() example below simply prints the 'from' email
address and returns the document unchanged. After running this script
the input mailbox and output mailbox should be identical.

"""

import mailbox, rfc822
import sys, os, string, re, datetime

from optparse import OptionParser

LF = '\x0a'
options = {}
def main ():
    global options
    usage = "usage: %prog [options] arg"
    parser = OptionParser(usage)
    parser.add_option("--file", dest="mbox_in",
                      help="mbox file to read (required)")
    parser.add_option("--out", dest="mbox_out", help="output mbox")
    parser.add_option("--filter", dest="filter", default="date",
                      help="filter type (date, header, regexp)")
    parser.add_option("--exp", dest="exp", 
                      help="filter expression (depends on filter type)")
    parser.add_option("--op", dest="op", default="=", help="filter operand")
    parser.add_option("--invert", dest="mbox_invert",
                      help="invert filter and output to a secondary file")
    parser.add_option("--verbose", dest="verbose", action="store_true", default=False)
    parser.add_option("--concise", dest="concise", action="store_true", default=False)

    (options, args) = parser.parse_args()


    if options.mbox_in is None:
        parser.print_help()
        sys.exit(-1)

    if "date" in string.lower(options.filter):
        return process_mailbox (date_filter)
    if "header" in string.lower(options.filter):
        return process_mailbox (header_filter)
    if "regexp" in string.lower(options.filter):
        return process_mailbox(regexp_filter)
    
    process_mailbox (passthrough_filter)



#datetime.datetime(year, month, day[, hour[, minute[, second[, microsecond[, tzinfo]]]]])

def convertStr(s):
    """Convert string to either int or float."""
    try:
        ret = int(s)
    except ValueError:
        #Try float.
        try:
            ret = float(s)
        except:
            ret = 0
    return ret


def get_datetime(msg_date):
    """ some messages have date strings that don't start with the day of the week"""
    weekday = 0
    day = 0
    month = 0
    year = 0
    days = {'Mon':0, 'Tue':1, 'Wed':2, 'Thu':3, 'Fri':4, 'Sat':5, 'Sun':6}
    months = {'Jan':1, 'Feb':2, 'Mar':3, 'Apr':4, 'May':5, 'Jun':6,
              'Jul':7, 'Aug':8, 'Sep':9, 'Oct':10, 'Nov':11, 'Dec':12,
              'JAN':1, 'FEB':2, 'MAR':3, 'APR':4, 'MAY':5, 'JUN':6,
              'JUL':7, 'AUG':8, 'SEP':9, 'OCT':10, 'NOV':11, 'DEC':12}
    date_strings = re.split("\W", msg_date)
    if len(date_strings) < 3:
        return datetime.datetime.today()

# mailers will use a date string like the following, or perhaps
# without the leading day of week
# Sat,  6 Oct 2007 04:39:36 -0700 (PDT)

    for num in range(6):
        try:
            if date_strings[num] in days:
                weekday = days[date_strings[0]]
                continue
        except:
            continue
        else:
            if str.isdigit(date_strings[num]):
                if day is 0:
                    day = convertStr(date_strings[num])
                else:
                    year = convertStr(date_strings[num])
                    # some git mailer scripts use a two digit year "09"
                    if year < 2000:
                        year += 2000
                    break
            else:
                if date_strings[num] in months:
                    month = months[date_strings[num]]
                    
# some mailers use weird date strings like the following:
# 2007 12 02
    if month == 0:
        year = convertStr(date_strings[0])
        month = convertStr(date_strings[1])
        day = convertStr(date_strings[2])

    try:
        msg_datetime = datetime.datetime(year, month, day)
    except:

# some mailers use a format like the following
# ??, 19 7 09 (TortoiseGit)
        year = convertStr(date_strings[4])
        month = convertStr(date_strings[3])
        day = convertStr(date_strings[2])
        if year < 2000:
            year += 2000
        try:
            msg_datetime = datetime.datetime(year, month, day)
            
        except:
            print "error parsing time stamp for message %d %d %d" %(year, month, day)
            print msg_date
            msg_datetime = datetime.datetime.today()
    return msg_datetime


# Thu, 4 Oct 2007 16:56:06 +0100 (BST)
# filter - date
# exp - <>=
# op  date string
def date_filter (msg, document):
    global options

    ret_doc = None

    # get the message date
    msg_date = msg['Date']
    msg_datetime = get_datetime(msg['Date'])

    #get the filter date
    if options.op is None:
        filter_datetime = datetime.datetime.today()
    else:
        # mm-dd-yyyy
        date_strings = re.split('[-//]', options.op)
        year = convertStr(date_strings[2])
        month = convertStr(date_strings[0])
        day = convertStr(date_strings[1])
        try:
            filter_datetime = datetime.datetime(year, month, day)
        except:
            print("error parsing date filter expression")
            filter_datetime = datetime.datetime.today()

    # now we need to evaluate the filter expression against the
    # message date header

    # msg_datetime exp filter_datetime

    if "<" in options.exp:
        if msg_datetime < filter_datetime:
            ret_doc = document
            
    else:
        if "=" in options.exp:
            if msg_datetime == filter_datetime:
                ret_doc = document

        else:
            if ">" in options.exp:
                if msg_datetime > filter_datetime:
                    ret_doc = document

    if options.verbose is True:
        if ret_doc is not None:
            print msg_date

    return ret_doc

def passthrough_filter (msg, document):
    """This prints the 'from' address of the message and
    returns the document unchanged.
    """
    from_addr = msg.getaddr('From')[1]
    print from_addr
    return document


# filter - header
# exp - regexp to filter header contents
# op - name of header 
def header_filter (msg, document):
    global options
    regxp = None
    try:
        msg_header = msg[options.op]
        regxp = re.compile(options.exp, re.I)
    except:
        print msg_header
        return None

    if regxp is not None:
        if regxp.search(msg_header) is not None:
            if options.verbose is True:
                print msg_header
            return document

    return None


# filter - regexp
# exp - regexp to filter document contents
# op - unused
def regexp_filter (msg, document):
    global options
    regxp = None

    try:
        regxp = re.compile(options.exp)
    except:
        return None

    if regxp is not None:
        if regxp.search(document) is not None:
            if options.verbose is True:
                try:
                    print msg['Subject']
                except:
                    print ""
            return document
    return None

def process_mailbox (filter_function):
    """This processes a each message in the 'in' mailbox and optionally
    writes the message to the 'out' mailbox. Each message is passed to
    the  filter_function. The filter function may return None to ignore
    the message or may return the document to be saved in the 'out' mailbox.
    See passthrough_filter().
    """
    global options
    finvert = None
    match = 0

    if options.mbox_out is None:
        fout = sys.stdout
    else:
        fout = file(options.mbox_out, 'w')

    # Open the mailbox.
    mb = mailbox.UnixMailbox (file(options.mbox_in,'r'))
        
    if options.mbox_invert is not None:
        finvert = file(options.mbox_invert, 'w')
        
    msg = mb.next()
    while msg is not None:
        # Properties of msg cannot be modified, so we pull out the
        # document to handle is separately. We keep msg around to
        # keep track of headers and stuff.
        document = msg.fp.read()

        match = filter_function (msg, document)
        if match is not None:
            write_message (fout, msg, document)
        else:
            if finvert is not None:
                write_message(finvert, msg, document)

        msg = mb.next()

    fout.close()

def write_message (fout, msg, document):
    """This writes an 'rfc822' message to a given file in mbox format.
    This assumes that the arguments 'msg' and 'document' were generate
    by the 'mailbox' module. The important thing to remember is that the
    document MUST end with two linefeeds ('\n'). It comes this way from
    the mailbox module, so you don't need to do anything if you want to
    write it unchanged. If you modified the document then be sure that
    it still ends with '\n\n'.
    """
    fout.write (msg.unixfrom)
    for l in msg.headers:
        fout.write (l)
    fout.write (LF)
    if options.concise is False:
        fout.write (document)

if __name__ == '__main__':
    main ()
