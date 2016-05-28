----------------配置-----------------

--Redis服务
redis_config = {
	
	-- Redis Deploy Type
	-- Type List : Singleton, Sentinel 
	deployType = "Sentinel";
	
	-- Address String format : 
	-- If the deployType is 'Sentinel', the password is configured on the master redis server.
	-- host1:port1:password1;host2:port2:password2;host3:port3:password3
	addresses = "10.31.23.201:26379;10.31.23.201:26380";
	
	--链接超时时间（毫秒）
	timeout = 15000;
	
	--连接池最大空闲时间（毫秒）
	pool_max_idle_timeout = 30000;
	--连接池最大连接数（针对每个worker process）
	pool_size = 30;
	
	
	--当deployType配置为'Sentinel'时，需要在此处指定master名称用于通过Sentinel获取主节点
	--Redis Sentinel中的master名称
	masterName = "master1";
};

--动态代理数据内存缓存
--是否启用Nginx全局共享内存缓存代理数据（true/false）
if_cache_proxy_data = true;
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