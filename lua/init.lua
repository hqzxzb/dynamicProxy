--初始化

-----------------配置-----------------Start

--Redis服务
redis_config = {
	--IP
	ip = "127.0.0.1",
	--Port
	port = 6379;
	--链接超时时间（毫秒）
	timeout = 15000;
};


-----URL二级目录动态代理-----

--动态代理数据内存缓存
--是否启用Nginx全局共享内存缓存代理数据（true/false）
if_cache_proxy_data = true;
--代理数据内存缓存失效时间（秒）--失效后重新从后台服务器获取
proxy_shared_cache_timeout = 10;
--Redis Key统一前缀
url_proxy_prefix = "dp-url-proxy-";

-----------------------------


-----------------配置-----------------End




-----------------初始化方法-----------------Start

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

-----------------初始化方法-----------------End