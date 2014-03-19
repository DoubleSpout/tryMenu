module("mysql_class2", package.seeall)


local mysql = require "resty.mysql"
local dbConn = require "conn"["connTable"]
local dateLib = require "date"

local ERR_MYSQL_LIB = "could not open mysql library"
local ERR_MYSQL_DB = "could not open mysql database"
local ERR_MYSQL_ERROR = "mysql occur error"
local ERR_NO_CITY = "no city param"
local ERR_NO_SUCH_CITY_MENU = "no such city menu"
local ERR_HAS_NO_PARENTID = 'has no parentid item'


Mysql_CLass = class('Mysql_CLass')

function Mysql_CLass:initialize(reqTable)
    self.host = dbConn.host
    self.port = dbConn.port
    self.database = dbConn.database
    self.user = dbConn.user
    self.password = dbConn.password
    self.max_packet_size =  1024 * 1024

    self.max_idle_timeout = 1000*60
    self.pool_size = 50
    self.reqTable = reqTable  --获得filter类的实例
    self.jsonTable={}

end


function Mysql_CLass:connect()
		
        local db, err = mysql:new()

        if not db then
	    ngx.log(ngx.ERR, "mysql library error " .. err) --出错记录错误日志，无法加载mysql库
            return ERR_MYSQL_LIB --返回错误code
        end
	
	self.db = db

        db:set_timeout(3000) -- 设定超时间3 sec

	local ok, err, errno, sqlstate = db:connect{ --建立数据库连接
                   host = self.host,
                   port = self.port,
                   database = self.database,
                   user = self.user,
                   password = self.password,
		   pool = self.pool_size,
                   max_packet_size = self.max_packet_size 
		}

	if not ok then --如果连接失败
	      ngx.log(ngx.ERR, "mysql not connect: " .. err) --出错记录错误日志
	      return ERR_MYSQL_DB  --返回错误code
        end
	local res, err, errno, sqlstate =  --查询默认设置utf-8表
		db:query("set names 'utf8';")
	
	return nil, db --连接成功返回ok状态码

end



function Mysql_CLass:close_conn() --关闭mysql连接封装
	 
	 local db = self.db
	 
	 local ok, err = db:set_keepalive(self.max_idle_timeout, self.pool_size) --将本链接放入连接池

	 if not ok then  --如果设置连接池出错
	    ngx.log(ngx.ERR, "mysql failed to back connect pool: " .. err) 
         end
	
end



function Mysql_CLass:query_item()
	
	 if not self.reqTable.city then	        
		return ERR_NO_CITY, nil
	 end

	 local updatetime = self.reqTable.updatetime -- 接受更新时间时间戳

	 if updatetime then -- 将updatetime转为dateLib对象
		updatetime = dateLib(tonumber(updatetime)):tolocal()
	 end
	
	

	 local err,db = self:connect() --连接mysql数据库

	 if err then
	        self:close_conn()
		return err,nil
	 end
	 
	 local now = os.date("%Y-%m-%d %H:%M:%S", os.time())

	 local property = "GAME_LIST_ITEM.Id, ItemType, Itemname, ItemNewTip, ItemExtraTip, Changed, parentId, Icon, ItemID, ItemUrl, OpenType, Width, Height, ItemParent, mycategorycode, HelpURL, ServerVersion, EName, channelcode, rootcode, mygamecode, WatchCrash, ServerID, GameServerAddr, GameServerPort, MinVer, MaxVer, MaxUser, GameTypeName, GAME_LIST_ITEM.writetime"
	 local sqlCmd = "select "..property.." from GAME_LIST_ITEM left join GAME_SITE on (GAME_LIST_ITEM.GAME_SITEId = GAME_SITE.Id) left join Game on (GAME_LIST_ITEM.GameId = Game.Id) WHERE GAME_LIST_ITEM.is_show=1 AND GAME_SITE.sitename="..ngx.quote_sql_str(self.reqTable.city).." AND GAME_LIST_ITEM.BeginTime < '"..now.."' AND GAME_LIST_ITEM.EndTime > '"..now.."' AND (Game.IsRun = 1 or Game.IsRun IS NULL)  ORDER BY GAME_LIST_ITEM.Iorder ASC;"
	 --local sqlCmd = "select "..property.." from GAME_LIST_ITEM left join GAME_SITE on (GAME_LIST_ITEM.GAME_SITEId = GAME_SITE.Id) left join Game on (GAME_LIST_ITEM.GameId = Game.Id) WHERE GAME_LIST_ITEM.is_show=1 AND GAME_SITE.sitename="..ngx.quote_sql_str(self.reqTable.city).." ORDER BY GAME_LIST_ITEM.Iorder DESC;"	  
	 -- ngx.log(ngx.ERR, sqlCmd) 
	 
	 local res, err, errno, sqlstate =  --查询 ApiServices 表
		db:query(sqlCmd)

	 self:close_conn() -- 关闭数据库连接
	 

	
	 if not res then
	      --如果表查询出错
	      ngx.log(ngx.ERR, "get mysql data error: " .. err .. ": " .. errno .. ": ".. sqlstate .. ".") --出错记录错误日志	      
	      return ERR_MYSQL_ERROR, nil
	 end

	 if table.getn(res) == 0 then --如果没有查到数据
		return ERR_NO_SUCH_CITY_MENU,nil
	 end
	 
	 self.menuTable = res --将查出的table保存在 self.menuTable 中
	 
	 local forceUpdate = 0
	

	 for i,v in ipairs(self.menuTable) do --循环剔除值为nil的属性
		for key in pairs(v) do 
		    
		    if v[key] == ngx.null or v[key] == '' or v[key] == 'NULL' then --lua中返回的mysql数据null值为ngx.null
			v[key] = nil
		    end

		    if v['ItemType'] == 'GAME_ROOT' then
		       v['updatetime'] = tostring(os.time())
		    end

		    local writetime = dateLib(v['writetime'])

		    if  updatetime and writetime>updatetime then
			--ngx.log(ngx.ERR, tostring(writetime))
			--ngx.log(ngx.ERR, tostring(updatetime))
			--ngx.log(ngx.ERR, tostring(self.reqTable.updatetime))
			--ngx.log(ngx.ERR, '**********')
			forceUpdate = forceUpdate + 1
		    end
		    
		
		end 
	 end
	 
	 if updatetime and forceUpdate == 0 then
		return nil,"cache"
	 end

	 self.menuTable = self:filterEmpty() -- 去除空房间的节点

	 err = self:genJsonTable() --生成输出的JSON类型的table

	 if err then --生成json类型table出错
		return err,nil
	 end

	 local ok,err = pcall(function() --转换成json字符串
	       self.jsonStr = cjson.encode(self.jsonTable[1])
	 end)
	 
	 if err then 
		return err,nil
	 end
	 
	 return nil,self.jsonStr
	  
end


function Mysql_CLass:genJsonTable() --创建json字符串
	  
	 self.removeKey = -1

	 while table.getn(self.menuTable) ~= 0 do --如果self.menuTable长度大于0，即还没有完全处理完	
		 local count = 0
		 self.hasFound = 0 --防止空转
		 for i,v in ipairs(self.menuTable) do --循环匹配
			 --递归查找jsonTable中是否含有id和父id相同的节点，如果相同，则将数据放入jsonTable中去
			self:traversalTable(self.jsonTable, v.parentId, v, i)
			if self.hasFound == 1 then --如果在这次循环已经找到，则跳出循环
				break;
			end
		 end
		 --ngx.log(ngx.ERR,cjson.encode(self.menuTable))

		 if self.hasFound == 0 then --如果没有找到父节点，则说明数组有错误，跳出循环
			ngx.log(ngx.ERR, "empty parentid data") --出错记录错误日志	      
		 	return ERR_HAS_NO_PARENTID,nil
		 end
		 table.remove(self.menuTable, self.removeKey) --将找到的节点从self.menuTable中剔除
	 end

	 
	 return nil

end

function Mysql_CLass:traversalTable(currentTable, parentId, item, num)

	if parentId == 0 then
		self:insertChild(currentTable,item,num) -- 根节点
		return
	end

	for i,v in ipairs(currentTable) do	
		if v.Id == parentId then	
		   v.Children = v.Children or {} --如果不存在Children节点，则创建它
		   self:insertChild(v.Children,item,num)
		elseif v.Children ~= nil then  --如果没找到，并且此项有Children的，则递归去Children中查找
		   self:traversalTable(v.Children, parentId, item, num) --递归查找
		end
	end
end


function Mysql_CLass:insertChild(curObj,item,num)
	for key in pairs(item) do 

	    if key == "Changed" then --lua中对mysql bit的返回值是\u0001
		if item[key] == '\\u0001' then
			item[key] = true
		else
			item[key] = false
		end
	    end

	    if key == "Icon" and item[key] == -1 then
		item[key] = item["EName"]
	    end
	end 
	table.insert(curObj,item)  --将匹配的节点插入指定的Children中
	self.removeKey = num		 --记录将要删除的self.menuTable项的位置
	self.hasFound = 1
end



function Mysql_CLass:filterEmpty()
	
	local tempTable = {} --临时保存table对象
	local removeC1       --删除的game channel数
	local removeC2       --删除的game kindof数
	local removeObj      

	local length1, removeIds1 = self:getRemoveIds(self.menuTable, 'GAME_CHANNEL')

	if length1 >0 then
		removeC1 = self:RemoveByIds(self.menuTable, removeIds1)
	end

	local length2, removeIds2 = self:getRemoveIds(self.menuTable, 'GAME_KINDOF')

	if length2 >0 then
		removeC2 = self:RemoveByIds(self.menuTable, removeIds2)
	end
	
	for i,v in ipairs(self.menuTable) do --第一步，循环结果，查找空channel
		  
		  if v then
			table.insert(tempTable,v)
		  end

	 end

	return tempTable;
end


function Mysql_CLass:getRemoveIds(objtable, typestr)
	
	local removeIds = {}


	for i,v1 in ipairs(objtable) do --第一步，循环菜单
		
		    if v1 and v1['ItemType'] == typestr then --如果是typestr类型
			local countParent = 0 --找到父类的计数
			local curId = v1['Id'] --暂存id
				for j,v2 in ipairs(objtable) do --循环查找其子类
					if v2 and v2['parentId'] == curId then --如果找到，计数+1
						countParent = countParent+1;
					end
				end
			if countParent == 0 then --如果没找到，则把这个id放入删除id数组
				table.insert(removeIds,curId)
			end
		    end

	 end

	 return table.getn(removeIds), removeIds --返回删除id数组长度和删除id数组
end


function Mysql_CLass:RemoveByIds(objtable, idsobj) -- 根据id数组删除对象中的内容
	
	local removeCount = 0;
	local removeObj

	for i,v in ipairs(objtable) do --循环大数组
		if v then
			for j,idv in ipairs(idsobj) do --循环id数组
				if idv == v['Id'] then --当发现id匹配，删除大数组中的项
					objtable[i] = false;
					removeCount = removeCount + 1;
					--removeObj = v
					break;
				end
			end
		end
	 end

	 return removeCount 
end
