from tbapi import SingletonType,TBAPI
import asyncio

if __name__ == "__main__":
    tbapi_obj = TBAPI()
    goods_id = "323550669039"
    ware_id = "55975686626"
    # async_result = asyncio.run(pddapi.get_ware_info(goods_id, ware_id, r"C:\Users\Public\nas_home\VMe_Export\browser\browser.exe"))
    # async_result = asyncio.run(pddapi.search("牛奶", r"C:\Users\Public\nas_home\VMe_Export\browser\browser.exe"))
    # async_result = asyncio.run(pddapi.search("可乐"))
    # async_result = asyncio.run(pddapi.search("可乐",browser_path = r"C:\Users\Public\nas_home\VMe_Export\browser\browser.exe"))
    # async_result = asyncio.run(pddapi.get_ware_info("653028866416","5341696216333", browser_path = r"C:\Users\Public\nas_home\VMe_Export\browser\browser.exe"))
    async_result = asyncio.run(tbapi_obj.get_ware_info("653028866416","5341696216333"))
    # async_result = asyncio.run(tbapi_obj.get_ware_info("729275647592",browser_path = r"C:\Users\Public\nas_home\VMe_Export\webkit-1992\Playwright.exe"))
    # async_result = asyncio.run(pddapi.get_ware_info("653028866416"))
    print(async_result)
