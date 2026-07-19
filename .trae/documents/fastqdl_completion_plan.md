# 计划：fastqdl 集成收尾——lint 修复、测试验证与提交推送

## 概述 (Summary)

本计划是 fastqdl 集成到 fetchngs.nf 流程的**最后收尾阶段**，承接已批准的 [fastqdl_verification_plan.md](file:///Users/siyangming/nextflow_nf_core/fetchngs.nf/.trae/documents/fastqdl_verification_plan.md)。前序 15 步计划中步骤 1-5 已完成，步骤 6 部分完成（lint 已运行，但 19 项失败待修复）。本计划聚焦剩余工作：完成 lint 修复 → 跑通 stub 测试 → 真实下载测试 → 回填文档 → 提交并推送。

## 当前状态分析 (Current State Analysis)

### ✅ 已完成（前序步骤 1-5）

| 步骤 | 项目 | 证据 |
|------|------|------|
| 1 | 删除 `modules/nf-core/kingfisher/~/` 目录 | 已 git rm |
| 2 | nextflow.config 11 处 lint 修复 | 已应用（hook_url、trace_report_suffix、includeConfig NXF_OFFLINE、conda.channels、arm64+emulate_amd64+wave profiles、charliecloud.registry、nf-schema@2.5.1、process.shell -C、trace_report_suffix 使用、nextflowVersion !>=25.04.8、check_max 闭包删除） |
| 3 | conf/base.config 重写 | 所有 check_max 调用已替换为直接表达式 |
| 4 | nextflow_schema.json 更新 | $schema 升级到 2020-12、definitions→$defs、$ref 路径更新、trace_report_suffix 已添加 |
| 5 | nextflow config -flat 验证 | 解析无错误 |

### ⚠️ 步骤 6 部分完成——待修复的 lint 失败

`nf-core pipelines lint` 已成功运行（结果见 `/tmp/lint_results.md`），剩 **19 项失败**和 **1 项可修复警告**：

#### 可修复的失败（11 项）

| # | lint 类别 | 问题 | 修复方案 |
|---|----------|------|----------|
| 1-5 | `plugin_includes` | 5 处 `from 'plugin/nf-validation'` 与 `nf-schema` 插件冲突 | 改为 `from 'plugin/nf-schema'` |
| 6-8 | `nextflow_config` | `params.max_cpus`、`params.max_memory`、`params.max_time` 不应在 config 中（schema 已定义） | 从 params 块删除 |
| 9-11 | `nextflow_config` | `params.validationFailUnrecognisedParams`、`params.validationLenientMode`、`params.validationShowHiddenParams`、`params.validationSchemaIgnoreParams` 不应在 config 中（nf-schema 自动管理） | 从 params 块删除 |
| 12 | `schema_params` | `validationSchemaIgnoreParams` 在 config 但不在 schema | 删除 config 项即解决（不再触发检查） |

**涉及文件**：
- [subworkflows/local/utils_nfcore_fetchngs_pipeline/main.nf](file:///Users/siyangming/nextflow_nf_core/fetchngs.nf/subworkflows/local/utils_nfcore_fetchngs_pipeline/main.nf) 第 12、13 行（2 处）
- [subworkflows/nf-core/utils_nfvalidation_plugin/main.nf](file:///Users/siyangming/nextflow_nf_core/fetchngs.nf/subworkflows/nf-core/utils_nfvalidation_plugin/main.nf) 第 11、12、13 行（3 处）
- [nextflow.config](file:///Users/siyangming/nextflow_nf_core/fetchngs.nf/nextflow.config) 第 44-46 行（max_*）、第 49-52 行（validation*）

#### 可修复的警告（1 项）

| # | lint 类别 | 问题 | 修复方案 |
|---|----------|------|----------|
| 1 | `schema_description` | `trace_report_suffix` 无描述 | 在 schema 中添加 description |

#### 不修复的失败/警告（前置存在或配置忽略）

| 类别 | 数量 | 原因 |
|------|------|------|
| `files_exist` 缺失 CI/test 文件（`.github/workflows/nf-test.yml`、`.github/actions/get-shards/action.yml`、`.github/actions/nf-test/action.yml`、`tests/default.nf.test`） | 4 | 前置缺失，本计划范围外 |
| `multiqc_config`（`assets/multiqc_config.yml`） | 1 | fetchngs 无 MultiQC，前置缺失 |
| `modules_config`（`conf/modules.config`） | 1 | `.nf-core.yml` 已忽略，但 lint 仍报告（已知行为） |
| `manifest.version` 应以 `dev` 结尾 | 1（警告） | 用户明确要求 `1.14.0` 非 dev，保留 |
| `pigz/compress`、`sratools/prefetch` `check_local_copy` | 2（模块） | 模块本地副本与远端不一致，非本次范围 |
| `fastq_download_prefetch_fasterqdump_sratools` `check_local_copy` | 1（子工作流） | 子工作流本地副本与远端不一致，非本次范围 |
| README badges 缺失、`.nf-core.yml` 版本未设置、`conf/igenomes.config` 缺失等 | 多（警告） | 前置缺失或不影响功能 |
| `utils_nfcore_fetchngs_pipeline` 子工作流警告（`main_nf_include_versions`、`meta_yml_exists`、`main_nf_version_emitted`） | 多（子工作流警告） | nf-core 模板生成代码的常规警告，不影响运行 |

### ⬜ 待完成（本计划范围）

剩余 10 步：
- 步骤 6 收尾：修复 lint 失败 + 1 项警告
- 步骤 7-11：stub 烟测 + 4 个 stub 测试（fastqdl 端到端、fastqdl 模块、fastqdl 工作流、kingfisher 模块、kingfisher 工作流）
- 步骤 12：端到端真实下载测试（允许失败）
- 步骤 13：回填实施记录文档
- 步骤 14：git commit 到 `fastqdl` 分支
- 步骤 15：推送到 `origin/fastqdl`

## 假设与决策 (Assumptions & Decisions)

| 决策项 | 取值 | 依据 |
|--------|------|------|
| `from 'plugin/nf-validation'` 处理 | 改为 `from 'plugin/nf-schema'` | nf-schema 2.x 推荐写法；circdna.nf 虽未改但 lint 也会失败，本次按用户要求"修复 lint 错误"执行 |
| `max_cpus`/`max_memory`/`max_time` 处理 | 从 nextflow.config params 块删除 | schema 的 `max_job_request_options` 已定义这些参数，config 中重复定义触发 lint 失败 |
| `validation*` 参数处理 | 从 nextflow.config params 块删除 | nf-schema 自动管理这些参数，config 中显式定义触发 lint 失败 |
| `trace_report_suffix` schema 描述 | 添加 `"description": "Suffix to add to trace/report/timeline/dag files."` | 修复 schema_description 警告 |
| `manifest.version` 是否改 dev | **不改**，保持 `1.14.0` | 用户明确要求版本提升为 v1.14.0 |
| 真实下载测试 SRR id | `SRR13191702` | testdata 中包含此 id |
| stub 烟测 outdir | `/tmp/results_fastqdl_stub` | 临时目录 |
| 真实下载失败处理 | 不阻塞计划完成，但必须在文档中记录失败原因 | 用户要求"工作流跑通"以 stub 烟测为准 |
| 是否合并到 master | **否** | 用户只要求推送到 fastqdl 分支 |
| 模块本地副本不一致（pigz、sratools/prefetch、fastq_download_prefetch_fasterqdump_sratools） | **不修复** | 非本计划范围，且可能涉及模块版本回退 |

## 拟定变更 (Proposed Changes)

### 步骤 6：完成 nf-core lint 修复

#### 6a. 修复 plugin_includes（5 处）

**编辑** [subworkflows/local/utils_nfcore_fetchngs_pipeline/main.nf](file:///Users/siyangming/nextflow_nf_core/fetchngs.nf/subworkflows/local/utils_nfcore_fetchngs_pipeline/main.nf)：

```groovy
// 旧（第 12-13 行）
include { fromSamplesheet           } from 'plugin/nf-validation'
include { paramsSummaryMap          } from 'plugin/nf-validation'

// 新
include { fromSamplesheet           } from 'plugin/nf-schema'
include { paramsSummaryMap          } from 'plugin/nf-schema'
```

**编辑** [subworkflows/nf-core/utils_nfvalidation_plugin/main.nf](file:///Users/siyangming/nextflow_nf_core/fetchngs.nf/subworkflows/nf-core/utils_nfvalidation_plugin/main.nf)：

```groovy
// 旧（第 11-13 行）
include { paramsHelp         } from 'plugin/nf-validation'
include { paramsSummaryLog   } from 'plugin/nf-validation'
include { validateParameters } from 'plugin/nf-validation'

// 新
include { paramsHelp         } from 'plugin/nf-schema'
include { paramsSummaryLog   } from 'plugin/nf-schema'
include { validateParameters } from 'plugin/nf-schema'
```

#### 6b. 从 nextflow.config params 块删除 7 个不应声明的参数

**编辑** [nextflow.config](file:///Users/siyangming/nextflow_nf_core/fetchngs.nf/nextflow.config)：

```groovy
// 旧（第 42-53 行）
    // Max resource options
    // Defaults only, expecting to be overwritten
    max_memory                  = '128.GB'
    max_cpus                    = 16
    max_time                    = '240.h'

    // Schema validation default options
    validationFailUnrecognisedParams = false
    validationLenientMode            = false
    validationShowHiddenParams       = false
    validationSchemaIgnoreParams     = ''
    validate_params                  = true

// 新
    // Max resource options
    // Defaults only, expecting to be overwritten
    // NOTE: max_cpus, max_memory, max_time are defined in nextflow_schema.json (max_job_request_options)
    //       and should not be set in nextflow.config to avoid nf-core lint failures.

    // Schema validation default options
    // NOTE: validation* parameters are managed automatically by the nf-schema plugin.
    validate_params                  = true
```

> 保留 `validate_params`（业务逻辑使用，非 nf-schema 内置参数）。

#### 6c. 为 trace_report_suffix 添加 schema 描述

**编辑** [nextflow_schema.json](file:///Users/siyangming/nextflow_nf_core/fetchngs.nf/nextflow_schema.json) 中 `trace_report_suffix` 定义：

```json
// 旧
"trace_report_suffix": {
    "type": "string",
    "hidden": true
}

// 新
"trace_report_suffix": {
    "type": "string",
    "hidden": true,
    "description": "Suffix to add to trace/report/timeline/dag files."
}
```

#### 6d. 重跑 nf-core lint 验证

```bash
cd /Users/siyangming/nextflow_nf_core/fetchngs.nf
NXF_HOME=/tmp/nxf_home_lint HIDE_PROGRESS=1 XDG_CONFIG_HOME=/tmp/xdg_config \
PATH="/Users/siyangming/.local/pipx/venvs/nf-core/bin:/Users/siyangming/.local/bin:/opt/homebrew/bin:/usr/bin:/bin" \
bash -c 'printf "y\ny\ny\ny\ny\nNo\nNo\nNo\nNo\nNo\nNo\nNo\nNo\nNo\nNo\n" | nf-core pipelines lint --plain-text --markdown /tmp/lint_results_v2.md > /tmp/lint_stdout_v2.log 2>&1; echo EXIT:$?'
```

**判断标准**：可修复的 11 项失败 + 1 项警告已消除；前置存在的失败（files_exist CI 文件缺失、multiqc_config、modules_config）和模块/子工作流 `check_local_copy` 失败可接受。

### 步骤 7：fastqdl 端到端 stub 烟测

```bash
cd /Users/siyangming/nextflow_nf_core/fetchngs.nf
rm -rf /tmp/results_fastqdl_stub work
nextflow run main.nf \
    -profile test_local,docker \
    --download_method fastqdl \
    --outdir /tmp/results_fastqdl_stub \
    -stub 2>&1 | tee /tmp/fastqdl_stub_smoke.log | tail -100
```

**判断标准**：exit code 0，`FASTQDL_DOWNLOAD` 进程被触发，samplesheet 生成。

**失败处理**：若报错，逐个分析并应用最小化修复，每修复一处重跑一次。

### 步骤 8：fastqdl 模块 stub 测试

```bash
cd /Users/siyangming/nextflow_nf_core/fetchngs.nf
nf-test test modules/nf-core/fastqdl/download/tests/main.nf.test 2>&1 | tee /tmp/fastqdl_module_test.log | tail -60
```

### 步骤 9：fastqdl 工作流 stub 测试

```bash
cd /Users/siyangming/nextflow_nf_core/fetchngs.nf
nf-test test workflows/sra/tests/sra_download_method_fastqdl.nf.test 2>&1 | tee /tmp/fastqdl_wf_test.log | tail -60
```

### 步骤 10：kingfisher 模块 stub 测试

```bash
cd /Users/siyangming/nextflow_nf_core/fetchngs.nf
nf-test test modules/nf-core/kingfisher/get/tests/main.nf.test 2>&1 | tee /tmp/kingfisher_module_test.log | tail -60
```

### 步骤 11：kingfisher 工作流 stub 测试

```bash
cd /Users/siyangming/nextflow_nf_core/fetchngs.nf
nf-test test workflows/sra/tests/sra_download_method_kingfisher.nf.test 2>&1 | tee /tmp/kingfisher_wf_test.log | tail -60
```

### 步骤 12：端到端真实下载测试（允许失败）

```bash
cd /Users/siyangming/nextflow_nf_core/fetchngs.nf
echo "SRR13191702" > /tmp/sra_ids_fastqdl_realtest.csv
rm -rf results_fastqdl_real
nextflow run main.nf \
    -profile docker \
    --input /tmp/sra_ids_fastqdl_realtest.csv \
    --download_method fastqdl \
    --outdir results_fastqdl_real 2>&1 | tee /tmp/fastqdl_real_test.log | tail -80
```

**失败处理**：若因网络/限速/容器拉取失败，不阻塞计划完成，但必须在实施文档中记录失败原因。

**清理**：测试完成后删除 `results_fastqdl_real` 与 `/tmp/sra_ids_fastqdl_realtest.csv`。

### 步骤 13：回填验证结果到实施记录文档

**编辑** [.trae/CHANGES&FIX/fastqdl_integration.md](file:///Users/siyangming/nextflow_nf_core/fetchngs.nf/.trae/CHANGES&FIX/fastqdl_integration.md)：

(a) 在 `## 改动清单` 中追加 lint 修复相关文件（nextflow.config、conf/base.config、nextflow_schema.json、2 个 subworkflow main.nf）

(b) 将 `## 验证结果` 章节每个子节替换为实际执行结果：
- lint 修复结果（修复前 19 失败 → 修复后 X 失败）
- fastqdl stub 烟测结果
- fastqdl 模块/工作流 stub 测试结果
- kingfisher 模块/工作流 stub 测试结果
- 真实下载测试结果（成功/失败+原因）

(c) 新增 `## kingfisher 预存问题修复` 章节（记录 `~/` 目录删除）

(d) 新增 `## Nextflow lint 修复` 章节，详细记录每处修复（参考 circdna.nf/CHANGES&FIX/20260630.md 格式）：
- trace_timestamp → params.trace_report_suffix
- check_max 完全移除
- conda channels 简化
- process.shell 增加 -C
- charliecloud.registry 添加
- includeConfig 离线模式处理
- hook_url 环境变量支持
- nf-validation → nf-schema（config + 代码导入）
- manifest.nextflowVersion 提升
- arm → arm64 + emulate_amd64
- wave profile 新增
- 删除不应在 config 中的 7 个 params（max_cpus/max_memory/max_time + 4 个 validation*）
- 为 trace_report_suffix 添加 schema 描述

(e) 更新 `## 后续待办` 章节 checkbox 状态

### 步骤 14：git commit 到 fastqdl 分支

**14a. 检查状态**
```bash
cd /Users/siyangming/nextflow_nf_core/fetchngs.nf
git status
git diff --stat
git log --oneline -5
```

**14b. 暂存改动**
```bash
git add -A
```

**14c. 提交**
```bash
git commit -m "$(cat <<'EOF'
feat(v1.14.0): integrate fastqdl, fix kingfisher pre-existing issues, and update to latest Nextflow syntax

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
  - Update plugin imports from 'plugin/nf-validation' to 'plugin/nf-schema'
  - Bump manifest.nextflowVersion to !>=25.04.8
  - Split arm profile into arm64 and emulate_amd64
  - Add wave profile
  - Remove redundant params (max_cpus/max_memory/max_time, validation*) from config
  - Add description for trace_report_suffix in schema
- Update nextflow_schema.json to JSON Schema 2020-12 draft ($defs notation)
- Remove erroneous modules/nf-core/kingfisher/~/ directory
- Add implementation docs in .trae/
EOF
)"
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

**15b. 推送**
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

## 验证步骤 (Verification Steps)

本计划的验收标准：

1. **必须通过**：
   - 步骤 6d nf-core lint 重跑后，可修复的 11 项失败 + 1 项警告已消除
   - 步骤 7 fastqdl 端到端 stub 烟测 exit code 0，samplesheet 生成
   - 步骤 13 实施记录文档已回填
   - 步骤 14 git commit 成功
   - 步骤 15 推送到 `origin/fastqdl` 成功，本地与远程 SHA 一致

2. **应当通过**：
   - 步骤 8-9 fastqdl 模块/工作流 stub 测试
   - 步骤 10-11 kingfisher 模块/工作流 stub 测试
   - 若失败需有合理解释

3. **尽量通过**：
   - 步骤 12 端到端真实下载测试——若失败需记录原因，不阻塞

## 不在本次范围内 (Out of Scope)

- 不合并 `fastqdl` 分支到 master、不打 v1.14.0 tag
- 不修复模块/子工作流 `check_local_copy` 失败（pigz/compress、sratools/prefetch、fastq_download_prefetch_fasterqdump_sratools）
- 不创建缺失的 CI 文件（`.github/workflows/nf-test.yml` 等）
- 不创建 `assets/multiqc_config.yml`（fetchngs 无 MultiQC）
- 不修改 `manifest.version` 为 dev（用户明确要求 `1.14.0`）
- 不修改 fastqdl 测试文件中 bio.nf 绝对路径引用
- 不修改 `conf/test_local.config` 默认 download_method
- 不主动重构 kingfisher 模块代码
- 不新增 gpu profile
- 不移除 nf-amazon 插件
- 不推送 commit 到 master/远程默认分支
