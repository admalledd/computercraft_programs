'''

"$CCSERVER/clink.py?user=$FOO&req=$BAR"

'''
import traceback


import client_link
from slpp import slpp


def main(self):
    print "got clinker.py call for %s::%s"%(self.path,self.path_args)

    if 'user' not in self.path_args:
        return self.send_error(403, 'no user specified!')

    unames = [uname for uname,oid in client_link.OID_map]

    if self.path_args['user'][0] not in unames:
        return self.send_error(403, 'user not found!')

    user_handler = client_link.user_handlers[self.path_args['user'][0]]

    if 'req' not in self.path_args:
        return self.send_error(404, "no request type requested!")

    if self.path_args['req'][0] == "get_file":
        if 'file' not in self.path_args:
            return self.send_error(400, "no file requested!")
        fcontents = user_handler.get_file(self.path_args['file'][0])
        if fcontents == None:
            return self.send_error(404,'File Not Found: %s' % self.path_args['file'][0])
        else:
            self.send_response(200)
            self.send_header('Content-type','text/plain')
            self.send_header('Content-length',len(fcontents))
            self.end_headers()
            self.wfile.write(fcontents)
            return
    elif self.path_args['req'][0] == 'puts' and self.posting:
        data=self.rfile.read(int(self.headers.getheader('content-length')))
        try:
            data=slpp.decode(data)
        except:
            traceback.print_exc(file=self.wfile)#web
            return self.send_error(400,"malformed LUA table, unable to parse for PUTS")
        user_handler.put_data(data)
        self.send_response(200)
        self.send_header('Content-type',"text/plain")
        self.end_headers()
        return

