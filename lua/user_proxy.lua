--Nginx日志写入
local log = ngx.log;

--获取全局共享内存
local shared_data = ngx.shared.shared_data;

--获取用户标签ID
local tag_id = ngx.var.tag_id;

--代理目标URL
local proxy_url = ngx.null;

if tag_id ~= nil and tag_id ~= "" then
	--当用户标签ID不为空时
	
	--判断是否启用缓存
	if if_cache_proxy_data then
		--通过共享内存获取代理地址
		local shared_data_proxy = shared_data:get(tag_id);
		if ( shared_data_proxy ~= nil and shared_data_proxy ~= "" ) then 
			ngx.var.dynamic_proxy_path = shared_data_proxy;
			return ;
		end
	end
	
	--创建redis实例
	local red = getRedisConnect();
	if not red then
		log(ngx.ERR, "Get Redis connect failure, Please check the Redis Service !");
	else
		--调用API获取数据
		local resp, err = red:get(user_proxy_prefix .. ngx.var.tag_id);
		if resp == ngx.null then
			log(ngx.ERR, "get [", user_proxy_prefix, ngx.var.tag_id, "] error : ", err);
		else 
			proxy_url = resp;
		end
		--关闭Redis连接
		close_redis(red);
	end
else
	log(ngx.ERR, "The [Tag-ID] is not found in Cookies !");
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