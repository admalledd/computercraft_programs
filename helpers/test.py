
import SocketServer,socket,threading

port=8083

class con_handler(SocketServer.BaseRequestHandler): 
    def setup(self):
        print "got con from %r"%(self.client_address,)


class V6Server(SocketServer.ThreadingTCPServer):
    address_family = socket.AF_INET6

def run_server(srv):
    try:
        srv.socket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        if srv.address_family == socket.AF_INET6:
            srv.socket.setsockopt(socket.IPPROTO_IPV6, socket.IPV6_V6ONLY, 1)
        srv.server_bind()
        srv.server_activate()

        srv.serve_forever()
    finally:
        srv.server_close()

server=SocketServer.ThreadingTCPServer(('0.0.0.0',port), con_handler, False)
server.daemon_threads = True
server_thread = threading.Thread(target=run_server,args=(server,))
server_thread.setDaemon(True)
server_thread.start()

server6=V6Server(('::',port,0,0), con_handler, False)
server6.daemon_threads = True
server6_thread = threading.Thread(target=run_server,args=(server6,))
server6_thread.setDaemon(True)
server6_thread.start()
import time;time.sleep(60)