--Redis公共操作类

--获取日志输出
local log = ngx.log;

--加载Redis模块
local redis = require("resty.redis");


--根据地址字符串加载地址列表
local function getAddressList()
	local addressList = {};
	local addressStrs = split(redis_config.addresses, ";");
	for key, value in ipairs(addressStrs) do
		local address = {
			ip = "";
			port = "";
			password = "";
		};

		local addressStrSplit = split(value, ":");

		if #(addressStrSplit) >= 2 then
			address.ip = addressStrSplit[1];
			address.port = addressStrSplit[2];
			if(#(addressStrSplit) >= 3) then
				address.password = addressStrSplit[3];
			end
			table.insert(addressList, address);
		end

		log(ngx.INFO, "address.ip="..address.ip);
		log(ngx.INFO, "address.port="..address.port);
		log(ngx.INFO, "address.password="..address.password);
	end
	return addressList;
end

--获取地址列表
local addresses = getAddressList();

--加载新的Redis命令
--加载sentinel命令，用于连接Redis Sentinel
redis.add_commands("sentinel");

--将传入key对应的地址调整为尝试连接的最高优先级
local function adjustAddressesPriority(key)
	local tempAddress = addresses[key];
	table.remove(addresses, key);
	table.insert(addresses, 1, tempAddress);
end

--从Redis Sentinel中获取master地址（Sentinel可集群化）
local function getMasterFromSentinel()
	--创建redis连接实例
	local red = redis:new();
	--设置redis连接超时（毫秒）
	red:set_timeout(redis_config.timeout);
	
	--Redis Master服务器IP和Port
	local redisMaster = {
		ip = "";
		port = "";
		password = "";
	};
	
	--循环Sentinel地址进行master获取
	for key, address in ipairs(addresses) do
		log(ngx.INFO, "Try to get master from ",address.ip,":",address.port,"...");
		--连接Redis Sentinel
		local ok, err = red:connect(address.ip, address.port);
		if not ok then
			--若连接失败，则提示异常
			log(ngx.ERR, "connect to redis sentinel error : ", err);
			close_redis(red);
		else
			--获取当前master服务器IP和Port
			local res, err = red:sentinel("get-master-addr-by-name",redis_config.masterName);
			if not res then
				--若执行命令失败，则提示异常
				log(ngx.ERR, "failed to do sentinel command: ", err);
				close_redis(red);
			else
				if key > 1 then
					--若当前连接成功的Sentinel实例所在顺序大于1时，将当前实例对应地址在地址列表中调整到第一位
					log(ngx.INFO, "Put Redis Sentinel ", address.ip..":"..address.port, " to the first !");
					adjustAddressesPriority(key);
				end
				redisMaster.ip = res[1];
				redisMaster.port = res[2];
				--当采用Redis Sentinel部署方式时，地址字符串中的密码表示master redis节点的访问密码
				redisMaster.password = address.password;
				--打断循环
				break;
			end
		end
	end
	
	log(ngx.INFO, "Redis Server : ", redisMaster.ip, ":", redisMaster.port);
	
	if redisMaster.ip == "" then
		return nil;
	else
		close_redis(red);
		return redisMaster;
	end
end

--通过单机（Singleton）模式获取连接
local function getConnectFromSingleton()
	--创建redis连接实例
	local red = redis:new();
	--设置redis连接超时（毫秒）
	red:set_timeout(redis_config.timeout);
	
	--建立redis连接
	local ok, err = red:connect(addresses[1].ip, addresses[1].port);
	if not ok then
		--ngx.say("connect to redis error : ", err);
		log(ngx.ERR, "connect to redis error : ", err);
		close_redis(red);
		return nil;
	end
	
	--当配置有密码时，使用密码进行认证
	if addresses[1].password ~= "" then
		local res, err = red:auth(addresses[1].password);
	    if not res then
	        log(ngx.ERR, "failed to authenticate: ", err);
	        close_redis(red);
	        return nil;
	    end
	end
	
	--连接后返回
	return red;
end

--通过Redis Sentinel模式获取连接（Sentinel可集群化）
local function getConnectFromSentinel()
	--创建redis连接实例
	local red = redis:new();
	--设置redis连接超时（毫秒）
	red:set_timeout(redis_config.timeout);
	
	local redisMaster = getMasterFromSentinel();
	
	--判断是否获取到master节点信息
	if not redisMaster then
		log(ngx.ERR, "can not get master redis server from sentinel : ");
		close_redis(red);
		return nil;
	end
	
	--建立redis连接
	local ok, err = red:connect(redisMaster.ip, redisMaster.port);
	if not ok then
		--ngx.say("connect to redis error : ", err);
		log(ngx.ERR, "connect to redis error : ", err);
		close_redis(red);
		return nil;
	end
	
	--当配置为需要密码时，进行密码认证
	if redisMaster.password ~= "" then
		local res, err = red:auth(redisMaster.password);
	    if not res then
	        log(ngx.ERR, "failed to authenticate: ", err);
	        close_redis(red);
	        return nil;
	    end
	end
	
	--连接后返回
	return red;
end

--设定Redis连接全局获取方法
function getRedisConnect()
	if redis_config.deployType == "Singleton" then
		local red = getConnectFromSingleton();
		return red;
	elseif redis_config.deployType == "Sentinel" then
		local red = getConnectFromSentinel();
		return red;
	else
		return nil;
	end
end

--关闭redis连接全局方法（采用返回连接池的方式）
function close_redis(red)
	if not red then
		return ;
	end
	--local ok, err = red:close();
	local ok, err = red:set_keepalive(redis_config.pool_max_idle_timeout, redis_config.pool_size);
	if not ok then
		--ngx.say("close redis error : ", err);
		--log(ngx.ERR, "close redis error : ", err);
		log(ngx.ERR, "set keepalive error : ", err);
		return ;
	end
end