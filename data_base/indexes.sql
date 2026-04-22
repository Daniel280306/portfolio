-- Grupo 32 – Daniel Santos nº 64168; Miguel Lopes nº 42081; Miguel Sousa nº 64150

SET search_path TO bd032_schema, public;

-- ===========================================================================
-- ÍNDICES
-- ===========================================================================

-- Índice composto em Consulta(estado, data_hora)
-- Otimiza:
--    - filtros por estado e ordenação por data_hora
--    - Q1, Q14, Q15, Q17, Q19, views relacionadas e triggers

CREATE INDEX cons_estado_data_hora_index ON Consulta (estado, data_hora);

-- ---------------------------------------------------------------------------

-- Índice em tem_cons_paci(id_paciente)
-- Otimiza:
--    - Q3: pacientes sem consultas (subquery NOT EXISTS)
--    - Q6, Q12, Q16: contagem/estatísticas de consultas por paciente
--    - Função obter_consultas_paciente (via joins indiretos)

CREATE INDEX tem_cons_paci_paciente_index ON tem_cons_paci (id_paciente);

-- ---------------------------------------------------------------------------

-- Índice em tem_cons_paci(id_consulta)
-- Otimiza:
--    - Q1, Q7, Q8, Q16, Q17, Q20: joins a partir de Consulta
--    - Trigger criar_historico_consulta_realizada (busca paciente pela consulta)

CREATE INDEX tem_cons_paci_consulta_index ON tem_cons_paci (id_consulta);

-- ---------------------------------------------------------------------------

-- Índice em pertence_dept_prof_saude(id_departamento)
-- Otimiza:
--    - Q2: contagem de profissionais por departamento
--    - Q5, Q11, Q19: estatísticas por departamento/unidade de saúde

CREATE INDEX pert_dept_prof_saude_departamento_index ON pertence_dept_prof_saude (id_departamento);

-- ---------------------------------------------------------------------------

-- Índice em pertence_dept_prof_saude(id_profissional_saude)
-- Otimiza:
--    - Q5, Q11, Q19: mapear rapidamente médico/enfermeiro -> departamento

CREATE INDEX pert_dept_prof_saude_profissional_saude_index ON pertence_dept_prof_saude (id_profissional_saude);

-- ---------------------------------------------------------------------------

-- Índice em realiza_med_cons(id_consulta)
-- Já existe um índice por médico (real_med_cons_medico_index no schema.sql)
-- Este acelera joins a partir de Consulta:
--    - Q1, Q4, Q5, Q6, Q14, Q15, Q17, Q19
--    - Trigger impedir_sobreposicao_consultas_medico

CREATE INDEX real_med_cons_consulta_index ON realiza_med_cons (id_consulta);

-- ---------------------------------------------------------------------------

-- Índice em participa_enf_cons(id_consulta)
-- Otimiza:
--    - Q7: listar enfermeiros por consulta

CREATE INDEX part_enf_cons_consulta_index ON participa_enf_cons (id_consulta);

-- ---------------------------------------------------------------------------

-- Índice composto em contem_presc_medi(id_consulta, id_prescricao)
-- Otimiza:
--    - Q8, Q9, Q18
--    - Função adicionar_medicamento_prescricao (verificação de existência)

CREATE INDEX cont_presc_medi_consulta_prescricao_index ON contem_presc_medi (id_consulta, id_prescricao);

-- ---------------------------------------------------------------------------

-- Índice em Prescricao(id_consulta)
-- Otimiza:
--    - Q8, Q10, Q17, Q18
--    - Função criar_prescricao (consultas associadas)

CREATE INDEX presc_consulta_index ON Prescricao (id_consulta);

-- ---------------------------------------------------------------------------

-- Índice composto em Medicamento(quantidade_stock, data_validade)
-- Otimiza:
--    - Q13, Q18, view medicamentos_em_risco_view
--    - Procedures e triggers de stock (atualizações/consultas frequentes)

CREATE INDEX medi_quantidade_stock_data_validade_index ON Medicamento (quantidade_stock, data_validade);

-- ---------------------------------------------------------------------------

-- Índice HASH em Medicamento(categoria)
-- Exemplo de índice não B-tree, para operações de igualdade:
--    - Q8: WHERE Medicamento.categoria = 'Antibiótico'

CREATE INDEX medi_categoria_index ON Medicamento USING HASH (categoria);

-- ---------------------------------------------------------------------------

-- Índice em tem_unid_saude_dept(id_unidade_saude)
-- Otimiza:
--    - Q11, Q19 e view consultas_realizadas_unidade_saude_tipo_consulta_view que agregam por unidade de saúde

CREATE INDEX tem_unid_saude_dept_unidade_index ON tem_unid_saude_dept (id_unidade_saude);
