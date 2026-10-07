from __future__ import annotations
import warnings, json
from typing import AsyncGenerator
from playwright.async_api import async_playwright
import playwright_stealth
import undetected_playwright
import time
from requests_toolbelt.multipart.encoder import MultipartEncoder
import urllib.parse

## https://github.com/Granitosaurus/playwright-stealth/blob/fbb50332284751db75728eab6900ebd2b7f56446/playwright_stealth/js/navigator.webdriver.js#L4
custom_playwright_stealth_script = """
if (navigator.webdriver === false) {
    // Post Chrome 89.0.4339.0 and already good
} else if (navigator.webdriver === undefined) {
    // Pre Chrome 89.0.4339.0 and already good
} else {
    // Pre Chrome 88.0.4291.0 and needs patching
    delete Object.getPrototypeOf(navigator).webdriver
}
"""
async def add_stealth(page):
    await page.add_init_script(custom_playwright_stealth_script)
    return True

__EXECUTABLE_PATH__  = "C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe"

PLAYWRIGHT_JS_SCRIPT =  """
fetch("{url}", {{
"headers": {headers},
"referrer": "{referrer}",
"referrerPolicy": "{referrerPolicy}",
"body": {body},
"method": "{method}",
"mode": "{mode}",
"credentials": "{credentials}"
}}).then(res => res.text());
"""

PLAYWRIGHT_STREAM_JS_SCRIPT =  """
(async () => {{
fetch("{url}", {{
"headers": {headers},
"referrer": "{referrer}",
"referrerPolicy": "{referrerPolicy}",
"body": {body},
"method": "{method}",
"mode": "{mode}",
"credentials": "{credentials}"
}}).then(response => {{
  free_ai_response_list_{uuid} = []
  if (!response.ok) {{
    free_ai_response_list_{uuid}.unshift("free_ai_response_list_done");
    throw new Error('Network response was not ok');
  }}
  // Get the readable stream of the response
  const responseStream = response.body;

  // Create a readable stream reader
  const reader = responseStream.getReader();
  // Iterative reading of data
  function readChunk() {{
    return reader.read().then(({{ value, done }}) => {{
      if (done) {{
        free_ai_response_list_{uuid}.unshift(value);
        free_ai_response_list_{uuid}.unshift("free_ai_response_list_done");
        return;
      }}
      // Process the read data (this can be processed as needed)
      free_ai_response_list_{uuid}.unshift(value);
      // Continue reading the next block of data
      readChunk();
    }});
  }}
  // Start reading data
  readChunk();
}})
.catch(error => {{
  console.error('have error:', error);
}});
}})()
"""


AUDIO_MUTE_JS_SCRIPT = """() => {
function disableVideoFeatures(video) {
  video.autoplay = false;
  video.muted = true;
  video.src = '';
}

let videos_playwright = document.getElementsByTagName('video');
for (let i = 0; i < videos_playwright.length; i++) {
  disableVideoFeatures(videos_playwright[i]);
}

let observer = new MutationObserver(function(mutations) {
  mutations.forEach(function(mutation) {
  mutation.addedNodes.forEach(function(node) {
    if (node instanceof HTMLVideoElement) {
      disableVideoFeatures(node);
      } else if (node.getElementsByTagName) {
      let videos = node.getElementsByTagName('video');
        for (let i = 0; i < videos.length; i++) {
          disableVideoFeatures(videos[i]);
        }
      }
    });
  });
});

let config_playwright = { childList: true, subtree: true };

observer.observe(document.body, config_playwright);
}"""

class PlaywrightBrowserSession:
    headers = {}
    timeout = 60
    proxies = None
    browser = None
    is_open_url = False
    use_117 = True
    p = None
    page = None

    def __init__(self,headers:dict[str, str]= {}, timeout=60, proxies=None, use_117=True, browser_path="") -> None:
        self.headers = headers
        self.timeout = timeout
        self.proxies = proxies
        self.use_117 = use_117
        self.browser_path = browser_path


    async def with_init_brower(self,**kwargs):
        if self.browser is None:
            await self.init_brower()
        return self

    async def clear_browser(self):
        if self.page:
            self.page = None
        if self.browser:
            await self.browser.close()
            self.browser = None
        if self.p:
            await self.p.stop()
            self.p = None
        self.is_open_url = False

    async def init_brower(self):
        await self.clear_browser()
        ua = None
        if self.use_117:
            ua = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/117.0.0.0 Safari/537.36'
            # ua = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/123.0.0.0 Safari/537.36 Edg/123.0.0.0"

        self.p = await async_playwright().start()
        
        if self.browser_path!="":
            self.browser = await self.p.webkit.launch_persistent_context(
                                        user_data_dir = "",
                                        headless= True,
                                        timeout = self.timeout*1000,
                                        user_agent=ua,
                                        executable_path=self.browser_path,
                                        extra_http_headers = self.headers,
                                        ignore_default_args = ['--mute-audio'],
                                        )
        else:
            self.browser = await self.p.webkit.launch_persistent_context(
                                        user_data_dir = "",
                                        headless= True,
                                        timeout = self.timeout*1000,
                                        user_agent=ua,
                                        extra_http_headers = self.headers,
                                        ignore_default_args = ['--mute-audio'],
                                        )
        ## https://github.com/QIN2DIM/undetected-playwright
        await undetected_playwright.stealth_async(self.browser)

    async def get_browser(self):
        if self.browser is None:
            await self.init_brower()
        return self.browser

    async def open_url(self, base_url):
        self.page = self.browser.pages[0]
        ## https://github.com/Granitosaurus/playwright-stealth
        await playwright_stealth.stealth_async(self.page)
        await add_stealth(self.page)
        await self.page.goto(base_url)
        await self.page.evaluate(AUDIO_MUTE_JS_SCRIPT)
        result = await self.open_url_initialize()
        if result:
            self.is_open_url = True

    async def open_url_initialize(self):
        return True

    async def get(self, url, params=None, headers={}, data=None,
                          form = None,timeout=None,stream=True, **kwargs):
        response = await self.page.request.get(
            url,
            params = params,
            headers = headers,
            data = data,
            form = form,
            timeout = timeout,
        )
        return response

    async def post(self, url, params=None, headers={}, data=None,
                          form = None,timeout=None,stream=True, **kwargs):
        response = await self.page.request.post(
            url,
            params = params,
            headers = headers,
            data = data,
            form = form,
            timeout = timeout,
        )
        return response

    async def js_fetch(self, url, params=None,data_params=None, headers={}, data=None,
                          form = None,timeout=None,stream=True,referrer = None,referrerPolicy = "strict-origin-when-cross-origin",
                          method = "POST",mode = "cors",credentials = "include",**kwargs):
        result_url = url
        if params!=None:
            result_url = url+"?"+urllib.parse.urlencode(params)
        
        ## Pay attention to data, form, and data_params can only have one value
        result_headers = headers
        result_data = None
        if data_params:
            result_data = urllib.parse.urlencode(data_params)
            result_data = "\""+result_data+"\""
        if form:
            multipart_encoder = MultipartEncoder(fields=form, boundary="----WebKitFormBoundaryF5qR4oA9jWZYBeey")
            form_data = multipart_encoder.to_string()
            result_headers["content-type"] = 'multipart/form-data; boundary={}'.format(multipart_encoder.boundary_value)
            result_data = json.dumps(bytes.decode(form_data))[1:-1]
            result_data = "\""+result_data+"\""
        if data:
            result_data = json.dumps(data)
            result_data = json.dumps({"result": result_data})[12:-2]
            result_data = "\""+result_data+"\""
        
        if result_data == None:
            result_data = "null"

        response_text = ""
        result_headers_str = json.dumps(result_headers)
        cur_js_script = PLAYWRIGHT_JS_SCRIPT.format(
            url = result_url,
            headers = result_headers_str,
            referrer = referrer if referrer else self.page.url,
            referrerPolicy = referrerPolicy,
            body = result_data,
            method = method,
            mode = mode,
            credentials = credentials
        )
        ## Note that attaching headers in JavaScript does not work, so it is necessary to manually set it here
        await self.page.set_extra_http_headers(result_headers)
        response_text = await self.page.evaluate(cur_js_script)
    
    