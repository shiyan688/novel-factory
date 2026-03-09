# NovelFactory 完整使用说明（v1）

本说明面向当前仓库已有交付：**共享 Schema + SQL 草案 + OpenAPI 契约 + Agent/状态机文档**。  
当前仓库不包含可直接启动的业务服务实现代码，你需要基于 OpenAPI/SQL 自行实现服务（或接入你现有框架）。

## 1. 目标与范围

本仓库支持两条可拼接流水线：

1. 项目 A（拆书建模与大纲数据库）
2. 项目 B（自动选题 -> 大纲 -> 细纲 -> 正文 -> 审校 -> 回写记忆）

统一版本：`schema_version = "v1"`。

## 2. 仓库结构

- `shared-schema/v1/`：A/B 共用 JSON Schema
- `sql/project_a_schema_v1.sql`：项目 A PostgreSQL DDL
- `sql/project_b_schema_v1.sql`：项目 B PostgreSQL DDL
- `api/project_a_openapi_v1.yaml`：项目 A API 契约
- `api/project_b_openapi_v1.yaml`：项目 B API 契约
- `prompts/project_a_agents.md`：项目 A Agent 规范
- `prompts/project_b_agents.md`：项目 B Agent 规范
- `docs/project_a_state_machine.md`：项目 A 状态机
- `docs/project_b_state_machine.md`：项目 B 状态机
- `docs/integration_contract_v1.md`：A/B 接缝契约

## 3. 环境准备

## 3.1 基础依赖

- PostgreSQL 15+
- PostgreSQL 扩展：`vector`（项目 A 模式向量检索）
- 任一后端框架（FastAPI / Node.js / Spring 等）用于实现 OpenAPI 契约
- 可选：`ajv-cli` 或 `python jsonschema` 用于 JSON Schema 校验

## 3.2 创建数据库

示例（PowerShell + `psql`）：

```powershell
psql -U postgres -c "CREATE DATABASE novelfactory_a;"
psql -U postgres -c "CREATE DATABASE novelfactory_b;"
```

## 3.3 初始化表结构

```powershell
psql -U postgres -d novelfactory_a -f sql/project_a_schema_v1.sql
psql -U postgres -d novelfactory_b -f sql/project_b_schema_v1.sql
```

## 3.4 接入你自己的大模型 API

本项目的建议做法是增加一层 **LLM Gateway（统一模型适配层）**，A/B 所有 Agent 都只调用网关，不直接依赖某一家模型厂商。

## 3.4.1 建议环境变量

```bash
LLM_PROVIDER=custom
LLM_BASE_URL=https://your-llm.example.com
LLM_API_KEY=your_api_key
LLM_MODEL_PLANNER=xxx-planner-model
LLM_MODEL_WRITER=xxx-writer-model
LLM_MODEL_AUDITOR=xxx-auditor-model
LLM_TIMEOUT_MS=60000
LLM_MAX_RETRY=2
```

## 3.4.2 统一调用接口（项目内）

建议在服务内部统一成一个函数签名（伪代码）：

```text
invoke_llm(task, system_prompt, user_prompt, response_format, temperature, max_tokens) -> json|string
```

- `task`：`planner|writer|auditor|extractor|editor`
- `response_format`：优先 `json_schema`，确保可直接落库
- `temperature`：
  - 抽取/审校：`0~0.3`
  - 构思/写作：`0.6~0.9`

## 3.4.3 OpenAI 兼容 API 的最小请求示例

如果你的模型服务兼容 OpenAI Chat Completions，可直接这样调用：

```bash
curl -X POST "$LLM_BASE_URL/v1/chat/completions" \
  -H "Authorization: Bearer $LLM_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "xxx-planner-model",
    "messages": [
      {"role":"system","content":"你是小说结构规划器，只输出JSON"},
      {"role":"user","content":"根据输入生成ChapterOutline"}
    ],
    "temperature": 0.2
  }'
```

## 3.4.4 非 OpenAI 兼容 API 的接入方式

如果你的 API 格式不同，在网关里做一次映射：

1. 把项目内部统一请求映射到供应商请求体。  
2. 把供应商响应映射回统一结构（`text` 或 `json`）。  
3. 统一处理超时、重试、限流和错误码。

## 3.4.5 JSON 输出强约束（强烈建议）

为了让 `StoryBible`、`OutlinePack`、`ReviewReport` 可直接入库：

1. 在 system prompt 明确“只输出 JSON，不要 markdown”。  
2. 在代码侧加 JSON Schema 校验（不通过则自动重试）。  
3. 重试时附带上次错误原因（例如缺字段、枚举不合法）。

## 3.4.6 推荐的模型分工

- Planner（选题/大纲）：`LLM_MODEL_PLANNER`
- Writer（正文）：`LLM_MODEL_WRITER`
- Auditor（连续性审校）：`LLM_MODEL_AUDITOR`
- Editor（润色，可复用 writer 或单独模型）

## 3.4.7 在本项目中的落点

- 项目 A：`prompts/project_a_agents.md` 中的 A1~A9 均通过网关调用模型。  
- 项目 B：`prompts/project_b_agents.md` 中的 B1~B12 均通过网关调用模型。  
- 结果在入库前统一过 `shared-schema/v1` 校验。

## 4. 统一数据契约（必须遵守）

所有对象都必须包含：

- `metadata.schema_version = "v1"`
- `metadata.producer`（`project-a|project-b|shared`）
- `metadata.created_at`（ISO8601）
- `metadata.updated_at`（ISO8601）

ID 前缀必须匹配 `shared-schema/v1/common.schema.json`，例如：

- `book_` / `proj_` / `arc_` / `ch_` / `sc_` / `pat_` / `draft_` / `review_` / `memevt_`

## 5. 项目 A 使用流程（拆书建模）

项目 A API（默认契约）：

- `POST /v1/source-books/import`
- `GET /v1/source-books/{book_id}`
- `POST /v1/extraction-jobs`
- `GET /v1/extraction-jobs/{job_id}`
- `GET /v1/books/{book_id}/model-pack`
- `POST /v1/patterns/search`
- `GET /v1/genres/{genre}/pattern-pack`

以下示例假设项目 A 服务地址：`http://localhost:8080`。

## 5.1 导入小说

```powershell
$body = @{
  title = "示例作品"
  genre_hint = @("修仙","副本")
  source_type = "txt"
  content_ref = "object://books/demo.txt"
} | ConvertTo-Json

Invoke-RestMethod -Method Post `
  -Uri "http://localhost:8080/v1/source-books/import" `
  -ContentType "application/json" `
  -Body $body
```

预期：返回 `job_id`、`book_id`、`status=queued`。

## 5.2 启动拆书任务

```powershell
$body = @{
  book_id = "book_001"
  modes = @("chapter","scene","character","world","style","pattern","foreshadow")
} | ConvertTo-Json

Invoke-RestMethod -Method Post `
  -Uri "http://localhost:8080/v1/extraction-jobs" `
  -ContentType "application/json" `
  -Body $body
```

## 5.3 轮询任务状态

```powershell
Invoke-RestMethod -Method Get `
  -Uri "http://localhost:8080/v1/extraction-jobs/job_001"
```

状态应从 `queued -> running -> success`。

## 5.4 导出结构化资产

```powershell
Invoke-RestMethod -Method Get `
  -Uri "http://localhost:8080/v1/books/book_001/model-pack"
```

你将得到 `BookModelPack`，这是项目 B 的核心输入之一。

## 5.5 检索叙事模式

```powershell
$body = @{
  genre = @("修仙")
  pattern_type = "opening_hook"
  constraints = @{
    pressure_level = "high"
    protagonist_state = "hidden_advantage"
  }
  top_k = 10
} | ConvertTo-Json -Depth 8

Invoke-RestMethod -Method Post `
  -Uri "http://localhost:8080/v1/patterns/search" `
  -ContentType "application/json" `
  -Body $body
```

## 5.6 获取题材模式包

```powershell
Invoke-RestMethod -Method Get `
  -Uri "http://localhost:8080/v1/genres/xianxia/pattern-pack"
```

## 6. 项目 B 使用流程（自动生产）

项目 B API（默认契约）：

- `POST /v1/projects`
- `GET /v1/projects/{project_id}`
- `POST /v1/topic-ideas/generate`
- `POST /v1/topic-ideas/{idea_id}/select`
- `POST /v1/story-bibles/generate`
- `GET /v1/story-bibles/{project_id}/latest`
- `POST /v1/outlines/master/generate`
- `POST /v1/outlines/volume/generate`
- `POST /v1/outlines/chapter/generate`
- `POST /v1/outlines/scene/generate`
- `GET /v1/outlines/{project_id}/latest`
- `POST /v1/drafts/generate`
- `GET /v1/drafts/{draft_id}`
- `POST /v1/reviews/run`
- `POST /v1/memory/writeback`
- `GET /v1/memory/snapshots/{project_id}/latest`
- `POST /v1/pipeline/runs/start`
- `GET /v1/pipeline/runs/{run_id}`

以下示例假设项目 B 服务地址：`http://localhost:8090`。

## 6.1 创建项目

```powershell
$body = @{
  project_id = "proj_001"
  title_working = "暂定书名"
  genre = @("修仙","副本")
  target_platform = "男频平台"
  audience = @("升级流","智斗向")
  target_length_words = 200000
  volume_count = 6
} | ConvertTo-Json

Invoke-RestMethod -Method Post `
  -Uri "http://localhost:8090/v1/projects" `
  -ContentType "application/json" `
  -Body $body
```

## 6.2 生成选题池

```powershell
$body = @{
  project_id = "proj_001"
  genre = @("修仙","副本")
  target_platform = "男频平台"
  audience = @("升级流","智斗向")
  constraints = @{
    forbidden_elements = @("纯后宫","纯恋爱")
    must_have = @("高压规则","信息差")
  }
  pattern_pack_refs = @("gpp_xianxia_001")
  top_k = 10
} | ConvertTo-Json -Depth 8

Invoke-RestMethod -Method Post `
  -Uri "http://localhost:8090/v1/topic-ideas/generate" `
  -ContentType "application/json" `
  -Body $body
```

## 6.3 选择选题

```powershell
Invoke-RestMethod -Method Post `
  -Uri "http://localhost:8090/v1/topic-ideas/idea_001/select"
```

## 6.4 生成 StoryBible

```powershell
$body = @{
  project_id = "proj_001"
  idea_id = "idea_001"
  pattern_refs = @("pat_101","pat_202")
  style_profile_ref = "style_xianxia_cold_01"
} | ConvertTo-Json

Invoke-RestMethod -Method Post `
  -Uri "http://localhost:8090/v1/story-bibles/generate" `
  -ContentType "application/json" `
  -Body $body
```

## 6.5 逐级生成大纲

总纲：

```powershell
$body = @{
  project_id = "proj_001"
  story_bible_id = "sb_001"
  target_length_words = 200000
  volume_count = 6
} | ConvertTo-Json

Invoke-RestMethod -Method Post `
  -Uri "http://localhost:8090/v1/outlines/master/generate" `
  -ContentType "application/json" `
  -Body $body
```

卷纲：

```powershell
$body = @{
  project_id = "proj_001"
  outline_id = "out_001"
} | ConvertTo-Json

Invoke-RestMethod -Method Post `
  -Uri "http://localhost:8090/v1/outlines/volume/generate" `
  -ContentType "application/json" `
  -Body $body
```

章纲：

```powershell
$body = @{
  project_id = "proj_001"
  volume_id = "arc_001"
  chapter_count = 20
} | ConvertTo-Json

Invoke-RestMethod -Method Post `
  -Uri "http://localhost:8090/v1/outlines/chapter/generate" `
  -ContentType "application/json" `
  -Body $body
```

场景纲：

```powershell
$body = @{
  project_id = "proj_001"
  chapter_id = "ch_021"
} | ConvertTo-Json

Invoke-RestMethod -Method Post `
  -Uri "http://localhost:8090/v1/outlines/scene/generate" `
  -ContentType "application/json" `
  -Body $body
```

## 6.6 生成正文草稿

```powershell
$body = @{
  project_id = "proj_001"
  chapter_id = "ch_021"
  scene_id = "sc_021_03"
  story_bible_id = "sb_001"
  outline_id = "out_001"
  memory_snapshot_id = "memsnap_021"
  style_profile_ref = "style_xianxia_cold_01"
} | ConvertTo-Json

Invoke-RestMethod -Method Post `
  -Uri "http://localhost:8090/v1/drafts/generate" `
  -ContentType "application/json" `
  -Body $body
```

## 6.7 审校

```powershell
$body = @{
  project_id = "proj_001"
  draft_id = "draft_021"
  checks = @("continuity","character_consistency","pace","hook","style_match")
} | ConvertTo-Json

Invoke-RestMethod -Method Post `
  -Uri "http://localhost:8090/v1/reviews/run" `
  -ContentType "application/json" `
  -Body $body
```

若 `decision` 为：

- `pass`：可进入回写
- `revise`：先修订再复审
- `required_rewrite`：必须重写该场景

## 6.8 记忆回写

```powershell
$body = @{
  project_id = "proj_001"
  draft_id = "draft_021"
  review_id = "review_021"
} | ConvertTo-Json

Invoke-RestMethod -Method Post `
  -Uri "http://localhost:8090/v1/memory/writeback" `
  -ContentType "application/json" `
  -Body $body
```

输出 `WritebackEvent`，并把新增事实写入 `MemoryLedger`。

## 7. A -> B 端到端最小闭环

1. 在项目 A 导入 10~20 本同题材小说并完成拆书。
2. 从 A 导出 `GenrePatternPack`、`StyleProfile`、`BookModelPack`。
3. 在项目 B 创建项目并生成 `TopicIdea`。
4. 选题后生成 `StoryBible` 与 `OutlinePack`。
5. 按场景循环执行：`Draft -> Review -> Writeback`。
6. 使用最新 `MemorySnapshot` 进入下一场景。

## 8. 自动状态机运行（可选）

项目 B 可直接由编排器驱动：

```powershell
$body = @{
  project_id = "proj_001"
  from_state = "initialized"
} | ConvertTo-Json

Invoke-RestMethod -Method Post `
  -Uri "http://localhost:8090/v1/pipeline/runs/start" `
  -ContentType "application/json" `
  -Body $body
```

轮询：

```powershell
Invoke-RestMethod -Method Get `
  -Uri "http://localhost:8090/v1/pipeline/runs/run_001"
```

## 9. JSON Schema 校验建议

推荐在 CI 增加校验（示例 `ajv-cli`）：

```bash
ajv validate -s shared-schema/v1/book-model-pack.schema.json -d sample/book-model-pack.json
ajv validate -s shared-schema/v1/story-bible.schema.json -d sample/story-bible.json
ajv validate -s shared-schema/v1/outline-pack.schema.json -d sample/outline-pack.json
```

上线前至少校验：

- `BookModelPack`
- `StoryBible`
- `OutlinePack`
- `DraftBundle`
- `ReviewReport`
- `WritebackEvent`

## 10. 常见问题与处理

## 10.1 `400 Bad Request`

常见原因：

- ID 前缀不符合规范（如 `book001`）
- `schema_version` 不是 `v1`
- 使用了未定义枚举值（如 `issue_type` 拼写错误）

处理：

- 对照 `shared-schema/v1/common.schema.json` 修正字段。

## 10.2 审校总是不过

常见原因：

- 场景写作输入未注入最新记忆快照
- StoryBible 硬规则与场景行为冲突

处理：

- 强制在 `drafts/generate` 前拉取最新 `memory_snapshot`。

## 10.3 回写失败

常见原因：

- `review.decision != pass`
- `WritebackEvent` 缺少必填字段

处理：

- 先修稿复审通过，再回写。

## 11. 版本与变更管理

- `v1` 已锁定，禁止破坏性改动。
- 破坏性变更必须升级到 `v2`（新 schema + 新 API）。
- `v1` 内仅允许向后兼容的新增字段，并提供默认值。

## 12. 实施顺序建议

1. 先落地项目 A（至少可导出模式包）。
2. 再落地项目 B 的前半段（选题 + StoryBible + 大纲）。
3. 最后接入正文、审校、回写闭环。

完成以上三步后，即可形成可持续迭代的小说工厂流水线。
