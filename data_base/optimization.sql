-- Grupo 32 – Daniel Santos nº 64168; Miguel Lopes nº 42081; Miguel Sousa nº 64150

SET search_path TO bd032_schema, public;

-- ===========================================================================
-- OTIMIZAÇÃO DE INTERROGAÇÕES
-- ===========================================================================

-- 5. Mostre o número de consultas por departamento (inferindo o departamento do médico que realizou a consulta).
-- Alterações principais:
--    - GROUP BY passa a usar id_departamento e nome em conjunto, alinhado com a chave primária de Departamento

EXPLAIN ANALYZE
SELECT
    Departamento.id_departamento,
    Departamento.nome AS departamento,
    COUNT(*) AS total_consultas
FROM Consulta
JOIN realiza_med_cons
  ON realiza_med_cons.id_consulta = Consulta.id_consulta
JOIN pertence_dept_prof_saude
  ON pertence_dept_prof_saude.id_profissional_saude = realiza_med_cons.id_profissional_saude
JOIN Departamento
  ON Departamento.id_departamento = pertence_dept_prof_saude.id_departamento
GROUP BY Departamento.id_departamento, Departamento.nome
ORDER BY total_consultas DESC, Departamento.nome;

-- ---------------------------------------------------------------------------

-- 8. Liste os pacientes que receberam pelo menos um medicamento da categoria "Antibiótico".
-- Alterações principais:
--    - DISTINCT substituído por GROUP BY id_paciente e nome

EXPLAIN ANALYZE
SELECT
    Paciente.id_paciente,
    Paciente.nome AS paciente
FROM Prescricao
JOIN contem_presc_medi
  ON contem_presc_medi.id_consulta = Prescricao.id_consulta
 AND contem_presc_medi.id_prescricao = Prescricao.id_prescricao
JOIN Medicamento
  ON Medicamento.id_medicamento = contem_presc_medi.id_medicamento
JOIN tem_cons_paci
  ON tem_cons_paci.id_consulta = Prescricao.id_consulta
JOIN Paciente
  ON Paciente.id_paciente = tem_cons_paci.id_paciente
WHERE Medicamento.categoria = 'Antibiótico'
GROUP BY Paciente.id_paciente, Paciente.nome
ORDER BY Paciente.nome;

-- ---------------------------------------------------------------------------

-- 11. Mostre, para cada unidade de saúde, o número de departamentos, de médicos e de enfermeiros associados.
-- Alterações principais:
--    - GROUP BY passa a usar id_unidade_saude e nome, em vez de só nome, alinhado com a chave primária de Unidade_Saude

EXPLAIN ANALYZE
SELECT
    Unidade_Saude.id_unidade_saude,
    Unidade_Saude.nome AS unidade_saude,
    COUNT(DISTINCT Departamento.id_departamento) AS num_departamentos,
    COUNT(DISTINCT Medico.id_profissional_saude) AS num_medicos,
    COUNT(DISTINCT Enfermeiro.id_profissional_saude) AS num_enfermeiros
FROM Unidade_Saude
LEFT JOIN tem_unid_saude_dept
       ON tem_unid_saude_dept.id_unidade_saude = Unidade_Saude.id_unidade_saude
LEFT JOIN Departamento
       ON Departamento.id_departamento = tem_unid_saude_dept.id_departamento
LEFT JOIN pertence_dept_prof_saude
       ON pertence_dept_prof_saude.id_departamento = Departamento.id_departamento
LEFT JOIN Medico
       ON Medico.id_profissional_saude = pertence_dept_prof_saude.id_profissional_saude
LEFT JOIN Enfermeiro
       ON Enfermeiro.id_profissional_saude = pertence_dept_prof_saude.id_profissional_saude
GROUP BY Unidade_Saude.id_unidade_saude, Unidade_Saude.nome
ORDER BY Unidade_Saude.nome;

-- ---------------------------------------------------------------------------

-- 15. Liste os médicos cuja carga de trabalho (número de consultas realizadas) nos últimos 30 dias está acima da média.
-- Alterações principais:
--    - Mantida a estrutura em CTEs; apenas exposto explicitamente o id_profissional_saude no resultado final para facilitar análise e comparação de planos de execução

EXPLAIN ANALYZE
WITH 
    consultas_ultimos_30_dias AS (
        SELECT
            realiza_med_cons.id_profissional_saude,
            COUNT(*) AS num_consultas
        FROM realiza_med_cons
        JOIN Consulta
          ON Consulta.id_consulta = realiza_med_cons.id_consulta
        WHERE Consulta.data_hora BETWEEN CURRENT_DATE - INTERVAL '30 days' AND CURRENT_DATE
          AND Consulta.estado = 'Realizada'
        GROUP BY realiza_med_cons.id_profissional_saude
    ),
    media AS (
        SELECT AVG(num_consultas) AS media_consultas
        FROM consultas_ultimos_30_dias
)
SELECT
    Profissional_Saude.id_profissional_saude,
    Profissional_Saude.nome AS medico,
    consultas_ultimos_30_dias.num_consultas
FROM consultas_ultimos_30_dias
JOIN media
  ON consultas_ultimos_30_dias.num_consultas > media.media_consultas
JOIN Profissional_Saude
  ON Profissional_Saude.id_profissional_saude = consultas_ultimos_30_dias.id_profissional_saude
ORDER BY consultas_ultimos_30_dias.num_consultas DESC, Profissional_Saude.nome;

-- ---------------------------------------------------------------------------

-- 18. Liste os medicamentos em situação de risco: stock abaixo do nível mínimo e/ou validade a expirar nos próximos 30 dias.
-- Alterações principais:
--    - CASE mais detalhado (expirada vs próxima), alinhado com a view medicamentos_em_risco_view
--    - Organização do WHERE e ORDER BY compatível com o índice composto (quantidade_stock, data_validade)

EXPLAIN ANALYZE
SELECT
    Medicamento.id_medicamento,
    Medicamento.nome,
    Medicamento.quantidade_stock,
    Medicamento.nivel_min_stock,
    Medicamento.data_validade,
    CASE
        WHEN Medicamento.quantidade_stock < Medicamento.nivel_min_stock
         AND Medicamento.data_validade < CURRENT_DATE THEN 'Stock abaixo do nível mínimo e validade expirada'
        WHEN Medicamento.quantidade_stock < Medicamento.nivel_min_stock
         AND Medicamento.data_validade BETWEEN CURRENT_DATE AND CURRENT_DATE + INTERVAL '30 days' THEN 'Stock abaixo do nível mínimo e validade próxima'
        WHEN Medicamento.quantidade_stock < Medicamento.nivel_min_stock THEN 'Stock abaixo do nível mínimo'
        WHEN Medicamento.data_validade < CURRENT_DATE THEN 'Validade expirada'
        WHEN Medicamento.data_validade BETWEEN CURRENT_DATE AND CURRENT_DATE + INTERVAL '30 days' THEN 'Validade próxima'
    END AS estado_stock
FROM Medicamento
WHERE Medicamento.quantidade_stock < Medicamento.nivel_min_stock
   OR Medicamento.data_validade <= CURRENT_DATE + INTERVAL '30 days'
ORDER BY estado_stock, Medicamento.data_validade, Medicamento.nome;
