#!/bin/bash

# Archivo de texto con las URLs
urls_file=$1
# Directorio de salida
dir=$2

# Se asegura de que el directorio de destino exista
mkdir -p $dir

# Lee el archivo de URLs línea por línea y descargar los archivos
while IFS= read -r url
do
    # Descarga el archivo
    echo "Descargando archivo desde $url..."
    wget -P $dir $url

    # Saca el nombre del archivo desde la URL
    filename=$(basename $url)

done < "$urls_file"

echo "Archivos descargados."

