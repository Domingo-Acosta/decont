#!/bin/bash

# URL del archivo de contaminantes
contaminants_url=$1
# Directorio de salida
dir=$2

# Descarga el archivo de contaminantes
echo "Descargando el archivo de contaminantes desde $contaminants_url..."
wget -P $dir $contaminants_url

# Saca el nombre del archivo desde la URL
filename=$(basename $contaminants_url)

# Descomprime el archivo si es .gz
if [[ "$filename" == *.gz ]]; then
    gunzip $dir/$filename
    filename_without_ext="${filename%.gz}"
else
    filename_without_ext=$filename
fi

# Filtra las secuencias de ARN pequeños nucleares (snRNA)
echo "Filtrando las secuencias de ARN pequeños nucleares..."
awk '/^>/ {if ($0 !~ /small nuclear/) print ">"$0; next} {print $0}' $dir/$filename_without_ext > $dir/filtered_$filename_without_ext

echo "Contaminantes descargados y filtrados."
