# 计划：fastqdl 集成 + kingfisher 预存问题修复 + lint 修复 + 提交（v1.14.0）

## 概述 (Summary)

本计划是 fastqdl 模块集成到 fetchngs.nf 流程的**收尾阶段**，包含 4 个目标：

1. **验证 fastqdl 集成**：完成用户明确要求的"工作流跑通"验证（模块 stub 测试、工作流 stub 测试、schema lint、端到端 stub 烟测、端到端真实下载测试）
2. **修复 kingfisher 同类预存问题**：清理误创建的 `modules/nf-core/kingfisher/~/` 冗余目录；验证 kingfisher 测试在修复后的 config 下能跑通
3. **修复 nextflow lint 错误和警告**：参考 circdna.nf 的修复模式，修复 `nextflow.config` 和 `conf/base.config` 中的 lint 问题，更新为最新语法
4. **提交 branch commit**：将所有改动提交到 `fastqdl` 分支，做好记录

前序实施已完成：分支创建、模块文件复制、工作流集成、schema 扩展、版本提升至 v1.14.0、CHANGELOG/README/usage 文档更新、以及 3 个 Nextflow 26.04.4 兼容性修复（`check_max` 闭包化、移除 try-catch、移除 `def trace_timestamp`）。

**重要发现**：前序修复中"移除 `def trace_timestamp`"的方式不正确——`trace_timestamp` 作为顶层变量在 config 块间无法共享，导致 `nextflow config -flat .` 报错 `trace_timestamp is not defined`，阻塞 nf-core lint 运行。本计划将参考 circdna.nf 模式正确修复。

## 当前状态分析 (Current State Analysis)

### 已完成（无需重复执行）

| 项目 | 状态 | 证据 |
|------|------|------|
| 分支 `fastqdl` 已切换 | ✅ | `git branch --show-current` → `fastqdl` |
| fastqdl 模块文件复制（8 个文件） | ✅ | `modules/nf-core/fastqdl/{download/*, sra_ids_test.csv}` 全部就位 |
| fastqdl 模块级 `nextflow.config` | ✅ | `withName: FASTQDL_DOWNLOAD { ext.args=''; publishDir=... }` |
| `workflows/sra/nextflow.config` 引入 fastqdl 配置 | ✅ | 第 8 行 `includeConfig "../../modules/nf-core/fastqdl/download/nextflow.config"` |
| `workflows/sra/main.nf` 4 处集成 | ✅ | import、branch 判断、branch 返回、模块调用 + mix 均已写入 |
| `nextflow_schema.json` enum 扩展 | ✅ | enum 已加 `"fastqdl"` |
| `nextflow.config` 版本提升 | ✅ | `version = '1.14.0'` |
| `CHANGELOG.md` v1.14.0 段落 | ✅ | 含 fastqdl Modules 与 Enhancements 条目 |
| `README.md` / `docs/usage.md` | ✅ | fastq-dl 选项已加 |
| fastqdl 工作流 stub 测试文件 | ✅ | `workflows/sra/tests/sra_download_method_fastqdl.nf.test` 已创建 |

### 已应用但需修正的修复

| 项目 | 当前状态 | 问题 | 修正方案 |
|------|----------|------|----------|
| `trace_timestamp` 修复 | 移除 `def`，作为顶层变量 | `nextflow config` 报错 `trace_timestamp is not defined`，阻塞 nf-core lint | 参考 circdna.nf：改为 `params.trace_report_suffix` |
| `check_max` 修复 | 转为闭包 `check_max = { ... }` | circdna.nf 已完全移除 check_max | 删除闭包，base.config 改为直接表达式 |
| `includeConfig` try-catch 修复 | 移除 try-catch | 可用但缺乏离线模式处理 | 参考 circdna.nf：添加 NXF_OFFLINE 条件判断 |

### kingfisher 预存问题分析

#### 问题 1：误创建的 `~/` 冗余目录（已确认）
- **位置**：`modules/nf-core/kingfisher/~/`（字面名 `~`，非 home 目录展开）
- **内容**：kingfisher extract 模块的完整副本（5 个文件，已被 git 追踪）
- **处理**：`git rm -r 'modules/nf-core/kingfisher/~'`

#### 问题 2：Nextflow 26.04.4 兼容性（已通过顶层 config 修复覆盖）
- kingfisher 模块自身代码无兼容性问题
- 测试失败根因是 `nextflow.config` 顶层问题，将在 lint 修复中一并解决

### lint 修复范围（参考 circdna.nf）

经运行 `nf-core pipelines lint` 发现：**lint 无法运行**，因为 `nextflow config -flat .` 报错 `trace_timestamp is not defined`。需先修复此阻塞问题，再运行 lint 检查其他问题。

已知的 lint 修复项（参考 circdna.nf/CHANGES&FIX/20260630.md）：

| # | 修复项 | fetchngs.nf 当前 | circdna.nf 修复后 | 影响 |
|---|--------|------------------|-------------------|------|
| 1 | trace_timestamp | 顶层变量（报错） | `params.trace_report_suffix` | 阻塞 lint，必须修复 |
| 2 | check_max 函数 | 闭包形式 | 完全移除 | base.config 需同步改 |
| 3 | conda channels | `['conda-forge', 'bioconda', 'defaults']` | `['conda-forge', 'bioconda']` | 移除 defaults |
| 4 | process.shell | `['/bin/bash', '-euo', 'pipefail']` | `["bash", "-C", "-e", "-u", "-o", "pipefail"]` | 增加 -C no clobber |
| 5 | charliecloud.registry | 未设置 | `'quay.io'` | 补齐 registry |
| 6 | includeConfig 离线模式 | 直接 includeConfig | 条件判断 + `/dev/null` | 支持 NXF_OFFLINE |
| 7 | hook_url | `null` | `System.getenv('HOOK_URL')` | 支持环境变量 |
| 8 | plugins nf-validation | `nf-validation@1.1.3` | `nf-schema@2.5.1` | nf-schema 向后兼容，代码导入不变 |
| 9 | manifest.nextflowVersion | `!>=23.04.0` | `!>=25.04.8` | 提升版本要求 |
| 10 | arm profile | `arm { ... }` | `arm64 { ... } + emulate_amd64 { ... }` | 拆分为两个 profile |
| 11 | wave profile | 无 | 有 | 新增（可选） |

**不纳入本次范围**：
- `gpu` profile：fetchngs.nf 是下载工具，不涉及 GPU 计算
- `nf-amazon` 插件移除：fetchngs.nf testdata 使用 s3://，保留该插件

### 待完成（本计划范围）

1. 删除误创建的 `modules/nf-core/kingfisher/~/` 目录
2. 修复 `nextflow.config` lint 问题（trace_timestamp、check_max、conda channels、process.shell、charliecloud.registry、includeConfig 离线模式、hook_url、plugins、manifest.nextflowVersion、arm/arm64 profiles、wave profile）
3. 修复 `conf/base.config`（移除 check_max 调用）
4. 更新 `nextflow_schema.json`（添加 `trace_report_suffix` 隐藏参数）
5. 运行 `nextflow config -flat .` 验证 config 解析无错误
6. 运行 `nf-core pipelines lint` 检查并修复剩余 lint 错误和警告
7. 运行 fastqdl 端到端 stub 烟测（验证工作流跑通）
8. 运行 fastqdl 模块 stub 测试
9. 运行 fastqdl 工作流 stub 测试
10. 运行 kingfisher 模块 stub 测试（验证预存问题已修复）
11. 运行 kingfisher 工作流 stub 测试（验证预存问题已修复）
12. 端到端真实下载测试（小规模 SRR id）
13. 将所有结果回填到实施记录文档
14. 提交 git commit 到 `fastqdl` 分支

## 假设与决策 (Assumptions & Decisions)

| 决策项 | 取值 | 依据 |
|--------|------|------|
| `~/` 目录处理 | `git rm -r` | 字面名 `~` 的冗余副本，无引用 |
| trace_timestamp 修复 | 改为 `params.trace_report_suffix` | circdna.nf 模式，params 块内定义，config 块间可共享 |
| check_max 处理 | 完全移除 | 用户明确选择"完全移除（与 circdna.nf 一致）" |
| nf-validation → nf-schema | 纳入本次范围 | 用户明确选择"纳入本次范围（推荐）"；nf-schema 向后兼容，代码导入不变 |
| manifest.nextflowVersion | 提升到 `!>=25.04.8` | 用户明确选择；与 circdna.nf 一致 |
| arm profile 重构 | 拆分为 arm64 + emulate_amd64 | circdna.nf 模式 |
| wave profile | 新增 | circdna.nf 模式 |
| gpu profile | 不新增 | fetchngs.nf 不涉及 GPU 计算 |
| nf-amazon 插件 | 保留 | fetchngs.nf testdata 使用 s3:// |
| 真实下载测试 SRR id | `SRR13191702` | testdata 中包含此 id |
| stub 烟测 outdir | `/tmp/results_fastqdl_stub` | 临时目录 |
| 是否提交 commit | **是** | 用户明确要求 |
| 是否推送到远程仓库 branch | **是** | 用户明确要求推送 commit 到远程 fastqdl 分支 |
| 是否合并到 master | **否** | 用户只要求提交到 branch |
| 失败处理策略 | stub 烟测必须通过；真实下载失败需记录原因 | 用户要求"工作流跑通"以 stub 烟测为准 |

## 拟定变更 (Proposed Changes)

### 步骤 1：删除 kingfisher 误创建的 `~/` 目录

```bash
cd /Users/siyangming/nextflow_nf_core/fetchngs.nf
git rm -r 'modules/nf-core/kingfisher/~'
```

### 步骤 2：修复 nextflow.config lint 问题

**编辑** [nextflow.config](file:///Users/siyangming/nextflow_nf_core/fetchngs.nf/nextflow.config)，应用以下 11 处修复：

**(2a) params 块：添加 trace_report_suffix，修改 hook_url**

在 params 块中（`hook_url = null` 附近）：
```groovy
// 旧
hook_url                   = null
help                       = false
version                    = false

// 新
hook_url                   = System.getenv('HOOK_URL')
help                       = false
version                    = false
trace_report_suffix        = new java.util.Date().format( 'yyyy-MM-dd_HH-mm-ss')
```

**(2b) includeConfig 离线模式处理**

```groovy
// 旧
// NOTE: try-catch removed for Nextflow 26+ compatibility (config statements cannot be mixed with try-catch)
includeConfig "${params.custom_config_base}/nfcore_custom.config"

// 新
// If params.custom_config_base is set AND either NXF_OFFLINE is not set or params.custom_config_base is a local path, the nfcore_custom.config file from the specified base path is included.
includeConfig params.custom_config_base && (!System.getenv('NXF_OFFLINE') || !params.custom_config_base.startsWith('http')) ? "${params.custom_config_base}/nfcore_custom.config" : "/dev/null"
```

**(2c) conda channels 简化**

在 conda 和 mamba profile 中：
```groovy
// 旧
channels               = ['conda-forge', 'bioconda', 'defaults']

// 新
conda.channels         = ['conda-forge', 'bioconda']
```

**(2d) arm profile 重构为 arm64 + emulate_amd64**

```groovy
// 旧
arm {
    docker.runOptions      = '-u $(id -u):$(id -g) --platform=linux/amd64'
}

// 新
arm64 {
    process.arch            = 'arm64'
    apptainer.ociAutoPull   = true
    singularity.ociAutoPull = true
    wave.enabled            = true
    wave.freeze             = true
    wave.strategy           = 'conda,container'
}
emulate_amd64 {
    docker.runOptions       = '-u $(id -u):$(id -g) --platform=linux/amd64'
}
```

**(2e) 新增 wave profile**

在 profiles 块中添加（在 gpu profile 之前，如果有的话）：
```groovy
wave {
    apptainer.ociAutoPull   = true
    singularity.ociAutoPull = true
    wave.enabled            = true
    wave.freeze             = true
    wave.strategy           = 'conda,container'
}
```

**(2f) charliecloud.registry 添加**

```groovy
// 旧
apptainer.registry   = 'quay.io'
docker.registry      = 'quay.io'
podman.registry      = 'quay.io'
singularity.registry = 'quay.io'

// 新
apptainer.registry    = 'quay.io'
docker.registry       = 'quay.io'
podman.registry       = 'quay.io'
singularity.registry  = 'quay.io'
charliecloud.registry = 'quay.io'
```

**(2g) plugins 更新：nf-validation → nf-schema**

```groovy
// 旧
plugins {
    id 'nf-validation@1.1.3' // Validation of pipeline parameters and creation of an input channel from a sample sheet
    id 'nf-amazon@3.4.2' // Amazon Web Services integration
}

// 新
plugins {
    id 'nf-schema@2.5.1' // Validation of pipeline parameters and creation of an input channel from a sample sheet
    id 'nf-amazon@3.4.2' // Amazon Web Services integration
}
```

> 注：代码中的 `from 'plugin/nf-validation'` 导入**不变**，因为 nf-schema 向后兼容（circdna.nf 也是这样做的）。

**(2h) process.shell 增加 -C**

```groovy
// 旧
process.shell = ['/bin/bash', '-euo', 'pipefail']

// 新
process.shell = [
    "bash",
    "-C",         // No clobber - prevent output redirection from overwriting files.
    "-e",         // Exit if a tool returns a non-zero status/exit code
    "-u",         // Treat unset variables and parameters as an error
    "-o",         // Returns the status of the last command to exit..
    "pipefail"    //   ..with a non-zero status or zero if all successfully execute
]
```

**(2i) trace_timestamp 替换为 params.trace_report_suffix**

删除顶层 `trace_timestamp = new java.util.Date().format(...)`，并将 timeline/report/trace/dag 块中的 `${trace_timestamp}` 改为 `${params.trace_report_suffix}`：
```groovy
// 旧
trace_timestamp = new java.util.Date().format( 'yyyy-MM-dd_HH-mm-ss')
timeline {
    enabled = true
    file    = "${params.outdir}/pipeline_info/execution_timeline_${trace_timestamp}.html"
}
// ... report/trace/dag 类似

// 新（删除 trace_timestamp 行）
timeline {
    enabled = true
    file    = "${params.outdir}/pipeline_info/execution_timeline_${params.trace_report_suffix}.html"
}
// ... report/trace/dag 类似
```

**(2j) manifest.nextflowVersion 提升**

```groovy
// 旧
nextflowVersion = '!>=23.04.0'

// 新
nextflowVersion = '!>=25.04.8'
```

**(2k) 删除 check_max 闭包**

删除 nextflow.config 末尾的整个 `check_max = { obj, resource_type -> ... }` 块（约 30 行）。

### 步骤 3：修复 conf/base.config（移除 check_max 调用）

**编辑** [conf/base.config](file:///Users/siyangming/nextflow_nf_core/fetchngs.nf/conf/base.config)，将所有 `check_max(...)` 调用改为直接表达式（参考 circdna.nf/conf/base.config）：

```groovy
// 旧
cpus   = { check_max( 1    * task.attempt, 'cpus'   ) }
memory = { check_max( 6.GB * task.attempt, 'memory' ) }
time   = { check_max( 4.h  * task.attempt, 'time'   ) }

// 新
cpus   = { 1    * task.attempt }
memory = { 6.GB * task.attempt }
time   = { 4.h  * task.attempt }
```

对所有 withLabel 块（process_single, process_low, process_medium, process_high, process_long, process_high_memory）应用相同改动。

> 注：这会丢失 max_cpus/max_memory/max_time 的硬限制功能，但与 circdna.nf 模式一致。用户已明确选择此方案。

### 步骤 4：更新 nextflow_schema.json（添加 trace_report_suffix 隐藏参数）

**编辑** [nextflow_schema.json](file:///Users/siyangming/nextflow_nf_core/fetchngs.nf/nextflow_schema.json)，在 params 定义中添加（参考 circdna.nf）：
```json
"trace_report_suffix": {
    "type": "string",
    "hidden": true,
    "default": ""
}
```

### 步骤 5：验证 config 解析

```bash
cd /Users/siyangming/nextflow_nf_core/fetchngs.nf
nextflow config -flat . 2>&1 | head -20
```

**判断标准**：无 `trace_timestamp is not defined` 错误，config 解析成功。

### 步骤 6：运行 nf-core lint 检查并修复剩余问题

```bash
cd /Users/siyangming/nextflow_nf_core/fetchngs.nf
nf-core pipelines lint 2>&1 | tail -100
```

**判断标准**：
- ✅ 成功：lint 运行完成，无错误（警告可接受）
- ❌ 失败：根据 lint 报告修复剩余问题，重新运行

**已知可能修复的 lint 问题**（根据 .nf-core.yml 配置）：
- `actions_ci: false`：已忽略 CI 配置 lint
- `files_exist: conf/modules.config`：已忽略该文件存在性检查
- `files_unchanged: assets/sendmail_template.txt`：已忽略该文件变更检查

### 步骤 7：运行 fastqdl 端到端 stub 烟测

```bash
cd /Users/siyangming/nextflow_nf_core/fetchngs.nf
rm -rf /tmp/results_fastqdl_stub work
nextflow run main.nf \
    -profile test_local,docker \
    --download_method fastqdl \
    --outdir /tmp/results_fastqdl_stub \
    -stub 2>&1 | tail -100
```

**判断标准**：exit code 0，`FASTQDL_DOWNLOAD` 进程被触发，samplesheet 生成。

### 步骤 7a：（条件触发）修复新暴露的兼容性报错

仅当步骤 7 报错时执行。逐个分析报错，应用最小化修复。每修复一处，重新运行步骤 7。

### 步骤 8：fastqdl 模块 stub 测试

```bash
nf-test test modules/nf-core/fastqdl/download/tests/main.nf.test 2>&1 | tail -60
```

### 步骤 9：fastqdl 工作流 stub 测试

```bash
nf-test test workflows/sra/tests/sra_download_method_fastqdl.nf.test 2>&1 | tail -60
```

### 步骤 10：kingfisher 模块 stub 测试

```bash
nf-test test modules/nf-core/kingfisher/get/tests/main.nf.test 2>&1 | tail -60
```

### 步骤 11：kingfisher 工作流 stub 测试

```bash
nf-test test workflows/sra/tests/sra_download_method_kingfisher.nf.test 2>&1 | tail -60
```

### 步骤 12：端到端真实下载测试

```bash
cd /Users/siyangming/nextflow_nf_core/fetchngs.nf
echo "SRR13191702" > /tmp/sra_ids_fastqdl_realtest.csv
rm -rf results_fastqdl_real
nextflow run main.nf \
    -profile docker \
    --input /tmp/sra_ids_fastqdl_realtest.csv \
    --download_method fastqdl \
    --outdir results_fastqdl_real 2>&1 | tail -80
```

**失败处理**：若因网络/限速/容器拉取失败，不阻塞计划完成，但必须在实施文档中记录失败原因。**清理**：测试完成后删除 `results_fastqdl_real` 与 `/tmp/sra_ids_fastqdl_realtest.csv`。

### 步骤 13：回填验证结果到实施记录文档

**编辑** [.trae/CHANGES&FIX/fastqdl_integration.md](file:///Users/siyangming/nextflow_nf_core/fetchngs.nf/.trae/CHANGES&FIX/fastqdl_integration.md)：

(a) 在 `## 改动清单` 中追加 lint 修复相关文件（nextflow.config、conf/base.config、nextflow_schema.json）

(b) 将 `## 验证结果` 章节每个子节替换为实际执行结果

(c) 新增 `## kingfisher 预存问题修复` 章节

(d) 新增 `## Nextflow lint 修复` 章节，详细记录每处修复（参考 circdna.nf/CHANGES&FIX/20260630.md 的格式）：
- trace_timestamp → params.trace_report_suffix
- check_max 完全移除
- conda channels 简化
- process.shell 增加 -C
- charliecloud.registry 添加
- includeConfig 离线模式处理
- hook_url 环境变量支持
- nf-validation → nf-schema
- manifest.nextflowVersion 提升
- arm → arm64 + emulate_amd64
- wave profile 新增

(e) 更新 `## 后续待办` 章节的 checkbox 状态

### 步骤 14：提交 git commit 到 fastqdl 分支

**14a. 检查 git status**
```bash
cd /Users/siyangming/nextflow_nf_core/fetchngs.nf
git status
git diff --stat
```

**14b. 暂存改动**
```bash
git add -A
```

**14c. 提交**
```bash
git commit -m "feat(v1.14.0): integrate fastqdl, fix kingfisher pre-existing issues, and update to latest Nextflow syntax

- Add fastqdl/download module from bio.nf as 5th download_method option
- Integrate FASTQDL_DOWNLOAD into SRA workflow with branch routing
- Extend nextflow_schema.json enum with 'fastqdl' and add trace_report_suffix
- Bump pipeline version to 1.14.0
- Update CHANGELOG.md, README.md, docs/usage.md
- Add workflow stub test for fastqdl download method
- Fix Nextflow 26.04.4 compatibility and lint issues in nextflow.config:
  - Replace trace_timestamp with params.trace_report_suffix
  - Remove check_max function, simplify base.config resource expressions
  - Simplify conda channels (remove 'defaults')
  - Update process.shell to add -C (no clobber)
  - Add charliecloud.registry
  - Add NXF_OFFLINE handling for includeConfig
  - Support hook_url from environment variable
  - Migrate nf-validation@1.1.3 to nf-schema@2.5.1
  - Bump manifest.nextflowVersion to !>=25.04.8
  - Split arm profile into arm64 and emulate_amd64
  - Add wave profile
- Remove erroneous modules/nf-core/kingfisher/~/ directory
- Add implementation docs in .trae/
"
```

**14d. 验证提交**
```bash
git log --oneline -3
git status  # 预期：working tree clean
```

### 步骤 15：推送到远程仓库 fastqdl 分支

**15a. 检查远程与上游配置**
```bash
cd /Users/siyangming/nextflow_nf_core/fetchngs.nf
git remote -v
git branch -vv | grep '^\*'
```

**15b. 推送（如已有上游则直接 push，否则设置 upstream）**
```bash
# 若 fastqdl 分支已有 upstream tracking
git push

# 若 fastqdl 分支无 upstream（首次推送）
git push -u origin fastqdl
```

**15c. 验证推送**
```bash
git log --oneline -1 origin/fastqdl  # 确认远程已更新到最新 commit
git rev-parse HEAD origin/fastqdl    # 两个 SHA 应一致
```

**判断标准**：远程 `origin/fastqdl` 已指向最新 commit，本地与远程 SHA 一致。

## 验证步骤 (Verification Steps)

本计划的验收标准：

1. **必须通过**：
   - 步骤 1 kingfisher `~/` 目录已删除
   - 步骤 5 `nextflow config -flat .` 无错误
   - 步骤 7 fastqdl 端到端 stub 烟测（exit code 0，samplesheet 生成）
   - 步骤 13 实施记录文档已回填
   - 步骤 14 git commit 成功
   - 步骤 15 推送到远程 `origin/fastqdl` 成功，本地与远程 SHA 一致

2. **应当通过**：
   - 步骤 6 nf-core lint 无错误（警告可接受）
   - 步骤 8-9 fastqdl 模块/工作流 stub 测试
   - 步骤 10-11 kingfisher 模块/工作流 stub 测试
   - 若失败需有合理解释

3. **尽量通过**：
   - 步骤 12 端到端真实下载测试——若失败需记录原因，不阻塞

## 不在本次范围内 (Out of Scope)

- 不合并 `fastqdl` 分支到 master、不打 v1.14.0 tag（由用户决定；但需推送到远程 fastqdl 分支）
- 不修改 fastqdl 测试文件中 bio.nf 绝对路径引用
- 不扩展真实下载测试规模
- 不修改 `conf/test_local.config` 默认 download_method
- 不主动重构 kingfisher 模块代码
- 不新增 gpu profile（fetchngs.nf 不涉及 GPU 计算）
- 不移除 nf-amazon 插件（fetchngs.nf testdata 使用 s3://）
- 不推送 commit 到 master/远程默认分支；仅推送到远程 `fastqdl` 分支
