--Redis公共操作类

--获取日志输出
local log = ngx.log;

--加载Redis模块
local redis = require("resty.redis");

--连接Redis服务器使用的IP和Port
local redis_ip = redis_config.ip;
local redis_port = redis_config.port;

--加载新的Redis命令
--加载sentinel命令，用于连接Redis Sentinel
redis.add_commands("sentinel");

--从Redis Sentinel中获取master地址
local function getMasterFromSentinel()
	--创建redis连接实例
	local red = redis:new();
	--设置redis连接超时（毫秒）
	red:set_timeout(redis_config.timeout);
	
	--连接Redis Sentinel
	local ok, err = red:connect(redis_config.ip, redis_config.port);
	if not ok then
		log(ngx.ERR, "connect to redis sentinel error : ", err);
		close_redis(red);
		return nil;
	end
	
	--获取当前master服务器IP和Port
	local res, err = red:sentinel("get-master-addr-by-name",redis_config.masterName);
	if not res then
	    log(ngx.ERR, "failed to do sentinel command: ", err);
	    close_redis(red);
	    return nil;
	end
	
	--log(ngx.INFO, "Redis Server : ", res[1], ":", res[2]);
	
	--重设Redis服务器IP和Port
	redis_ip = res[1];
	redis_port = res[2];
	close_redis(red);
end

--设定Redis连接全局获取方法
function getRedisConnect()
	--创建redis连接实例
	local red = redis:new();
	--设置redis连接超时（毫秒）
	red:set_timeout(redis_config.timeout);
	
	--当配置为Redis Sentinel时
	if redis_config.isSentinel then
		--重设连接Redis的地址
		getMasterFromSentinel();
		--log(ngx.INFO, "Redis Server from Sentinel : ", redis_ip, ":", redis_port);
	end
	
	--建立redis连接
	local ok, err = red:connect(redis_ip, redis_port);
	if not ok then
		--ngx.say("connect to redis error : ", err);
		log(ngx.ERR, "connect to redis error : ", err);
		close_redis(red);
		return nil;
	end
	
	--当配置为需要密码时，进行密码认证
	if redis_config.isAuth then
		local res, err = red:auth(redis_config.password);
	    if not res then
	        log(ngx.ERR, "failed to authenticate: ", err);
	        return nil;
	    end
	end
	
	--连接后返回
	return red;
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