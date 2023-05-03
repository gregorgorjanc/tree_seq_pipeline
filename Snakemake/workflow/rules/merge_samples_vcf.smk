import yaml
#vcfdir = "vcfDir"
#chromosomes = [f'Chr{n}' for n in range(1, 3)]

if len(allFiles) != 1:
    rule get_samples:
        input:
            [f'{vcfdir}' + x
                for x in expand('/{{chromosome}}/{{chromosome}}_{suffixOne}.vcf.gz',
                    suffixOne = splitFiles)] if len(splitFiles) != 0 else [],
            [f'{vcfdir}' + x
                for x in expand('/{{chromosome}}/{{chromosome}}_{suffixTwo}.vcf.gz',
                    suffixTwo = combinedFiles)] if len(combinedFiles) != 0 else []
        output: temp(f'{vcfdir}/{{chromosome}}/{{chromosome}}_{{file}}.txt')
        shell:
            """
            bcftools query -l {input} > {output}
            """

#     # Executes per chromosome! Takes all .txt files at once, compare and remove
#     # duplicates, and write a new temporary .txt for each one.
    rule compare:
        input:
            [f'{vcfdir}' + x
                for x in expand('/{{chromosome}}/{{chromosome}}_{file}.txt',
                    file=allFiles)]
        output:
            temp([f'{vcfdir}' + x for x in
                expand('/{{chromosome}}/{{chromosome}}_{file}.filtered',
                    file=allFiles)])
# #         log: expand('logs/{{chromosome}}_{file}.log', file=allfiles)
        run:
            from itertools import combinations
            samplelist=[]
            for ifile in input:
                with open(ifile, 'r') as f:
                    samplelist.append(f.read().splitlines())

            for a, b in combinations(samplelist, 2):
                [b.remove(element) for element in a if element in b]

            for i, ofile in enumerate(output):
                with open(ofile, 'w') as f:
                    [f.write(f'{line}\n') for line in samplelist[i]]
                    f.close()
#
# #     # Executes for all chromosomes all files at once. Takes .txt and .vcf as input
# #     # and filters the vcfs based on the new filtered samples list. index the output.
    rule filter:
        input:
            vcf = f'{vcfdir}/{{chromosome}}/{{chromosome}}_{{file}}.vcf.gz',
            ids = f'{vcfdir}/{{chromosome}}/{{chromosome}}_{{file}}.filtered'
        output: f'{vcfdir}/{{chromosome}}/{{chromosome}}_{{file}}.filtered.vcf.gz'
#         conda:
#             'envs/vcfEdit.yaml'
#         log: 'logs/{chromosome}_{file}.log'
        shell:
            """
            bcftools view -S {input.ids} --force-samples {input.vcf} -O z -o {output}
            bcftools index {output}
            """
#
# #     # Again takes all files for each chromosome at once.
# #     # Merges all vcfs and indexes them.
# #     # Outputs the final merged vcf for each chromosome directly in the vcfDir.
    rule merge:
        input: [f'{vcfdir}' + x for x in expand('/{{chromosome}}/{{chromosome}}_{file}.filtered.vcf.gz', file=allFiles)]
        output: f'{vcfdir}/{{chromosome}}_final.vcf.gz'
#         conda:
#             'env/vcfEdit.yaml'
#         log: 'logs/{chromosome}_merged.log'
        shell:
            """
            bcftools merge -m all {input} -O z -o {output}
            bcftools index {output}
            """

else:
    rule rename:
        input:
            [f'{vcfdir}' + x
                for x in expand('/{{chromosome}}/{{chromosome}}_{file}.vcf.gz',
                    suffixOne = splitFiles)] if len(splitFiles) != 0 else [],
            [f'{vcfdir}' + x
                for x in expand('/{{chromosome}}/{{chromosome}}_{file}.vcf.gz',
                    suffixTwo = combinedFiles)] if len(combinedFiles) != 0 else []
        output:
            f'{vcfdir}/{{chromosome}}_final.vcf.gz'
        shell:
            "mv {file} {output}"