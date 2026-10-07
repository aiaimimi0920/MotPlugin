from tbapi import SingletonType,TBAPI
from . import ware_protocol_pb2 as sub_protocol_pb2
from modules.protocol_handle import ProtocolHandle
import six
@six.add_metaclass(SingletonType)
class Ware(object):
    protocol_handle = None
    main = None
    browser_path = ""
    def __init__(self, browser_path=""):
        self.protocol_handle = ProtocolHandle()
        from main import Main
        self.main = Main()
        self.register_all_protocol()
        self.browser_path = browser_path

    def register_all_protocol(self):
        ## Register all server-side call protocols
        self.protocol_handle.register_protocol_format_with_object(sub_protocol_pb2, self)
    

    async def search_ware(self, data):
        tbdapi_obj = TBAPI()
        keyword = data.get("keyword","")
        max_result = data.get("max_result",-1)
        ware_info_list = await tbdapi_obj.search(keyword, max_result=max_result,  browser_path = self.browser_path)
        return ware_info_list

    async def get_ware_info(self, data):
        tbdapi_obj = TBAPI()
        good_id = data.get("good_id","")
        sku_id = data.get("sku_id","")
        sku_url = data.get("sku_url","")
        max_result = data.get("max_result",-1)
        ware_info = await tbdapi_obj.get_ware_info(good_id=good_id, sku_id=sku_id, sku_url=sku_url, max_result=max_result, browser_path=self.browser_path)
        return ware_info

    ## The method name has the same name as the sub protocol
    async def S_C_SEARCH_WARE(self, client, syncId, data):
        return await self.main.send_service_request(client, syncId, data, self.S_C_SEARCH_WARE)

    ## The method name has the same name as the sub protocol
    async def  S_C_GET_WARE_INFO(self, client, syncId, data):
        return await self.main.send_service_request(client, syncId, data, self.S_C_GET_WARE_INFO)


    ## The method name has the same name as the sub protocol
    async def C_S_SEARCH_WARE(self, client, syncId ,content):
        ware_info_list = await self.search_ware(content)
        await self.S_C_SEARCH_WARE(client, syncId, ware_info_list)

    ## The method name has the same name as the sub protocol
    async def C_S_GET_WARE_INFO(self, client, syncId ,content):
        ware_info = await self.get_ware_info(content)
        await self.S_C_GET_WARE_INFO(client, syncId, ware_info)

