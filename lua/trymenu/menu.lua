local enterTime = tonumber(os.time()) -- 进入时候时间戳，用来判断是否超时

local Mysql_Class = require "mysql_class2"["Mysql_CLass"] --数据库db类

local args = ngx.req.get_uri_args() or {}

local mysql = Mysql_Class:new(args) --实例化mysql类

local err,json = mysql:query_item()

ngx.header["Content-Type"] = 'application/octet-stream';

if err then
	ngx.status = ngx.HTTP_NOT_FOUND
	return ngx.say(err)
end

if args.noencode then
	ngx.say(json)
else

	local XorKey = 4
	local s = ngx.encode_base64(json)

	local stable={}
	for i=1,#s do
		table.insert(stable, string.char(bit.bxor(string.byte(s, i),XorKey)))	
	end
	local s2 = table.concat(stable)

	-- ngx.header["Content-Type"] = 'application/json; charset=UTF-8';

	ngx.say(s2)
end

local resTime = tonumber(os.time()) -- 响应后时间戳

local dealTime = resTime - enterTime
if dealTime > 5 then
	ngx.log(ngx.ERR, "deal request too long :" ..tostring(dealTime)) --出错记录错误日志	
end