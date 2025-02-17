#! nextflow

params.help = null
def helpMessage() {
  log.info"""
  ------------------------------------------------------------------------------
                            MANEline PIPELINE
  ------------------------------------------------------------------------------
  Usage:

  nextflow run brucemoran/tutorial_25

  Description:

  Get fastq from Google Drive, unsplit, prep for Sarek.

  Mandatory arguments:

    --runID         [str]       Identifier for the run

    --gdPath        [str]       Path to Google Drive files (all files therein taken!)

    --email         [str]       Email address to send reports

    --outDir        [str]       Output directory (top level)

  Optional:

    --help          [str]       Display help
    """.stripIndent()
}

if (params.help) exit 0, helpMessage()

//requires
if(params.runID == null){
  exit 1, "Please specify --runID"
}

if(params.gdPath == null){
  exit 1, "Please specify --gdPath, path of Google Drive dir in which are fastq files"
}

if(params.email == null){
  exit 1, "Please specify --email"
}

if(params.outDir == null){
  exit 1, "Please specify --outDir"
}

//whole workflow
workflow {
  get_fq()
  set_fq(get_fq)
}
process get_fq {
  
  output:
  path fqs

  script:
  """
  ${params.gdPath}/*fq
  """
}

//Get the fastq bits, and operate on them
process set_fq {

    input:
    path fqs.collect()
    
    output:
    file("*.fastq.gz")

    script:
    def fastq_gz = params.outDir + "/" + params.runID + ".fastq.gz"
    """
    cat * >> 'fastq.fq'
    gzip fastq.fq > ${fastq.gz}
    """
}

//when completed...
workflow.onComplete = {
    sleep(100)
    def subject = """\
        [brucemoran/tutorial_25] SUCCESS [$workflow.runName]
        """
        .stripIndent()
    if (!workflow.success) {
        subject = """\
            [brucemoran/tutorial_25] FAILURE [$workflow.runName]
            """
            .stripIndent()
    }

    def msg = """\
        Pipeline execution summary
        ---------------------------
        RunName     : ${workflow.runName}
        Completed at: ${workflow.complete}
        Duration    : ${workflow.duration}
        workDir     : ${workflow.workDir}
        exit status : ${workflow.exitStatus}
        """
        .stripIndent()

    sendMail(to: "${params.email}",
                subject: subject,
                body: msg)
}

