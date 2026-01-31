#!/bin/bash

# Directorio de las muestras
samples_dir=$1   
# Directorio de salida
output_dir=$2    
# ID de la muestra
sample_id=$3    

# Crea el directorio de salida si no existe
mkdir -p $output_dir

# Verifica si existen archivos para fusionar
files_to_merge=($samples_dir/*$sample_id*.fastq.gz)

if [ ${#files_to_merge[@]} -eq 0 ]; then
    echo "No se encontraron archivos para la muestra $sample_id en $samples_dir"
    exit 1
fi

echo "Archivos encontrados para la muestra $sample_id: ${files_to_merge[@]}"

# Fusiona todos los archivos FastQ de la muestra en un solo archivo
cat "${files_to_merge[@]}" > $output_dir/$sample_id.fastq.gz



