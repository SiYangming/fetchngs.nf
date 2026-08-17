process SRATOOLS_PREFETCH {
    tag "$id"
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/sra-tools:3.2.1--h4304569_1' :
        'quay.io/biocontainers/sra-tools:3.2.1--h4304569_1' }"

    input:
    tuple val(meta), val(id)
    path ncbi_settings
    path certificate

    output:
    tuple val(meta), path(id), emit: sra
    path 'versions.yml'      , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    args = task.ext.args ?: ''
    args2 = task.ext.args2 ?: '5 1 100'  // <num retries> <base delay in seconds> <max delay in seconds>
    def cert_arg = certificate ?
        (certificate.name.endsWith('.jwt') ? "--perm ${certificate}" :
        certificate.name.endsWith('.ngc') ? "--ngc ${certificate}" : '') : ''
    final_args = "${args} ${cert_arg}".trim()
    """
    echo "${args2}"
    echo "${final_args}"
    """
    template 'retry_with_backoff.sh'
}
