from __future__ import annotations

from .requests import PlaywrightBrowserSession
from .helper import get_cookies
import json
import re
import asyncio

class JDAPI():

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
            "authority": "api.m.jd.com",
            "accept": "application/json, text/javascript, */*; q=0.01",
            "accept-language": "zh-CN,zh;q=0.9",
            "origin": "https://www.jd.com",
            "referer": "https://www.jd.com",
            "sec-ch-ua": "\"Chromium\";v=\"122\", \"Not(A:Brand\";v=\"24\", \"Google Chrome\";v=\"122\"",
            "sec-ch-ua-mobile": "?0",
            "sec-ch-ua-platform": "\"Windows\"",
            "sec-fetch-dest": "empty",
            "sec-fetch-mode": "cors",
            "sec-fetch-site": "same-site",
            "user-agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36",
            # "user-agent":"Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/123.0.0.0 Safari/537.36 Edg/123.0.0.0",
            "x-referer-page": "https://www.jd.com",
            "x-rp-client": "h5_1.0.0"
        }
        
        session = PlaywrightBrowserSession(headers, browser_path=browser_path)
        cur_cookie_dict = get_cookies()
        session =  await session.with_init_brower()
        await session.browser.add_cookies(cur_cookie_dict)
        url = f"https://search.jd.com/Search?keyword={keyword}"
        # await session.browser.pages[0].route('**/*', self.intercept)
        await session.open_url(url)
        
        count = 0
        goods_list_locator = f'#J_goodsList > ul > li'
        goods_list_elements = []
        
        while count<5:
            await session.page.wait_for_timeout(0.2*1000)
            goods_list_elements = await session.page.query_selector_all(goods_list_locator)
            if len(goods_list_elements)>=max_result or len(goods_list_elements)>=10:
                break
            count+=1
            
        goods_list = []
        # because in webkit browser, the jd price sometime not show, so we need cache price from search view
        base_price_map = {}
        for key in goods_list_elements:
            goods_list.append(str(await key.get_attribute('data-sku')))
            goods_price_locator = f'.J_{goods_list[-1]}'
            goods_price_elements = await session.page.query_selector_all(goods_price_locator)
            price = await goods_price_elements[0].inner_text()
            base_price_map[goods_list[-1]] = price
        
        await session.clear_browser()
        
        goods_list = goods_list[:max_result*2]
        
        all_results = []
        once_num = 5
        for i in range(int(len(goods_list)/once_num)):
            tasks = [self.fetch_ware_info(good_id=good, browser_path=browser_path) for good in goods_list[once_num*i:once_num*(i+1)]]
            results = await asyncio.gather(*tasks)
            cur_results = []
            for data in results:
                if data["price"]=="":
                    if data["sku_id"] in base_price_map:
                        data["price"] = base_price_map[data["sku_id"]]
                        cur_results.append(data)
                else:
                    cur_results.append(data)
            all_results.extend(cur_results)
            if len(all_results)>=max_result:
                break
        return {"ware_infos":all_results}
    
    async def fetch_ware_info(self, good_id="", browser_path=""):
        return await self.get_ware_info(good_id, browser_path=browser_path)
        
    async def get_ware_info(self, sku_id, browser_path=""):
        headers = {
            "authority": "api.m.jd.com",
            "accept": "application/json, text/javascript, */*; q=0.01",
            "accept-language": "zh-CN,zh;q=0.9",
            "origin": "https://item.jd.com",
            "referer": "https://item.jd.com/100071422470.html",
            "sec-ch-ua": "\"Chromium\";v=\"122\", \"Not(A:Brand\";v=\"24\", \"Google Chrome\";v=\"122\"",
            "sec-ch-ua-mobile": "?0",
            "sec-ch-ua-platform": "\"Windows\"",
            "sec-fetch-dest": "empty",
            "sec-fetch-mode": "cors",
            "sec-fetch-site": "same-site",
            "user-agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36",
            # "user-agent":"Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/123.0.0.0 Safari/537.36 Edg/123.0.0.0",
            "x-referer-page": "https://item.jd.com/10096186210939.html",
            "x-rp-client": "h5_1.0.0"
        }
        session = PlaywrightBrowserSession(headers, browser_path=browser_path)
        cur_cookie_dict = get_cookies()
        session =  await session.with_init_brower()
        await session.browser.add_cookies(cur_cookie_dict)
        url = f"https://item.jd.com/{sku_id}.html"
        # await session.browser.pages[0].route('**/*', self.intercept)
        await session.open_url(url)
        

        # await comment_list_elements[4].click()
        price_locator = f'.J-p-{sku_id}'
        elements = await session.page.wait_for_selector(price_locator, state="attached")
        price2_locator = f'.p-price > .J-p-{sku_id}'
        price_elements = await session.page.query_selector_all(price2_locator)
        price = await price_elements[0].inner_text()
        count = 0
        while price == "" and count<5:
            await session.page.wait_for_timeout(0.2*1000)
            price_elements = await session.page.query_selector_all(price2_locator)
            price = await price_elements[0].inner_text()
            # print("price: ",price)
            count+=1
        
        if price!="":
            price_sign_locator = f'.p-price > span'
            price_sign_elements = await session.page.query_selector_all(price_sign_locator)
            price_sign = await price_sign_elements[0].inner_text()
            price = price_sign+price
        
        specs_key_locator = f'.Ptable-item > dl > dl > dt'
        specs_value_locator = f'.Ptable-item > dl > dl > dd'
        specs_value_tips_locator = f'.Ptable-item > dl > dl > .Ptable-tips'
        specs_key_elements = await session.page.query_selector_all(specs_key_locator)
        specs_value_elements = await session.page.query_selector_all(specs_value_locator)
        specs_value_tips_elements = await session.page.query_selector_all(specs_value_tips_locator)
        
        specs_value_tips_elements_data = []
        for key in specs_value_tips_elements:
            specs_value_tips_elements_data.append(await key.inner_text())
        
        specs_key_elements_data = []
        for key in specs_key_elements:
            specs_key_elements_data.append(await key.inner_text())

        specs_value_elements_data = []
        for key in specs_value_elements:
            cur_data = await key.inner_text()
            if cur_data not in specs_value_tips_elements_data:
                specs_value_elements_data.append(cur_data)
        
        specs = {}
        for i in range(len(specs_key_elements_data)):
            specs[specs_key_elements_data[i]] = specs_value_elements_data[i]

        package_list_key_locator = f'.package-list > h3'
        package_list_value_locator = f'.package-list > p'
        package_list_key_elements = await session.page.query_selector_all(package_list_key_locator)
        package_list_value_elements = await session.page.query_selector_all(package_list_value_locator)

        package_list_key = await package_list_key_elements[0].inner_text()
        package_list_value = await package_list_value_elements[0].inner_text()
        
        specs[package_list_key] = package_list_value
    
        parameter_list_locator = f'.p-parameter > .p-parameter-list > li'
        parameter_list_elements = await session.page.query_selector_all(parameter_list_locator)
        
        parameters = {}
        for key in parameter_list_elements:
            key_value = await key.inner_text()
            parameter_key, parameter_value = key_value.split("：",1)
            parameters[parameter_key] = await key.get_attribute('title')
        
        image_list_locator = f'#spec-img'
        image_list_elements = await session.page.query_selector_all(image_list_locator)
        
        images = []
        for image_node in image_list_elements:
            src = await image_node.get_attribute('data-origin')
            src = "https:" + src
            src = re.sub(r'/n[\d]+/', "/imgzone/", src)
            images.append(src)

        comment_list_locator = f'#detail > .tab-main > ul > li'
        comment_list_elements = await session.page.query_selector_all(comment_list_locator)
        for element in comment_list_elements:
            data_anchor = await element.get_attribute("data-anchor")
            if data_anchor == "#comment":
                await element.click()
                break


        element = await session.page.wait_for_selector('.percent-con', state="attached")
        
        percent_con = await element.inner_text()
        comment_locator = f'.filter-list > li'
        comment_elements = await session.page.query_selector_all(comment_locator)
        comment_elements = comment_elements[:7]
        comments = {}
        comments["好评度"] = percent_con
        for node in comment_elements:
            key_value = await node.inner_text()
            key, value = key_value.split("(")
            value = value[:-1]
            comments[key] = value
        
        comment_con_locator = f'.comment-con'
        comment_con_elements = await session.page.query_selector_all(comment_con_locator)
        comment_con_list = []
        for node in comment_con_elements:
            key_value = await node.inner_text()
            comment_con_list.append(key_value)

        await session.clear_browser()
                
        return {
            "specs":specs,
            "images":images,
            "sku_id":str(sku_id),
            "comments":comment_con_list,
            "comments_info":comments,
            "price":str(price),
            "parameters":parameters,
            "url":url,
        }


