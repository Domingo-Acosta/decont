#!/bin/bash

# Contaminantes
contaminants_fasta=$1
# Directorio de salida
output_dir=$2

# Crea el directorio de salida si no existe
mkdir -p $output_dir

# Usa STAR para indexar el archivo de contaminantes
echo "Indexando el archivo de contaminantes..."

STAR --runThreadN 4 --runMode genomeGenerate --genomeDir $output_dir \
--genomeFastaFiles $contaminants_fasta --genomeSAindexNbases 9

echo "Indexación completada."

