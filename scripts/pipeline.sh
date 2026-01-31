#!/bin/bash

# Crea los directorios necesarios si no existen
mkdir -p out/merged out/star out/trimmed log/cutadapt res

# Descarga todos los archivos de las URLs del archivo data/urls
bash scripts/download.sh data/urls data

# Descarga el archivo FASTA de contaminantes, lo descomprime y lo filtra para eliminar los ARN nucleares pequeños
bash scripts/contaminants.sh https://masterbioinformatica.com/decont/contaminants.fasta.gz res

# Indexa el archivo de contaminantes
bash scripts/index.sh res/filtered_contaminants.fasta res/contaminants_idx

# Genera la lista de sample_ids basada en los archivos en data/
data_dir="data"
output_file="list_of_sample_ids"
> $output_file

# Recorre todos los archivos FastQ en el directorio y extraer los sample_ids
for file in $data_dir/*.fastq.gz
do
    # Extrae el sample_id del nombre del archivo
    # Suponemos que el sample_id es la primera parte antes del primer guión (-)
    sample_id=$(basename "$file" | cut -d'-' -f1)
    
    # Agrega el sample_id al archivo de salida, si no está ya en la lista
    if ! grep -q "$sample_id" $output_file; then
        echo $sample_id >> $output_file
    fi
done

# Fusiona las muestras en un solo archivo
while IFS= read -r sid; do
    bash scripts/merge_fastqs.sh data out/merged "$sid"
done < list_of_sample_ids

# Ejecuta cutadapt para todos los archivos fusionados
echo "Ejecutando cutadapt para todos los archivos fusionados..." | tee -a log/cutadapt.log
for input_file in out/merged/*.fastq.gz
do
    # Extrae el nombre de archivo base (sin la ruta)
    filename=$(basename "$input_file")
    # Genera el nombre del archivo recortado
    trimmed_file="out/trimmed/${filename%.fastq.gz}.trimmed.fastq.gz"
    # Genera el nombre del archivo de log para cutadapt
    log_file="log/cutadapt/${filename%.fastq.gz}.log"
    
    echo "Ejecutando cutadapt en $input_file..." | tee -a log/cutadapt.log
    cutadapt -m 18 -a TGGAATTCTCGGGTGCCAAGG --discard-untrimmed \
        -o $trimmed_file $input_file > $log_file 2>&1

    # Agrega la información de cutadapt al log general
    echo "Resumen de cutadapt para $filename:" >> log/cutadapt.log
    grep -E "Reads with adapters|Total basepairs" $log_file >> log/cutadapt.log
done

echo "Iniciando mapeo con STAR..."

# El árbol muestra log/pipeline.log, así que lo definimos así:
summary_log="log/pipeline.log"
# Limpia el log si ya existe para empezar de cero
> $summary_log

for trimmed_file in out/trimmed/*.trimmed.fastq.gz
do
    # Extrae el Sample ID
    # Si el archivo es out/trimmed/C57BL_6NJ.trimmed.fastq.gz -> sid será C57BL_6NJ
    filename=$(basename "$trimmed_file")
    sid=${filename%.trimmed.fastq.gz}

    echo "Procesando STAR para la muestra: $sid"
    
    # Crea el subdirectorio para la muestra en out/star/
    mkdir -p out/star/$sid

    # Ejecuta STAR
    STAR --runThreadN 4 \
         --genomeDir res/contaminants_idx \
         --outReadsUnmapped Fastx \
         --readFilesIn $trimmed_file \
         --readFilesCommand gunzip -c \
         --outFileNamePrefix out/star/$sid/

# Genera el log
    
    echo "Muestra: $sid" >> $summary_log
    
    # Extrae de Cutadapt (usando el log que creaste en el paso anterior)
    cutadapt_log="log/cutadapt/${sid}.log"
    
    echo "  [Cutadapt]" >> $summary_log
    grep "Reads with adapters" $cutadapt_log | sed 's/^/    /' >> $summary_log
    grep "Total basepairs" $cutadapt_log | sed 's/^/    /' >> $summary_log
    
    # Extrae de STAR (del archivo Log.final.out que genera STAR)
    star_log="out/star/$sid/Log.final.out"
    
    echo "  [STAR]" >> $summary_log
    grep "Uniquely mapped reads %" $star_log | sed 's/^/    /' >> $summary_log
    grep "% of reads mapped to multiple loci" $star_log | sed 's/^/    /' >> $summary_log
    grep "% of reads mapped to too many loci" $star_log | sed 's/^/    /' >> $summary_log
    echo "------------------------------------------" >> $summary_log
    
done

echo "Fin. Un saludo, Tomás :)"






