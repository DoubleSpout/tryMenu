--ngx_lua启动执行这里，将一些常用的数据缓存在此，避免每次request都去请求数据库，减少i/o
	
require "cjson"	--cjson库
require "ngx" --ngx库
require "lua_middle_class" --lua 对象增强库


--设定下载的cache标识
local down_cache = ngx.shared.down_cache
local suc = down_cache:add("is_cache", "0")

--如果出错则记录初始化失败
if not suc then
    ngx.log(ngx.ERR, 'lua init _down_is_cache failed')
end