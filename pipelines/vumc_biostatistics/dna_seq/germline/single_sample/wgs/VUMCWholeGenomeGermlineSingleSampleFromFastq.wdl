version 1.0

## Copyright Broad Institute/VUMC, 2018/2022
##
## This WDL pipeline implements data pre-processing and initial variant calling (GVCF
## generation) according to the GATK Best Practices (June 2016) for germline SNP and
## Indel discovery in human whole-genome data.
##
## Requirements/expectations :
## - Human whole-genome pair-end sequencing data in FASTQ format
## - GVCF output names must end in ".g.vcf.gz"
## - Reference genome must be Hg38 with ALT contigs
##
## Runtime parameters are optimized for Broad's Google Cloud Platform implementation.
## For program versions, see docker containers.
##
## LICENSING :
## This script is released under the WDL source code license (BSD-3) (see LICENSE in
## https://github.com/broadinstitute/wdl). Note however that the programs it calls may
## be subject to different licenses. Users are responsible for checking that they are
## authorized to run all programs before running this script. Please see the docker
## page at https://hub.docker.com/r/broadinstitute/genomes-in-the-cloud/ for detailed
## licensing information pertaining to the included programs.

import "../../../../../../pipelines/broad/dna_seq/germline/single_sample/wgs/WholeGenomeGermlineSingleSample.wdl" as BroadPipeline
import "../../../../../../structs/dna_seq/DNASeqStructs.wdl"

# WORKFLOW DEFINITION
workflow VUMCWholeGenomeGermlineSingleSampleFromFastq {

  String pipeline_version = "3.1.7.1.beta"

  input {
    # Optional for VUMC pipeline
    String sample_name 
    String fastq_1 
    String fastq_2 
    String readgroup_name 
    String? library_name 
    String? platform_unit 
    String? run_date 
    String? platform_name 
    String? sequencing_center 

    # Optional for BROAD pipeline
    DNASeqSingleSampleReferences references
    DragmapReference? dragmap_reference
    VariantCallingScatterSettings scatter_settings
    PapiSettings papi_settings

    File? fingerprint_genotypes_file
    File? fingerprint_genotypes_index

    File wgs_coverage_interval_list

    Boolean provide_bam_output = false
    Boolean use_gatk3_haplotype_caller = true

    Boolean dragen_functional_equivalence_mode = false
    Boolean dragen_maximum_quality_mode = false

    Boolean run_dragen_mode_variant_calling = false
    Boolean use_spanning_event_genotyping = true
    Boolean unmap_contaminant_reads = true
    Boolean perform_bqsr = true
    Boolean use_bwa_mem = true
    Boolean allow_empty_ref_alt = false
    Boolean use_dragen_hard_filtering = false
  }

  # Convert pair of FASTQs to uBAM
  call PairedFastQsToUnmappedBAM {
    input:
      sample_name = sample_name,
      fastq_1 = fastq_1,
      fastq_2 = fastq_2,
      readgroup_name = readgroup_name,
      library_name = library_name,
      platform_unit = platform_unit,
      run_date = run_date,
      platform_name = platform_name,
      sequencing_center = sequencing_center,
  }

  SampleAndUnmappedBams sample_and_unmapped_bams = object {
    base_file_name: sample_name,
    final_gvcf_base_name: sample_name,
    flowcell_unmapped_bams: [ PairedFastQsToUnmappedBAM.output_unmapped_bam ],
    sample_name: sample_name,
    unmapped_bam_suffix: ".bam"
  }

  call BroadPipeline.WholeGenomeGermlineSingleSample as broad {
    input:
      sample_and_unmapped_bams = sample_and_unmapped_bams,
      references = references,
      dragmap_reference = dragmap_reference,
      scatter_settings = scatter_settings,
      papi_settings = papi_settings,
      fingerprint_genotypes_file = fingerprint_genotypes_file,
      fingerprint_genotypes_index = fingerprint_genotypes_index,
      wgs_coverage_interval_list = wgs_coverage_interval_list,
      provide_bam_output = provide_bam_output,
      use_gatk3_haplotype_caller = use_gatk3_haplotype_caller,
      dragen_functional_equivalence_mode = dragen_functional_equivalence_mode,
      dragen_maximum_quality_mode = dragen_maximum_quality_mode,
      run_dragen_mode_variant_calling = run_dragen_mode_variant_calling,
      use_spanning_event_genotyping = use_spanning_event_genotyping,
      unmap_contaminant_reads = unmap_contaminant_reads,
      perform_bqsr = perform_bqsr,
      use_bwa_mem = use_bwa_mem,
      allow_empty_ref_alt = allow_empty_ref_alt,
      use_dragen_hard_filtering = use_dragen_hard_filtering
  }

  # Outputs that will be retained when execution is complete
  output {
    Array[File] quality_yield_metrics = broad.quality_yield_metrics

    Array[File] unsorted_read_group_base_distribution_by_cycle_pdf = broad.unsorted_read_group_base_distribution_by_cycle_pdf
    Array[File] unsorted_read_group_base_distribution_by_cycle_metrics = broad.unsorted_read_group_base_distribution_by_cycle_metrics
    Array[File] unsorted_read_group_insert_size_histogram_pdf = broad.unsorted_read_group_insert_size_histogram_pdf
    Array[File] unsorted_read_group_insert_size_metrics = broad.unsorted_read_group_insert_size_metrics
    Array[File] unsorted_read_group_quality_by_cycle_pdf = broad.unsorted_read_group_quality_by_cycle_pdf
    Array[File] unsorted_read_group_quality_by_cycle_metrics = broad.unsorted_read_group_quality_by_cycle_metrics
    Array[File] unsorted_read_group_quality_distribution_pdf = broad.unsorted_read_group_quality_distribution_pdf
    Array[File] unsorted_read_group_quality_distribution_metrics = broad.unsorted_read_group_quality_distribution_metrics

    File read_group_alignment_summary_metrics = broad.read_group_alignment_summary_metrics
    File read_group_gc_bias_detail_metrics = broad.read_group_gc_bias_detail_metrics
    File read_group_gc_bias_pdf = broad.read_group_gc_bias_pdf
    File read_group_gc_bias_summary_metrics = broad.read_group_gc_bias_summary_metrics

    File? cross_check_fingerprints_metrics = broad.cross_check_fingerprints_metrics

    File selfSM = broad.selfSM
    Float contamination = broad.contamination

    File calculate_read_group_checksum_md5 = broad.calculate_read_group_checksum_md5

    File agg_alignment_summary_metrics = broad.agg_alignment_summary_metrics
    File agg_bait_bias_detail_metrics = broad.agg_bait_bias_detail_metrics
    File agg_bait_bias_summary_metrics = broad.agg_bait_bias_summary_metrics
    File agg_gc_bias_detail_metrics = broad.agg_gc_bias_detail_metrics
    File agg_gc_bias_pdf = broad.agg_gc_bias_pdf
    File agg_gc_bias_summary_metrics = broad.agg_gc_bias_summary_metrics
    File agg_insert_size_histogram_pdf = broad.agg_insert_size_histogram_pdf
    File agg_insert_size_metrics = broad.agg_insert_size_metrics
    File agg_pre_adapter_detail_metrics = broad.agg_pre_adapter_detail_metrics
    File agg_pre_adapter_summary_metrics = broad.agg_pre_adapter_summary_metrics
    File agg_quality_distribution_pdf = broad.agg_quality_distribution_pdf
    File agg_quality_distribution_metrics = broad.agg_quality_distribution_metrics
    File agg_error_summary_metrics = broad.agg_error_summary_metrics

    File? fingerprint_summary_metrics = broad.fingerprint_summary_metrics
    File? fingerprint_detail_metrics = broad.fingerprint_detail_metrics

    File wgs_metrics = broad.wgs_metrics
    File raw_wgs_metrics = broad.raw_wgs_metrics

    File duplicate_metrics = broad.duplicate_metrics
    File? output_bqsr_reports = broad.output_bqsr_reports

    File gvcf_summary_metrics = broad.gvcf_summary_metrics
    File gvcf_detail_metrics = broad.gvcf_detail_metrics

    File? output_bam = broad.output_bam
    File? output_bam_index = broad.output_bam_index

    File output_cram = broad.output_cram
    File output_cram_index = broad.output_cram_index
    File output_cram_md5 = broad.output_cram_md5

    File validate_cram_file_report = broad.validate_cram_file_report

    File output_vcf = broad.output_vcf
    File output_vcf_index = broad.output_vcf_index
  }
  meta {
    allowNestedInputs: true
  }
}

# Convert a pair of FASTQs to uBAM
task PairedFastQsToUnmappedBAM {
  input {
    # Command parameters
    String sample_name
    File fastq_1
    File fastq_2
    String readgroup_name
    String? library_name 
    String? platform_unit 
    String? run_date 
    String? platform_name 
    String? sequencing_center 

    # Runtime parameters
    Int addtional_disk_space_gb = 100
    Int machine_mem_gb = 7
    Int preemptible_attempts = 3

    # Sometimes the output is larger than the input, or a task can spill to disk.
    # In these cases we need to account for the input (1) and the output (1.5) or the input(1), the output(1), and spillage (.5).
    Float disk_multiplier = 2.5

    String docker = "broadinstitute/gatk:latest"
    String gatk_path = "/gatk/gatk"
  }
  Int command_mem_gb = machine_mem_gb - 1
  Float fastq_size = size(fastq_1, "GB") + size(fastq_2, "GB")
  Int disk_space_gb = ceil(fastq_size + (fastq_size * disk_multiplier ) + addtional_disk_space_gb)
  command {
    ~{gatk_path} --java-options "-Xmx~{command_mem_gb}g" \
      FastqToSam \
      --FASTQ ~{fastq_1} \
      --FASTQ2 ~{fastq_2} \
      --OUTPUT ~{sample_name}.unmapped.bam \
      --SAMPLE_NAME ~{sample_name} \
      ~{"--LIBRARY_NAME " + library_name} \
      ~{"--PLATFORM_UNIT " + platform_unit} \
      ~{"--RUN_DATE " + run_date} \
      ~{"--PLATFORM " + platform_name} \
      ~{"--SEQUENCING_CENTER " + sequencing_center} \
      --READ_GROUP_NAME ~{readgroup_name}
  }
  runtime {
    docker: docker
    memory: machine_mem_gb + " GB"
    disks: "local-disk " + disk_space_gb + " HDD"
    preemptible: preemptible_attempts
  }
  output {
    File output_unmapped_bam = "~{sample_name}.unmapped.bam"
  }
}
