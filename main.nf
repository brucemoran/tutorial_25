#! nextflow

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
    """.stripIndent()
}

if (params.help) exit 0, helpMessage()

//requires
if(params.runID == null){
  exit 1, "Please specify --runID"
}

if(params.email == null){
  exit 1, "Please specify --email"
}

if(params.outDir == null){
  exit 1, "Please specify --email"
} else {
  params.outputDir = params.outDir 
}

//file input channel
workflow {
  def fq_bits = Channel.fromPath('params.gdPath/*.fq').collect()
  get_set_fq(fq_bits)
}

//Get the fastq bits, and operate on them
process get_set_fq {

    input:
    path 'fq'
    
    output:
    file("*.fastq.gz") into ( finished )

    script:
    def fastq_gz = params.runID + ".fastq.gz"
    """
    cat * >> 'fastq.fq'
    gzip fastq.fq > ${fastq.gz}
    """
}

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

