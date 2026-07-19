# 计划：fastqdl 集成最终收尾——编译修复、测试验证、提交推送

## 概述 (Summary)

本计划是 fastqdl 集成到 fetchngs.nf 流程的**最后一公里**，承接 [fastqdl_completion_plan.md](file:///Users/siyangming/nextflow_nf_core/fetchngs.nf/.trae/documents/fastqdl_completion_plan.md)。前序计划中步骤 6a-6c（lint 修复）已完成，但步骤 7（fastqdl stub 烟测）因 `subworkflows/nf-core/utils_nfcore_pipeline/main.nf` 中残留 3 处 Nextflow 26.04.4 编译错误而阻塞。本计划覆盖：修复残留编译错误 → 跑通 stub 烟测与模块/工作流测试 → 真实下载测试 → 回填文档 → 提交并推送到 `origin/fastqdl`。

wave profile 已在 [nextflow.config](file:///Users/siyangming/nextflow_nf_core/fetchngs.nf/nextflow.config#L115-L121) 第 115-121 行添加，本计划仅做存在性确认，不重复修改。

## 当前状态分析 (Current State Analysis)

### Git 状态

- **当前分支**：`fastqdl`
- **未提交改动**：14 个文件修改 + 3 个新增目录（`.trae/`、`modules/nf-core/fastqdl/`、`workflows/sra/tests/sra_download_method_fastqdl.nf.test`）
- **未推送 commit**：上次会话尚未执行 commit

### ✅ 已完成（前序步骤 1-6c）

| 步骤 | 项目 | 状态 |
|------|------|------|
| 1 | fastqdl 模块复制到 `modules/nf-core/fastqdl/download/` | 完成 |
| 2 | kingfisher `~/` 目录删除（git rm 已暂存） | 完成 |
| 3 | `workflows/sra/main.nf` 4 处集成（import、branch判断、branch返回、module调用+mix） | 完成 |
| 4 | `nextflow_schema.json` enum 扩展、JSON Schema 2020-12 迁移、`$defs` 重命名 | 完成 |
| 5 | `nextflow.config` 11 处 lint 修复（含 wave profile 添加） | 完成 |
| 6 | `conf/base.config` check_max 完全移除 | 完成 |
| 6a | 5 处 `from 'plugin/nf-validation'` → `'plugin/nf-schema'` | 完成 |
| 6b | 7 个冗余 params 从 nextflow.config 删除 | 完成 |
| 6c | `trace_report_suffix` schema 描述添加 | 完成 |
| 6' | `subworkflows/nf-core/utils_nfcore_pipeline/main.nf` import 移除、for 循环改 .each | 完成 |
| 6'' | `subworkflows/nf-core/utils_nextflow_pipeline/main.nf` import 移除、for 循环改 .each、C 风格 for 改 (0..n-2).each | 完成 |
| 6''' | `subworkflows/local/utils_nfcore_fetchngs_pipeline/main.nf` 2 处 plugin import 更新 | 完成 |
| 6'''' | `subworkflows/nf-core/utils_nfvalidation_plugin/main.nf` 3 处 plugin import 更新 | 完成 |

### ⚠️ 步骤 7 阻塞——残留编译错误

`subworkflows/nf-core/utils_nfcore_pipeline/main.nf` 中残留 3 类编译错误（参考 [circdna.nf](file:///Users/siyangming/nextflow_nf_core/circdna.nf/subworkflows/nf-core/utils_nfcore_pipeline/main.nf) 的修复模式）：

| 行号 | 当前代码 | 错误 | 修复方案（参考 circdna.nf） |
|------|----------|------|---------------------------|
| 34 | `valid_config = true` | `valid_config was assigned but not declared` | 改为 `def valid_config = true as Boolean`（circdna.nf 第 33 行） |
| 42 | `valid_config = false` | 同上（同作用域） | 由 34 行的 `def` 声明自动解决 |
| 44 | `return valid_config` | `valid_config is not defined` | 由 34 行的 `def` 声明自动解决 |
| 97 | `versions = yaml.load(...).collectEntries { ... }` | `versions was assigned but not declared` | 改为 `def versions = yaml.load(...).collectEntries { ... }`（circdna.nf 第 82 行） |
| 347 | `throw GroovyException('Send plaintext e-mail, not HTML')` | `GroovyException is not defined` | 改为 `throw new org.codehaus.groovy.GroovyException('Send plaintext e-mail, not HTML')`（circdna.nf 第 330 行） |

**注**：可能还有其他类似问题隐藏在文件后续行（如 `versions`、`colorcodes`、`Map` 声明等），需在修复后重跑 stub 烟测才能发现。

## 假设与决策 (Assumptions & Decisions)

| 决策项 | 取值 | 依据 |
|--------|------|------|
| 编译错误修复模式 | 严格对齐 circdna.nf 同名文件 | 用户明确要求"修复为最新的语法，可以参考 circdna.nf" |
| `GroovyException` 处理 | 改为 `new org.codehaus.groovy.GroovyException(...)` | circdna.nf 第 330 行的相同模式 |
| `valid_config` 类型 | `def valid_config = true as Boolean` | circdna.nf 第 33 行的相同模式 |
| `versions` 声明 | 加 `def` 前缀 | circdna.nf 第 82 行的相同模式 |
| 测试 profile 选择 | fastqdl 用 `test,docker` + `--download_method fastqdl`（test_local 默认 kingfisher） | 避免覆盖 test_local 默认值 |
| stub 烟测 outdir | `/tmp/results_fastqdl_stub` | 临时目录 |
| 真实下载 SRR id | `SRR13191702` | testdata 中包含此 id |
| 真实下载失败处理 | 不阻塞计划完成，但必须在文档中记录失败原因 | 用户要求"工作流跑通"以 stub 烟测为准 |
| 是否合并到 master | **否** | 用户只要求推送到 fastqdl 分支 |
| wave profile | 已添加，仅做存在性确认 | nextflow.config 第 115-121 行已存在 |

## 拟定变更 (Proposed Changes)

### 步骤 1：修复 utils_nfcore_pipeline/main.nf 残留编译错误

**文件**：[subworkflows/nf-core/utils_nfcore_pipeline/main.nf](file:///Users/siyangming/nextflow_nf_core/fetchngs.nf/subworkflows/nf-core/utils_nfcore_pipeline/main.nf)

#### 1a. 修复 `valid_config` 未声明（第 34 行）

```groovy
// 旧
def checkConfigProvided() {
    valid_config = true

// 新
def checkConfigProvided() {
    def valid_config = true as Boolean
```

#### 1b. 修复 `versions` 未声明（第 97 行）

```groovy
// 旧
def processVersionsFromYAML(yaml_file) {
    def yaml = new org.yaml.snakeyaml.Yaml()
    versions = yaml.load(yaml_file).collectEntries { k, v -> [ k.tokenize(':')[-1], v ] }

// 新
def processVersionsFromYAML(yaml_file) {
    def yaml = new org.yaml.snakeyaml.Yaml()
    def versions = yaml.load(yaml_file).collectEntries { k, v -> [ k.tokenize(':')[-1], v ] }
```

#### 1c. 修复 `GroovyException` 未定义（第 347 行）

```groovy
// 旧
            if (plaintext_email) { throw GroovyException('Send plaintext e-mail, not HTML') }

// 新
            if (plaintext_email) { throw new org.codehaus.groovy.GroovyException('Send plaintext e-mail, not HTML') }
```

#### 1d. 全文扫描同类问题

修复上述 3 处后，再次重跑 stub 烟测；若仍有同类错误（如 `Map colors`、`Map colorcodes`、`String version_string`、`String yaml_file_text` 等使用 Java 类型声明的语句），按 circdna.nf 模式逐个改为 `def` + `as Type` 后缀。

参考 circdna.nf 同名文件已修复的等价位置：
- 第 33 行：`def valid_config = true as Boolean` ✓
- 第 63 行：`def version_string = "" as String` ✓
- 第 82 行：`def versions = ...` ✓
- 第 149 行：`def yaml_file_text = "..." as String` ✓
- 第 164 行：`def colorcodes = [:] as Map` ✓
- 第 326 行：`def colors = logColours(...) as Map` ✓

### 步骤 2：fastqdl 端到端 stub 烟测

```bash
cd /Users/siyangming/nextflow_nf_core/fetchngs.nf
rm -rf /tmp/results_fastqdl_stub work
nextflow run main.nf \
    -profile test,docker \
    --input modules/nf-core/fastqdl/sra_ids_test.csv \
    --download_method fastqdl \
    --outdir /tmp/results_fastqdl_stub \
    -stub 2>&1 | tee /tmp/fastqdl_stub_smoke.log | tail -100
```

**判断标准**：exit code 0，`FASTQDL_DOWNLOAD` 进程被触发，samplesheet 生成。

**失败处理**：若仍报编译错误，回到步骤 1 修复后重跑；若报运行时错误（如 stub 文件缺失、容器拉取失败），逐个最小化修复。

### 步骤 3：fastqdl 模块 stub 测试

```bash
cd /Users/siyangming/nextflow_nf_core/fetchngs.nf
nf-test test modules/nf-core/fastqdl/download/tests/main.nf.test 2>&1 | tee /tmp/fastqdl_module_test.log | tail -60
```

**判断标准**：测试通过（或失败原因可解释，例如 nf-test 环境未配置）。

### 步骤 4：fastqdl 工作流 stub 测试

```bash
cd /Users/siyangming/nextflow_nf_core/fetchngs.nf
nf-test test workflows/sra/tests/sra_download_method_fastqdl.nf.test 2>&1 | tee /tmp/fastqdl_wf_test.log | tail -60
```

### 步骤 5：kingfisher 模块 stub 测试

```bash
cd /Users/siyangming/nextflow_nf_core/fetchngs.nf
nf-test test modules/nf-core/kingfisher/get/tests/main.nf.test 2>&1 | tee /tmp/kingfisher_module_test.log | tail -60
```

### 步骤 6：kingfisher 工作流 stub 测试

```bash
cd /Users/siyangming/nextflow_nf_core/fetchngs.nf
nf-test test workflows/sra/tests/sra_download_method_kingfisher.nf.test 2>&1 | tee /tmp/kingfisher_wf_test.log | tail -60
```

### 步骤 7：端到端真实下载测试（允许失败）

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

### 步骤 8：回填验证结果到实施记录文档

**编辑** [.trae/CHANGES&FIX/fastqdl_integration.md](file:///Users/siyangming/nextflow_nf_core/fetchngs.nf/.trae/CHANGES&FIX/fastqdl_integration.md)：

(a) 在 `## 改动清单 → 修改文件` 中追加 lint 修复相关文件：
- `nextflow.config`（lint 修复 + wave profile + arm64 拆分 + emulate_amd64 + nf-schema@2.5.1 + nextflowVersion 提升 + 7 个冗余 params 删除）
- `conf/base.config`（check_max 完全移除）
- `nextflow_schema.json`（JSON Schema 2020-12 迁移、`$defs` 重命名、`trace_report_suffix` 描述）
- `subworkflows/local/utils_nfcore_fetchngs_pipeline/main.nf`（2 处 plugin import）
- `subworkflows/nf-core/utils_nfvalidation_plugin/main.nf`（3 处 plugin import）
- `subworkflows/nf-core/utils_nfcore_pipeline/main.nf`（import 移除、for→.each、def 声明、GroovyException 全限定名）
- `subworkflows/nf-core/utils_nextflow_pipeline/main.nf`（import 移除、for→.each、C 风格 for→range.each）

(b) 将 `## 验证结果` 章节每个子节替换为实际执行结果：
- 分支与文件清单（git branch、git status 输出）
- 版本号（grep version nextflow.config 输出）
- fastqdl 模块 stub 测试结果
- fastqdl 工作流 stub 测试结果
- Schema 合法性（可选，若 nf-core lint 重跑则填入）
- 端到端 stub 烟测结果（步骤 2 的输出摘要）
- 端到端真实下载测试结果（步骤 7 的输出摘要，成功/失败+原因）

(c) 新增 `## kingfisher 预存问题修复` 章节（记录 `~/` 目录删除与 kingfisher 模块/工作流 stub 测试结果）

(d) 新增 `## Nextflow lint 修复` 章节，详细记录每处修复：
- trace_timestamp → params.trace_report_suffix
- check_max 完全移除
- conda channels 简化（移除 'defaults'）
- process.shell 增加 -C
- charliecloud.registry 添加
- includeConfig NXF_OFFLINE 离线模式处理
- hook_url 环境变量支持
- nf-validation → nf-schema（config + 5 处代码导入）
- manifest.nextflowVersion 提升到 !>=25.04.8
- arm → arm64 + emulate_amd64 拆分
- wave profile 新增
- 7 个冗余 params 删除（max_cpus/max_memory/max_time + 4 个 validation*）
- trace_report_suffix schema 描述添加
- JSON Schema 2020-12 + $defs 重命名
- Nextflow 26.04.4 兼容性修复（import 移除、for→.each、def 声明、GroovyException 全限定名）

(e) 更新 `## 后续待办` 章节 checkbox 状态

### 步骤 9：git commit 到 fastqdl 分支

**9a. 检查状态**
```bash
cd /Users/siyangming/nextflow_nf_core/fetchngs.nf
git status
git diff --stat
git log --oneline -5
```

**9b. 暂存改动**
```bash
git add -A
```

**9c. 提交**
```bash
git commit -m "$(cat <<'EOF'
feat(v1.14.0): integrate fastqdl, fix kingfisher pre-existing issues, and update to latest Nextflow syntax

- Add fastqdl/download module from bio.nf as 5th download_method option
- Integrate FASTQDL_DOWNLOAD into SRA workflow with branch routing
- Extend nextflow_schema.json enum with 'fastqdl' and migrate to JSON Schema 2020-12 ($defs)
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
- Fix Nextflow 26.04.4 compatibility in subworkflows:
  - utils_nfcore_pipeline: remove import declarations, convert for loops to .each, add def declarations, fully-qualify GroovyException
  - utils_nextflow_pipeline: remove import declarations, convert for loops to .each, fully-qualify JsonOutput/Yaml/FilesEx
- Remove erroneous modules/nf-core/kingfisher/~/ directory
- Add implementation docs in .trae/
EOF
)"
```

**9d. 验证提交**
```bash
git log --oneline -3
git status  # 预期：working tree clean
```

### 步骤 10：推送到远程仓库 fastqdl 分支

**10a. 检查远程与上游配置**
```bash
cd /Users/siyangming/nextflow_nf_core/fetchngs.nf
git remote -v
git branch -vv | grep '^\*'
```

**10b. 推送**
```bash
# 若 fastqdl 分支已有 upstream tracking
git push

# 若 fastqdl 分支无 upstream（首次推送）
git push -u origin fastqdl
```

**10c. 验证推送**
```bash
git log --oneline -1 origin/fastqdl  # 确认远程已更新到最新 commit
git rev-parse HEAD origin/fastqdl    # 两个 SHA 应一致
```

## 验证步骤 (Verification Steps)

本计划的验收标准：

1. **必须通过**：
   - 步骤 1 修复后 `nextflow run main.nf` 不再报编译错误
   - 步骤 2 fastqdl 端到端 stub 烟测 exit code 0，`FASTQDL_DOWNLOAD` 进程被触发，samplesheet 生成
   - 步骤 8 实施记录文档已回填实际执行结果
   - 步骤 9 git commit 成功
   - 步骤 10 推送到 `origin/fastqdl` 成功，本地与远程 SHA 一致

2. **应当通过**：
   - 步骤 3-4 fastqdl 模块/工作流 stub 测试
   - 步骤 5-6 kingfisher 模块/工作流 stub 测试
   - 若失败需有合理解释（如 nf-test 环境未配置）

3. **尽量通过**：
   - 步骤 7 端到端真实下载测试——若失败需记录原因，不阻塞

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
- 不重跑 nf-core lint（用户已取消，步骤 6d 跳过；config 解析已通过 `nextflow config -flat .` 验证）
