#!/bin/bash

# Crea los directorios necesarios si no existen
mkdir -p out/merged out/star out/trimmed log/cutadapt res

# BONUS: Descarga archivos con wget si no existen
wget -nc -i data/urls -P data

# Descarga y filtra contaminantes
bash scripts/contaminants.sh https://masterbioinformatica.com/decont/contaminants.fasta.gz res

# BONUS: Indexa solo si no existe el índice
if [ ! -d "res/contaminants_idx" ] || [ -z "$(ls -A res/contaminants_idx)" ]; then
    bash scripts/index.sh res/filtered_contaminants.fasta res/contaminants_idx
else
    echo "El índice de contaminantes ya existe. Saltando..."
fi

# Genera la lista de sample_ids
data_dir="data"
output_file="list_of_sample_ids"
> $output_file

for file in $data_dir/*.fastq.gz
do
    sample_id=$(basename "$file" | cut -d'-' -f1)
    if ! grep -q "$sample_id" $output_file; then
        echo $sample_id >> $output_file
    fi
done

# Fusiona las muestras
while IFS= read -r sid; do
    # BONUS: Solo fusiona si el archivo de salida no existe
    if [ ! -f "out/merged/${sid}.fastq.gz" ]; then
        bash scripts/merge_fastqs.sh data out/merged "$sid"
    else
        echo "Muestra $sid ya fusionada. Saltando..."
    fi
done < list_of_sample_ids

# Ejecuta cutadapt
echo "Ejecutando cutadapt..." | tee -a log/cutadapt.log
for input_file in out/merged/*.fastq.gz
do
    filename=$(basename "$input_file")
    trimmed_file="out/trimmed/${filename%.fastq.gz}.trimmed.fastq.gz"
    log_file="log/cutadapt/${filename%.fastq.gz}.log"
    
    # BONUS: Comprueba antes de inciar cutadapt
    if [ -f "$trimmed_file" ]; then
        echo "Archivo $filename ya recortado (trimmed). Saltando..."
    else
        echo "Ejecutando cutadapt en $input_file..." | tee -a log/cutadapt.log
        cutadapt -m 18 -a TGGAATTCTCGGGTGCCAAGG --discard-untrimmed \
            -o $trimmed_file $input_file > $log_file 2>&1
    fi

    echo "Resumen de cutadapt para $filename:" >> log/cutadapt.log
    [ -f "$log_file" ] && grep -E "Reads with adapters|Total basepairs" $log_file >> log/cutadapt.log
done

echo "Iniciando mapeo con STAR..."

summary_log="log/pipeline.log"
> $summary_log

for trimmed_file in out/trimmed/*.trimmed.fastq.gz
do
    filename=$(basename "$trimmed_file")
    sid=${filename%.trimmed.fastq.gz}

    echo "Procesando STAR para la muestra: $sid"
    mkdir -p out/star/$sid
    
    # BONUS: Comprueba antes de inciar STAR
    if [ -f "out/star/$sid/Log.final.out" ]; then
       echo "Muestra $sid ya procesada por STAR. Saltando..."
    else
        STAR --runThreadN 4 \
             --genomeDir res/contaminants_idx \
             --outReadsUnmapped Fastx \
             --readFilesIn $trimmed_file \
             --readFilesCommand gunzip -c \
             --outFileNamePrefix out/star/$sid/
    fi
    
    # Genera Log Summary
    echo "Muestra: $sid" >> $summary_log
    cutadapt_log="log/cutadapt/${sid}.log"
    
    echo "  [Cutadapt]" >> $summary_log
    [ -f "$cutadapt_log" ] && grep "Reads with adapters" $cutadapt_log | sed 's/^/    /' >> $summary_log
    
    star_log="out/star/$sid/Log.final.out"
    echo "  [STAR]" >> $summary_log
    [ -f "$star_log" ] && grep "Uniquely mapped reads %" $star_log | sed 's/^/    /' >> $summary_log
    echo "------------------------------------------" >> $summary_log
done

echo "Si desea eliminar archivos temporales, ejecute: bash scripts/cleanup.sh [data|resources|output|logs]"

echo "Fin. Un saludo, Tomás :)"





