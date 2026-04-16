# 故障排查手册

在收集日志、路由匹配与调用链证据后，使用这份手册对可能原因进行排序。

## 通用排序规则

1. 优先考虑同时被日志与代码匹配支持的原因。
2. 当现象是请求被拒绝（`400`、`401`、`403`、`404`）时，优先考虑靠近 API 入口的原因。
3. 当现象是数据为空、数据不一致、持久化缺失或下游失败时，优先考虑更深层的服务（Service）或模型（Model）层原因。
4. 当路由识别存在歧义、日志缺失，或同一路径匹配到多个处理器（Handler）时，降低置信度。
5. 如果证据稀少，返回 Top 3 可能性，而不是过度下结论。

## 现象映射

### 400 参数错误

常见原因类别：
- 请求字段名不匹配
- 必填参数缺失
- DTO / 序列化器（Serializer）/ 模式（Schema）校验失败
- 类型转换失败
- 方法不匹配导致进入了意外的解析分支

检查重点：
- 请求解析器（Parser）与校验器（Validator）
- DTO、序列化器（Serializer）、Pydantic 模型、请求类
- 参数提取逻辑
- query string、body 与 form 来源不匹配

证据示例：
- 日志中的校验异常
- `request.args` 或 `request.json` 与文档请求不匹配
- `BaseModel` 或序列化器（Serializer）必填字段缺失

### 401 未认证

常见原因类别：
- token 或 cookie 解析缺失
- 鉴权中间件（Middleware）拒绝
- token 解码失败
- 认证请求头名称或前缀错误

检查重点：
- 中间件（Middleware）、guard、permission class、auth backend
- 请求头提取代码
- 设置（Settings）或安全配置读取

证据示例：
- `Unauthorized`、`invalid token`、`missing authorization`
- 路由周围存在 auth decorator 或 guard

### 403 权限问题

常见原因类别：
- permission class 或 guard 拒绝
- 角色不匹配
- 租户或归属过滤不匹配
- 功能开关或配置门控

检查重点：
- permission class
- guard / 中间件（Middleware）
- 资源归属检查
- 设置（Settings）或 ACL 来源

证据示例：
- 明确的 `forbidden` 日志
- `permission_classes` 或 guard 分支拒绝访问

### 404 路由问题

常见原因类别：
- 路径不匹配
- HTTP 方法不匹配
- router、Blueprint 或模块挂载导致的前缀不匹配
- 路由版本不匹配
- 未考虑嵌套路由组前缀

检查重点：
- 路由声明文件
- 全局前缀
- router 注册
- Blueprint、Nest 模块、Spring 类级别映射

证据示例：
- 存在相似路由，但前缀或方法不同
- 找到了路由声明，但挂载路径不同

### 500 异常

常见原因类别：
- 未处理的 null / none / nil 访问
- 序列化器（Serializer）或模式（Schema）崩溃
- 外部依赖错误
- 数据库查询异常
- 缺少配置或环境变量读取错误

检查重点：
- 堆栈跟踪帧
- 服务（Service）与仓储（Repository）调用
- 外部客户端封装
- 重新抛出异常或吞掉上下文的异常处理块

证据示例：
- stack trace 行
- `NullPointerException`、`AttributeError`、`TypeError`、`SQL` 异常、超时标记

### 参数缺失

常见原因类别：
- 请求来源不匹配（`query` vs `json` vs `form`）
- 框架依赖提取不匹配
- 序列化器（Serializer）/ DTO 字段别名不匹配
- 中间件（Middleware）错误消费了请求体

### 数据为空

常见原因类别：
- 查询过滤条件过严
- 租户 / 归属 / 状态过滤
- 软删除排除
- 分页窗口问题
- 数据源或环境配置错误

检查重点：
- ORM 过滤条件
- queryset、仓储（Repository）方法、SQLAlchemy 查询链
- 默认作用域与状态过滤器

### 数据不一致

常见原因类别：
- 响应整形不匹配
- 同一接口使用了多个序列化器（Serializer）或 DTO
- 环境配置或数据源不同
- 按角色 / 功能开关 / 租户切分的条件分支

### 未持久化 / 未插入

常见原因类别：
- 未进入保存分支
- 事务回滚
- 异步队列路径未执行
- 外部服务已接收请求，但本地持久化被跳过
- 缺少 ORM flush/commit 分支

检查重点：
- 写路径控制流
- 服务（Service）保存分支
- 仓储（Repository）插入方法
- 队列或事件分发边界

注意：
- 只做诊断；不要运行写操作来验证。

### 超时

常见原因类别：
- 外部 HTTP 依赖缓慢或不可用
- 数据库慢查询
- 日志中可见锁竞争现象
- 缺少超时覆盖或发生重试风暴

检查重点：
- 外部客户端封装
- 仓储（Repository）查询
- 异步等待点
- 超时配置读取

### 外部依赖异常

常见原因类别：
- 第三方 API 错误
- 消息队列不可用
- 缓存服务不可用
- DNS 或网络故障
- 下游响应契约变更

检查重点：
- 客户端适配器
- 集成服务类
- 错误处理与兜底逻辑

### 配置问题

常见原因类别：
- 环境变量缺失
- settings key 错误
- 路由前缀配置不匹配
- 按环境区分的 auth 或 DB 配置不匹配

检查重点：
- `settings.py`、`.env` 读取器、配置加载器、Spring properties 访问、Laravel config 调用
- 功能门控与环境分支

## 输出规则

对于每一个可能原因，始终提供：
- 具体代码位置
- 证据摘要
- 现象为何匹配的原因
- 只读验证建议
