
process SRA_RUNINFO_TO_FTP {

    conda "conda-forge::python=3.9.5"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/python:3.9--1' :
        'biocontainers/python:3.9--1' }"

    input:
    path runinfo

    output:
    path "*.tsv"       , emit: tsv
    path "versions.yml", emit: versions

    script:
    """
    sra_runinfo_to_ftp.py \\
        ${runinfo.join(',')} \\
        ${runinfo.toString().tokenize(".")[0]}.runinfo_ftp.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version | sed 's/Python //g')
    END_VERSIONS
    """

    stub:
    """
    echo "id\trun_accession\texperiment_accession\tlibrary_layout\tfastq_ftp\tfastq_md5\tfastq_1\tfastq_2\tmd5_1\tmd5_2\tsingle_end" > ${runinfo.toString().tokenize(".")[0]}.runinfo_ftp.tsv
    echo "DRX024467_DRR026872\tDRR026872\tDRX024467\tSINGLE\tftp://example.com/file.fastq.gz\tmd5sum\tftp://example.com/file.fastq.gz\t\tmd5sum\t\ttrue" >> ${runinfo.toString().tokenize(".")[0]}.runinfo_ftp.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version | sed 's/Python //g')
    END_VERSIONS
    """
}
