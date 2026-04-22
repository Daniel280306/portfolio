ANY = '_'  # constante a usar na definição dos padrões de registo

class Table:
  def __init__(self, scheme, key_idx, widths):
    self._scheme = scheme.split(' ')
    self._key_idx = key_idx
    self._table = {}
    self._widths = widths
    
  ## TODO
  
  
  def add(self, register):
    key = tuple(register[i] for i in self._key_idx)
    self._table[key] = register
    
    
    
  def delete(self, pattern):
    keys_to_delete = []
    for key, row in self._table.items():
        # Verifica se todos os elementos do padrão correspondem ao registro
        match = True
        for i in range(len(pattern)):
            if pattern[i] != ANY and pattern[i] != row[i]:
                match = False
                break
        if match:
            keys_to_delete.append(key)
    
    # Remove os registros marcados
    for key in keys_to_delete:
        del self._table[key]
        
  
  
  
  
  def lookup(self, pattern):
    matching_records = []  # Lista para guardar os registros que combinam
    
    for row in self._table.values():  # Percorre todos os registros
        match = True  # Assume que combina no início
        
        for i in range(len(pattern)):  # Verifica cada campo do padrão
            if pattern[i] != ANY and pattern[i] != row[i]:
                match = False  # Se algum campo não combinar, marca como falso
                break
        
        if match:  # Se todos os campos combinaram
            matching_records.append(row)  # Adiciona o registro à lista
    
    return matching_records  # Retorna a lista de registros que combinam
    
    
    
    
  def select(self, p):
    new_table = Table(' '.join(self._scheme), self._key_idx.copy(), self._widths.copy())
    for row in self._table.values():
        if p(row):  # Se o registro satisfaz o predicado p
            new_table.add(row)
    return new_table
    
    
    
  
  
  def project(self, subscheme, subkey_idx):
    """Projeta a tabela num subesquema com colunas reordenadas"""
    # Converte subscheme para lista se for string
    subscheme_list = subscheme.split(' ') if isinstance(subscheme, str) else subscheme
    
    # Obtém os índices das colunas no esquema original
    col_indices = [self._scheme.index(col) for col in subscheme_list]
    
    # Obtém as larguras das colunas selecionadas
    new_widths = [self._widths[i] for i in col_indices]
    
    # Cria a nova tabela com o subesquema e novas chaves
    new_table = Table(subscheme, subkey_idx, new_widths)
    
    # Adiciona os registros projetados
    for row in self._table.values():
        new_row = tuple(row[i] for i in col_indices)
        new_table.add(new_row)
    
    return new_table
    
    
  
  
  
  def __add__(self, other):

    # Criar nova tabela com mesma estrutura
    new_table = Table(' '.join(self._scheme), self._key_idx.copy(), self._widths.copy())
    
    # Adicionar todos os registros da primeira tabela
    for row in self._table.values():
        new_table.add(row)
    
    # Adicionar todos os registros da segunda tabela (sobrescrevendo duplicados)
    for row in other._table.values():
        new_table.add(row)  # Se existir mesma chave, substitui
    
    return new_table
    
    
    
  
  
  
  
  def __mul__(self, other):

    # Criar nova tabela com mesma estrutura
    new_table = Table(' '.join(self._scheme), self._key_idx.copy(), self._widths.copy())
    
    # Obter chaves da outra tabela para busca eficiente
    other_keys = set(other._table.keys())
    
    # Adicionar apenas registros cujas chaves existem em ambas tabelas
    for key, row in self._table.items():
        if key in other_keys:
            new_table.add(row)
    
    return new_table
    
  
  
  
  def __sub__(self, other):

    # Criar nova tabela
    new_table = Table(' '.join(self._scheme), self._key_idx.copy(), self._widths.copy())
    
    # Obter chaves da outra tabela para comparação
    other_keys = set(other._table.keys())
    
    # Adicionar apenas registros cuja chave não está na outra tabela
    for key, row in self._table.items():
        if key not in other_keys:
            new_table.add(row)
    
    return new_table
    
    
  

  def __pow__(self, other):
        common_cols = [col for col in self._scheme if col in other._scheme]
        
        self_indices = [self._scheme.index(col) for col in common_cols]
        other_indices = [other._scheme.index(col) for col in common_cols]

        new_scheme = self._scheme + [col for col in other._scheme if col not in self._scheme]
        
        new_key_idx = self._key_idx.copy()

        for i, x in enumerate(other._key_idx):
            c = other._scheme[x]
            if c in self._scheme:
                a = self._scheme.index(c)
            else:
                a = len(self._scheme) + i
            if a not in new_key_idx:
                new_key_idx.append(a)

        new_widths = self._widths + [
            other._widths[i] 
            for i, col in enumerate(other._scheme) 
            if col not in common_cols
        ]

        new_table = Table(' '.join(new_scheme), new_key_idx, new_widths)

        for row1 in self._table.values():
            for row2 in other._table.values():
                if all(row1[i] == row2[j] for i, j in zip(self_indices, other_indices)):
                    combined_row = row1 + tuple(
                        row2[i] 
                        for i in range(len(row2)) 
                        if other._scheme[i] not in common_cols
                    )
                    new_table.add(combined_row)

        return new_table

    
    
  
    
    

    
    
  def __iter__(self):
        for key, row in self._table.items():
            yield (key, row) 
    
    
    
  



    
    

  
  ##### não alterar __repr__ #####
  def __repr__(self):  
    header = ' | '.join((k + '!'*(i in self._key_idx)).ljust(self._widths[i])
                        for i,k in enumerate(self._scheme))
    content = '\n'.join( ' | '.join(str(column).ljust(self._widths[i]) 
                                    for i,column in enumerate(row))
                        for row in self._table.values())
    return '\n'.join((header+'\n'+content ).split('\n'))  
    
##################################################################
######### tabelas exemplos para os testes (não alterar!) #########
##################################################################

def make_db():
    addresses = Table('id num address country', key_idx=[0], widths=[3,5,36,8])
    addresses.add( (1, 50000, "Campo Grande 016, 1749-016 Lisboa",    'PT') )
    addresses.add( (2, 50000, "Av. da Liberdade 2, 1250-144 Lisboa",  'PT') )
    addresses.add( (3, 50001, "Av. da Republica 12, 1210-54 Lisboa",  'PT') )
    addresses.add( (4, 50002, "Av. Infante Santo 8, 1350-001 Lisboa", 'PT') )
    
    students = Table('num name grad year', key_idx=[0], widths=[5,12,5,4])
    students.add( (50000, 'Ana',   'LEI', 2020) )
    students.add( (50001, 'Rui',   'LEI', 2022) )
    students.add( (50002, 'Pedro', 'LTI', 2022) )
    students.add( (50003, 'Dulce', 'LF',  2021) )
    students.add( (50004, 'Pedro', 'LMA', 2022) )    
    
    return addresses, students

