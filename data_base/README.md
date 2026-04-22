# PostgreSQL Database Optimization

## Project Overview

Optimization of a hospital management database. Achieved **32% performance improvement** on critical queries through indexing and query rewriting.

## Results

| Query | Improvement |
|-------|-------------|
| Query 11 | 32.98% faster |
| Query 1 | 22.66% faster |
| Query 5 | 6.38% faster |

## 🛠️ Techniques Used

- **EXPLAIN ANALYZE** - Identified bottlenecks
- **B-tree Indexes** - For equality and range queries
- **Hash Indexes** - For fast equality lookups
- **Composite Indexes** - Multi-column conditions
- **Query Rewriting** - Restructured complex joins
- **Read/Write Trade-off Analysis** - Documented index impact

## Files

| File | Description |
|------|-------------|
| `indexes.sql` | All indexes created (B-tree, Hash, composite) |
| `optimization.sql` | Rewritten queries (before vs after) |
| `benchmarks.sql` | Performance measurement scripts |
| `relatorio-e3.pdf` | Complete technical report with graphs |

## How to Run

```sql
-- 1. Create indexes
\i indexes.sql

-- 2. Run benchmarks
\i benchmarks.sql

-- 3. Test optimized queries
\i optimization.sql

## Full Report

For detailed analysis with performance graphs and explanations, see:
- `relatorio-e3.pdf` - Complete technical report (32% improvement documented)
