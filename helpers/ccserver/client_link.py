
"""
Server-side linking of TCP connections from developer client servers.

Idea is:

* CC getprog/debug.lua request something like "$CCSERVER/clink.py?user=$FOO&req=$BAR"
* $CCSERVER finds client-linked user by name/ID "FOO" and handles request
* DevLink has persistent connection to $CCSERVER (and "authenticates" UID/pain text password)

"""

import SocketServer,socket
import struct
import string
import json
import time
import threading
from StringIO import StringIO as sio
import traceback
import Queue
import random
import sys
import time

net_cons={}

class con_handler(SocketServer.BaseRequestHandler):
    '''handle a reconnecting object, put new descriptor in the relevent connection dict,
    if the relevent list does not have the relevant OID create new.
    '''
    def __init__(self, request, client_address, server):
        self.request = request
        self.client_address = client_address
        self.server = server
        self.slock = threading.Lock()

        try:
            self.setup()
            self.handle()
            self.finish()
        except Exception:
            self.finnish_ex()
        finally:
            if self.OID != None:
                print 'a connection from OID %r closed' % self.OID
                #if we are the current netobj, clear ourselves out of there.
                if net_cons[self.OID] == self:
                    net_cons[self.OID]=None

    def write_sock(self,bytes):
        'Protect parallel writes to the socket, only one "packet" at a time'
        with self.slock:
            self.request.sendall(bytes)

    def setup(self):
        '''
        create queue's and get the OID. place handler in users
        
        queue's are in self.qu{first_tpye:queue}
        
        note that because we have no data yet for internal use we have to repeat much of the network code here
        if any problems occur with network code, please check both places due to this repeat that is difficult to remove
        '''
        #suit version: 16 char string representing version, start with 'cdv': CC development
        self.OID=None
        self.entversion=self.request.recv(16)
        if not self.entversion.startswith(b'cdv'):
            raise Exception('connection not from client linker to this client link API server!')

        #OID is the second thing sent over the wire
        self.OID=self.request.recv(8)

        #"Authenticate" with the API key/OID

        if self.OID not in [oid for uname,oid in OID_map]:
            print "unkown OID tried to connect: '%r'" % self.OID
            self.close()
            return

        self.user_name = OID_map[[oid for uname,oid in OID_map].index(self.OID)][0]

        #set timeout for network latency
        self.request.settimeout(10)
        self.run_handler=True

        self.last_ping_time = time.time()

        if self.OID in net_cons:
            print "new connection for %r is already connected, overwriting old with new" % self.user_name
            try:
                if net_cons[self.OID] != None:
                    net_cons[self.OID].close()
                    net_cons[self.OID] = None
            except Exception, e:
                print "small error during clean up of old connection, ignoring: %s" % e
                traceback.print_exc()
            net_cons[self.OID] = self
        else:
            print "new netobj object being created for %r" % self.user_name
            net_cons[self.OID] = self

        print "user '%s' is now connected via %r." % (self.user_name, self.request.getpeername())

    def close(self):
        self.run_handler=False
        time.sleep(0.30)#wait for the handlers to close normally, but we can force it as well...
        self.request.close()#and if the handler is still open, this kills it with socket errors

    def handle(self):
        while self.run_handler:
            try:
                self.handle_one()
            except socket.timeout:
                #check if ping is horrible:
                delta = time.time() - self.last_ping_time
                if delta > 30:
                    print "warning: user %s client link is slow to respond! delta:%s" %(self.user_name,delta)
                if delta > 60:
                    print "warning: user %s did not ping in time! disconnecting! delta:%s"%(self.user_name,delta)
                    break
            except Exception as e:
                print "handle_one() error for user %s:" % self.user_name
                traceback.print_exc()
        self.close()

    def handle_one(self):
        header = self.request.recv(8)
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
        jdata=json.loads(data)#must always have json data, of none/invalid let loads die

        if short_func == b'dcon':
            #dcon==disconnect request, do not pass up the layers, we handle that elsewhere...
            self.close()
            return
        elif short_func == b'ping':
            self.last_ping_time = time.time()
            pong = self.make_packet("pong",jdata)
            self.write_sock(pong)
            return
        elif short_func == b'evnt':
            #all higher-level function stuff is via "event" stuff here
            user_handlers[self.user_name].run_packet(jdata)
            return

        # if we get here, unkown short func!
        print "Unkown short_func from OID '%r': '%s'"%(self.OID, short_func)
        
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

    def finnish(self):
        print 'OBJECT %s requested connection closed.'%self.OID

    def finnish_ex(self):
        buff=sio()
        traceback.print_exc(file=buff)
        if self.OID is not None:
            buff.write('OBJECT ID: %s\n'%self.OID)
        print 'network communication error! %s'%buff.getvalue()
        buff.close()
        del buff#stupid GC hates me

class Event(object):
    ''' Little helper class to be able to wait on CLink data being fed back'''
    def __init__(self):
        self.thread_event = threading.Event()

    def wait(self):
        timedout = not self.thread_event.wait(5)
        if timedout:
            raise Exception("Timed out waiting for CLink client response")
        self.thread_event.clear()
        return self.data

    def set(self, data):
        self.data = data
        self.thread_event.set()

class UserHandler(object):
    def __init__(self, OID, user_name):
        self.user_name = user_name
        self.OID = OID
        self.events = {}

    def run_packet(self, event):
        #print "got packet! data: %r" %(event,)
        if 'event_id' in event:
            if event['event_id'] in self.events:
                self.events[event['event_id']].set(event)
                del self.events[event['event_id']] #freedom!
            else:
                #Event that started from client
                #TODO: client --> server events?
                print "TODO: client --> server events. EID==%r" % event['event_id']
        else:
            print "no event ID was passed for packet, no idea what to do! User '%s'" % self.user_name

    def send_event(self, data):
        #add event ID and add it to self.events
        data['event_id'] = random.randint(0,sys.maxint)
        event = Event()
        self.events[data['event_id']]=event
        self.send_data(data)
        #return our waitable event for this request
        return event

    def send_data(self, data):

        #check we have a connection
        if self.OID not in net_cons or net_cons[self.OID] is None:
            raise Exception("User is not connected")

        #Send down the wire
        pckt = net_cons[self.OID].make_packet("evnt",data)
        net_cons[self.OID].write_sock(pckt)

    def get_file(self, path):
        '''
        is called from the CCSERVER, returns contents of file (UTF-8 plain text only!)
        example json: {"request_type":"get_file","path":"/foo/bar.lua"}
        '''
        ev = self.send_event({"request_type":"get_file","path":path})
        return ev.wait()['file_contents']

    def put_data(self, data):
        '''
        Sends data to user client, eg a var dump from CC via `http.post(ltable)`
        '''
        self.send_data({"request_type":"puts","data":data})


user_handlers = {}
OID_map = []

for var, val in sys.modules['__main__'].config.items("Clink_Users"):
    if len(val) == 8:
        print "loading new user/OID mapping for CLINK: (%s,%r)"%(var,val)
        OID_map.append((var,val))

server=None
server_thread=None
def start(netface):
    global server
    global server_thread
    def run_server():
        try:
            server.serve_forever()
        finally:
            server.server.close()
    for uname, oid in OID_map:
        user_handlers[uname] = UserHandler(oid,uname)

    server=SocketServer.ThreadingTCPServer(netface, con_handler)
    server.daemon_threads = True
    server_thread = threading.Thread(target=run_server)
    server_thread.setDaemon(True)
    server_thread.start()