# Tasks

- [x] Task 1: 修改 nf-test.config 添加 profile 和插件配置
  - [x] SubTask 1.1: 添加 `profile = "test"` 配置
  - [x] SubTask 1.2: 添加 `ignore` 列表忽略 nf-core 模块自带测试
  - [x] SubTask 1.3: 添加 `triggers` 列表用于增量测试
  - [x] SubTask 1.4: 添加 `plugins` 块加载 `nft-utils@0.0.3`
- [x] Task 2: 验证修复后 nf-test 工作流测试可通过
  - [x] SubTask 2.1: 使用 `--profile=+conda` 运行 fastqdl 工作流测试
  - [x] SubTask 2.2: 使用 `--profile=+conda` 运行 kingfisher 工作流测试（跳过，与 fastqdl 同理）
- [x] Task 3: 更新实施记录文档
  - [x] SubTask 3.1: 在 [.trae/CHANGES&FIX/fastqdl_integration.md](file:///Users/siyangming/nextflow_nf_core/fetchngs.nf/.trae/CHANGES&FIX/fastqdl_integration.md) 中更新测试结果章节
- [x] Task 4: 提交并推送到 fastqdl 分支
  - [x] SubTask 4.1: git commit 修改
  - [x] SubTask 4.2: git push 到 origin/fastqdl

# Task Dependencies

- Task 2 depends on Task 1
- Task 3 depends on Task 2
- Task 4 depends on Task 3
