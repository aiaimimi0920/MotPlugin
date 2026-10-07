#
# BSD 3-Clause License
#
# Copyright (c) 2018 - 2023, Oleg Malyavkin
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# * Redistributions of source code must retain the above copyright notice, this
#   list of conditions and the following disclaimer.
#
# * Redistributions in binary form must reproduce the above copyright notice,
#   this list of conditions and the following disclaimer in the documentation
#   and/or other materials provided with the distribution.
#
# * Neither the name of the copyright holder nor the names of its
#   contributors may be used to endorse or promote products derived from
#   this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

# DEBUG_TAB redefine this "  " if you need, example: const DEBUG_TAB = "\t"

const PROTO_VERSION = 3

const DEBUG_TAB : String = "  "

enum PB_ERR {
	NO_ERRORS = 0,
	VARINT_NOT_FOUND = -1,
	REPEATED_COUNT_NOT_FOUND = -2,
	REPEATED_COUNT_MISMATCH = -3,
	LENGTHDEL_SIZE_NOT_FOUND = -4,
	LENGTHDEL_SIZE_MISMATCH = -5,
	PACKAGE_SIZE_MISMATCH = -6,
	UNDEFINED_STATE = -7,
	PARSE_INCOMPLETE = -8,
	REQUIRED_FIELDS = -9
}

enum PB_DATA_TYPE {
	INT32 = 0,
	SINT32 = 1,
	UINT32 = 2,
	INT64 = 3,
	SINT64 = 4,
	UINT64 = 5,
	BOOL = 6,
	ENUM = 7,
	FIXED32 = 8,
	SFIXED32 = 9,
	FLOAT = 10,
	FIXED64 = 11,
	SFIXED64 = 12,
	DOUBLE = 13,
	STRING = 14,
	BYTES = 15,
	MESSAGE = 16,
	MAP = 17
}

const DEFAULT_VALUES_2 = {
	PB_DATA_TYPE.INT32: null,
	PB_DATA_TYPE.SINT32: null,
	PB_DATA_TYPE.UINT32: null,
	PB_DATA_TYPE.INT64: null,
	PB_DATA_TYPE.SINT64: null,
	PB_DATA_TYPE.UINT64: null,
	PB_DATA_TYPE.BOOL: null,
	PB_DATA_TYPE.ENUM: null,
	PB_DATA_TYPE.FIXED32: null,
	PB_DATA_TYPE.SFIXED32: null,
	PB_DATA_TYPE.FLOAT: null,
	PB_DATA_TYPE.FIXED64: null,
	PB_DATA_TYPE.SFIXED64: null,
	PB_DATA_TYPE.DOUBLE: null,
	PB_DATA_TYPE.STRING: null,
	PB_DATA_TYPE.BYTES: null,
	PB_DATA_TYPE.MESSAGE: null,
	PB_DATA_TYPE.MAP: null
}

const DEFAULT_VALUES_3 = {
	PB_DATA_TYPE.INT32: 0,
	PB_DATA_TYPE.SINT32: 0,
	PB_DATA_TYPE.UINT32: 0,
	PB_DATA_TYPE.INT64: 0,
	PB_DATA_TYPE.SINT64: 0,
	PB_DATA_TYPE.UINT64: 0,
	PB_DATA_TYPE.BOOL: false,
	PB_DATA_TYPE.ENUM: 0,
	PB_DATA_TYPE.FIXED32: 0,
	PB_DATA_TYPE.SFIXED32: 0,
	PB_DATA_TYPE.FLOAT: 0.0,
	PB_DATA_TYPE.FIXED64: 0,
	PB_DATA_TYPE.SFIXED64: 0,
	PB_DATA_TYPE.DOUBLE: 0.0,
	PB_DATA_TYPE.STRING: "",
	PB_DATA_TYPE.BYTES: [],
	PB_DATA_TYPE.MESSAGE: null,
	PB_DATA_TYPE.MAP: []
}

enum PB_TYPE {
	VARINT = 0,
	FIX64 = 1,
	LENGTHDEL = 2,
	STARTGROUP = 3,
	ENDGROUP = 4,
	FIX32 = 5,
	UNDEFINED = 8
}

enum PB_RULE {
	OPTIONAL = 0,
	REQUIRED = 1,
	REPEATED = 2,
	RESERVED = 3
}

enum PB_SERVICE_STATE {
	FILLED = 0,
	UNFILLED = 1
}

class PBField:
	func _init(a_name : String, a_type : int, a_rule : int, a_tag : int, packed : bool, a_value = null):
		name = a_name
		type = a_type
		rule = a_rule
		tag = a_tag
		option_packed = packed
		value = a_value
		
	var name : String
	var type : int
	var rule : int
	var tag : int
	var option_packed : bool
	var value
	var is_map_field : bool = false
	var option_default : bool = false

class PBTypeTag:
	var ok : bool = false
	var type : int
	var tag : int
	var offset : int

class PBServiceField:
	var field : PBField
	var func_ref = null
	var state : int = PB_SERVICE_STATE.UNFILLED

class PBPacker:
	static func convert_signed(n : int) -> int:
		if n < -2147483648:
			return (n << 1) ^ (n >> 63)
		else:
			return (n << 1) ^ (n >> 31)

	static func deconvert_signed(n : int) -> int:
		if n & 0x01:
			return ~(n >> 1)
		else:
			return (n >> 1)

	static func pack_varint(value) -> PackedByteArray:
		var varint : PackedByteArray = PackedByteArray()
		if typeof(value) == TYPE_BOOL:
			if value:
				value = 1
			else:
				value = 0
		for _i in range(9):
			var b = value & 0x7F
			value >>= 7
			if value:
				varint.append(b | 0x80)
			else:
				varint.append(b)
				break
		if varint.size() == 9 && varint[8] == 0xFF:
			varint.append(0x01)
		return varint

	static func pack_bytes(value, count : int, data_type : int) -> PackedByteArray:
		var bytes : PackedByteArray = PackedByteArray()
		if data_type == PB_DATA_TYPE.FLOAT:
			var spb : StreamPeerBuffer = StreamPeerBuffer.new()
			spb.put_float(value)
			bytes = spb.get_data_array()
		elif data_type == PB_DATA_TYPE.DOUBLE:
			var spb : StreamPeerBuffer = StreamPeerBuffer.new()
			spb.put_double(value)
			bytes = spb.get_data_array()
		else:
			for _i in range(count):
				bytes.append(value & 0xFF)
				value >>= 8
		return bytes

	static func unpack_bytes(bytes : PackedByteArray, index : int, count : int, data_type : int):
		var value = 0
		if data_type == PB_DATA_TYPE.FLOAT:
			var spb : StreamPeerBuffer = StreamPeerBuffer.new()
			for i in range(index, count + index):
				spb.put_u8(bytes[i])
			spb.seek(0)
			value = spb.get_float()
		elif data_type == PB_DATA_TYPE.DOUBLE:
			var spb : StreamPeerBuffer = StreamPeerBuffer.new()
			for i in range(index, count + index):
				spb.put_u8(bytes[i])
			spb.seek(0)
			value = spb.get_double()
		else:
			for i in range(index + count - 1, index - 1, -1):
				value |= (bytes[i] & 0xFF)
				if i != index:
					value <<= 8
		return value

	static func unpack_varint(varint_bytes) -> int:
		var value : int = 0
		for i in range(varint_bytes.size() - 1, -1, -1):
			value |= varint_bytes[i] & 0x7F
			if i != 0:
				value <<= 7
		return value

	static func pack_type_tag(type : int, tag : int) -> PackedByteArray:
		return pack_varint((tag << 3) | type)

	static func isolate_varint(bytes : PackedByteArray, index : int) -> PackedByteArray:
		var result : PackedByteArray = PackedByteArray()
		for i in range(index, bytes.size()):
			result.append(bytes[i])
			if !(bytes[i] & 0x80):
				break
		return result

	static func unpack_type_tag(bytes : PackedByteArray, index : int) -> PBTypeTag:
		var varint_bytes : PackedByteArray = isolate_varint(bytes, index)
		var result : PBTypeTag = PBTypeTag.new()
		if varint_bytes.size() != 0:
			result.ok = true
			result.offset = varint_bytes.size()
			var unpacked : int = unpack_varint(varint_bytes)
			result.type = unpacked & 0x07
			result.tag = unpacked >> 3
		return result

	static func pack_length_delimeted(type : int, tag : int, bytes : PackedByteArray) -> PackedByteArray:
		var result : PackedByteArray = pack_type_tag(type, tag)
		result.append_array(pack_varint(bytes.size()))
		result.append_array(bytes)
		return result

	static func pb_type_from_data_type(data_type : int) -> int:
		if data_type == PB_DATA_TYPE.INT32 || data_type == PB_DATA_TYPE.SINT32 || data_type == PB_DATA_TYPE.UINT32 || data_type == PB_DATA_TYPE.INT64 || data_type == PB_DATA_TYPE.SINT64 || data_type == PB_DATA_TYPE.UINT64 || data_type == PB_DATA_TYPE.BOOL || data_type == PB_DATA_TYPE.ENUM:
			return PB_TYPE.VARINT
		elif data_type == PB_DATA_TYPE.FIXED32 || data_type == PB_DATA_TYPE.SFIXED32 || data_type == PB_DATA_TYPE.FLOAT:
			return PB_TYPE.FIX32
		elif data_type == PB_DATA_TYPE.FIXED64 || data_type == PB_DATA_TYPE.SFIXED64 || data_type == PB_DATA_TYPE.DOUBLE:
			return PB_TYPE.FIX64
		elif data_type == PB_DATA_TYPE.STRING || data_type == PB_DATA_TYPE.BYTES || data_type == PB_DATA_TYPE.MESSAGE || data_type == PB_DATA_TYPE.MAP:
			return PB_TYPE.LENGTHDEL
		else:
			return PB_TYPE.UNDEFINED

	static func pack_field(field : PBField) -> PackedByteArray:
		var type : int = pb_type_from_data_type(field.type)
		var type_copy : int = type
		if field.rule == PB_RULE.REPEATED && field.option_packed:
			type = PB_TYPE.LENGTHDEL
		var head : PackedByteArray = pack_type_tag(type, field.tag)
		var data : PackedByteArray = PackedByteArray()
		if type == PB_TYPE.VARINT:
			var value
			if field.rule == PB_RULE.REPEATED:
				for v in field.value:
					data.append_array(head)
					if field.type == PB_DATA_TYPE.SINT32 || field.type == PB_DATA_TYPE.SINT64:
						value = convert_signed(v)
					else:
						value = v
					data.append_array(pack_varint(value))
				return data
			else:
				if field.type == PB_DATA_TYPE.SINT32 || field.type == PB_DATA_TYPE.SINT64:
					value = convert_signed(field.value)
				else:
					value = field.value
				data = pack_varint(value)
		elif type == PB_TYPE.FIX32:
			if field.rule == PB_RULE.REPEATED:
				for v in field.value:
					data.append_array(head)
					data.append_array(pack_bytes(v, 4, field.type))
				return data
			else:
				data.append_array(pack_bytes(field.value, 4, field.type))
		elif type == PB_TYPE.FIX64:
			if field.rule == PB_RULE.REPEATED:
				for v in field.value:
					data.append_array(head)
					data.append_array(pack_bytes(v, 8, field.type))
				return data
			else:
				data.append_array(pack_bytes(field.value, 8, field.type))
		elif type == PB_TYPE.LENGTHDEL:
			if field.rule == PB_RULE.REPEATED:
				if type_copy == PB_TYPE.VARINT:
					if field.type == PB_DATA_TYPE.SINT32 || field.type == PB_DATA_TYPE.SINT64:
						var signed_value : int
						for v in field.value:
							signed_value = convert_signed(v)
							data.append_array(pack_varint(signed_value))
					else:
						for v in field.value:
							data.append_array(pack_varint(v))
					return pack_length_delimeted(type, field.tag, data)
				elif type_copy == PB_TYPE.FIX32:
					for v in field.value:
						data.append_array(pack_bytes(v, 4, field.type))
					return pack_length_delimeted(type, field.tag, data)
				elif type_copy == PB_TYPE.FIX64:
					for v in field.value:
						data.append_array(pack_bytes(v, 8, field.type))
					return pack_length_delimeted(type, field.tag, data)
				elif field.type == PB_DATA_TYPE.STRING:
					for v in field.value:
						var obj = v.to_utf8_buffer()
						data.append_array(pack_length_delimeted(type, field.tag, obj))
					return data
				elif field.type == PB_DATA_TYPE.BYTES:
					for v in field.value:
						data.append_array(pack_length_delimeted(type, field.tag, v))
					return data
				elif typeof(field.value[0]) == TYPE_OBJECT:
					for v in field.value:
						var obj : PackedByteArray = v.to_bytes()
						data.append_array(pack_length_delimeted(type, field.tag, obj))
					return data
			else:
				if field.type == PB_DATA_TYPE.STRING:
					var str_bytes : PackedByteArray = field.value.to_utf8_buffer()
					if PROTO_VERSION == 2 || (PROTO_VERSION == 3 && str_bytes.size() > 0):
						data.append_array(str_bytes)
						return pack_length_delimeted(type, field.tag, data)
				if field.type == PB_DATA_TYPE.BYTES:
					if PROTO_VERSION == 2 || (PROTO_VERSION == 3 && field.value.size() > 0):
						data.append_array(field.value)
						return pack_length_delimeted(type, field.tag, data)
				elif typeof(field.value) == TYPE_OBJECT:
					var obj : PackedByteArray = field.value.to_bytes()
					if obj.size() > 0:
						data.append_array(obj)
					return pack_length_delimeted(type, field.tag, data)
				else:
					pass
		if data.size() > 0:
			head.append_array(data)
			return head
		else:
			return data

	static func unpack_field(bytes : PackedByteArray, offset : int, field : PBField, type : int, message_func_ref) -> int:
		if field.rule == PB_RULE.REPEATED && type != PB_TYPE.LENGTHDEL && field.option_packed:
			var count = isolate_varint(bytes, offset)
			if count.size() > 0:
				offset += count.size()
				count = unpack_varint(count)
				if type == PB_TYPE.VARINT:
					var val
					var counter = offset + count
					while offset < counter:
						val = isolate_varint(bytes, offset)
						if val.size() > 0:
							offset += val.size()
							val = unpack_varint(val)
							if field.type == PB_DATA_TYPE.SINT32 || field.type == PB_DATA_TYPE.SINT64:
								val = deconvert_signed(val)
							elif field.type == PB_DATA_TYPE.BOOL:
								if val:
									val = true
								else:
									val = false
							field.value.append(val)
						else:
							return PB_ERR.REPEATED_COUNT_MISMATCH
					return offset
				elif type == PB_TYPE.FIX32 || type == PB_TYPE.FIX64:
					var type_size
					if type == PB_TYPE.FIX32:
						type_size = 4
					else:
						type_size = 8
					var val
					var counter = offset + count
					while offset < counter:
						if (offset + type_size) > bytes.size():
							return PB_ERR.REPEATED_COUNT_MISMATCH
						val = unpack_bytes(bytes, offset, type_size, field.type)
						offset += type_size
						field.value.append(val)
					return offset
			else:
				return PB_ERR.REPEATED_COUNT_NOT_FOUND
		else:
			if type == PB_TYPE.VARINT:
				var val = isolate_varint(bytes, offset)
				if val.size() > 0:
					offset += val.size()
					val = unpack_varint(val)
					if field.type == PB_DATA_TYPE.SINT32 || field.type == PB_DATA_TYPE.SINT64:
						val = deconvert_signed(val)
					elif field.type == PB_DATA_TYPE.BOOL:
						if val:
							val = true
						else:
							val = false
					if field.rule == PB_RULE.REPEATED:
						field.value.append(val)
					else:
						field.value = val
				else:
					return PB_ERR.VARINT_NOT_FOUND
				return offset
			elif type == PB_TYPE.FIX32 || type == PB_TYPE.FIX64:
				var type_size
				if type == PB_TYPE.FIX32:
					type_size = 4
				else:
					type_size = 8
				var val
				if (offset + type_size) > bytes.size():
					return PB_ERR.REPEATED_COUNT_MISMATCH
				val = unpack_bytes(bytes, offset, type_size, field.type)
				offset += type_size
				if field.rule == PB_RULE.REPEATED:
					field.value.append(val)
				else:
					field.value = val
				return offset
			elif type == PB_TYPE.LENGTHDEL:
				var inner_size = isolate_varint(bytes, offset)
				if inner_size.size() > 0:
					offset += inner_size.size()
					inner_size = unpack_varint(inner_size)
					if inner_size >= 0:
						if inner_size + offset > bytes.size():
							return PB_ERR.LENGTHDEL_SIZE_MISMATCH
						if message_func_ref != null:
							var message = message_func_ref.call()
							if inner_size > 0:
								var sub_offset = message.from_bytes(bytes, offset, inner_size + offset)
								if sub_offset > 0:
									if sub_offset - offset >= inner_size:
										offset = sub_offset
										return offset
									else:
										return PB_ERR.LENGTHDEL_SIZE_MISMATCH
								return sub_offset
							else:
								return offset
						elif field.type == PB_DATA_TYPE.STRING:
							var str_bytes : PackedByteArray = PackedByteArray()
							for i in range(offset, inner_size + offset):
								str_bytes.append(bytes[i])
							if field.rule == PB_RULE.REPEATED:
								field.value.append(str_bytes.get_string_from_utf8())
							else:
								field.value = str_bytes.get_string_from_utf8()
							return offset + inner_size
						elif field.type == PB_DATA_TYPE.BYTES:
							var val_bytes : PackedByteArray = PackedByteArray()
							for i in range(offset, inner_size + offset):
								val_bytes.append(bytes[i])
							if field.rule == PB_RULE.REPEATED:
								field.value.append(val_bytes)
							else:
								field.value = val_bytes
							return offset + inner_size
					else:
						return PB_ERR.LENGTHDEL_SIZE_NOT_FOUND
				else:
					return PB_ERR.LENGTHDEL_SIZE_NOT_FOUND
		return PB_ERR.UNDEFINED_STATE

	static func unpack_message(data, bytes : PackedByteArray, offset : int, limit : int) -> int:
		while true:
			var tt : PBTypeTag = unpack_type_tag(bytes, offset)
			if tt.ok:
				offset += tt.offset
				if data.has(tt.tag):
					var service : PBServiceField = data[tt.tag]
					var type : int = pb_type_from_data_type(service.field.type)
					if type == tt.type || (tt.type == PB_TYPE.LENGTHDEL && service.field.rule == PB_RULE.REPEATED && service.field.option_packed):
						var res : int = unpack_field(bytes, offset, service.field, type, service.func_ref)
						if res > 0:
							service.state = PB_SERVICE_STATE.FILLED
							offset = res
							if offset == limit:
								return offset
							elif offset > limit:
								return PB_ERR.PACKAGE_SIZE_MISMATCH
						elif res < 0:
							return res
						else:
							break
			else:
				return offset
		return PB_ERR.UNDEFINED_STATE

	static func pack_message(data) -> PackedByteArray:
		var DEFAULT_VALUES
		if PROTO_VERSION == 2:
			DEFAULT_VALUES = DEFAULT_VALUES_2
		elif PROTO_VERSION == 3:
			DEFAULT_VALUES = DEFAULT_VALUES_3
		var result : PackedByteArray = PackedByteArray()
		var keys : Array = data.keys()
		keys.sort()
		for i in keys:
			if data[i].field.value != null:
				if data[i].state == PB_SERVICE_STATE.UNFILLED \
				&& !data[i].field.is_map_field \
				&& typeof(data[i].field.value) == typeof(DEFAULT_VALUES[data[i].field.type]) \
				&& data[i].field.value == DEFAULT_VALUES[data[i].field.type]:
					continue
				elif data[i].field.rule == PB_RULE.REPEATED && data[i].field.value.size() == 0:
					continue
				result.append_array(pack_field(data[i].field))
			elif data[i].field.rule == PB_RULE.REQUIRED:
				print("Error: required field is not filled: Tag:", data[i].field.tag)
				return PackedByteArray()
		return result

	static func check_required(data) -> bool:
		var keys : Array = data.keys()
		for i in keys:
			if data[i].field.rule == PB_RULE.REQUIRED && data[i].state == PB_SERVICE_STATE.UNFILLED:
				return false
		return true

	static func construct_map(key_values):
		var result = {}
		for kv in key_values:
			result[kv.get_key()] = kv.get_value()
		return result
	
	static func tabulate(text : String, nesting : int) -> String:
		var tab : String = ""
		for _i in range(nesting):
			tab += DEBUG_TAB
		return tab + text
	
	static func value_to_string(value, field : PBField, nesting : int) -> String:
		var result : String = ""
		var text : String
		if field.type == PB_DATA_TYPE.MESSAGE:
			result += "{"
			nesting += 1
			text = message_to_string(value.data, nesting)
			if text != "":
				result += "\n" + text
				nesting -= 1
				result += tabulate("}", nesting)
			else:
				nesting -= 1
				result += "}"
		elif field.type == PB_DATA_TYPE.BYTES:
			result += "<"
			for i in range(value.size()):
				result += str(value[i])
				if i != (value.size() - 1):
					result += ", "
			result += ">"
		elif field.type == PB_DATA_TYPE.STRING:
			result += "\"" + value + "\""
		elif field.type == PB_DATA_TYPE.ENUM:
			result += "ENUM::" + str(value)
		else:
			result += str(value)
		return result
	
	static func field_to_string(field : PBField, nesting : int) -> String:
		var result : String = tabulate(field.name + ": ", nesting)
		if field.type == PB_DATA_TYPE.MAP:
			if field.value.size() > 0:
				result += "(\n"
				nesting += 1
				for i in range(field.value.size()):
					var local_key_value = field.value[i].data[1].field
					result += tabulate(value_to_string(local_key_value.value, local_key_value, nesting), nesting) + ": "
					local_key_value = field.value[i].data[2].field
					result += value_to_string(local_key_value.value, local_key_value, nesting)
					if i != (field.value.size() - 1):
						result += ","
					result += "\n"
				nesting -= 1
				result += tabulate(")", nesting)
			else:
				result += "()"
		elif field.rule == PB_RULE.REPEATED:
			if field.value.size() > 0:
				result += "[\n"
				nesting += 1
				for i in range(field.value.size()):
					result += tabulate(str(i) + ": ", nesting)
					result += value_to_string(field.value[i], field, nesting)
					if i != (field.value.size() - 1):
						result += ","
					result += "\n"
				nesting -= 1
				result += tabulate("]", nesting)
			else:
				result += "[]"
		else:
			result += value_to_string(field.value, field, nesting)
		result += ";\n"
		return result
		
	static func message_to_string(data, nesting : int = 0) -> String:
		var DEFAULT_VALUES
		if PROTO_VERSION == 2:
			DEFAULT_VALUES = DEFAULT_VALUES_2
		elif PROTO_VERSION == 3:
			DEFAULT_VALUES = DEFAULT_VALUES_3
		var result : String = ""
		var keys : Array = data.keys()
		keys.sort()
		for i in keys:
			if data[i].field.value != null:
				if data[i].state == PB_SERVICE_STATE.UNFILLED \
				&& !data[i].field.is_map_field \
				&& typeof(data[i].field.value) == typeof(DEFAULT_VALUES[data[i].field.type]) \
				&& data[i].field.value == DEFAULT_VALUES[data[i].field.type]:
					continue
				elif data[i].field.rule == PB_RULE.REPEATED && data[i].field.value.size() == 0:
					continue
				result += field_to_string(data[i].field, nesting)
			elif data[i].field.rule == PB_RULE.REQUIRED:
				result += data[i].field.name + ": " + "error"
		return result



############### USER DATA BEGIN ################


enum C2SMAINPROTOCOL {
	C2SMAINPROTOCOL_NONE = 0,
	C_S_WARE = 1
}

enum S2CMAINPROTOCOL {
	S2CMAINPROTOCOL_NONE = 0,
	S_C_WARE = 1
}

enum C2SPROTOCOL {
	C2SPROTOCOL_NONE = 0,
	C_S_SEARCH_WARE = 1001,
	C_S_GET_WARE_INFO = 1002
}

enum S2CPROTOCOL {
	S2CPROTOCOL_NONE = 0,
	S_C_SEARCH_WARE = 2001,
	S_C_GET_WARE_INFO = 2002
}

class M_C_S_SEARCH_WARE:
	func _init():
		var service
		
		_keyword = PBField.new("keyword", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _keyword
		data[_keyword.tag] = service
		
		_max_result = PBField.new("max_result", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = _max_result
		data[_max_result.tag] = service
		
	var data = {}
	
	var _keyword: PBField
	func get_keyword() -> String:
		return _keyword.value
	func clear_keyword() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		_keyword.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_keyword(value : String) -> void:
		_keyword.value = value
	
	var _max_result: PBField
	func get_max_result() -> int:
		return _max_result.value
	func clear_max_result() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		_max_result.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_max_result(value : int) -> void:
		_max_result.value = value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class M_C_S_GET_WARE_INFO:
	func _init():
		var service
		
		_good_id = PBField.new("good_id", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _good_id
		data[_good_id.tag] = service
		
		_sku_id = PBField.new("sku_id", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _sku_id
		data[_sku_id.tag] = service
		
		_sku_url = PBField.new("sku_url", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 3, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _sku_url
		data[_sku_url.tag] = service
		
		_max_result = PBField.new("max_result", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 4, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = _max_result
		data[_max_result.tag] = service
		
	var data = {}
	
	var _good_id: PBField
	func get_good_id() -> String:
		return _good_id.value
	func clear_good_id() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		_good_id.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_good_id(value : String) -> void:
		_good_id.value = value
	
	var _sku_id: PBField
	func get_sku_id() -> String:
		return _sku_id.value
	func clear_sku_id() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		_sku_id.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_sku_id(value : String) -> void:
		_sku_id.value = value
	
	var _sku_url: PBField
	func get_sku_url() -> String:
		return _sku_url.value
	func clear_sku_url() -> void:
		data[3].state = PB_SERVICE_STATE.UNFILLED
		_sku_url.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_sku_url(value : String) -> void:
		_sku_url.value = value
	
	var _max_result: PBField
	func get_max_result() -> int:
		return _max_result.value
	func clear_max_result() -> void:
		data[4].state = PB_SERVICE_STATE.UNFILLED
		_max_result.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_max_result(value : int) -> void:
		_max_result.value = value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class M_S_C_GET_WARE_INFO:
	func _init():
		var service
		
		_good_id = PBField.new("good_id", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _good_id
		data[_good_id.tag] = service
		
		_specs = PBField.new("specs", PB_DATA_TYPE.MAP, PB_RULE.REPEATED, 2, true, [])
		service = PBServiceField.new()
		service.field = _specs
		service.func_ref = Callable(self, "add_empty_specs")
		data[_specs.tag] = service
		
		_images = PBField.new("images", PB_DATA_TYPE.STRING, PB_RULE.REPEATED, 3, true, [])
		service = PBServiceField.new()
		service.field = _images
		data[_images.tag] = service
		
		_sku_ids = PBField.new("sku_ids", PB_DATA_TYPE.STRING, PB_RULE.REPEATED, 4, true, [])
		service = PBServiceField.new()
		service.field = _sku_ids
		data[_sku_ids.tag] = service
		
		_comments = PBField.new("comments", PB_DATA_TYPE.STRING, PB_RULE.REPEATED, 5, true, [])
		service = PBServiceField.new()
		service.field = _comments
		data[_comments.tag] = service
		
		_comments_info = PBField.new("comments_info", PB_DATA_TYPE.MAP, PB_RULE.REPEATED, 6, true, [])
		service = PBServiceField.new()
		service.field = _comments_info
		service.func_ref = Callable(self, "add_empty_comments_info")
		data[_comments_info.tag] = service
		
		_prices = PBField.new("prices", PB_DATA_TYPE.MAP, PB_RULE.REPEATED, 7, true, [])
		service = PBServiceField.new()
		service.field = _prices
		service.func_ref = Callable(self, "add_empty_prices")
		data[_prices.tag] = service
		
		_special_specs = PBField.new("special_specs", PB_DATA_TYPE.MAP, PB_RULE.REPEATED, 8, true, [])
		service = PBServiceField.new()
		service.field = _special_specs
		service.func_ref = Callable(self, "add_empty_special_specs")
		data[_special_specs.tag] = service
		
		_urls = PBField.new("urls", PB_DATA_TYPE.MAP, PB_RULE.REPEATED, 9, true, [])
		service = PBServiceField.new()
		service.field = _urls
		service.func_ref = Callable(self, "add_empty_urls")
		data[_urls.tag] = service
		
	var data = {}
	
	var _good_id: PBField
	func get_good_id() -> String:
		return _good_id.value
	func clear_good_id() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		_good_id.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_good_id(value : String) -> void:
		_good_id.value = value
	
	var _specs: PBField
	func get_raw_specs():
		return _specs.value
	func get_specs():
		return PBPacker.construct_map(_specs.value)
	func clear_specs():
		data[2].state = PB_SERVICE_STATE.UNFILLED
		_specs.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MAP]
	func add_empty_specs() -> M_S_C_GET_WARE_INFO.map_type_specs:
		var element = M_S_C_GET_WARE_INFO.map_type_specs.new()
		_specs.value.append(element)
		return element
	func add_specs(a_key, a_value) -> void:
		var idx = -1
		for i in range(_specs.value.size()):
			if _specs.value[i].get_key() == a_key:
				idx = i
				break
		var element = M_S_C_GET_WARE_INFO.map_type_specs.new()
		element.set_key(a_key)
		element.set_value(a_value)
		if idx != -1:
			_specs.value[idx] = element
		else:
			_specs.value.append(element)
	
	var _images: PBField
	func get_images() -> Array:
		return _images.value
	func clear_images() -> void:
		data[3].state = PB_SERVICE_STATE.UNFILLED
		_images.value = []
	func add_images(value : String) -> void:
		_images.value.append(value)
	
	var _sku_ids: PBField
	func get_sku_ids() -> Array:
		return _sku_ids.value
	func clear_sku_ids() -> void:
		data[4].state = PB_SERVICE_STATE.UNFILLED
		_sku_ids.value = []
	func add_sku_ids(value : String) -> void:
		_sku_ids.value.append(value)
	
	var _comments: PBField
	func get_comments() -> Array:
		return _comments.value
	func clear_comments() -> void:
		data[5].state = PB_SERVICE_STATE.UNFILLED
		_comments.value = []
	func add_comments(value : String) -> void:
		_comments.value.append(value)
	
	var _comments_info: PBField
	func get_raw_comments_info():
		return _comments_info.value
	func get_comments_info():
		return PBPacker.construct_map(_comments_info.value)
	func clear_comments_info():
		data[6].state = PB_SERVICE_STATE.UNFILLED
		_comments_info.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MAP]
	func add_empty_comments_info() -> M_S_C_GET_WARE_INFO.map_type_comments_info:
		var element = M_S_C_GET_WARE_INFO.map_type_comments_info.new()
		_comments_info.value.append(element)
		return element
	func add_comments_info(a_key, a_value) -> void:
		var idx = -1
		for i in range(_comments_info.value.size()):
			if _comments_info.value[i].get_key() == a_key:
				idx = i
				break
		var element = M_S_C_GET_WARE_INFO.map_type_comments_info.new()
		element.set_key(a_key)
		element.set_value(a_value)
		if idx != -1:
			_comments_info.value[idx] = element
		else:
			_comments_info.value.append(element)
	
	var _prices: PBField
	func get_raw_prices():
		return _prices.value
	func get_prices():
		return PBPacker.construct_map(_prices.value)
	func clear_prices():
		data[7].state = PB_SERVICE_STATE.UNFILLED
		_prices.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MAP]
	func add_empty_prices() -> M_S_C_GET_WARE_INFO.map_type_prices:
		var element = M_S_C_GET_WARE_INFO.map_type_prices.new()
		_prices.value.append(element)
		return element
	func add_prices(a_key, a_value) -> void:
		var idx = -1
		for i in range(_prices.value.size()):
			if _prices.value[i].get_key() == a_key:
				idx = i
				break
		var element = M_S_C_GET_WARE_INFO.map_type_prices.new()
		element.set_key(a_key)
		element.set_value(a_value)
		if idx != -1:
			_prices.value[idx] = element
		else:
			_prices.value.append(element)
	
	var _special_specs: PBField
	func get_raw_special_specs():
		return _special_specs.value
	func get_special_specs():
		return PBPacker.construct_map(_special_specs.value)
	func clear_special_specs():
		data[8].state = PB_SERVICE_STATE.UNFILLED
		_special_specs.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MAP]
	func add_empty_special_specs() -> M_S_C_GET_WARE_INFO.map_type_special_specs:
		var element = M_S_C_GET_WARE_INFO.map_type_special_specs.new()
		_special_specs.value.append(element)
		return element
	func add_special_specs(a_key) -> M_S_C_GET_WARE_INFO.SPECS_INFO:
		var idx = -1
		for i in range(_special_specs.value.size()):
			if _special_specs.value[i].get_key() == a_key:
				idx = i
				break
		var element = M_S_C_GET_WARE_INFO.map_type_special_specs.new()
		element.set_key(a_key)
		if idx != -1:
			_special_specs.value[idx] = element
		else:
			_special_specs.value.append(element)
		return element.new_value()
	
	var _urls: PBField
	func get_raw_urls():
		return _urls.value
	func get_urls():
		return PBPacker.construct_map(_urls.value)
	func clear_urls():
		data[9].state = PB_SERVICE_STATE.UNFILLED
		_urls.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MAP]
	func add_empty_urls() -> M_S_C_GET_WARE_INFO.map_type_urls:
		var element = M_S_C_GET_WARE_INFO.map_type_urls.new()
		_urls.value.append(element)
		return element
	func add_urls(a_key, a_value) -> void:
		var idx = -1
		for i in range(_urls.value.size()):
			if _urls.value[i].get_key() == a_key:
				idx = i
				break
		var element = M_S_C_GET_WARE_INFO.map_type_urls.new()
		element.set_key(a_key)
		element.set_value(a_value)
		if idx != -1:
			_urls.value[idx] = element
		else:
			_urls.value.append(element)
	
	class SPECS_INFO:
		func _init():
			var service
			
			_data = PBField.new("data", PB_DATA_TYPE.MAP, PB_RULE.REPEATED, 1, true, [])
			service = PBServiceField.new()
			service.field = _data
			service.func_ref = Callable(self, "add_empty_data")
			data[_data.tag] = service
			
		var data = {}
		
		var _data: PBField
		func get_raw_data():
			return _data.value
		func get_data():
			return PBPacker.construct_map(_data.value)
		func clear_data():
			data[1].state = PB_SERVICE_STATE.UNFILLED
			_data.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MAP]
		func add_empty_data() -> M_S_C_GET_WARE_INFO.SPECS_INFO.map_type_data:
			var element = M_S_C_GET_WARE_INFO.SPECS_INFO.map_type_data.new()
			_data.value.append(element)
			return element
		func add_data(a_key, a_value) -> void:
			var idx = -1
			for i in range(_data.value.size()):
				if _data.value[i].get_key() == a_key:
					idx = i
					break
			var element = M_S_C_GET_WARE_INFO.SPECS_INFO.map_type_data.new()
			element.set_key(a_key)
			element.set_value(a_value)
			if idx != -1:
				_data.value[idx] = element
			else:
				_data.value.append(element)
		
		class map_type_data:
			func _init():
				var service
				
				_key = PBField.new("key", PB_DATA_TYPE.STRING, PB_RULE.REQUIRED, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
				_key.is_map_field = true
				service = PBServiceField.new()
				service.field = _key
				data[_key.tag] = service
				
				_value = PBField.new("value", PB_DATA_TYPE.STRING, PB_RULE.REQUIRED, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
				_value.is_map_field = true
				service = PBServiceField.new()
				service.field = _value
				data[_value.tag] = service
				
			var data = {}
			
			var _key: PBField
			func get_key() -> String:
				return _key.value
			func clear_key() -> void:
				data[1].state = PB_SERVICE_STATE.UNFILLED
				_key.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
			func set_key(value : String) -> void:
				_key.value = value
			
			var _value: PBField
			func get_value() -> String:
				return _value.value
			func clear_value() -> void:
				data[2].state = PB_SERVICE_STATE.UNFILLED
				_value.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
			func set_value(value : String) -> void:
				_value.value = value
			
			func _to_string() -> String:
				return PBPacker.message_to_string(data)
				
			func to_bytes() -> PackedByteArray:
				return PBPacker.pack_message(data)
				
			func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
				var cur_limit = bytes.size()
				if limit != -1:
					cur_limit = limit
				var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
				if result == cur_limit:
					if PBPacker.check_required(data):
						if limit == -1:
							return PB_ERR.NO_ERRORS
					else:
						return PB_ERR.REQUIRED_FIELDS
				elif limit == -1 && result > 0:
					return PB_ERR.PARSE_INCOMPLETE
				return result
			
		func _to_string() -> String:
			return PBPacker.message_to_string(data)
			
		func to_bytes() -> PackedByteArray:
			return PBPacker.pack_message(data)
			
		func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
			var cur_limit = bytes.size()
			if limit != -1:
				cur_limit = limit
			var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
			if result == cur_limit:
				if PBPacker.check_required(data):
					if limit == -1:
						return PB_ERR.NO_ERRORS
				else:
					return PB_ERR.REQUIRED_FIELDS
			elif limit == -1 && result > 0:
				return PB_ERR.PARSE_INCOMPLETE
			return result
		
	class map_type_specs:
		func _init():
			var service
			
			_key = PBField.new("key", PB_DATA_TYPE.STRING, PB_RULE.REQUIRED, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
			_key.is_map_field = true
			service = PBServiceField.new()
			service.field = _key
			data[_key.tag] = service
			
			_value = PBField.new("value", PB_DATA_TYPE.STRING, PB_RULE.REQUIRED, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
			_value.is_map_field = true
			service = PBServiceField.new()
			service.field = _value
			data[_value.tag] = service
			
		var data = {}
		
		var _key: PBField
		func get_key() -> String:
			return _key.value
		func clear_key() -> void:
			data[1].state = PB_SERVICE_STATE.UNFILLED
			_key.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
		func set_key(value : String) -> void:
			_key.value = value
		
		var _value: PBField
		func get_value() -> String:
			return _value.value
		func clear_value() -> void:
			data[2].state = PB_SERVICE_STATE.UNFILLED
			_value.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
		func set_value(value : String) -> void:
			_value.value = value
		
		func _to_string() -> String:
			return PBPacker.message_to_string(data)
			
		func to_bytes() -> PackedByteArray:
			return PBPacker.pack_message(data)
			
		func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
			var cur_limit = bytes.size()
			if limit != -1:
				cur_limit = limit
			var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
			if result == cur_limit:
				if PBPacker.check_required(data):
					if limit == -1:
						return PB_ERR.NO_ERRORS
				else:
					return PB_ERR.REQUIRED_FIELDS
			elif limit == -1 && result > 0:
				return PB_ERR.PARSE_INCOMPLETE
			return result
		
	class map_type_comments_info:
		func _init():
			var service
			
			_key = PBField.new("key", PB_DATA_TYPE.STRING, PB_RULE.REQUIRED, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
			_key.is_map_field = true
			service = PBServiceField.new()
			service.field = _key
			data[_key.tag] = service
			
			_value = PBField.new("value", PB_DATA_TYPE.STRING, PB_RULE.REQUIRED, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
			_value.is_map_field = true
			service = PBServiceField.new()
			service.field = _value
			data[_value.tag] = service
			
		var data = {}
		
		var _key: PBField
		func get_key() -> String:
			return _key.value
		func clear_key() -> void:
			data[1].state = PB_SERVICE_STATE.UNFILLED
			_key.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
		func set_key(value : String) -> void:
			_key.value = value
		
		var _value: PBField
		func get_value() -> String:
			return _value.value
		func clear_value() -> void:
			data[2].state = PB_SERVICE_STATE.UNFILLED
			_value.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
		func set_value(value : String) -> void:
			_value.value = value
		
		func _to_string() -> String:
			return PBPacker.message_to_string(data)
			
		func to_bytes() -> PackedByteArray:
			return PBPacker.pack_message(data)
			
		func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
			var cur_limit = bytes.size()
			if limit != -1:
				cur_limit = limit
			var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
			if result == cur_limit:
				if PBPacker.check_required(data):
					if limit == -1:
						return PB_ERR.NO_ERRORS
				else:
					return PB_ERR.REQUIRED_FIELDS
			elif limit == -1 && result > 0:
				return PB_ERR.PARSE_INCOMPLETE
			return result
		
	class map_type_prices:
		func _init():
			var service
			
			_key = PBField.new("key", PB_DATA_TYPE.STRING, PB_RULE.REQUIRED, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
			_key.is_map_field = true
			service = PBServiceField.new()
			service.field = _key
			data[_key.tag] = service
			
			_value = PBField.new("value", PB_DATA_TYPE.STRING, PB_RULE.REQUIRED, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
			_value.is_map_field = true
			service = PBServiceField.new()
			service.field = _value
			data[_value.tag] = service
			
		var data = {}
		
		var _key: PBField
		func get_key() -> String:
			return _key.value
		func clear_key() -> void:
			data[1].state = PB_SERVICE_STATE.UNFILLED
			_key.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
		func set_key(value : String) -> void:
			_key.value = value
		
		var _value: PBField
		func get_value() -> String:
			return _value.value
		func clear_value() -> void:
			data[2].state = PB_SERVICE_STATE.UNFILLED
			_value.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
		func set_value(value : String) -> void:
			_value.value = value
		
		func _to_string() -> String:
			return PBPacker.message_to_string(data)
			
		func to_bytes() -> PackedByteArray:
			return PBPacker.pack_message(data)
			
		func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
			var cur_limit = bytes.size()
			if limit != -1:
				cur_limit = limit
			var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
			if result == cur_limit:
				if PBPacker.check_required(data):
					if limit == -1:
						return PB_ERR.NO_ERRORS
				else:
					return PB_ERR.REQUIRED_FIELDS
			elif limit == -1 && result > 0:
				return PB_ERR.PARSE_INCOMPLETE
			return result
		
	class map_type_special_specs:
		func _init():
			var service
			
			_key = PBField.new("key", PB_DATA_TYPE.STRING, PB_RULE.REQUIRED, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
			_key.is_map_field = true
			service = PBServiceField.new()
			service.field = _key
			data[_key.tag] = service
			
			_value = PBField.new("value", PB_DATA_TYPE.MESSAGE, PB_RULE.REQUIRED, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
			_value.is_map_field = true
			service = PBServiceField.new()
			service.field = _value
			service.func_ref = Callable(self, "new_value")
			data[_value.tag] = service
			
		var data = {}
		
		var _key: PBField
		func get_key() -> String:
			return _key.value
		func clear_key() -> void:
			data[1].state = PB_SERVICE_STATE.UNFILLED
			_key.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
		func set_key(value : String) -> void:
			_key.value = value
		
		var _value: PBField
		func get_value() -> M_S_C_GET_WARE_INFO.SPECS_INFO:
			return _value.value
		func clear_value() -> void:
			data[2].state = PB_SERVICE_STATE.UNFILLED
			_value.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		func new_value() -> M_S_C_GET_WARE_INFO.SPECS_INFO:
			_value.value = M_S_C_GET_WARE_INFO.SPECS_INFO.new()
			return _value.value
		
		func _to_string() -> String:
			return PBPacker.message_to_string(data)
			
		func to_bytes() -> PackedByteArray:
			return PBPacker.pack_message(data)
			
		func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
			var cur_limit = bytes.size()
			if limit != -1:
				cur_limit = limit
			var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
			if result == cur_limit:
				if PBPacker.check_required(data):
					if limit == -1:
						return PB_ERR.NO_ERRORS
				else:
					return PB_ERR.REQUIRED_FIELDS
			elif limit == -1 && result > 0:
				return PB_ERR.PARSE_INCOMPLETE
			return result
		
	class map_type_urls:
		func _init():
			var service
			
			_key = PBField.new("key", PB_DATA_TYPE.STRING, PB_RULE.REQUIRED, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
			_key.is_map_field = true
			service = PBServiceField.new()
			service.field = _key
			data[_key.tag] = service
			
			_value = PBField.new("value", PB_DATA_TYPE.STRING, PB_RULE.REQUIRED, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
			_value.is_map_field = true
			service = PBServiceField.new()
			service.field = _value
			data[_value.tag] = service
			
		var data = {}
		
		var _key: PBField
		func get_key() -> String:
			return _key.value
		func clear_key() -> void:
			data[1].state = PB_SERVICE_STATE.UNFILLED
			_key.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
		func set_key(value : String) -> void:
			_key.value = value
		
		var _value: PBField
		func get_value() -> String:
			return _value.value
		func clear_value() -> void:
			data[2].state = PB_SERVICE_STATE.UNFILLED
			_value.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
		func set_value(value : String) -> void:
			_value.value = value
		
		func _to_string() -> String:
			return PBPacker.message_to_string(data)
			
		func to_bytes() -> PackedByteArray:
			return PBPacker.pack_message(data)
			
		func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
			var cur_limit = bytes.size()
			if limit != -1:
				cur_limit = limit
			var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
			if result == cur_limit:
				if PBPacker.check_required(data):
					if limit == -1:
						return PB_ERR.NO_ERRORS
				else:
					return PB_ERR.REQUIRED_FIELDS
			elif limit == -1 && result > 0:
				return PB_ERR.PARSE_INCOMPLETE
			return result
		
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class M_S_C_SEARCH_WARE:
	func _init():
		var service
		
		_ware_infos = PBField.new("ware_infos", PB_DATA_TYPE.MESSAGE, PB_RULE.REPEATED, 1, true, [])
		service = PBServiceField.new()
		service.field = _ware_infos
		service.func_ref = Callable(self, "add_ware_infos")
		data[_ware_infos.tag] = service
		
	var data = {}
	
	var _ware_infos: PBField
	func get_ware_infos() -> Array:
		return _ware_infos.value
	func clear_ware_infos() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		_ware_infos.value = []
	func add_ware_infos() -> M_S_C_GET_WARE_INFO:
		var element = M_S_C_GET_WARE_INFO.new()
		_ware_infos.value.append(element)
		return element
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
################ USER DATA END #################
