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

import "../../../../../../tasks/broad/BamProcessing.wdl" as Processing
import "../../../../../../tasks/broad/Qc.wdl" as QC
import "../../../../../../tasks/broad/AggregatedBamQC.wdl" as AggregatedQC
import "../../../../../../structs/dna_seq/DNASeqStructs.wdl"

# WORKFLOW DEFINITION
workflow VUMCMappedCramQC {

  String pipeline_version = "1.0.0.0"

  input {
    File input_cram
    File input_cram_index

    String sample_name

    DNASeqSingleSampleReferences references
    PapiSettings papi_settings

    File wgs_coverage_interval_list
  }

  String recalibrated_bam_basename = sample_name + ".aligned.duplicates_marked.recalibrated"

  call AggregatedQC.AggregatedBamQC {
    input:
      base_recalibrated_bam = input_cram,
      base_recalibrated_bam_index = input_cram_index,
      base_name = sample_name,
      sample_name = sample_name,
      recalibrated_bam_base_name = recalibrated_bam_basename,
      haplotype_database_file = references.haplotype_database_file,
      references = references,
      papi_settings = papi_settings
  }

  # QC the sample WGS metrics (stringent thresholds)
  call QC.CollectWgsMetrics as CollectWgsMetrics {
    input:
      input_bam = input_cram,
      input_bam_index = input_cram_index,
      metrics_filename = sample_name + ".wgs_metrics",
      ref_fasta = references.reference_fasta.ref_fasta,
      ref_fasta_index = references.reference_fasta.ref_fasta_index,
      wgs_coverage_interval_list = wgs_coverage_interval_list,
      preemptible_tries = papi_settings.agg_preemptible_tries
  }

  # QC the sample raw WGS metrics (common thresholds)
  call QC.CollectRawWgsMetrics as CollectRawWgsMetrics {
    input:
      input_bam = input_cram,
      input_bam_index = input_cram_index,
      metrics_filename = sample_name + ".raw_wgs_metrics",
      ref_fasta = references.reference_fasta.ref_fasta,
      ref_fasta_index = references.reference_fasta.ref_fasta_index,
      wgs_coverage_interval_list = wgs_coverage_interval_list,
      preemptible_tries = papi_settings.agg_preemptible_tries
  }

  # Outputs that will be retained when execution is complete
  output {
    File read_group_alignment_summary_metrics = AggregatedBamQC.read_group_alignment_summary_metrics
    File read_group_gc_bias_detail_metrics = AggregatedBamQC.read_group_gc_bias_detail_metrics
    File read_group_gc_bias_pdf = AggregatedBamQC.read_group_gc_bias_pdf
    File read_group_gc_bias_summary_metrics = AggregatedBamQC.read_group_gc_bias_summary_metrics

    File agg_alignment_summary_metrics = AggregatedBamQC.agg_alignment_summary_metrics
    File agg_bait_bias_detail_metrics = AggregatedBamQC.agg_bait_bias_detail_metrics
    File agg_bait_bias_summary_metrics = AggregatedBamQC.agg_bait_bias_summary_metrics
    File agg_gc_bias_detail_metrics = AggregatedBamQC.agg_gc_bias_detail_metrics
    File agg_gc_bias_pdf = AggregatedBamQC.agg_gc_bias_pdf
    File agg_gc_bias_summary_metrics = AggregatedBamQC.agg_gc_bias_summary_metrics
    File agg_insert_size_histogram_pdf = AggregatedBamQC.agg_insert_size_histogram_pdf
    File agg_insert_size_metrics = AggregatedBamQC.agg_insert_size_metrics
    File agg_pre_adapter_detail_metrics = AggregatedBamQC.agg_pre_adapter_detail_metrics
    File agg_pre_adapter_summary_metrics = AggregatedBamQC.agg_pre_adapter_summary_metrics
    File agg_quality_distribution_pdf = AggregatedBamQC.agg_quality_distribution_pdf
    File agg_quality_distribution_metrics = AggregatedBamQC.agg_quality_distribution_metrics
    File agg_error_summary_metrics = AggregatedBamQC.agg_error_summary_metrics

    File wgs_metrics = CollectWgsMetrics.metrics
    File raw_wgs_metrics = CollectRawWgsMetrics.metrics
  }
  meta {
    allowNestedInputs: true
  }
}
