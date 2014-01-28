import pprint
from slpp import slpp
import urlparse

def main(self):
    '''returns all data posted to the file, good way to check what the server thinks it is getting'''
    if self.path_args == None:
        self.send_response(400)
    else:
        #print self.path_args
        pass
    data=self.rfile.read(int(self.headers.getheader('content-length')))
    try:
        data=slpp.decode(data)
    except:
        print "malformed lua table, bailout!"
        self.send_response(400)
        self.end_headers()
        return
    self.send_response(200)
    self.send_header('Content-type',"text/plain")
    self.end_headers()
    #self.wfile.write("test")
    if self.path_args['query'][0]=='item':
        #we are using the AE/ME search system. data is a table of all ME items to look through
        out=[]
        for k,v in data.iteritems():
            if self.path_args['name'][0] in v['name'].lower():
                print v['name'],v['id'],v['dmg']
                out.append(v)
        self.wfile.write(slpp.encode(out))
    elif self.path_args['query'][0]=='dump':
        pprint.pprint(data)
