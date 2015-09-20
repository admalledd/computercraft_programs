'''
This is a small webserver meant to help with the use of the minecraft mod computercraft
the mod can make (simple) http GET/POSTs but more advanced parsing is... a pain
so this webserver takes up the slack and difficulty of most "more advanced"
requests.

also in the GET list is /fs/* paths which are used along with getprog.lua and the programlist:

when under development you can change the paths of the GETS in those to point to this 
server meaning less github pushes while testing.


'''
import md5
import urllib
import urllib2
import urlparse
import uuid
#import xml.dom.minidom

from SocketServer import ThreadingMixIn
from BaseHTTPServer import BaseHTTPRequestHandler, HTTPServer
import socket,threading

import imp
import cgi
import os

import pprint
import traceback

import ConfigParser

try:
    import magic #acess lib magic for MIME types
    mimer = magic.Magic(mime=True)
except:
    print "libmagic import error, falling back to builtin mimetypes"
    import mimetypes
    mimer = None #set to make sure that nothing fails with other code, test for "if mimer:... else:...."

config = ConfigParser.ConfigParser({'ccdir':os.path.dirname(os.path.abspath(__file__))})

#later files over-write. User config should be last.
config.read((
    os.path.join(os.path.dirname(os.path.abspath(__file__)),'config.ini'), #local Config
    "/opt/ccserver/config.ini", #sys config
    os.path.join(os.path.expanduser("~"),'.ccserver.cfg') #user config, should contain USER secret tokens
    ))

#note that fs is from python filesystem (easy_install fs), I only have it installed on pypy
import fs.osfs
webfiles = fs.osfs.OSFS(config.get('ccserver','webfiles'))
project_base=fs.osfs.OSFS(config.get('ccserver','project_base'))

#import after config setup
import client_link

class MyHandler(BaseHTTPRequestHandler):
    def send_html_header(self):
        '''send the most common header: the html headers. done here in case we want to change the normal headers at any time.
        scripts should normaly send headers with this, unless they are doing their own thing, at which point is why we allow 
        a script to not call this and send its own headers.
        
        '''
        self.send_response(200)
        self.send_header('Content-type',    'text/html')
        self.end_headers()
            
    def realfile(self):
        rawdata = webfiles.getcontents(self.path) #if we are here we assume the file exists, therefor we can read the contents like this
        ##TODO: handle buffering so that we dont try to read a 4 gig file and choke on the RAM usage
        
        #find mimetype of file
        if mimer:
            mime = mimer.from_buffer(rawdata)
        else:
            mime = mimetypes.guess_type(self.path,0)[0]

        #send headers
        self.send_response(200)
        self.send_header('Content-type',mime)
        self.end_headers()
        self.wfile.write(rawdata)
    
    def pyfile(self):
        try:
            modual = imp.load_source('', webfiles.getsyspath(self.path))
            modual.main(self)
        except:
            #print to console first in case of broken socket pipe
            print str('-'*60)#console
            traceback.print_exc()#console
            print str('-'*60)+'\n\n'#console
            self.send_error(500, 'Internal dynamix server error')#web and console
            self.wfile.write('<HTML><BODY><PRE>\n\n')#web
            self.wfile.write("Exception in user code:\n")#web
            self.wfile.write(str('-'*60)+'\n\n')#web
            traceback.print_exc(file=self.wfile)#web
            self.wfile.write(str('-'*60)+'\n\n')#web
            self.wfile.write('\n\n</HTML></BODY></PRE>\n')#web
        
    def is_webfile(self,path=None):
        '''called only after the args have been parsed from self.path
        checks if the file is on disk, and in a real area on disk at that.
        
        '''
        if path == None: path=self.path #allow calls using self.is_webfile(path) or use self.path
        return webfiles.exists(path)
        
    def do_GET(self):
        self.posting = False
        try:
            parsed = urlparse.urlparse(self.path)
            self.path_args = urlparse.parse_qs(parsed.query,keep_blank_values=True)
            self.query = parsed.query #raw query, useful for loader.py
            self.path = parsed.path
            if self.path.endswith('/'): #handle index of a directory with this
                
                #check for index.py, then try index.html, if none work, 404
                
                #test index.py
                if self.is_webfile(self.path+'index.py'):
                    self.path=self.path+'index.py'
                    self.pyfile()
                    return
                #test index.html
                elif self.is_webfile(self.path+'index.html'):
                    self.path=self.path+'index.html'
                    self.realfile()
                    return
                #no matches, we fall through to 404
            
            elif self.path.endswith('.py') and self.is_webfile(): #python dynamic code?
                self.pyfile()
                return
                
            elif self.is_webfile(): #final chance at returning a file, check for a real file called self.path
                self.realfile()
                return
                
            self.send_error(404,'File Not Found REPL fail: %s' % self.path)
            return
                
        except IOError:
            self.send_error(404,'File Not Found IOError: %s' % self.path)
     

    def do_POST(self):
        self.posting=True
        self.path_args=None
        try:
            #if '?' in self.path:
            parsed=urlparse.urlparse(self.path)
            self.path_args=urlparse.parse_qs(parsed.query,keep_blank_values=True)
            self.path= parsed.path
            
            if self.path.endswith('.py') and self.is_webfile(): #python dynamic code?
                self.pyfile()
                return
            
        except :
            self.send_error(500, 'Server could not POST data to: %s'%self.path)
            traceback.print_exc(file=self.wfile)
            
        #fell through, unable to POST
        self.send_error(404, 'File Not Found POST error: %s'%self.path)

welcome='''\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/
httpserver started on port: %i
cl-server started on port: %i
\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/
'''

class ThreadingHTTPServer(ThreadingMixIn, HTTPServer):
    # Overrides SocketServer.ThreadingMixIn.daemon_threads
    daemon_threads = True
    # Overrides BaseHTTPServer.HTTPServer.allow_reuse_address
    allow_reuse_address = True

class HTTPServerV6(ThreadingHTTPServer):
    address_family = socket.AF_INET6
    allow_reuse_address = True

    def run_server_in_thread(self):
        def _run_server():
            try:
                self.serve_forever()
            finally:
                self.server.close()
        server_thread = threading.Thread(target=_run_server)
        server_thread.setDaemon(True)
        server_thread.start()
    @staticmethod
    def ipv6fixup(srv):
        "Call just after creating your srv object to fix some ipv6 stuff..."
        #some wizardry to make socket dual-sock ipv4 and ipv6 work
        print "Fixing up srv hosting on %s for ipv4+ipv6 dual stack" % (srv.server_address,)
        srv.socket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        if srv.address_family == socket.AF_INET6:
            srv.socket.setsockopt(socket.IPPROTO_IPV6, socket.IPV6_V6ONLY, 1)
        srv.server_bind()
        srv.server_activate()

def main():
    server = ThreadingHTTPServer(('0.0.0.0', config.getint('ccserver','HTTP_Port')), MyHandler, False)
    HTTPServerV6.ipv6fixup(server)
    server6 = HTTPServerV6(('::', config.getint('ccserver','HTTP_Port')), MyHandler, False)
    HTTPServerV6.ipv6fixup(server6)
    server6.run_server_in_thread()

    client_link.start(config.getint('ccserver','CLINK_Port'))
    print welcome % (config.getint('ccserver','HTTP_Port'), config.getint('ccserver','CLINK_Port'))
    server.serve_forever()
if __name__ == '__main__':
    main()
