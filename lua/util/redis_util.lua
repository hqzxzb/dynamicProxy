--Redis公共操作类

--获取日志输出
local log = ngx.log;

--加载Redis模块
local redis = require("resty.redis");

--设定Redis连接全局获取方法
function getRedisConnect()
	--创建redis连接实例
	local red = redis:new();
	--设置redis连接超时（毫秒）
	red:set_timeout(redis_config.timeout);
	--建立redis连接
	local ok, err = red:connect(redis_config.ip, redis_config.port);
	if not ok then
		--ngx.say("connect to redis error : ", err);
		log(ngx.ERR, "connect to redis error : ", err);
		close_redis(red);
		return nil;
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