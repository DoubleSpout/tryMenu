local Mysql_Class = require "mysql_class2"["Mysql_CLass"] --数据库db类


local args = ngx.req.get_uri_args() or {}

local mysql = Mysql_Class:new(args) --实例化mysql类


local err,json = mysql:query_item()


if err then
	ngx.status = ngx.HTTP_NOT_FOUND
	return ngx.say(err)
end

if json == 'cache' then	
	ngx.say(json)
	return
end

ngx.header["Content-Type"] = 'application/json; charset=UTF-8';
ngx.say(json)
