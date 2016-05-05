--Nginx日志写入
local log = ngx.log;

--获取全局共享内存
local shared_data = ngx.shared.shared_data;

--Request URI中除["/根目录"]外的部分（必须使用request_uri获取原始URL包括参数）
--无需使用，Nginx自动带上二级目录进行转发
local ext_uri = ngx.var.request_uri;
--log(ngx.INFO, "ext_uri : ", ext_uri);

--判断是否启用缓存
if if_cache_proxy_data then
	--通过共享内存获取代理地址
	local shared_data_proxy = shared_data:get(ngx.var.root_path);
	if ( shared_data_proxy ~= nil and shared_data_proxy ~= "" ) then 
		--拼接完整URL
		ngx.var.dynamic_proxy_path = shared_data_proxy;
		--log(ngx.INFO, "dynamic_proxy_path : ", ngx.var.dynamic_proxy_path);
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
	local resp, err = red:get(url_proxy_prefix .. ngx.var.root_path);
	if resp == ngx.null then
		log(ngx.ERR, "get [", url_proxy_prefix, ngx.var.root_path, "] error : ", err);
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
	--拼接完整URL
	proxy_url = proxy_url; 
	--判断是否启用全局缓存
	if if_cache_proxy_data then 
		--写入全局共享变量
		shared_data:set(ngx.var.root_path, proxy_url, proxy_shared_cache_timeout);
	end
end

--回写结果（直接使用set_by_lua_file设置变量不知道为什么redis连接会报错）
ngx.var.dynamic_proxy_path = proxy_url;

--log(ngx.INFO, "ext_uri : ", ext_uri, " -- dynamic_proxy_path : ", ngx.var.dynamic_proxy_path);