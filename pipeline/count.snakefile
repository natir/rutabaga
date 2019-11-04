###############################################################################
# Manage input and output                                                     #
###############################################################################
inputs = {
    "s_pneumoniae": ["reads/SRR8556426.fasta"],
    "c_vartiovaarae": ["reads/ERR1877966.fasta", "reads/ERR1877967.fasta", "reads/ERR1877968.fasta", "reads/ERR1877969.fasta", "reads/ERR1877970.fasta"],
    "e_coli_ont": ["reads/SRR8494940.fasta"],
    "e_coli_pb": ["reads/SRR8494911.fasta"],
    "s_cerevisiae": ["reads/SRR2157264_1.fasta", "reads/SRR2157264_2.fasta"],
}

outputs = {
    "s_pneumoniae": "count/s_pneumoniae",
    "c_vartiovaarae": "count/c_vartiovaarae",
    "e_coli_ont": "count/e_coli_ont",
    "e_coli_pb": "count/e_coli_pb",
    "s_cerevisiae": "count/s_cerevisiae",
}

def generate_output(dataset, k, suffix):
    return outputs[dataset] + ".k" + k + "." + suffix

def generate_all_output(suffix):
    for dataset in outputs.keys():
        for k in range(13, 21, 2) :
            yield generate_output(dataset, str(k), suffix)


###############################################################################
# Section PCON                                                                #
###############################################################################
rule pcon:
    input:
        lambda wildcards: inputs[wildcards.dataset_name]
    output:
        "count/{dataset_name}.k{kmer_size}.pcon"
    benchmark:
        "benchmark/pcon/{dataset_name}.k{kmer_size}.tsv"
    resources:
        mem_mb = lambda wcd: round((pow(2, 2 * wcd.kmer_size - 1)/2)/1000000)+10
    shell:
        "pcon count -i {input} -o {output} -k {wildcards.kmer_size} -m 1"

rule all_pcon:
    input:
        list(generate_all_output("pcon")),
        
###############################################################################
# Section KMC                                                                 #
###############################################################################
rule kmc:
    input:
        lambda wildcards: inputs[wildcards.dataset_name]
    output:
        "count/{dataset_name}.k{kmer_size}.kmc.kmc_suf",
    benchmark:
        "benchmark/kmc/{dataset_name}.k{kmer_size}.tsv"
    shell:
        " && ".join([
            "mkdir -p kmc_workdir/{wildcards.dataset_name}",
            "mkdir -p kmc_file_input",
            "echo {input} > kmc_file_input/{wildcards.dataset_name}.lst",
            "sed -i 's/ /\\n/g' kmc_file_input/{wildcards.dataset_name}.lst",
            "kmc -k{wildcards.kmer_size} -t1 -fa @kmc_file_input/{wildcards.dataset_name}.lst count/{wildcards.dataset_name}.k{wildcards.kmer_size}.kmc kmc_workdir/{wildcards.dataset_name}",
            ])

rule all_kmc:
    input:
        generate_all_output("kmc.kmc_suf"),

###############################################################################
# Section JELLYFISH                                                           #
###############################################################################
rule jellyfish:
    input:
        lambda wildcards: inputs[wildcards.dataset_name]
    output:
        "count/{dataset_name}.k{kmer_size}.jellyfish"
    benchmark:
        "benchmark/jellyfish/{dataset_name}.k{kmer_size}.tsv"
    shell:
        "jellyfish count -m{wildcards.kmer_size} -t1 -s6G -C -o {output} {input}"
          
rule all_jellyfish:
    input:
        generate_all_output("jellyfish"),
        
rule count_all:
    input:
        rules.all_pcon.input,
        rules.all_kmc.input,
        rules.all_jellyfish.input,


