--是否启用全局缓存
local ifCache = false;

--获取全局共享内存
local shared_data = ngx.shared.shared_data;

--判断是否启用缓存
if ifCache then
		--通过共享内存获取代理地址
		local shared_data_proxy = shared_data:get(ngx.var.root_path);
		if ( shared_data_proxy ~= nil and shared_data_proxy ~= "" ) then 
				ngx.var.dynamic_proxy_path = shared_data_proxy;
				return ;
		end
end

--加载redis模块
local redis = require("resty.redis");

--Redis服务器 IP
local ip = "127.0.0.1";
--Redis服务器 端口号
local port = 6379;

--关闭redis连接
local function close_redis(red)
    if not red then
        return ;
    end
    local ok, err = red:close();
    if not ok then
        ngx.say("close redis error : ", err);
    end
end

--创建redis实例
local red = redis:new();
--设置redis连接超时（毫秒）
red:set_timeout(15000);
--建立redis连接
local ok, err = red:connect(ip, port);
if not ok then
    ngx.say("connect to redis error : ", err);
    close_redis(red);
end

--调用API获取数据
local resp, err = red:get(ngx.var.root_path);
if not resp then
    ngx.say("get [", ngx.var.root_path, "] error : ", err);
    close_redis(red);
end

--得到的数据为空处理
if resp == ngx.null then
		--设定默认值
    resp = "http://127.0.0.1:" .. ngx.var.server_port .. "/errorproxy"; 
else 
		--判断是否启用全局缓存
		if ifCache then 
				--写入全局共享变量
				shared_data:set(ngx.var.root_path, resp);
		end
end
close_redis(red);

--回写结果（直接使用set_by_lua_file设置变量不知道为什么redis连接会报错）
ngx.var.dynamic_proxy_path = resp;