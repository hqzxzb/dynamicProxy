--Nginx日志写入
local log = ngx.log;

--获取全局共享内存
local shared_data = ngx.shared.shared_data;

--根据Group-Key-Type类型，执行不同的处理流程
if ngx.var.proxy_key_type == "GroupID" then
	--当Key使用的是分组ID时，读取分组ID对应的代理地址
	
	--判断是否启用缓存
	if if_cache_proxy_data then
		--通过共享内存获取代理地址
		local shared_data_proxy = shared_data:get(ngx.var.proxy_key);
		if ( shared_data_proxy ~= nil and shared_data_proxy ~= "" ) then 
			ngx.var.dynamic_proxy_path = shared_data_proxy;
			return ;
		end
	end
	
	--代理目标URL
	local proxy_url = ngx.null;
	
	--创建redis实例
	local red = getRedisConnect();
	if not red then
		log(ngx.ERR, "Get Redis connect failure, Please check the Redis Service !");
	else
		--调用API获取数据
		local resp, err = red:get(user_group_proxy_prefix .. ngx.var.proxy_key);
		if resp == ngx.null then
			log(ngx.ERR, "get [", user_group_proxy_prefix, ngx.var.proxy_key, "] error : ", err);
		else 
			proxy_url = resp;
		end
		--关闭Redis连接
		close_redis(red);
	end
	
	--得到的数据为空处理
	if proxy_url == ngx.null then
		--设定默认值
		proxy_url = "http://127.0.0.1:" .. ngx.var.server_port .. "/errorproxy"; 
	else 
		--判断是否启用全局缓存
		if if_cache_proxy_data then 
			--写入全局共享变量
			shared_data:set(ngx.var.proxy_key, proxy_url, proxy_shared_cache_timeout);
		end
	end
	
	--回写结果（直接使用set_by_lua_file设置变量不知道为什么redis连接会报错）
	ngx.var.dynamic_proxy_path = proxy_url;
	return ;
	
elseif ngx.var.proxy_key_type == "UserID" then
	--当Key使用的是用户ID时，查询用户ID所属分组，然后根据分组进行代理
	
else
	log(ngx.ERR, "The [Group-Key-Type] is not found in Cookies !");
end