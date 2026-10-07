from jdapi import SingletonType,JDAPI
import asyncio

if __name__ == "__main__":
    jdapi_obj = JDAPI()
    ware_id = "55975686626"
    # async_result = asyncio.run(jdapi.get_ware_info(ware_id, r"C:\Users\Public\nas_home\VMe_Export\browser\browser.exe"))
    async_result = asyncio.run(jdapi_obj.search("牛奶"))
    print(async_result)
