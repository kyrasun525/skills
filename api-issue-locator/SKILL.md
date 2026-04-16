---
name: 通过接口定位问题
description: 面向后端项目的只读 API 故障排查与问题定位技能。当 Codex 需要根据 API 路径、方法、名称或现象描述调查接口问题，并在不修改代码、配置、数据或系统状态的前提下，快速定位可能原因、代码位置、入口点、日志与调用链路时使用。
---

# 通过接口定位问题

以只读模式调查 API 问题。读取日志、搜索路由（Route）、定位入口点、追踪调用链路，并产出基于证据的假设。不要修复任何内容，不要更改项目文件，也不要运行会改变环境的命令。

## 必需操作模式

- 严格保持只读。
- 只进行读取、搜索与分析。
- 绝不修改项目代码、配置、数据库状态、缓存、日志或生成产物。
- 绝不输出补丁方案或修复代码。
- 如果命令可能改变系统状态，则不要运行。
- 调查前先加载 [references/readonly-investigation-rules.md](references/readonly-investigation-rules.md)。
- 最终响应结构使用 [references/output-format.md](references/output-format.md)。
- 当需要根据现象匹配可能原因时，使用 [references/troubleshooting-playbook.md](references/troubleshooting-playbook.md)。

## 输入

分析前收集以下输入：

1. API 路径、方法，或接口名称。
2. 问题描述、现象、状态码，或观察到的异常。
3. 可选上下文，例如请求参数、环境、时间戳、trace id、user id，或示例报错文本。

如果缺少某一个标识，仍要基于已有信息继续。如果无法唯一识别 API，则返回 Top 3 入口候选与 Top 3 最可能原因。

## 调查工作流

### 第一步：读取日志

优先运行 `scripts/read_logs.sh`。

目的：
- 扫描常见后端日志目录与 `*.log` 文件。
- 提取 `error`、`exception`、`timeout`、`null` 等问题标记附近的证据。
- 捕获可能与现象匹配的文件路径与片段。

用法：

```bash
bash scripts/read_logs.sh "<optional-keyword>"
```

### 第二步：搜索 API

使用路径、方法、名称或其它路由线索运行 `scripts/locate_issue.sh`。

目的：
- 搜索路由（Route）定义、控制器（Controller）/视图（View）处理器，以及框架注解。
- 支持 Java、PHP、Node.js 与 Python 框架。
- 返回候选文件与匹配到的路由声明。

用法：

```bash
bash scripts/locate_issue.sh "<api clue>" "<optional method>"
```

### 第三步：定位入口点

识别最可能的路由（Route）与请求入口。

重点查看：
- 路由声明文件。
- 控制器（Controller）、视图（View）、处理器（Handler）或端点函数。
- 中间件（Middleware）、权限、鉴权，或校验层。
- 请求解析与参数映射。

框架提示：

- Java Spring Boot / Spring MVC：
  - 路由注解：`@RequestMapping`、`@GetMapping`、`@PostMapping`、`@PutMapping`、`@DeleteMapping`、`@PatchMapping`
  - 入口文件：`Controller`、`RestController`
  - 重点关注请求 DTO、拦截器、校验、服务调用、仓储（Repository）使用

- PHP Laravel / ThinkPHP / 原生：
  - 路由文件：`routes/*.php`、`route/*.php`
  - 入口文件：控制器（Controller）、中间件（Middleware）、服务（Service）、模型（Model）
  - 重点关注请求校验、中间件（Middleware）、ORM 查询、配置读取

- Node.js NestJS / Express：
  - 路由标记：装饰器、router 方法、`app.use`、`router.get/post/put/delete`
  - 入口文件：控制器（Controller）、模块、 中间件（Middleware）、服务提供者
  - 重点关注 pipe、guard、interceptor、DTO、异步依赖失败

- Python Django：
  - 路由文件：`urls.py`
  - 路由模式：`path(`、`re_path(`、router 注册
  - 入口文件：`views.py`、`APIView`、`ViewSet`、通用视图
  - 重点关注 `serializer`、`permission_classes`、`queryset`、`settings.py`、鉴权、过滤与请求解析

- Python Flask：
  - 路由标记：`@app.route`、`Blueprint`、`blueprint.route`
  - 请求访问：`request.args`、`request.json`、`request.form`
  - 重点关注 Blueprint 前缀、SQLAlchemy 查询、中间件（Middleware）、before/after request hooks

- Python FastAPI：
  - 路由标记：`APIRouter`、`@router.get`、`@router.post`、`@app.get`、`@app.post`
  - 依赖标记：`Depends`
  - 数据模型：`BaseModel`、Pydantic schema
  - 重点关注参数映射、依赖注入、DB session 生命周期、响应模型整形

- Python 原生路由：
  - 搜索手写 WSGI/ASGI 分发器、正则路由、路径映射、请求方法分支、轻量框架封装
  - 重点关注处理器注册、请求解析、配置加载、直接 DB 调用，以及异常吞掉逻辑

Python 必需搜索关键词：
- `urls.py`
- `path(`
- `APIView`
- `ViewSet`
- `@app.route`
- `Blueprint`
- `APIRouter`
- `Depends`
- `request.args`
- `request.json`
- `BaseModel`
- `settings.py`

### 第四步：追踪调用链路

使用已发现的路由（Route）、处理器（Handler）、类或函数名运行 `scripts/trace_callchain.sh`。

目的：
- 追踪从路由到控制器（Controller）/视图（View）再到服务（Service）以及模型（Model）或仓储（Repository）的可能链路。
- 暴露跨文件跳转的候选路径。
- 高亮附近的调用点与框架胶水代码。

用法：

```bash
bash scripts/trace_callchain.sh "<symbol or file clue>"
```

### 第五步：构建基于证据的假设

将日志、路由匹配、调用链候选与用户报告的现象结合起来。

必需行为：
- 产出 Top 1 到 Top 3 最可能原因。
- 每个原因都必须绑定一个或多个具体代码位置。
- 说明每个原因为何与证据匹配。
- 只提供验证建议。
- 不要建议代码修改。

### 第六步：输出诊断结果

使用 [references/output-format.md](references/output-format.md) 中的结构。

最少必需章节：
- 接口信息
- 日志证据
- 入口定位候选
- 调用链候选
- Top 1 到 Top 3 最可能原因
- 问题代码位置
- 推理与证据
- 验证步骤
- 结论

### 第七步：提供验证建议

验证在可能情况下必须保持只读。

示例：
- 重新核对精确的路由声明与 HTTP 方法。
- 对比请求字段名与解析器（Parser）或序列化器（Serializer）的预期是否一致。
- 重新阅读事件时间戳附近的相关日志。
- 检查权限或鉴权分支。
- 确认查询过滤条件、租户范围，或软删除条件。
- 检查依赖注入 wiring 与外部客户端初始化。
- 在不修改配置的前提下检查环境相关配置读取。

## 支持的问题类型

至少覆盖以下问题类别：

- `400` 参数错误
- `401` 未认证
- `403` 无权限
- `404` 路由未找到
- `500` 未处理异常
- 参数缺失
- 数据为空
- 数据不一致
- 未持久化 / 未插入
- 超时
- 外部依赖失败
- 配置问题

## 框架搜索指南

### Java

搜索路由（Route）与处理器（Handler）标记：
- `@RequestMapping`
- `@GetMapping`
- `@PostMapping`
- `@PutMapping`
- `@DeleteMapping`
- `@PatchMapping`
- `@RestController`
- `@Controller`

搜索下游层：
- `Service`
- `Repository`
- `Mapper`
- `Feign`
- `RestTemplate`
- `WebClient`

### PHP

搜索路由（Route）与处理器（Handler）标记：
- `Route::get`
- `Route::post`
- `Route::put`
- `Route::delete`
- `Route::any`
- `Route::group`
- `->middleware`
- `Route::rule`
- `Route::resource`

搜索下游层：
- `Controller`
- `Service`
- `Model`
- `Repository`
- `validate`
- `request()->`

### Node.js

搜索路由（Route）与处理器（Handler）标记：
- `@Controller`
- `@Get`
- `@Post`
- `@Put`
- `@Delete`
- `router.get`
- `router.post`
- `app.get`
- `app.post`

搜索下游层：
- `@Injectable`
- `service`
- `repository`
- `guard`
- `pipe`
- `interceptor`

### Python

搜索路由（Route）与处理器（Handler）标记：
- `urls.py`
- `path(`
- `re_path(`
- `router.register`
- `APIView`
- `ViewSet`
- `@app.route`
- `Blueprint`
- `APIRouter`
- `Depends`
- `@router.get`
- `@router.post`
- `@app.get`
- `@app.post`

搜索请求与校验标记：
- `request.args`
- `request.json`
- `request.form`
- `BaseModel`
- `serializer`
- `permission_classes`
- `queryset`
- `settings.py`

搜索下游层：
- `SessionLocal`
- `db.session`
- `objects.filter`
- `objects.get`
- `select_related`
- `prefetch_related`
- `SQLAlchemy`

## 命令策略

允许的命令家族：
- `rg`
- `grep`
- `find`
- `ls`
- `cat`
- `sed -n`
- `awk`
- `head`
- `tail`
- `sort`
- `uniq`
- 仅用于只读管道的 `xargs`

禁止的操作：
- 任何文件写入或原地编辑
- `rm`、`mv`、`cp`
- `sed -i`
- 对项目文件执行 `chmod`
- 数据库写入
- `migrate`
- 清缓存、重启队列、重启服务、部署，或任何会改变状态的命令

## 资源加载指南

只读取必要内容：
- 在调查开始时加载 [references/readonly-investigation-rules.md](references/readonly-investigation-rules.md)。
- 需要进行现象分类或原因排序时加载 [references/troubleshooting-playbook.md](references/troubleshooting-playbook.md)。
- 在输出最终诊断前加载 [references/output-format.md](references/output-format.md)。
- 执行 `scripts/` 中的脚本，而不是重复改写同样的 shell 逻辑。

## 脚本入口点

- `scripts/read_logs.sh`：从日志中提取问题证据
- `scripts/locate_issue.sh`：搜索路由定义与入口候选
- `scripts/trace_callchain.sh`：追踪从路由到服务再到模型的可能跳转
- `scripts/inspect_api.sh`：在同一条只读流程中执行日志、搜索与调用链分析

## 最终护栏

发送答案前，确认以下内容全部满足：
- 每个原因都有代码位置。
- 每个原因都包含明确推理。
- 验证建议保持只读。
- 没有提出修复补丁、迁移、配置修改或写操作。
- 如果证据不足，要明确说明，并给出 Top 3 候选，而不是假装确定。
