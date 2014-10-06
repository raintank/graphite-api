from flask.sessions import SessionInterface, SecureCookieSession
import hashlib
import urllib, hmac
import json
import base64

def sign(val, app):
    signed = hmac.new(app.secret_key, val, hashlib.sha256)
    return base64.b64encode(signed.digest()).strip(b'=')    

class raintankSessionInterface(SessionInterface):
    ''' Session class that can extract a signed cookie
        created by the NodeJS Express framework.
    '''
    session_class = SecureCookieSession

    def open_session(self, app, request):
        c = request.cookies.get(app.session_cookie_name)
        if not c:
            return self.session_class()
        c = urllib.unquote(request.cookies.get(app.session_cookie_name))
        parts = c.split('.')
        signature = parts[-1]
        val = '.'.join(parts[0:-1])
        if not val or not val.startswith('s:j:'):
            return self.session_class()
        sig = sign(val[2:], app)
        if sig != signature:
            return self.session_class()
        jsonData = val[4:]
        try:
            data = json.loads(jsonData)
            return self.session_class(data)
        except BadSignature:
            return self.session_class()

    def save_session(self, app, session, response):
        pass
    
    def should_set_cookie(self, app, session):
        return False

