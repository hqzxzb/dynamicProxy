--初始化处理

--获取日志输出
local log = ngx.log;

--加载Redis模块
local redis = require("resty.redis");

--设定Redis连接参数
local redis_ip = "127.0.0.1";
local redis_port = 6379;
--连接超时时间（毫秒）
local redis_timeout = 15000;

--设定Redis连接全局获取方法
function getRedisConnect()
	--创建redis连接实例
	local red = redis:new();
	--设置redis连接超时（毫秒）
	red:set_timeout(redis_timeout);
	--建立redis连接
	local ok, err = red:connect(redis_ip, redis_port);
	if not ok then
		--ngx.say("connect to redis error : ", err);
		log(ngx.ERR, "connect to redis error : ", err);
		close_redis(red);
		return nil;
	end
	--连接后返回
	return red;
end

--关闭redis连接全局方法
function close_redis(red)
	if not red then
		return ;
	end
	local ok, err = red:close();
	if not ok then
		--ngx.say("close redis error : ", err);
		log(ngx.ERR, "close redis error : ", err);
		return ;
	end
end