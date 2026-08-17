# Unified Configuration Guide for nf-core/fetchngs

## 1. Clear Configuration Instructions

The server configuration (`conf/server.config`) consolidates the previous `fetchngs_unified_config.config`, `fetchngs_custom_config_template.config`, `SRP189094.config` and `PRJNA974167.config` into a single, manageable file. Input/output are passed via CLI; general download settings and per-process resources live in the config.

### How to Use
1.  **Activate** the `server` profile (`conf/server.config`) together with a container engine profile:
    ```bash
    nextflow run nf-core/fetchngs \
        --input samplesheets/SRP189094/SRR_Acc_List.csv \
        --outdir results \
        -profile server,docker
    ```
2.  **Override** personalised parameters (input, outdir, max_cpus, max_memory, max_time) on the command line as needed.

---

## 2. Usage Examples

### Scenario 1: Unstable Network
**Use Case:** You are experiencing frequent timeouts, connection refusals, or slow speeds when downloading from SRA/ENA.
**Action:** Override `SRA_FASTQ_FTP` settings or pass `--max_time` on the command line.
**Key Settings:**
-   `maxRetries = 2` (config): Retries failed processes.
-   `ext.args`: Adds `wget` retry flags (`-t 15`, `--retry-connrefused`, `-T 300`).
-   Increases timeouts (`--read-timeout 300`, `--dns-timeout 60`).

### Scenario 2: High Performance (HPC)
**Use Case:** You are running on a cluster with high bandwidth and `aspera` installed.
**Action:** Set `--download_method aspera` on the command line.
**Key Settings:**
-   `download_method = 'aspera'`
-   `maxForks = 8`: Downloads files in parallel.
-   `cpus` & `memory`: Allocated higher resources.

### Scenario 3: Limited Resources (Laptop)
**Use Case:** Running on a personal machine with limited RAM/CPU.
**Action:** Pass `--max_memory '16.GB' --max_cpus 4` on the command line.
**Key Settings:**
-   `max_memory = '16.GB'` / `max_cpus = 4` (CLI override).
-   Lower `maxForks` if network saturation is a concern.

### Scenario 4: Metadata Only
**Use Case:** You only want the run information/metadata, not the FASTQ files.
**Action:** Pass `--skip_fastq_download` on the command line.

### Scenario 5: RNA-seq Integration
**Use Case:** Preparing data for `nf-core/rnaseq`.
**Action:** Pass `--nf_core_pipeline rnaseq`. This will generate a compatible `samplesheet.csv`.

---

## 3. Important Notes and Warnings

-   **Parameter Overrides:** Values in `conf/server.config` override default pipeline parameters. Command-line flags (e.g., `--max_cpus 8`) override settings in the config.
-   **Input Lists:** SRR accession lists live under `samplesheets/SRP189094/` and `samplesheets/PRJNA974167/`; resolve via `--input samplesheets/<PROJECT>/SRR_Acc_List.csv`.

---

## 4. Version History

-   **v1.0**: Initial release with separate configuration files for each scenario.
-   **v1.1**: Consolidated all configuration files into `fetchngs_unified_config.config`. Added detailed comments and the `check_max` function for robust resource management. Documentation merged into `UNIFIED_CONFIG_GUIDE.md`.
-   **v2.0**: Replaced all custom configs with a single `conf/server.config` registered as the `server` profile; input/outdir moved to CLI arguments (aligned with `circdna.nf` / `isoseq.nf` conventions).

---

## 5. Best Practices

-   **Start Simple:** Try the default configuration first. Only adjust settings if you encounter specific issues (e.g., network errors) or have specific constraints.
-   **Verify Resources:** Before running on a large batch, check that your machine/cluster meets the `max_memory` and `max_cpus` limits.
-   **Resume:** Always use `-resume` when restarting a pipeline to avoid re-downloading successfully retrieved files.
-   **Clean Up:** Consider setting `cleanup = true` in your nextflow config to remove intermediate files, though this prevents resuming from those specific steps.

---

*This document supersedes previous configuration guides (`CONFIG_FILES_OVERVIEW.md`, `COMPARISON.md`, etc.).*
