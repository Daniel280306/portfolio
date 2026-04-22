#!/bin/bash

# Verificar argumentos
if [ $# -ne 2 ]; then
    echo "Uso: $0 <pasta_dos_clientes> <max_processos>"
    exit 1
fi

echo "Analises começando!"

# definir variaveis dos argumentos
PASTA=$1
MAX_PROCESSOS=$2

# verificar se a pasta existe
if ! [ -d ${PASTA} ]; then
	echo "ERRO: A pasta ${PASTA} não existe"
	exit 1
fi

# percorrer ficheiros csv nas pasta
num_proc_ativos=0

for ficheiro in ${PASTA}/*.csv; do

	if [ ${num_proc_ativos} -ge ${MAX_PROCESSOS} ]; then
		wait -n
		num_proc_ativos=$((num_proc_ativos-1))
	fi

	python3 analisar_cliente.py ${ficheiro} &
	num_proc_ativos=$((num_proc_ativos+1))

done

wait

echo "Todas as análises concluídas."





