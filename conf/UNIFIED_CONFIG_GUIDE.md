# Unified Configuration Guide for nf-core/fetchngs

## 1. Clear Configuration Instructions

This unified configuration file (`fetchngs_unified_config.config`) consolidates settings for various execution environments into a single, manageable file. It uses a **Scenario-based** approach, where specific blocks of configuration can be uncommented to adapt the pipeline to your needs.

### How to Use
1.  **Open** `conf/fetchngs_unified_config.config` in your text editor.
2.  **Locate** the scenario that matches your environment (e.g., "Scenario 1: Network Unstable").
3.  **Uncomment** the configuration block (remove `/*` and `*/` or `//`) for that scenario.
4.  **Run** the pipeline using this config file:
    ```bash
    nextflow run nf-core/fetchngs \
        --input ids.csv \
        --outdir results \
        -c conf/fetchngs_unified_config.config \
        -profile docker
    ```

---

## 2. Usage Examples

### Scenario 1: Unstable Network
**Use Case:** You are experiencing frequent timeouts, connection refusals, or slow speeds when downloading from SRA/ENA.
**Action:** Uncomment the block under `Scenario 1`.
**Key Settings:**
-   `maxRetries = 5`: Retries failed processes up to 5 times.
-   `ext.args`: Adds `wget` retry flags (`-t 30`, `--waitretry=60`, `--retry-connrefused`).
-   Increases timeouts (`-T 900` = 15 mins).

### Scenario 2: High Performance (HPC)
**Use Case:** You are running on a cluster with high bandwidth and `aspera` installed.
**Action:** Uncomment the block under `Scenario 2` and set `download_method = 'aspera'` in the params.
**Key Settings:**
-   `download_method = 'aspera'`
-   `maxForks = 10`: Downloads 10 files in parallel.
-   `cpus` & `memory`: Allocated higher resources (up to 32 CPUs, 256GB RAM).

### Scenario 3: Limited Resources (Laptop)
**Use Case:** Running on a personal machine with limited RAM/CPU.
**Action:** Uncomment the block under `Scenario 3`.
**Key Settings:**
-   `maxForks = 1`: Downloads files one by one to prevent system freeze.
-   `max_memory = '16.GB'` / `max_cpus = 4`.
-   `ext.args`: Limits download rate (`--limit-rate=5M`).

### Scenario 4: Metadata Only
**Use Case:** You only want the run information/metadata, not the FASTQ files.
**Action:** Uncomment `skip_fastq_download = true` in the `params` section.

### Scenario 5: RNA-seq Integration
**Use Case:** Preparing data for `nf-core/rnaseq`.
**Action:** Uncomment `nf_core_pipeline = 'rnaseq'`. This will generate a compatible `samplesheet.csv`.

---

## 3. Important Notes and Warnings

-   **Conflict Avoidance:** Do not uncomment multiple conflicting scenarios (e.g., Scenario 2 and Scenario 3) at the same time. If you do, the last one defined will typically take precedence, but it can lead to undefined behavior.
-   **Parameter Overrides:** Values specified in this config file will override default pipeline parameters. Command-line flags (e.g., `--max_cpus 8`) will override settings in this file.
-   **Check Max Function:** The `check_max` function at the end of the file ensures that resource requests do not exceed the limits set in `params.max_cpus` and `params.max_memory`.
-   **AWS Batch:** Scenario 6 requires a properly configured AWS environment and credentials.

---

## 4. Version History

-   **v1.0**: Initial release with separate configuration files for each scenario.
-   **v1.1**: Consolidated all configuration files into `fetchngs_unified_config.config`. Added detailed comments and the `check_max` function for robust resource management. Documentation merged into `UNIFIED_CONFIG_GUIDE.md`.

---

## 5. Best Practices

-   **Start Simple:** Try the default configuration first. Only enable scenarios if you encounter specific issues (e.g., network errors) or have specific constraints.
-   **Verify Resources:** Before running on a large batch, check that your machine/cluster meets the `max_memory` and `max_cpus` limits defined in the file.
-   **Resume:** Always use `-resume` when restarting a pipeline to avoid re-downloading successfully retrieved files.
-   **Clean Up:** If using Scenario 3 (Limited Resources), consider setting `cleanup = true` in your nextflow config to remove intermediate files, though this prevents resuming from those specific steps.

---

*This document supersedes previous configuration guides (`CONFIG_FILES_OVERVIEW.md`, `COMPARISON.md`, etc.).*
