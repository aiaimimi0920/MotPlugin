from __future__ import annotations

from .requests import PlaywrightBrowserSession
from .helper import get_cookies
import json
import re
import asyncio

class TBAPI():

    session = None
    is_auth = False
    
    async def intercept(self, route, request):
        if request.resource_type in {'image'}:
            await route.abort()
        else:
            await route.continue_()
    
    async def search(self, keyword, max_result=-1, browser_path=""):
        if max_result == -1:
            max_result = 10
        headers = {
            # "authority": "api.m.jd.com",
            "accept": "application/json, text/javascript, */*; q=0.01",
            "accept-language": "zh-CN,zh;q=0.9",
            "origin": "https://www.taobao.com/",
            "referer": "https://www.taobao.com/",
            "sec-ch-ua": "\"Chromium\";v=\"122\", \"Not(A:Brand\";v=\"24\", \"Google Chrome\";v=\"122\"",
            "sec-ch-ua-mobile": "?0",
            "sec-ch-ua-platform": "\"Windows\"",
            "sec-fetch-dest": "empty",
            "sec-fetch-mode": "cors",
            "sec-fetch-site": "same-site",
            "user-agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36",
            # "user-agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:124.0) Gecko/20100101 Firefox/124.0",
            "x-referer-page": "https://www.taobao.com/",
            "x-rp-client": "h5_1.0.0"
        }
        
        session = PlaywrightBrowserSession(headers, browser_path=browser_path)
        cur_cookie_dict = get_cookies()
        session =  await session.with_init_brower()
        await session.browser.add_cookies(cur_cookie_dict)
        if TBAPI.is_auth==False:
            url = "https://login.taobao.com/"
            await session.open_url(url,timeout = 60*1000 ,wait_until="domcontentloaded")
            await session.page.wait_for_url("https://i.taobao.com/my_taobao.htm**")
            TBAPI.is_auth = True
        
        url = f"https://s.taobao.com/search?commend=all&page=1&q={keyword}&search_type=item&tab=all"
        # await session.browser.pages[0].route('**/*', self.intercept)
        await session.open_url(url,timeout = 60*1000 ,wait_until="domcontentloaded")

        # await session.page.route("**/*.jpg", lambda route: route.abort())
        # await session.page.route("**/*.webp", lambda route: route.abort())
        # await session.page.route("**/*.mp4", lambda route: route.abort())
        # await session.page.route("//cloud.video.taobao.com/**", lambda route: route.abort())
        
        count = 0
        item_button_locator = f'#pageContent > div > div > div > div > div > a'        
        item_button_elements = []
        while True and count<10:
            item_button_elements = await session.page.query_selector_all(item_button_locator)
            if len(item_button_elements)>0:
                break
            count+=1
            await session.page.wait_for_timeout(0.2*1000)
        
        goodid_list = []
        goodid_url_list = []
        for node in item_button_elements:
            pattern = re.compile(r'id=(?P<goodid>\d+)') 
            href_str = await node.get_attribute('href')
            
            searchObj  = re.search(pattern, href_str, flags=0)
            if searchObj:
                goodid_list.append(searchObj.group("goodid"))
                goodid_url_list.append("https:"+href_str)
        
        await session.clear_browser()
        goodid_list = goodid_list[:max_result*2]
        goodid_url_list = goodid_url_list[:max_result*2]
        
        all_results = []
        once_num = 1
        for i in range(int(len(goodid_list)/once_num)):
            tasks = [self.fetch_ware_info(good_id=good, max_result = 2, browser_path=browser_path) for good in goodid_list[once_num*i:once_num*(i+1)]]
            results = await asyncio.gather(*tasks)
            results = [data for data in results if data and len(data.get("prices",{}))>0]
            all_results.extend(results)
            if len(all_results)>=max_result:
                break
        return {"ware_infos":all_results}
        
    
    async def fetch_ware_info(self, good_id="", max_result=-1, browser_path=""):
        return await self.get_ware_info(good_id=good_id, max_result=max_result,browser_path=browser_path)
        
    async def get_ware_info(self, good_id="", sku_id="", sku_url="", max_result=-1, browser_path=""):
        if max_result == -1:
            max_result = 5
        headers = {
            # "authority": "api.m.jd.com",
            "accept": "application/json, text/javascript, */*; q=0.01",
            "accept-language": "zh-CN,zh;q=0.9",
            "origin": "https://www.taobao.com/",
            "referer": "https://www.taobao.com/",
            "sec-ch-ua": "\"Chromium\";v=\"122\", \"Not(A:Brand\";v=\"24\", \"Google Chrome\";v=\"122\"",
            "sec-ch-ua-mobile": "?0",
            "sec-ch-ua-platform": "\"Windows\"",
            "sec-fetch-dest": "empty",
            "sec-fetch-mode": "cors",
            "sec-fetch-site": "same-site",
            "user-agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36",
            # "user-agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:124.0) Gecko/20100101 Firefox/124.0",
            "x-referer-page": "https://www.taobao.com/",
            "x-rp-client": "h5_1.0.0"
        }
        
        session = PlaywrightBrowserSession(headers, browser_path=browser_path)
        cur_cookie_dict = get_cookies()
        session =  await session.with_init_brower()
        
        await session.browser.add_cookies(cur_cookie_dict)
        if TBAPI.is_auth==False:
            url = "https://login.taobao.com/"
            await session.open_url(url,timeout = 60*1000 ,wait_until="domcontentloaded")
            await session.page.wait_for_url("https://i.taobao.com/my_taobao.htm**")
            TBAPI.is_auth = True
        
        url = ""
        if sku_id!="":
            url = f"https://item.taobao.com/item.htm?id={good_id}&skuId={sku_id}"
        else:
            url = f"https://item.taobao.com/item.htm?id={good_id}"
        
        if sku_url!="":
            url = sku_url
        
        # print("baseurl: ",url)
        # await session.browser.pages[0].route('**/*', self.intercept)

        await session.open_url(url)
        
        # await session.page.wait_for_timeout(1*1000)
            
        now_sku_url = session.page.url
        
        if now_sku_url.find("huodong.taobao.com") != -1:
            await session.clear_browser()
            return {}
        
        now_url_id_pattern = re.compile(r'id=(?P<id>\d+)') 
        now_url_skuid_pattern = re.compile(r'skuId=(?P<skuid>\d+)') 
        now_url_id_search_obj  = re.search(now_url_id_pattern, now_sku_url, flags=0)
        now_url_skuid_search_obj  = re.search(now_url_skuid_pattern, now_sku_url, flags=0)
        
        now_id = ""
        now_sku_id = ""
       
        if now_url_id_search_obj:
            now_id = now_url_id_search_obj.group("id")
        if now_url_skuid_search_obj:
            now_sku_id = now_url_skuid_search_obj.group("skuid")
        
        just_get_one_sku = False
        if now_id!="" and now_sku_id!="":
            just_get_one_sku = True
        
        count = 0
        specs_locator = f'#root > div > div > div > div > div > div:nth-child(1) > div > div > div > div > span'
        
        specs_elements = []
        while True and count<10:
            
            specs_elements = await session.page.query_selector_all(specs_locator)
            if len(specs_elements)>0:
                class_name = await specs_elements[0].get_attribute('class')
                if class_name!="" and class_name!=None and class_name.find("Attrs--attr")!=-1:
                    break
            count+=1
            await session.page.wait_for_timeout(0.2*1000)
        
        specs = {}
        
        for element in specs_elements:
            key_value = await element.get_attribute('title')
            if key_value!="" and key_value!=None:
                key, value = key_value.split("：", 1)
                specs[key] = value
        
        images_locator = f'#root > div > div > div > div > div > div > div > ul > li > img'
        images_elements = await session.page.query_selector_all(images_locator)
        images = []
        
        image_pattern = re.compile(r'.jpg_.*') 
        
        
        for element in images_elements:
            src = await element.get_attribute('src')
            src = "https:" + src
            src  = re.sub(image_pattern, ".jpg", src, flags=0)
            images.append(src)
            
        # await session.page.wait_for_timeout(2*1000)
        # comment_button_locator = f'#root > div > div > div > div > div > div > div > div'
        # comment_button_elements = await session.page.query_selector_all(comment_button_locator)
        
        # cur_comment_button_elements = []
        # for node in comment_button_elements:
        #     class_name = await node.get_attribute("class")
        #     if class_name and class_name.startswith("Tabs--title--"):
        #         cur_comment_button_elements.append(node)
        
        # await cur_comment_button_elements[1].click()
        # print("session.page.url: ",session.page.url)
        
        count = 0
        sku_wrapper_locator = f'.skuCate > .skuItemWrapper'
        
        sku_wrapper_element = []
        while True and count<10:
            sku_wrapper_element = await session.page.query_selector_all(sku_wrapper_locator)
            if len(sku_wrapper_element)>0:
                break
            count+=1
            await session.page.wait_for_timeout(0.2*1000)
        
        sku_wrapper_element_size = len(sku_wrapper_element)
        
        sku_wrapper_elements_child_size = []
        for i in range(sku_wrapper_element_size):
            sku_wrapper_elements_child_locator = f'.skuCate:nth-child(%d) > .skuItemWrapper > div'%(i+1)
            sku_wrapper_elements_child_elements = await session.page.query_selector_all(sku_wrapper_elements_child_locator)
            sku_wrapper_elements_child_size.append(len(sku_wrapper_elements_child_elements))
        
        need_check_index = []
        price_map = {}
        sku_item_map = {}
        url_map = {}
        if just_get_one_sku:
            price_locator = f'#root > div > div > div > div > div > div > div > div > div > div > div > div > span:nth-child(2) ~ span'
            price_elements = await session.page.query_selector_all(price_locator)
            if len(price_elements)>=2:
                price_sign = await price_elements[-2].inner_text()
                price = await price_elements[-1].inner_text()
                price_map[now_sku_id] = price_sign+price
                
                cur_sku_item_data = {}
                for i in range(sku_wrapper_element_size):
                    wrapper_index = i+1
                    target_item_key_locator = f'.skuCate:nth-child(%d) > .skuCateText'%(wrapper_index)
                    target_item_key_elements = await session.page.query_selector_all(target_item_key_locator)
                    cur_title_key = ""
                    if len(target_item_key_elements)>0:
                        title_key = await target_item_key_elements[0].inner_text()
                        if title_key!="":
                            title_key_list = title_key.split("：",1)
                            cur_title_key = title_key_list[0]
                            
                    if cur_title_key =="":
                        continue
                    
                    target_item_value_locator = f'.skuCate:nth-child(%d) > .skuItemWrapper > .current > div'%(wrapper_index)
                    target_item_value_elements = await session.page.query_selector_all(target_item_value_locator)
                    if len(target_item_value_elements)>0:
                        title_value = await target_item_value_elements[0].get_attribute("title")
                        if title_value!="":
                            cur_sku_item_data[cur_title_key] = title_value

                sku_item_map[now_sku_id] = cur_sku_item_data
                
                url_map[now_sku_id] = session.page.url
            
        else:
            pattern = re.compile(r'skuId=(?P<skuid>\d+)') 
            
            for i in range(sku_wrapper_element_size):
                max_value = sku_wrapper_elements_child_size[i]
                if len(need_check_index)==0:
                    for i in range(max_value):
                        need_check_index.append([i+1])
                else:
                    cur_need_check_index = []
                    for cur_need_check in need_check_index:
                        for i in range(max_value):
                            cur_need_check_copy = list(cur_need_check)
                            cur_need_check_copy.append(i+1)
                            cur_need_check_index.append(cur_need_check_copy)
                    need_check_index = cur_need_check_index
                
            for need_check_list in need_check_index:
                
                for i in range(sku_wrapper_element_size):
                    wrapper_index = i+1
                    item_index = need_check_list[i]

                    target_item_locator = f'.skuCate:nth-child(%d) > .skuItemWrapper > .current'%(wrapper_index)
                    target_item_elements = await session.page.query_selector_all(target_item_locator)
                    if len(target_item_elements)>0:
                        class_name = await target_item_elements[0].get_attribute("class")
                        if class_name!="":
                            if class_name.find("current") != -1:
                                await target_item_elements[0].click()
                                await session.page.wait_for_load_state()
                
                next_check = False     
                for i in range(sku_wrapper_element_size):
                    wrapper_index = i+1
                    item_index = need_check_list[i]

                    target_item_locator = f'.skuCate:nth-child(%d) > .skuItemWrapper > div:nth-child(%d)'%(wrapper_index,item_index)
                    target_item_elements = await session.page.query_selector_all(target_item_locator)
                    if len(target_item_elements)>0:
                        class_name = await target_item_elements[0].get_attribute("class")
                        if class_name!="":
                            if class_name.find("disabled") != -1:
                                next_check = True
                                break
                            else:
                                await target_item_elements[0].click()
                                await session.page.wait_for_load_state()
                if next_check:
                    continue
                
                cur_sku_url2 = ""
                count = 0
                cur_skuid = ""
                while True and count<10:
                    cur_sku_url2 = session.page.url
                    searchObj  = re.search(pattern, cur_sku_url2, flags=0)
                    cur_skuid = ""
                    if searchObj:
                        cur_skuid = searchObj.group("skuid")
                    if cur_skuid != "":
                        break
                    count+=1
                    await session.page.wait_for_timeout(0.2*1000)

                price_locator = f'#root > div > div > div > div > div > div > div > div > div > div > div > div > span:nth-child(2) ~ span'
                price_elements = await session.page.query_selector_all(price_locator)
                if len(price_elements)>=2:                    
                    price_sign = await price_elements[-2].inner_text()
                    price = await price_elements[-1].inner_text()
                    price_map[cur_skuid] = price_sign+price
                        
                    cur_sku_item_data = {}
                    for i in range(sku_wrapper_element_size):
                        wrapper_index = i+1
                        target_item_key_locator = f'.skuCate:nth-child(%d) > .skuCateText'%(wrapper_index)
                        target_item_key_elements = await session.page.query_selector_all(target_item_key_locator)
                        cur_title_key = ""
                        if len(target_item_key_elements)>0:
                            title_key = await target_item_key_elements[0].inner_text()
                            if title_key!="":
                                title_key_list = title_key.split("：",1)
                                cur_title_key = title_key_list[0]
                                
                        if cur_title_key =="":
                            continue
                        
                        target_item_value_locator = f'.skuCate:nth-child(%d) > .skuItemWrapper > .current > div'%(wrapper_index)
                        target_item_value_elements = await session.page.query_selector_all(target_item_value_locator)
                        if len(target_item_value_elements)>0:
                            title_value = await target_item_value_elements[0].get_attribute("title")
                            if title_value!="":
                                cur_sku_item_data[cur_title_key] = title_value

                    sku_item_map[cur_skuid] = {"data":cur_sku_item_data}
                    
                    url_map[cur_skuid] = session.page.url

                if len(sku_item_map)>=max_result:
                    break
                
        await session.clear_browser()
        
        return {
            "good_id":str(now_id),
            
            "specs":specs,
            "images":images,
            "sku_ids":list(sku_item_map.keys()),
            "comments":[],
            "comments_info":{},
            
            "prices":price_map,
            "special_specs":sku_item_map,
            "urls":url_map,
        }