#!/usr/bin/env python3

# imports:

import signal
import pickle
import struct
import os, sys, csv
from time import sleep
from multiprocessing import Process, Queue, Semaphore, Value, Lock, Array


# Verificar argumento
arg = sys.argv[1]
if not os.path.exists(arg):	#se o ficheiro nao existir:
	print(f"ERRO: o ficheiro {arg} não existe")
	exit()	#sair

# Recursos partilhados
R_StockWarehouse = Semaphore(1)
R_DeliveryCapacity = Semaphore(1)

P_Expensive_recursos = Array("i", 2)	# ex.: [1,0] = R_StockWarehouse ocupado ; R_DeliveryCapacity livre . (1=ocupado; 0=livre)
P_Special_recursos = Array("i", 2)

# vars globais
total_gasto=Value("d", 0)
customer = os.path.splitext(os.path.basename(arg))[0]

MAX_SIZE=3	#tamanho do buffer - NAO SEI QUAL É
T = 3	#tempo do P_TotalWorker

lock_escrita = Lock()	#lock usado para segurar que os 2 processos nao escrevem ao mesmo tempo no binario

open("ledger.bin", "wb").close	#apagar dados anteriores do bin

# buffer circular partilhado
class BufferCircular:
	def __init__(self):
		self.tamanho = 5
		self.buffer = Array("c", 250 * self.tamanho)
		self.counter_leitura = Array("i", self.tamanho)
		self.counter_leitura_mutex = Lock()
		self.empty = Semaphore(self.tamanho)

		#semaforos full reservados para cada processo
		self.full1 = Semaphore(0)
		self.full2 = Semaphore(0)
		self.full3 = Semaphore(0)
		self.fulls = [self.full1, self.full2, self.full3]

		self.inPosition = Value("i", 0)	#pointer de escrita
		self.outPositions = Array("i", 3)	#array dos 3 pointers de cada processo

	def estado(self):	#metodo para printar estado das slots e dos pointers
		print("============================ SLOTS =============================")
		for i in range(self.tamanho):
			data = pickle.loads(self.buffer[0+(250*i):250+(250*i)])
			print(f"slot {i}: {data}")

		print("---------------------------- POINTERS --------------------------")
		print(f"pointer (P_Expensive): {self.outPosition_P1.value}")
		print(f"pointer (P_Total): {self.outPosition_P2.value}")
		print(f"pointer (P_Special): {self.outPosition_P3.value}")
		print("=================================================================")

	def produzir(self, item):
		self.empty.acquire()	#empty: -1
		writer_pointer = self.inPosition.value	#valor do pointer de escrita
		data = pickle.dumps(item)	#conversao para bytes
		data_size = len(data)
		self.buffer[ (250*writer_pointer) : data_size+(250*writer_pointer) ] = data	#escrita para o buffer na slot certa

		self.counter_leitura[self.inPosition.value] = 0  # reset do contador

		self.inPosition.value = (writer_pointer + 1) % self.tamanho	#avancar uma posicao do pointer de escrita

		#incrementar todos os semaforos full da lista de fulls
		for full in self.fulls:
			full.release()	#full: +1

		return writer_pointer	#returnar posicao do pointer de escrita

	def consumir(self, num_processo):
		num_processo -= 1
		self.fulls[num_processo].acquire()
		reader_pointer = self.outPositions[num_processo]	#valor do pointer de leitura
		item = pickle.loads(self.buffer[ 0+(250*reader_pointer) : 250+(250*reader_pointer) ])
		# print(f"Processo {num_processo} consumiu: {item}")

		# incrementa contador de leituras
		with self.counter_leitura_mutex:
			self.counter_leitura[reader_pointer] += 1

		# incrementa o pointer do processo que consumiu
		self.outPositions[num_processo] = (reader_pointer + 1) % self.tamanho

		# se 3 consumidores já leram...

		with self.counter_leitura_mutex:	#n precisava desse mutex, podia fazer um get_lock do counter
			if self.counter_leitura[reader_pointer] == 3:	#se a slot já foi lida 3 vezes:
				self.counter_leitura[reader_pointer] = 0     # limpa contador
				self.empty.release()              # libera slot

		return item


#inicializar buffer
buffer_circular = BufferCircular()

def aux_estado_recursos(estado):
	if estado == 1:
		return "tem"
	elif estado == 0:
		return "está á espera de"

def estado_recursos():
	print(f"Processo P_Expensive: {aux_estado_recursos(P_Expensive_recursos[0])} R_StockWarehouse e {aux_estado_recursos(P_Expensive_recursos[1])} R_DeliveryCapacity")
	print(f"Processo P_Special: {aux_estado_recursos(P_Special_recursos[0])} R_StockWarehouse e {aux_estado_recursos(P_Special_recursos[1])} R_DeliveryCapacity")
	system_state = "SAFE"
	if (P_Expensive_recursos[0]==1 and P_Expensive_recursos[1]==0) and (P_Special_recursos[0]==0 and P_Special_recursos[1]==1):
		system_state = "UNSAFE"

	print(f"[{customer}] Estado do sistema: [{system_state}]\n")

# Processo 1: artigos caros (>1000€)
def P_Expensive(n_processo):
	#enquanto a fila tiver elementos executar: (mas sendo q qnd este codigo corre a   fila ainda esta vazia n é possivel fazer um while fila>0
	while True:
		compra = buffer_circular.consumir(n_processo)
		isExpensive = False

		#print(f"P_Expensive {compra}")
		if compra == "EXIT":  #"EXIT" é adicionado ao buffer qnd não há mais linhas para ler
			exit()

		elif float(compra[3]) > 1000:
			print(f"[{customer}:P_Expensive] Compra cara: {compra[2]} -> {compra[3]}€")
			isExpensive = True

		#escrever para o bin
		with lock_escrita:
			with open("ledger.bin", "ab") as f:
				dic = {"nome": compra[2], "price": compra[3], "expensive": isExpensive}

				data = pickle.dumps(dic)	#tranformar dic em bin
				size = len(data)	#tamamnho dos dados

				f.write(struct.pack("I", size))	#escrever bytes do tamanho dos dados
				f.write(data)	#escrever dados

		if isExpensive:
			R_StockWarehouse.acquire()
			P_Expensive_recursos[0] = 1
			sleep(0.1)
			estado_recursos()

			R_DeliveryCapacity.acquire()
			P_Expensive_recursos[1] = 1
			estado_recursos()

			sleep(0.1)

			R_StockWarehouse.release()
			P_Expensive_recursos[0] = 0
			estado_recursos()

			R_DeliveryCapacity.release()
			P_Expensive_recursos[1] = 0
			estado_recursos()

		sleep(.01)

# Processo 2: total gasto
def P_Total(n_processo):
	#handler para printar total acumulado
	signal.signal(signal.SIGALRM, handler)
	signal.setitimer(signal.ITIMER_REAL, T, T)

	while True:
		compra = buffer_circular.consumir(n_processo)
		if compra == "EXIT":  #"EXIT" é adicionado ao buffer qnd não há mais linhas para ler
			exit()

		with total_gasto.get_lock():
			total_gasto.value += float(compra[3])

		sleep(.01)

# Processo 3: compras nos dias 29,30,31
def P_Special(n_processo):
	while True:
		compra = buffer_circular.consumir(n_processo)
		isSpecial = False

		if compra == "EXIT":  #"EXIT" é adicionado ao buffer qnd não há mais linhas para ler
			exit()

		dia = list(map(int, compra[0].split("-")))[2]
		if dia in [29,30,31]:
			print(f"[{customer}:P_Special] Compra dia especial: {compra[2]} -> {compra[0]}")
			isSpecial = True

		#escrever para o bin
		with lock_escrita:
			with open("ledger.bin", "ab") as f:
				dic = {"nome": compra[2], "price": compra[3], "special": isSpecial}

				data = pickle.dumps(dic)  #converter em bin
				size = len(data)	#tamanho dos dados

				f.write(struct.pack("I", size))	#escrever tamanho dos dados
				f.write(data)	#escrever dados

		if isSpecial:
			R_DeliveryCapacity.acquire()
			P_Special_recursos[1] = 1
			sleep(0.1)
			estado_recursos()

			R_StockWarehouse.acquire()
			P_Special_recursos[0] = 1
			estado_recursos()

			sleep(0.1)

			R_DeliveryCapacity.release()
			P_Special_recursos[1] = 0
			estado_recursos()

			R_StockWarehouse.release()
			P_Special_recursos[0] = 0
			estado_recursos()

		sleep(.01)

# Processo 4:  Output periodico e handler
def handler(signum, frame):
	with total_gasto.get_lock():
		print(f"[{customer}:P_TotalWorker] Total acumulado até agora -> {round(total_gasto.value,2)}")

# -- Main --

# Análise iniciada.
def main():
	print(f"[{customer}:main] Análise iniciada")

	# definir processos
	P1 = Process(target=P_Expensive, args=(1,))
	P2 = Process(target=P_Total, args=(2,))
	P3 = Process(target=P_Special, args=(3,))

	# iniciar processos
	P1.start()
	P2.start()
	P3.start()

	with open(arg, "r") as f:
		next(f)	#saltar a primeira linha
		for linha in f:
			linha = linha.strip()
			linha = linha.split(",")
			buffer_circular.produzir(linha)

	# enviar "EXIT" para o buffer para os processos saberem que podem encerrar
	buffer_circular.produzir("EXIT")

	P1.join()
	P2.join()
	P3.join()

	print(f"[{customer}:P_Total] Total gasto: {round(total_gasto.value,2)}€")
	print(f"[{customer}:main] Análise concluída")
main()
# Análise concluída.








