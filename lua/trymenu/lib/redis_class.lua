module("redis_class", package.seeall)

local redis = require "resty.redis"
local RedisConn = require "conn"["connRedis"]
local dateLib = require "date"


Redis_Class = class('Redis_Class')

function Redis_Class:initialize(city,userversion)
    self.host = RedisConn.host
    self.port = RedisConn.port
    
    self.pool=RedisConn.pool
    self.max_idle_timeout=RedisConn.max_idle_timeout

    self.version = userversion
    self.city = city or 'main'

    self.cacheTime = 60

end


function Redis_Class:connect()
		
        local red = redis:new()
	
	red:set_timeout(3000) -- 1 second

	local ok, err = red:connect(self.host, self.port)

        if not ok then
	    ngx.log(ngx.ERR, "redis library error " .. err) --出错记录错误日志，无法加载mysql库
            return ERR_MYSQL_LIB --返回错误code
        end
	
	self.red = red
	
	return nil, red --连接成功返回ok状态码

end



function Redis_Class:close_conn() --关闭redis连接封装
	 
	 local red = self.red
	 
	 local ok, err = red:set_keepalive(self.max_idle_timeout, self.pool) --将本链接放入连接池

	 if not ok then  --如果设置连接池出错
	    ngx.log(ngx.ERR, "redis failed to back connect pool: " .. err) 
         end
	
end



function Redis_Class:get_data() -- 获取redis缓存数据
	
	local err, red = self:connect()

	if err then
		return err
	end

	local now = tonumber(os.time()) --获得当前时间

	local res, err = red:get("lastCacheTime") --获取上次缓存时间
        if err then --如果失败
	    self:close_conn()
	    ngx.log(ngx.ERR, "failed to get lastCacheTime: ", err)
	    return err
        end
	
	if res == ngx.null then --如果没获取到 上一次缓存时间
	    self:close_conn()
	    ngx.log(ngx.WARN, "no lastCacheTime")
	    return 'no lastCacheTime'
	end
	
	local lastCacheTime = tonumber(res)

	if now - lastCacheTime > self.cacheTime then --如果缓存已经失效
	    self:close_conn()
            ngx.log(ngx.INFO, "cache expired lastCacheTime is " .. tostring(lastCacheTime))
	    return 'cache expired'
	end
	
	--如果满足上述条件，则去redis拿缓存


	if not self.version then
	    return self:send_cache_jsonstr()
	end

	local key = self.city .. '_version'	
	local version, err = red:get(key) --获取此city城市的版本号
	if err then --如果失败
	    self:close_conn()
	    ngx.log(ngx.ERR, 'failed to get '..key..'err: ',err)
	    return err
        end

	if version == ngx.null then --如果没获取到次版本号的city，则返回此city下面的缓存jsonstr	    
	    ngx.log(ngx.WARN, "no city version")
	    return self:send_cache_jsonstr()
	end
	

	if version ~= self.version then --如果用户当前版本号与数据库不同，则响应redis字符串	    
	    return self:send_cache_jsonstr()		
	else --如果版本号相符，就返回cache字符串
	    --ngx.log(ngx.INFO, 'hit cache return cache')
	    self:close_conn()
	    return nil,'cache'
	end

end


function Redis_Class:send_cache_jsonstr()
    
    local keyJson = self.city .. '_json'
    local res, err = self.red:get(keyJson) --获取此city城市的版本号
    self:close_conn()
    if err then --如果失败	        
	ngx.log(ngx.ERR, 'failed to get '..keyJson..'err: ',err)
	return err
    end
    if res == ngx.null then --如果没获取到缓存内容
	ngx.log(ngx.WARN, 'no cache data,key is',keyJson)
	return 'no cache data'
    end

    --ngx.log(ngx.INFO, 'hit cache return jsonstr')
    return nil,res --找到缓存json字符串，返回

end




function Redis_Class:set_data(jsonstr,version)
	
	local err, red = self:connect()
	
	if err then
		return err
	end
	
	local keyJson = self.city .. '_json' -- 城市json字符串key
	local keyVersion = self.city .. '_version' -- 城市版本号key

	red:init_pipeline() --管道生成
	red:set('lastCacheTime', os.time()) -- 存入城市json缓存
	red:set(keyJson, jsonstr) -- 存入城市json缓存
	red:set(keyVersion, version) -- 存入城市版本号值

	local res, err = red:commit_pipeline() --执行
	self:close_conn()
	
	if err then -- 如果生成缓存失败，记录日志
	    ngx.log(ngx.WARN, 'create '..self.city..' err :',err)
	    return err
	end
         ngx.log(ngx.INFO, 'create '..self.city..' cache success')
	return nil

end

 