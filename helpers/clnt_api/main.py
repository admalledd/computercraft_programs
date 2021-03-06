#!/usr/bin/python

"""

Takes requests from the server and passes them to the proper handler.

Handlers that would be a good idea (tm):

* puts.py (Dump information from a CC program back to the dev)
* loader.py (load a file from local hdd to CC)
* gen_programlist.py (regenerate based on http call the programlist DB for getprog)
"""


#startup:
# 16 char "Version"
# 8 char "UID/OID"

#packet "desc"
# 8 char "header"
#    4 char content_len
#    4 char "short func"
# XX char JSON data

#"short funcs" (some may be only on one side, described in parens which side)
# "ping" (client) ping/pong keepalive
# "pong" (server) pong-response data is mirror of "ping"'d data
# "dcon" (client/server) disconnect from other end "cleanly"
# "evnt" (client) Server is requesting resource/higher level processing. See "evnt" desc bellow.


import socket,threading
import sys
import struct
import json
import string
import os,os.path
import pprint
import time

HOST, PORT = "mc.admalledd.com", 8083

#provided by API hoster, is semi-secure key
# generated via 
# >>> syms = string.ascii_letters+string.digits+string.punctuation
# >>> ''.join([syms[i] for i in [random.randrange(0,len(syms)) for x in range(8)]])
UID = ";Yh|_~,2"
#UID = "{[1yQ+@@"

#Directory where CLink files should be retrieved from, Defaults to project directory
BASE_FILE_PATH = os.path.realpath(os.path.join(os.getcwd(),'..','..','cc_code'))

def is_subdir(path, directory):
    path = os.path.realpath(path)
    directory = os.path.realpath(directory)
    relative = os.path.relpath(path, directory)
    return not relative.startswith(os.pardir + os.sep)

def get_file(path):
    #if path.startswith('/'): path = path[1:] #string starting "/"
    path = os.path.join(BASE_FILE_PATH, *path.split('/'))
    #check for path-escape stuff
    if not is_subdir(path, BASE_FILE_PATH):
        print "get_file() request was for a file outside of BASE_FILE_PATH! got: %r" % path
        return None # aka file not found
    if os.path.exists(path):
        return open(path, 'r').read()
    else:
        print "get_file() requested file not found! file: %r" % path

class cl_net(object):
    def __init__(self, host, port, UID):
        self.UID = UID
        self.HOST,self.PORT = host,port

        self.sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self.slock = threading.Lock()

    @staticmethod
    def make_packet(action,data):
        '''
        this function is broken out so others beyond the writer can use it
        packet def:
            '####xxxx'
            4 chars of number, being packet size packed using struct.pack('I',####)
            4 chars of ASCII letters, to either:
                if from devuser: to translate into function names (eg: 'ghit'==def got_hit(self,weapon)...)
                    here data would be the json object representing the weapon
                if from server: action name for suit to do (eg, 'chst'==changestats)
                    here data would be something like: {'health':('-',5)} #loose five health
        '''
        if len(action.encode('ascii')) !=4:
            raise Exception('action must be 4 chars.')
        data = json.dumps(data)#,skipkeys=True,default=lambda o:str(o)
        header=struct.pack('I',len(data))+action.encode('ascii')
        return header+data.encode('ascii')

    def write_sock(self,bytes):
        with self.slock:
            self.sock.sendall(bytes)

    def run_forever(self):
        self.connect()
        try:
            self.serve_forever()
        finally:
            print "client link closing"
            self.close()

    def connect(self):
        self.sock.connect((self.HOST,self.PORT))

        #send handshake/auth
        self.write_sock("cdv-0.0.1develop"+self.UID)

        #startup ping thread
        self.ping_thread = threading.Thread(target=self.ping_keep_alive)
        self.ping_thread.setDaemon(True)
        self.ping_thread.start()

    def ping_keep_alive(self):
        import time
        loop_count = 0
        while True:
            time.sleep(20)
            self.write_sock(self.make_packet('ping',{"count":loop_count}))
            loop_count += 1

    def serve_forever(self):
        while True:
            self.handle_one()

    def handle_one(self):

        header = self.sock.recv(8)
        content_len = struct.unpack('I',header[:4])[0]
        #see description above for header layout
        short_func = header[4:].decode("ascii")
        for ch in short_func:
            if ch not in string.ascii_letters:
                raise Exception('received bad call function, must be ascii_letters. got:"%s"'%short_func)

        def read_chunky(chk_len):
            'read semi-chunked content, allows for retrying better-ish'
            ##read data in 4096 byte chunks, but once under, use actual size
            ##TODO: rate limit the input, as is we read more and more data till we run out of ram. we need a max packet size and handler
            if chk_len >4096:
                tcon = chk_len
                data = []
                while tcon > 4096:
                    data.append(self.sock.recv(4096))
                    tcon = tcon-4096
                    #time.sleep(0.01)
                data.append(self.sock.recv(tcon))
                data = ''.join(data)
            else:
                data = self.sock.recv(chk_len)    
            return data
        
        data = ''
        while len(data) != content_len:
            #print "length delta: %d ::: %d"%(content_len,len(data))    
            data += read_chunky(content_len - len(data))

        data=data.decode("UTF-8")
        
        #pprint.pprint(data)
        jdata=json.loads(data)#must always have json data, of none/invalid let loads die

        if short_func == b'dcon':
            #dcon==disconnect sock, do not pass up the layers, we handle that elsewhere...
            self.close()
            return
        elif short_func == b'ping':
            pong = self.make_packet("pong",jdata)
            self.write_sock(pong)
            return
        elif short_func == b'pong':
            #print "pong returned, loop data: %r" % jdata
            return
        elif short_func == b'evnt':
            #all higher-level function stuff is via "event" stuff here
            self.run_packet(jdata)
            return
        # if we get here, unkown short func!
        print "Unkown short_func: '%s'"%short_func

    def close(self):
        self.write_sock(self.make_packet("dcon",{}))
        self.sock.close()

    def run_packet(self, event):
        if 'request_type' not in event:
            print "bad event was sent!"
            return
        if  event['request_type'] == 'puts':
            print "put_data event:"
            pprint.pprint(event['data'])
        elif event['request_type'] == 'get_file':
            print "getting file %r" % event['path']
            fcontents = get_file(event['path'])
            rdata = {
                "file_contents": fcontents,
                "event_id": event['event_id']
            }
            resp = self.make_packet('evnt',rdata)
            self.write_sock(resp)


if __name__ == '__main__':
    print "connecting to API server (%s:%s) with filedir==%r"%(HOST,PORT,BASE_FILE_PATH)
    c = cl_net(HOST,PORT,UID)
    c.run_forever()
