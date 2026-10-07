from __future__ import annotations
from os import path
import rookiepy
_cookies = []

def get_cookies():
    global _cookies
    if _cookies == []:
        cookies = rookiepy.load()
        _cookies = cookies
        _cookies = [cookie for cookie in _cookies if (cookie.get("value","")!="" and cookie.get("value","")!=None and isinstance(cookie.get("expires",0),int))]
    return _cookies