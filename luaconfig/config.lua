----------------配置-----------------

--Redis服务
redis_config = {
	--IP
	ip = "127.0.0.1",
	--Port
	port = "6379";
	--链接超时时间（毫秒）
	timeout = 15000;
	
	--连接池最大空闲时间（毫秒）
	pool_max_idle_timeout = 30000;
	--连接池最大连接数（针对每个worker process）
	pool_size = 30;
	
	
	--是否使用了Redis Sentinel
	--当此处配置为true时，ip和port参数所指向的地址为Redis Sentinel地址
	isSentinel = false;
	--Redis Sentinel中的master名称
	masterName = "master1";
	
	--是否需要密码认证
	isAuth = false;
	password = "redis";
};

--动态代理数据内存缓存
--是否启用Nginx全局共享内存缓存代理数据（true/false）
if_cache_proxy_data = false;
--代理数据内存缓存失效时间（秒）--失效后重新从后台服务器获取
proxy_shared_cache_timeout = 10;

-----URL二级目录动态代理-----

--Redis Key统一前缀
url_proxy_prefix = "dp-url-proxy-";

-----------------------------

-----Cookie用户标签动态代理-----

--Redis Key统一前缀
user_proxy_prefix = "dp-user-proxy-";

--------------------------------