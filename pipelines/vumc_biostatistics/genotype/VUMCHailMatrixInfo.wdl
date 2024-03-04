version 1.0

workflow VUMCHailMatrixInfo {
  input {
    String prefix
    String input_hail_mt_path

    String reference_genome = "GRCh38"

    String? project_id
  }

  call HailMatrixInfo {
    input:
      prefix = prefix,
      input_hail_mt_path = input_hail_mt_path,
      reference_genome = reference_genome,
      project_id = project_id,
  }

  output {
    String sample_file = HailMatrixInfo.sample_file
    Int num_samples = HailMatrixInfo.num_samples
    Int num_variants = HailMatrixInfo.num_variants
  }
}

task HailMatrixInfo {
  input {
    String prefix
    String input_hail_mt_path
    String reference_genome
    String? project_id

    String docker = "shengqh/hail_gcp:20240213"
    Int memory_gb = 2
    Int preemptible = 1
  }

  String output_sample_file = "${prefix}.samples"

  command <<<

#https://discuss.hail.is/t/i-get-a-negativearraysizeexception-when-loading-a-plink-file/899
export PYSPARK_SUBMIT_ARGS="--driver-java-options '-XX:hashCode=0' --conf 'spark.executor.extraJavaOptions=-XX:hashCode=0' pyspark-shell"

mkdir -p ./tmp

python3 <<CODE

import hail as hl

if "~{project_id}" == "":
  hl.init(spark_conf={
    "spark.driver.memory": "~{memory_gb}g",
    "spark.local.dir": "./tmp"
  },
  tmp_dir="./tmp",
  local_tmpdir="./tmp",
  idempotent=True)
else:
  hl.init(spark_conf={
    "spark.driver.memory": "~{memory_gb}g",
    "spark.local.dir": "./tmp",
    'spark.hadoop.fs.gs.requester.pays.mode': 'AUTO',
    'spark.hadoop.fs.gs.requester.pays.project.id': "~{project_id}"
  },
  tmp_dir="./tmp",
  local_tmpdir="./tmp",
  idempotent=True)

hl.default_reference("~{reference_genome}")

mt = hl.read_matrix_table("~{input_hail_mt_path}")

with open("num_samples.txt", "wt") as fout:
  fout.write(f"{mt.count_cols()}")

with open("num_variants.txt", "wt") as fout:
  fout.write(f"{mt.count_rows()}")

with open("~{output_sample_file}", "wt") as fout:
  for s in mt.s.collect():
    fout.write(f"{s}\n")

CODE

>>>

  runtime {
    cpu: 1
    docker: "~{docker}"
    preemptible: preemptible
    disks: "local-disk 4 HDD"
    memory: "~{memory_gb} GiB"
  }
  output {
    String sample_file = "~{output_sample_file}"
    Int num_samples = read_int("num_samples.txt")
    Int num_variants = read_int("num_variants.txt")
  }
}
