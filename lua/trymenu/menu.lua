local Mysql_Class = require "mysql_class2"["Mysql_CLass"] --数据库db类
local str = require "resty.string"


local args = ngx.req.get_uri_args() or {}

local mysql = Mysql_Class:new(args) --实例化mysql类

local err,json = mysql:query_item()


if err then
	ngx.status = ngx.HTTP_NOT_FOUND
	return ngx.say(err)
end


local XorKey = 4
local s = ngx.encode_base64(json)

local stable={}
for i=1,#s do
	table.insert(stable, string.char(bit.bxor(string.byte(s, i),XorKey)))	
end
local s2 = table.concat(stable)


--local s2table={}
--for j=1,#s2 do
--	table.insert(s2table, string.char(bit.bxor(string.byte(s2, j),XorKey)))
--end
--local s3 = table.concat(s2table)


--ngx.log(ngx.ERR, json) --出错记录错误日志，无法加载mysql库
--ngx.log(ngx.ERR, ngx.decode_base64(s3)) --出错记录错误日志，无法加载mysql库


-- ngx.header["Content-Type"] = 'application/json; charset=UTF-8';

ngx.say(s2)

