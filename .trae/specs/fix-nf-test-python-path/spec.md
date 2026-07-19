# 修复 nf-test 中 MULTIQC_MAPPINGS_CONFIG python 找不到错误 Spec

## Why

在 fastqdl 集成收尾阶段运行 nf-test 工作流测试时，`MULTIQC_MAPPINGS_CONFIG` 进程报错 `env: python: No such file or directory`，导致 `sra_download_method_fastqdl.nf.test` 和 `sra_download_method_kingfisher.nf.test` 两个工作流 stub 测试失败。

根本原因是 [nf-test.config](file:///Users/siyangming/nextflow_nf_core/fetchngs.nf/nf-test.config) 缺少 `profile = "test"` 配置，nf-test 运行时不会加载任何 profile，因此 main.nf 中声明的 `conda "conda-forge::python=3.9.5"` 不会生效，进程直接在本地执行，而本地 PATH 中没有 `python` 命令（macOS 默认只有 `python3`）。

参考 [circrna.nf/nf-test.config](file:///Users/siyangming/nextflow_nf_core/circrna.nf/nf-test.config) 的配置模式修复。

## What Changes

- 修改 [nf-test.config](file:///Users/siyangming/nextflow_nf_core/fetchngs.nf/nf-test.config)，对齐 circrna.nf 的配置结构：
  - 添加 `profile = "test"` 配置（核心修复）
  - 添加 `plugins` 块加载 `nft-utils@0.0.3`
  - 添加 `triggers` 列表（可选，用于增量测试）
  - 添加 `ignore` 列表忽略 nf-core 模块自带测试（可选）
- 不修改 [modules/local/multiqc_mappings_config/main.nf](file:///Users/siyangming/nextflow_nf_core/fetchngs.nf/modules/local/multiqc_mappings_config/main.nf)（保持 `python` 命令，依赖 conda 环境提供）
- 不修改 [tests/nextflow.config](file:///Users/siyangming/nextflow_nf_core/fetchngs.nf/tests/nextflow.config)（资源限制已合理）

## Impact

- Affected specs: 无（首次 spec）
- Affected code:
  - [nf-test.config](file:///Users/siyangming/nextflow_nf_core/fetchngs.nf/nf-test.config)（主要修改文件）
  - 间接影响所有 nf-test 工作流测试的运行方式

## ADDED Requirements

### Requirement: nf-test 配置 profile

nf-test 配置文件 SHALL 指定默认 profile 为 `test`，确保 nf-test 运行时加载 [conf/test.config](file:///Users/siyangming/nextflow_nf_core/fetchngs.nf/conf/test.config) 的参数定义。

#### Scenario: 本地运行 nf-test 不指定 profile
- **WHEN** 用户执行 `nf-test test workflows/sra/tests/sra_download_method_fastqdl.nf.test`
- **THEN** nf-test 自动加载 `test` profile，main.nf 中的 conda 配置仍不生效（因 conda profile 未启用），但 test params 已加载

#### Scenario: 本地运行 nf-test 追加 conda profile
- **WHEN** 用户执行 `nf-test test --profile=+conda workflows/sra/tests/sra_download_method_fastqdl.nf.test`
- **THEN** nf-test 加载 `test` + `conda` 两个 profile，main.nf 中的 `conda "conda-forge::python=3.9.5"` 生效，`python` 命令可用

#### Scenario: 本地运行 nf-test 追加 docker profile
- **WHEN** 用户执行 `nf-test test --profile=+docker workflows/sra/tests/sra_download_method_fastqdl.nf.test`
- **THEN** nf-test 加载 `test` + `docker` 两个 profile，进程在 docker 容器内执行，`python` 命令可用

### Requirement: nf-test 加载 nft-utils 插件

nf-test 配置文件 SHALL 加载 `nft-utils@0.0.3` 插件，与 circrna.nf 保持一致，提供测试工具函数。

## MODIFIED Requirements

### Requirement: nf-test.config 配置结构

参考 [circrna.nf/nf-test.config](file:///Users/siyangming/nextflow_nf_core/circrna.nf/nf-test.config)，fetchngs.nf 的 nf-test.config 应包含以下完整配置块：

```hocon
config {
    testsDir = "."
    workDir = System.getenv("NFT_WORKDIR") ?: ".nf-test"
    configFile = "tests/nextflow.config"
    profile = "test"
    ignore = [
        'modules/nf-core/**/tests/*',
        'subworkflows/nf-core/**/tests/*',
    ]
    triggers = [
        '.github/actions/nf-test/action.yml',
        '.github/workflows/nf-test.yml',
        'assets/schema_input.json',
        'bin/*',
        'conf/test.config',
        'nextflow.config',
        'nextflow_schema.json',
        'nf-test.config',
        'tests/.nftignore',
        'tests/nextflow.config',
    ]
    plugins {
        load "nft-utils@0.0.3"
    }
}
```

## REMOVED Requirements

无。
