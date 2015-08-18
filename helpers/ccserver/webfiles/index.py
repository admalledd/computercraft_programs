import client_link

def main(self):

    self.send_response(200)
    self.send_header('Content-type',    'text/plain')
    self.end_headers()

    self.wfile.write('you are supposed to get an actual file, not the base URL... \n')
    self.wfile.write('or are you just testing?')