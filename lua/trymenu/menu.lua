local Mysql_Class = require "mysql_class2"["Mysql_CLass"] --数据库db类

local args = ngx.req.get_uri_args() or {}

local mysql = Mysql_Class:new(args) --实例化mysql类

local err,json = mysql:query_item()

ngx.header["Content-Type"] = 'application/octet-stream';

if err then
	ngx.status = ngx.HTTP_NOT_FOUND
	return ngx.say(err)
end

--ngx.say(json)


local XorKey = 4
local s = ngx.encode_base64(json)

local stable={}
for i=1,#s do
	table.insert(stable, string.char(bit.bxor(string.byte(s, i),XorKey)))	
end
local s2 = table.concat(stable)



-- ngx.header["Content-Type"] = 'application/json; charset=UTF-8';

ngx.say(s2)

