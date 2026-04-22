
# Operating System

##  Overview

Multi-process data pipeline for analyzing large CSV files (thousands of purchase records). Demonstrates OS-level concurrency with process pools, shared memory, and synchronization.

## Architecture
CSV Files (clients)
↓
Bash Script (process pool, max processes limit)
↓
Python Process per file
↓
3 Threads working in parallel
├── T1: Expensive purchases (>1000€)
├── T2: Running total
└── T3: Special dates (29,30,31)



##  Phase 1 Features

| Feature | Implementation |
|---------|----------------|
| Process Pool | Bash `wait -n` with configurable concurrency |
| Multi-threading | 3 threads per CSV file |
| Output Format | `[filename:T1] Compra cara: produto -> valor€` |
| Input Validation | Error handling for missing files |

##  Phase 2 Features (Advanced)

| Feature | Implementation |
|---------|----------------|
| Shared Circular Buffer | Inter-process communication |
| Semaphores & Mutex | Synchronization primitives |
| Deadlock Detection | Safe/unsafe state monitoring |
| SIGALRM Timer | Periodic output every 3 seconds |
| Binary Audit Log | Concurrent writes with file locking |
| Resource Simulation | Stock warehouse & delivery capacity |

##  Files

| File | Description |
|------|-------------|
| `executar_analises.sh` | Bash script with process pool |
| `analisar_cliente.py` | Python program with threads |
| `analisar_cliente_phase2.py` | Phase 2 with shared buffer and deadlock detection |

##  How to Run

```bash
# Make script executable
chmod +x executar_analises.sh

# Run with 3 concurrent processes
./executar_analises.sh ../csvs/ 3

# Example output:
# [customer1:main] Análise iniciada.
# [customer1:T1] Compra cara: PlacaGrafica -> 1023.13€
# [customer1:T3] Compra dia especial: Motherboard -> 2026-04-29
# [customer1:T2] Total gasto: 136894.46€
# [customer1:main] Análise concluída.
