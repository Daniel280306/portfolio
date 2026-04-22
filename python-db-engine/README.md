# Python Relational Database Engine

##  Overview

In-memory relational database engine implemented from scratch in Python. Supports relational algebra operations similar to SQL databases.

## Operations Supported

| Operation | Description | SQL Equivalent |
|-----------|-------------|----------------|
| `add(record)` | Insert a new record | `INSERT` |
| `delete(pattern)` | Remove records matching pattern | `DELETE WHERE` |
| `lookup(pattern)` | Find records matching pattern | `SELECT WHERE` |
| `select(predicate)` | Filter records by condition | `WHERE` with function |
| `project(subscheme, keys)` | Reorder and select columns | `SELECT` with specific columns |
| `union (+)` | Combine two tables | `UNION` |
| `intersection (*)` | Keep records with keys in both tables | `INTERSECT` |
| `difference (-)` | Keep records with keys not in other table | `EXCEPT` |
| `natural join (**)` | Combine tables on common columns | `NATURAL JOIN` |

##  Features

| Feature | Description |
|---------|-------------|
| **Composite Keys** | Multi-column primary keys |
| **Pattern Matching** | Wildcard-based lookup (`ANY = '_'`) |
| **Table Iteration** | `for key, row in table:` |
| **Formatted Output** | Column-aligned with key indicators (`!` suffix) |
| **Type Safety** | Preserves data types during operations |

##  Files

| File | Description |
|------|-------------|
| `table.py` | Main Table class implementation |
| `test.py` | Unit tests and usage examples |
| `demo.py` | Demonstration script |

##  How to Run

```python
from table import Table

# Create table with schema: "id name age"
T = Table("id name age", key_idx=[0], widths=[3, 10, 3])

# Add records
T.add((1, "Alice", 25))
T.add((2, "Bob", 30))
T.add((3, "Charlie", 35))

# Pattern lookup (find all with name 'Bob')
results = T.lookup(('_', 'Bob', '_'))

# Project (reorder columns: age, id, name)
projected = T.project("age id name", [0])

# Union with another table
T2 = Table("id name age", key_idx=[0], widths=[3, 10, 3])
T2.add((4, "Diana", 28))
union = T + T2

# Natural join
addresses = Table("id address city", key_idx=[0], widths=[3, 20, 10])
addresses.add((1, "Main St", "Lisbon"))
joined = T ** addresses

# Iterate
for key, row in T:
    print(f"Key: {key}, Row: {row}")
