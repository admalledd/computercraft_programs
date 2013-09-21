
import chatterbot

import cgi

bot1session = chatterbot.ChatterBotFactory().create(chatterbot.ChatterBotType.CLEVERBOT).create_session()    
def main(self):
    ctype, pdict = cgi.parse_header(self.headers.getheader('content-type'))
    print self.headers
    if ctype == 'multipart/form-data':
        self.query=cgi.parse_multipart(self.rfile, pdict)
    elif ctype == "application/x-www-form-urlencoded":
        self.query = self.rfile.read(int(self.headers.getheader('Content-Length')))
    self.send_response(200)
    self.end_headers()
    resp = bot1session.think(self.query)
    self.wfile.write("<HTML><BODOY>\n")
    print self.query
    print resp
    self.wfile.write(resp+'\n')
    self.wfile.write("</BODY></HTML>")
    return