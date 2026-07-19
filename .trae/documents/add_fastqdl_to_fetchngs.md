# 计划：将 fastqdl 模块集成到 fetchngs.nf 流程

## 概述 (Summary)

将位于 `/Users/siyangming/nextflow_nf_core/bio.nf/modules/fastqdl/download/` 的自定义 `fastq-dl` 模块集成到 `fetchngs.nf` 流程中，作为 `--download_method fastqdl` 的第 5 种下载选项，与现有的 `ftp` / `sratools` / `aspera` / `kingfisher` 并列。所有工作在新分支 `fastqdl` 上进行，实施文档统一存放于 `fetchngs.nf/.trae/` 目录下。

## 当前状态分析 (Current State Analysis)

### 源模块（bio.nf/modules/fastqdl/download/）
- **进程名**：`FASTQDL_DOWNLOAD`，已支持 stub 测试模式
- **输入**：`tuple val(meta), val(accession)`，accession 为 ENA/SRA accession（Study/Experiment/Run）
- **输出**：
  - `fastq`：`tuple val(meta), path("*.fastq.gz")`
  - `versions`：`path "versions.yml"`
  - `run_info`：`tuple val(meta), path("*-run-info.tsv")`
  - `run_mergers`：`tuple val(meta), path("*-run-mergers.tsv")`
- **容器**：`quay.io/biocontainers/fastq-dl:4.0.1--pyhdfd78af_0`（Singularity 走 Galaxy depot）
- **Conda**：`bioconda::fastq-dl=4.0.1`
- **测试数据**：`bio.nf/modules/fastqdl/sra_ids_test.csv`（10 个 SRA/ENA/GEO accession）

### 目标流程（fetchngs.nf）当前架构
- DSL2 nf-core 流程，入口 `main.nf` → `NFCORE_FETCHNGS` workflow → `SRA` workflow
- `SRA` workflow（[workflows/sra/main.nf](file:///Users/siyangming/nextflow_nf_core/fetchngs.nf/workflows/sra/main.nf)）通过 `branch` 操作符按 `download_method` 分流：
  - `aspera` → `ASPERA_CLI`（local module）
  - `ftp` → `SRA_FASTQ_FTP`（local module）
  - `sratools` → `FASTQ_DOWNLOAD_PREFETCH_FASTERQDUMP_SRATOOLS`（nf-core subworkflow）
  - `kingfisher` → `KINGFISHER_GET`（nf-core module，位于 [modules/nf-core/kingfisher/get/](file:///Users/siyangming/nextflow_nf_core/fetchngs.nf/modules/nf-core/kingfisher/get/main.nf)）
- 各分支 `fastq` 输出通过 `.mix()` 合并到 `ch_sra_metadata`
- `download_method` 在 [nextflow_schema.json](file:///Users/siyangming/nextflow_nf_core/fetchngs.nf/nextflow_schema.json#L50-L57) 中定义为 enum：`["aspera", "ftp", "sratools", "kingfisher"]`
- 仓库当前在 `master` 分支，工作树干净；`.trae/` 文件夹不存在，需新建

### Kingfisher 集成先例（作为本计划的参考模板）
kingfisher 模块文件结构：
- `modules/nf-core/kingfisher/get/main.nf`、`meta.yml`、`environment.yml`、`nextflow.config`、`tests/`
- `nextflow.config` 中通过 `withName: KINGFISHER_GET { ext.args = ...; publishDir = ... }` 配置
- [workflows/sra/nextflow.config](file:///Users/siyangming/nextflow_nf_core/fetchngs.nf/workflows/sra/nextflow.config) 通过 `includeConfig` 引入模块级配置
- **kingfisher 模块不在 `modules.json` 中登记**（因为非 nf-core/modules 仓库安装），fastqdl 沿用此先例

## 假设与决策 (Assumptions & Decisions)

| 决策项 | 取值 | 依据 |
|--------|------|------|
| 分支名 | `fastqdl` | 用户偏好"简单软件名"（如 `cresil` 而非 `feature/cresil-nf-modules`） |
| 模块放置位置 | `modules/nf-core/fastqdl/download/` | 参考 kingfisher 在 `modules/nf-core/kingfisher/get/` 的先例 |
| 是否更新 `modules.json` | **否** | kingfisher 同为自定义模块亦不在 modules.json 中 |
| 集成方式 | 新增 `download_method = 'fastqdl'` 选项 | 与 kingfisher 平行，最自然 |
| 分支返回值 | `[ meta, meta.run_accession ]` | fastq-dl 接受 run accession，与 sratools/kingfisher 一致 |
| 容器/Conda | 沿用模块现有配置 | 已符合 bio.nf project memory 中的硬约束 |
| 测试数据 | 复用 `bio.nf/modules/fastqdl/sra_ids_test.csv` 副本 | 与 kingfisher 模块布局一致；模块测试中保留 bio.nf 绝对路径引用以兼容现有 snapshot（kingfisher 测试亦如此） |
| 文档语言 | 中文 | 用户偏好 |
| Docker runOptions | 沿用 fetchngs.nf 既有 `docker` profile 中的 `-u $(id -u):$(id -g)` | nextflow.config 已配置，无需重复 |

## 拟定变更 (Proposed Changes)

### 步骤 1：创建新分支
在 `fetchngs.nf` 仓库基于 `master` 创建并切换到新分支 `fastqdl`：
```bash
cd /Users/siyangming/nextflow_nf_core/fetchngs.nf
git checkout -b fastqdl
```

### 步骤 2：复制模块文件到目标位置
将 `bio.nf/modules/fastqdl/download/` 下的所有文件原样复制到 `fetchngs.nf/modules/nf-core/fastqdl/download/`：
- `main.nf`（无需修改——进程名 `FASTQDL_DOWNLOAD`、stub 块、容器配置均已就绪）
- `meta.yml`
- `environment.yml`
- `tests/main.nf.test`
- `tests/main.nf.test.snap`
- `tests/nextflow.config`

同时复制 `bio.nf/modules/fastqdl/sra_ids_test.csv` 到 `fetchngs.nf/modules/nf-core/fastqdl/sra_ids_test.csv`（与 kingfisher 模块根目录布局一致）。

### 步骤 3：新建模块级 nextflow.config
**新建文件**：`fetchngs.nf/modules/nf-core/fastqdl/download/nextflow.config`

内容参考 [kingfisher/get/nextflow.config](file:///Users/siyangming/nextflow_nf_core/fetchngs.nf/modules/nf-core/kingfisher/get/nextflow.config)：
```groovy
process {
    withName: FASTQDL_DOWNLOAD {
        ext.args = ''
        publishDir = [
            path: { "${params.outdir}/fastq" },
            mode: params.publish_dir_mode,
            saveAs: { filename -> filename.equals('versions.yml') ? null : filename }
        ]
    }
}
```
> 说明：fastq-dl 默认参数即可，故 `ext.args = ''`；`versions.yml` 不发布到 fastq 目录。

### 步骤 4：更新 workflows/sra/nextflow.config
**编辑** [workflows/sra/nextflow.config](file:///Users/siyangming/nextflow_nf_core/fetchngs.nf/workflows/sra/nextflow.config)，在 kingfisher 那一行之后追加：
```groovy
includeConfig "../../modules/nf-core/fastqdl/download/nextflow.config"
```

### 步骤 5：更新 workflows/sra/main.nf
**编辑** [workflows/sra/main.nf](file:///Users/siyangming/nextflow_nf_core/fetchngs.nf/workflows/sra/main.nf)，做以下 4 处改动：

**(a) import 区**：在 `KINGFISHER_GET` 之后追加：
```groovy
include { FASTQDL_DOWNLOAD        } from '../../modules/nf-core/fastqdl/download/main'
```

**(b) branch 操作符的 download_method 判断**（第 83-85 行附近，kingfisher 判断之后）追加：
```groovy
if (params.download_method == 'fastqdl') {
    download_method = 'fastqdl'
}
```

**(c) branch 返回值**（第 93-94 行附近，kingfisher 分支之后）追加新分支：
```groovy
fastqdl: download_method == 'fastqdl'
    return [ meta, meta.run_accession ]
```

**(d) 模块调用与输出合并**（第 127-138 行附近，KINGFISHER_GET 调用块之后）追加：
```groovy
//
// MODULE: Download sequencing reads using fastq-dl
//
FASTQDL_DOWNLOAD (
    ch_sra_reads.fastqdl
)
ch_versions = ch_versions.mix(FASTQDL_DOWNLOAD.out.versions.first())
```
并在 fastq 合并区（第 136-138 行）的 `.mix(KINGFISHER_GET.out.fastq)` 之后追加 `.mix(FASTQDL_DOWNLOAD.out.fastq)`。

### 步骤 6：更新 nextflow_schema.json
**编辑** [nextflow_schema.json](file:///Users/siyangming/nextflow_nf_core/fetchngs.nf/nextflow_schema.json#L50-L57) 中 `download_method` 字段：
- `enum` 改为：`["aspera", "ftp", "sratools", "kingfisher", "fastqdl"]`
- `description` 改为：`"Method to download FastQ files. Available options are 'aspera', 'ftp', 'sratools', 'kingfisher' or 'fastqdl'. Default is 'ftp'."`
- `help_text` 改为：`"FTP and Aspera CLI download FastQ files directly from the ENA FTP whereas sratools uses sra-tools to download *.sra files and convert to FastQ. Kingfisher uses the Kingfisher tool to download data. fastqdl uses fastq-dl to download from ENA or SRA."`

### 步骤 7：新增工作流 stub 测试
**新建文件**：`fetchngs.nf/workflows/sra/tests/sra_download_method_fastqdl.nf.test`

内容参考 [sra_download_method_kingfisher.nf.test](file:///Users/siyangming/nextflow_nf_core/fetchngs.nf/workflows/sra/tests/sra_download_method_kingfisher.nf.test)：
```groovy
nextflow_workflow {

    name "Test workflow: sra/main.nf"
    script "../main.nf"
    workflow "SRA"
    tag "SRA_DOWNLOAD_METHOD_FASTQDL"
    options "-stub"

    test("Parameters: --download_method fastqdl") {
        when {
            workflow {
                """
                input[0] = Channel.from("DRX024467")
                """
            }
            params {
                download_method = 'fastqdl'
                sample_mapping_fields = 'run_accession,experiment_accession'
            }
        }
        then {
            assert workflow.success
            with(workflow.out.samplesheet) {
                assert path(get(0)).exists()
                assert path(get(0)).readLines().any { it.contains("DRR026872") }
            }
        }
    }
}
```

### 步骤 8：提升 fetchngs.nf 小版本号
**编辑** [nextflow.config](file:///Users/siyangming/nextflow_nf_core/fetchngs.nf/nextflow.config#L218-L227) 中 `manifest` 块的 `version` 字段：
- 当前值：`version = '1.12.0'`
- 新值：`version = '1.14.0'`（直接设为正式版本号 `1.14.0`，无 `dev` 后缀；本次发布将 kingfisher 与 fastqdl 两项新功能一并纳入 v1.14.0）

### 步骤 9：更新 CHANGELOG.md
**编辑** [CHANGELOG.md](file:///Users/siyangming/nextflow_nf_core/fetchngs.nf/CHANGELOG.md#L6-L12)：

(a) 将现有 `## v1.13.0dev` 段落标题重命名为 `## v1.14.0`（v1.13.0 从未正式发布，将其 dev 段直接提升为 v1.14.0，kingfisher 条目随之归入 v1.14.0）。

(b) 在 `v1.14.0` 段落内的 `### Modules` 与 `### Enhancements` 子段追加 fastqdl 条目：
```markdown
### Modules
- Added `kingfisher` modules (get, extract, annotate) for alternative SRA download and handling.
- Added `fastqdl/download` module for alternative SRA/ENA download via fastq-dl.

### Enhancements
- Added support for `params.download_method = 'kingfisher'` in SRA workflow.
- Added support for `params.download_method = 'fastqdl'` in SRA workflow.
- Bumped pipeline version to `1.14.0` to include `kingfisher` and `fastqdl` download methods.
```

### 步骤 10：更新 README.md 与 docs/usage.md
- **README.md** 第 70-72 行附近的下载方式列表，追加一行：
  `   - Use [fastq-dl](https://github.com/rpetit3/fastq-dl) to fetch FASTQ from ENA or SRA. Use \`--download_method fastqdl\` to force this behaviour.`
- **docs/usage.md** 第 75 行附近补充 fastqdl 选项说明

### 步骤 11：创建实施文档到 .trae/ 目录
按用户偏好"Document implementation details in CHANGES&FIX directory"，在 `fetchngs.nf/.trae/` 下创建：
- `fetchngs.nf/.trae/documents/add_fastqdl_to_fetchngs.md`（本计划文档，已存在）
- `fetchngs.nf/.trae/CHANGES&FIX/fastqdl_integration.md`（实施细节记录，执行阶段生成）

> 注：`.trae/documents/add_fastqdl_to_fetchngs.md` 在计划阶段即生成；`.trae/CHANGES&FIX/fastqdl_integration.md` 在执行阶段补全实际改动清单与验证结果。

## 验证步骤 (Verification Steps)

1. **分支确认**：
   ```bash
   cd /Users/siyangming/nextflow_nf_core/fetchngs.nf && git branch --show-current
   ```
   预期输出：`fastqdl`

2. **文件清单确认**：
   ```bash
   git status
   ```
   预期看到：新增 `modules/nf-core/fastqdl/` 整目录、`workflows/sra/tests/sra_download_method_fastqdl.nf.test`、`.trae/` 目录；修改 `workflows/sra/main.nf`、`workflows/sra/nextflow.config`、`nextflow_schema.json`、`nextflow.config`（manifest.version）、`CHANGELOG.md`、`README.md`、`docs/usage.md`

2.1 **版本号确认**：
```bash
grep "version" /Users/siyangming/nextflow_nf_core/fetchngs.nf/nextflow.config | head -1
```
预期输出包含：`version = '1.14.0'`

3. **模块 stub 测试**：
   ```bash
   nf-test test modules/nf-core/fastqdl/download/tests/main.nf.test
   ```
   预期：两个 stub 用例通过（sra_ids_from_csv 与 single_accession）

4. **工作流 stub 测试**：
   ```bash
   nf-test test workflows/sra/tests/sra_download_method_fastqdl.nf.test
   ```
   预期：`Parameters: --download_method fastqdl` 用例通过，samplesheet 中包含 `DRR026872`

5. **Schema 合法性**：
   ```bash
   nf-core pipelines schema lint nextflow_schema.json
   ```
   预期：无错误（enum 已正确扩展）

6. **端到端 stub 烟测（必需）—— 验证工作流可跑通**：
   ```bash
   cd /Users/siyangming/nextflow_nf_core/fetchngs.nf
   nextflow run main.nf \
       -profile test_local,docker \
       --download_method fastqdl \
       --outdir results_fastqdl_stub \
       -stub \
       -resume
   ```
   预期：
   - 流程成功启动并完成（exit code 0）
   - `FASTQDL_DOWNLOAD` 进程被实际触发（查看 trace/report 中是否包含该进程）
   - `results_fastqdl_stub/samplesheet/samplesheet.csv` 与 `results_fastqdl_stub/samplesheet/id_mappings.csv` 生成
   - `results_fastqdl_stub/pipeline_info/` 下生成 report/trace/timeline 文件
   - 注意：`test_local.config` 默认 `download_method = 'kingfisher'`，需通过命令行 `--download_method fastqdl` 覆盖

7. **端到端真实下载测试（必需）—— 验证 fastq-dl 实际可下载**：
   使用小规模真实 SRA id 进行实际下载验证（避免大规模耗时）：
   ```bash
   cd /Users/siyangming/nextflow_nf_core/fetchngs.nf
   echo "SRR13191702" > /tmp/sra_ids_fastqdl_realtest.csv
   nextflow run main.nf \
       -profile docker \
       --input /tmp/sra_ids_fastqdl_realtest.csv \
       --download_method fastqdl \
       --outdir results_fastqdl_real \
       -resume
   ```
   预期：
   - 流程成功完成（exit code 0）
   - `FASTQDL_DOWNLOAD` 进程实际执行 `fastq-dl` 命令并下载 FASTQ 文件
   - `results_fastqdl_real/fastq/` 下生成 `*.fastq.gz` 文件
   - `results_fastqdl_real/samplesheet/samplesheet.csv` 中包含 `SRR13191702` 且 fastq_1/fastq_2 路径正确指向已下载文件
   - 若网络/容器环境受限无法跑通，需在 `.trae/CHANGES&FIX/fastqdl_integration.md` 中记录失败原因与后续排查方向

   > 失败处理：若真实下载因网络、SRA 限速或容器拉取失败，至少保证步骤 6 stub 烟测通过；真实下载失败需在实施文档中明确记录未通过原因。

## 不在本次范围内 (Out of Scope)
- 不修改 `bio.nf` 中的源模块（保持其作为模块源仓库的角色）
- 不更新 `modules.json`（kingfisher 先例）
- 不修改 `conf/test.config` / `conf/test_full.config`（保持默认 ftp 测试不变）
- 不添加 fastq-dl 的非 stub 真实下载测试（避免 CI 长耗时与外部网络依赖）
- 不在 `conf/test_local.config` 中将默认 download_method 改为 fastqdl（保持 kingfisher 现状）
