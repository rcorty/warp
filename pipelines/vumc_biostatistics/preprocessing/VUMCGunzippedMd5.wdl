version 1.0

workflow VUMCGunzippedMd5 {
  input {
    String gzipped_file
  }

  call Md5File {
    input:
      gzipped_file = gzipped_file,
  }

  output {
    String gunzipped_md5 = Md5File.gunzipped_md5
  }
}

task Md5File {
  input {
    String gzipped_file
  }

  String md5_file = "md5.txt"

  command <<<
gzip -d -c ~{gzipped_file} | md5sum | cut -d ' ' -f1 > ~{md5_file}
>>>

  runtime {
    docker: "ubuntu:latest"
    preemptible: 1
    disks: "local-disk 10 HDD"
    memory: "2 GiB"
  }
  output {
    String gunzipped_md5 = read_string("~{md5_file}")
  }
}