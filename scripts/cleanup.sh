#!/bin/bash

# Si no hay argumentos, borrar todo
if [ $# -eq 0 ]; then
    rm -rf data/*.fastq.gz res/* out/* log/* list_of_sample_ids
    echo "Todo limpio."
    exit 0
fi

# Procesa argumentos específicos
for arg in "$@"; do
    case $arg in
        data)
            rm -rf data/*.fastq.gz
            echo "Datos eliminados."
            ;;
        resources)
            rm -rf res/*
            echo "Recursos eliminados."
            ;;
        output)
            rm -rf out/*
            echo "Outputs eliminados."
            ;;
        logs)
            rm -rf log/*
            echo "Logs eliminados."
            ;;
        *)
            echo "Argumento no reconocido: $arg"
            ;;
    esac
done
