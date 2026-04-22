-- Grupo 32 – Daniel Santos nº 64168; Miguel Lopes nº 42081; Miguel Sousa nº 64150

-- SET search_path TO bd032_schema, public;

-- ===========================================================================
-- INTERROGAÇÕES SQL
-- ===========================================================================

-- 1. Liste o nome dos pacientes, a data/hora da consulta e o nome do médico responsável, apenas para consultas com o estado "Realizada".

SELECT
    Paciente.nome AS paciente,
    Consulta.data_hora AS data_hora_consulta,
    Profissional_Saude.nome AS medico
FROM Consulta
JOIN tem_cons_paci
  ON tem_cons_paci.id_consulta = Consulta.id_consulta
JOIN Paciente
  ON Paciente.id_paciente = tem_cons_paci.id_paciente
JOIN realiza_med_cons
  ON realiza_med_cons.id_consulta = Consulta.id_consulta
JOIN Medico
  ON Medico.id_profissional_saude = realiza_med_cons.id_profissional_saude
JOIN Profissional_Saude
  ON Profissional_Saude.id_profissional_saude = Medico.id_profissional_saude
WHERE Consulta.estado = 'Realizada' -- Filtra apenas consultas realizadas
ORDER BY Consulta.data_hora DESC;

-- ---------------------------------------------------------------------------

-- 2. Mostre o nome de cada departamento e o número total de profissionais de saúde que nele trabalham.

SELECT
    Departamento.nome AS departamento,
    COUNT(pertence_dept_prof_saude.id_profissional_saude) AS num_profissionais -- Conta quantos profissionais de saúde pertencem ao departamento
FROM Departamento
LEFT JOIN pertence_dept_prof_saude
       ON pertence_dept_prof_saude.id_departamento = Departamento.id_departamento
GROUP BY Departamento.nome
ORDER BY num_profissionais DESC, Departamento.nome;

-- ---------------------------------------------------------------------------

-- 3. Liste os pacientes que nunca realizaram qualquer consulta.

SELECT
    Paciente.nome
FROM Paciente
WHERE NOT EXISTS ( -- Procura a existência de linhas na tabela "tem_cons_paci"
    SELECT 1
    FROM tem_cons_paci
    WHERE tem_cons_paci.id_paciente = Paciente.id_paciente
); -- Se não existirem linhas, o paciente é mostrado no resultado

-- ---------------------------------------------------------------------------

-- 4. Liste os médicos que já realizaram mais de 5 consultas (mostrar nome e total).

SELECT
    Profissional_Saude.nome AS medico,
    COUNT(realiza_med_cons.id_consulta) AS num_consultas -- Conta o número de consultas realizadas por cada médico
FROM realiza_med_cons
JOIN Medico
  ON Medico.id_profissional_saude = realiza_med_cons.id_profissional_saude
JOIN Profissional_Saude
  ON Profissional_Saude.id_profissional_saude = Medico.id_profissional_saude
GROUP BY Profissional_Saude.nome
HAVING COUNT(realiza_med_cons.id_consulta) > 5 -- Mostra só os que têm mais que 5
ORDER BY num_consultas DESC;

-- ---------------------------------------------------------------------------

-- 5. Mostre o número de consultas por departamento (inferindo o departamento do médico que realizou a consulta).

SELECT
    Departamento.nome AS departamento,
    COUNT(*) AS total_consultas -- Conta o número de consultas associadas ao departamento
FROM Consulta
JOIN realiza_med_cons
  ON realiza_med_cons.id_consulta = Consulta.id_consulta
JOIN pertence_dept_prof_saude
  ON pertence_dept_prof_saude.id_profissional_saude = realiza_med_cons.id_profissional_saude
JOIN Departamento
  ON Departamento.id_departamento = pertence_dept_prof_saude.id_departamento
GROUP BY Departamento.nome
ORDER BY total_consultas DESC, Departamento.nome;

-- ---------------------------------------------------------------------------

-- 6. Liste os pacientes que já tiveram consultas com mais de um médico diferente.

SELECT
    Paciente.nome AS paciente,
    COUNT(DISTINCT realiza_med_cons.id_profissional_saude) AS medicos_distintos -- Conta o número de médicos distintos por paciente
FROM Paciente
JOIN tem_cons_paci
  ON tem_cons_paci.id_paciente = Paciente.id_paciente
JOIN realiza_med_cons
  ON realiza_med_cons.id_consulta = tem_cons_paci.id_consulta
GROUP BY Paciente.nome
HAVING COUNT(DISTINCT realiza_med_cons.id_profissional_saude) > 1 -- Mostra só os que têm mais que 1
ORDER BY medicos_distintos DESC, Paciente.nome;

-- ---------------------------------------------------------------------------

-- 7. Liste todas as consultas (data/hora e paciente) e, se existir, o(s) enfermeiro(s) participante(s). Mostre "sem enfermeiro" quando não houver.

SELECT
    Consulta.id_consulta,
    Consulta.data_hora AS data_hora_consulta,
    Paciente.nome AS paciente,
    COALESCE(Profissional_Saude.nome, 'sem enfermeiro') AS enfermeiro
FROM Consulta
JOIN tem_cons_paci
  ON tem_cons_paci.id_consulta = Consulta.id_consulta
JOIN Paciente
  ON Paciente.id_paciente = tem_cons_paci.id_paciente
LEFT JOIN participa_enf_cons
       ON participa_enf_cons.id_consulta = Consulta.id_consulta
LEFT JOIN Enfermeiro
       ON Enfermeiro.id_profissional_saude = participa_enf_cons.id_profissional_saude
LEFT JOIN Profissional_Saude
       ON Profissional_Saude.id_profissional_saude = Enfermeiro.id_profissional_saude
ORDER BY Consulta.data_hora DESC, enfermeiro;

-- ---------------------------------------------------------------------------

-- 8. Liste os pacientes que receberam pelo menos um medicamento da categoria "Antibiótico".

SELECT DISTINCT
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
WHERE Medicamento.categoria = 'Antibiótico' -- Filtra apenas medicamentos de categoria "Antibiótico"
ORDER BY Paciente.nome;

-- ---------------------------------------------------------------------------

-- 9. Mostre os três medicamentos mais prescritos (contando prescrições distintas).

SELECT
    Medicamento.nome AS medicamento,
    COUNT(DISTINCT (contem_presc_medi.id_consulta,
                    contem_presc_medi.id_prescricao)) AS total_prescricoes -- Conta o número de prescrições distintas com base na combinação "consulta + prescrição"
FROM contem_presc_medi
JOIN Medicamento
  ON Medicamento.id_medicamento = contem_presc_medi.id_medicamento
GROUP BY Medicamento.nome
ORDER BY total_prescricoes DESC, Medicamento.nome
LIMIT 3; -- Só os 3 mais prescritos

-- ---------------------------------------------------------------------------

-- 10. Liste os médicos (nome e especialidade) que nunca emitiram uma prescrição. (assumindo que quem prescreve é o médico que realizou a consulta que tem prescrição)

SELECT
    Profissional_Saude.nome AS medico,
    Medico.especialidade
FROM Medico
JOIN Profissional_Saude
ON Profissional_Saude.id_profissional_saude = Medico.id_profissional_saude
WHERE NOT EXISTS ( -- Exclui os médicos que aparecem em alguma prescrição
    SELECT 1
    FROM realiza_med_cons
    JOIN Prescricao
      ON Prescricao.id_consulta = realiza_med_cons.id_consulta
    WHERE realiza_med_cons.id_profissional_saude = Medico.id_profissional_saude
);

-- ---------------------------------------------------------------------------

-- 11. Mostre, para cada unidade de saúde, o número de departamentos, de médicos e de enfermeiros associados.

SELECT
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
GROUP BY Unidade_Saude.nome
ORDER BY Unidade_Saude.nome;

-- ---------------------------------------------------------------------------

-- 12. Liste o número de consultas por paciente e a média global.

SELECT
    pacientes_consultas.id_paciente,
    pacientes_consultas.nome,
    pacientes_consultas.num_consultas,
    AVG(pacientes_consultas.num_consultas) OVER () AS media_consultas_paciente -- Média global de consultas por paciente
FROM (
    SELECT
        Paciente.id_paciente,
        Paciente.nome,
        COUNT(tem_cons_paci.id_consulta) AS num_consultas -- Número de consultas de cada paciente
    FROM Paciente
    LEFT JOIN tem_cons_paci
           ON tem_cons_paci.id_paciente = Paciente.id_paciente
    GROUP BY Paciente.id_paciente, Paciente.nome
) AS pacientes_consultas
ORDER BY pacientes_consultas.num_consultas DESC, pacientes_consultas.nome;

-- ---------------------------------------------------------------------------

-- 13. Mostre o estado do stock de todos os medicamentos, classificando como "Esgotado", "Abaixo do nível mínimo" ou "OK".

SELECT
    Medicamento.nome,
    Medicamento.quantidade_stock,
    Medicamento.nivel_min_stock,
    CASE
        WHEN Medicamento.quantidade_stock = 0 THEN 'Esgotado'
        WHEN Medicamento.quantidade_stock < Medicamento.nivel_min_stock THEN 'Abaixo do nível mínimo'
        ELSE 'OK'
    END AS estado_stock
FROM Medicamento
ORDER BY estado_stock, Medicamento.nome;

-- ---------------------------------------------------------------------------

-- 14. Mostre, para cada médico, a próxima consulta marcada.

SELECT
    Profissional_Saude.nome AS medico,
    MIN(Consulta.data_hora) AS data_hora_proxima_consulta
FROM Medico
JOIN Profissional_Saude
  ON Profissional_Saude.id_profissional_saude = Medico.id_profissional_saude
JOIN realiza_med_cons
  ON realiza_med_cons.id_profissional_saude = Medico.id_profissional_saude
JOIN Consulta
  ON Consulta.id_consulta = realiza_med_cons.id_consulta
WHERE Consulta.estado = 'Marcada'
  AND Consulta.data_hora > NOW() -- Apenas consultas futuras
GROUP BY Profissional_Saude.nome
ORDER BY data_hora_proxima_consulta;

-- ---------------------------------------------------------------------------

-- 15. Liste os médicos cuja carga de trabalho (número de consultas realizadas) nos últimos 30 dias está acima da média.

WITH 
    consultas_ultimos_30_dias AS (
        SELECT
            realiza_med_cons.id_profissional_saude,
            COUNT(*) AS num_consultas
        FROM realiza_med_cons
        JOIN Consulta
          ON Consulta.id_consulta = realiza_med_cons.id_consulta
        WHERE Consulta.data_hora BETWEEN CURRENT_DATE - INTERVAL '30 days' AND CURRENT_DATE -- Seleciona as consultas realizadas nos últimos 30 dias até hoje
          AND Consulta.estado = 'Realizada'
        GROUP BY realiza_med_cons.id_profissional_saude
    ),
    media AS (
        SELECT AVG(num_consultas) AS media_consultas
        FROM consultas_ultimos_30_dias
)
SELECT
    Profissional_Saude.nome AS medico,
    consultas_ultimos_30_dias.num_consultas
FROM consultas_ultimos_30_dias
JOIN media
  ON consultas_ultimos_30_dias.num_consultas > media.media_consultas -- Apenas médicos acima da média
JOIN Profissional_Saude
  ON Profissional_Saude.id_profissional_saude = consultas_ultimos_30_dias.id_profissional_saude
ORDER BY consultas_ultimos_30_dias.num_consultas DESC;

-- ---------------------------------------------------------------------------

-- 16. Para cada paciente, mostre o número total de consultas e a distribuição por estado ("Marcada", "Realizada", "Cancelada").

SELECT
    Paciente.id_paciente,
    Paciente.nome,
    COUNT(Consulta.id_consulta) AS total_consultas,
    SUM(CASE WHEN Consulta.estado = 'Marcada' THEN 1 ELSE 0 END) AS consultas_marcadas, -- Soma o número de consultas marcadas
    SUM(CASE WHEN Consulta.estado = 'Realizada' THEN 1 ELSE 0 END) AS consultas_realizadas, -- Soma o número de consultas realizadas
    SUM(CASE WHEN Consulta.estado = 'Cancelada' THEN 1 ELSE 0 END) AS consultas_canceladas -- Soma o número de consultas canceladas
FROM Paciente
LEFT JOIN tem_cons_paci
       ON tem_cons_paci.id_paciente = Paciente.id_paciente
LEFT JOIN Consulta
       ON Consulta.id_consulta = tem_cons_paci.id_consulta
GROUP BY Paciente.id_paciente, Paciente.nome
ORDER BY total_consultas DESC, Paciente.nome;

-- ---------------------------------------------------------------------------

-- 17. Liste as consultas realizadas que não têm qualquer prescrição associada.

SELECT
    Consulta.id_consulta,
    Consulta.data_hora,
    Paciente.nome AS paciente,
    Profissional_Saude.nome AS medico,
    Consulta.diagnostico,
    Consulta.observacoes
FROM Consulta
JOIN tem_cons_paci
  ON tem_cons_paci.id_consulta = Consulta.id_consulta
JOIN Paciente
  ON Paciente.id_paciente = tem_cons_paci.id_paciente
JOIN realiza_med_cons
  ON realiza_med_cons.id_consulta = Consulta.id_consulta
JOIN Medico
  ON Medico.id_profissional_saude = realiza_med_cons.id_profissional_saude
JOIN Profissional_Saude
  ON Profissional_Saude.id_profissional_saude = Medico.id_profissional_saude
WHERE Consulta.estado = 'Realizada'
AND NOT EXISTS ( -- Garante que não existe prescrição associada à consulta
    SELECT 1
    FROM Prescricao
    WHERE Prescricao.id_consulta = Consulta.id_consulta
)
ORDER BY Consulta.data_hora DESC;

-- ---------------------------------------------------------------------------

-- 18. Liste os medicamentos em situação de risco: stock abaixo do nível mínimo e/ou validade a expirar nos próximos 30 dias.

SELECT
    Medicamento.id_medicamento,
    Medicamento.nome,
    Medicamento.quantidade_stock,
    Medicamento.nivel_min_stock,
    Medicamento.data_validade,
    CASE
        WHEN Medicamento.quantidade_stock < Medicamento.nivel_min_stock
         AND Medicamento.data_validade <= CURRENT_DATE + INTERVAL '30 days' THEN 'Stock abaixo do nível mínimo e validade próxima'
        WHEN Medicamento.quantidade_stock < Medicamento.nivel_min_stock THEN 'Stock abaixo do nível mínimo'
        WHEN Medicamento.data_validade <= CURRENT_DATE + INTERVAL '30 days' THEN 'Validade próxima'
    END AS estado_stock
FROM Medicamento
WHERE Medicamento.quantidade_stock < Medicamento.nivel_min_stock
   OR Medicamento.data_validade <= CURRENT_DATE + INTERVAL '30 days' -- Seleciona só medicamentos em alguma situação de risco
ORDER BY estado_stock, Medicamento.data_validade, Medicamento.nome;

-- ---------------------------------------------------------------------------

-- 19. Mostre, para cada unidade de saúde e tipo de consulta, o número total de consultas realizadas.

SELECT
    Unidade_Saude.nome AS unidade_saude,
    Consulta.tipo_consulta,
    COUNT(*) AS total_consultas
FROM Consulta
JOIN realiza_med_cons
  ON realiza_med_cons.id_consulta = Consulta.id_consulta
JOIN Medico
  ON Medico.id_profissional_saude = realiza_med_cons.id_profissional_saude
JOIN pertence_dept_prof_saude
  ON pertence_dept_prof_saude.id_profissional_saude = Medico.id_profissional_saude
JOIN tem_unid_saude_dept
  ON tem_unid_saude_dept.id_departamento = pertence_dept_prof_saude.id_departamento
JOIN Unidade_Saude
  ON Unidade_Saude.id_unidade_saude = tem_unid_saude_dept.id_unidade_saude
WHERE Consulta.estado = 'Realizada' -- Filtra apenas consultas realizadas
GROUP BY Unidade_Saude.nome, Consulta.tipo_consulta
ORDER BY Unidade_Saude.nome, Consulta.tipo_consulta;

-- ---------------------------------------------------------------------------

-- 20. Mostre a timeline do histórico médico de um paciente, ordenada da data mais recente para a mais antiga. (assumindo paciente id = 1; pode-se alterar para outro)

SELECT
    Historico_Medico.data_registo,
    Historico_Medico.condicao,
    Historico_Medico.descricao
FROM Historico_Medico
JOIN possui_paci_hist_med
  ON possui_paci_hist_med.id_historico_medico = Historico_Medico.id_historico_medico
JOIN Paciente
  ON Paciente.id_paciente = possui_paci_hist_med.id_paciente
WHERE Paciente.id_paciente = 1 -- Paciente que se pretende analisar
ORDER BY Historico_Medico.data_registo DESC;

-- ===========================================================================
-- VIEWS
-- ===========================================================================

-- View 1: Consultas realizadas com o nome do paciente e do médico responsável. (Interrogação 1)

CREATE OR REPLACE VIEW consultas_realizadas_paciente_medico_view AS
SELECT
    Paciente.nome AS paciente,
    Consulta.data_hora AS data_hora_consulta,
    Profissional_Saude.nome AS medico
FROM Consulta
JOIN tem_cons_paci
  ON tem_cons_paci.id_consulta = Consulta.id_consulta
JOIN Paciente
  ON Paciente.id_paciente = tem_cons_paci.id_paciente
JOIN realiza_med_cons
  ON realiza_med_cons.id_consulta = Consulta.id_consulta
JOIN Medico
  ON Medico.id_profissional_saude = realiza_med_cons.id_profissional_saude
JOIN Profissional_Saude
  ON Profissional_Saude.id_profissional_saude = Medico.id_profissional_saude
WHERE Consulta.estado = 'Realizada';

-- Exemplo de utilização:
-- SELECT * FROM consultas_realizadas_paciente_medico_view
-- ORDER BY data_hora_consulta DESC; -- Feita apenas no SELECT sobre a View

-- ---------------------------------------------------------------------------

-- View 2: Estado do stock de todos os medicamentos. Classifica cada medicamento como "Esgotado", "Abaixo do nível mínimo" ou "OK". (Interrogação 13)

CREATE OR REPLACE VIEW estado_stock_medicamentos_view AS
SELECT
    Medicamento.id_medicamento,
    Medicamento.nome,
    Medicamento.quantidade_stock,
    Medicamento.nivel_min_stock,
    CASE
        WHEN Medicamento.quantidade_stock = 0 THEN 'Esgotado'
        WHEN Medicamento.quantidade_stock < Medicamento.nivel_min_stock THEN 'Abaixo do nível mínimo'
        ELSE 'OK'
    END AS estado_stock
FROM Medicamento;

-- Exemplo de utilização:
-- SELECT * FROM estado_stock_medicamentos_view
-- ORDER BY estado_stock, nome;

-- ---------------------------------------------------------------------------

-- View 3: Medicamentos em situação de risco. Considera medicamentos com stock abaixo do nível mínimo e/ou validade a expirar nos próximos 30 dias. (Interrogação 18)

CREATE OR REPLACE VIEW medicamentos_em_risco_view AS
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
   OR Medicamento.data_validade <= CURRENT_DATE + INTERVAL '30 days';

-- Exemplo de utilização:
-- SELECT * FROM medicamentos_em_risco_view
-- ORDER BY estado_stock, data_validade, nome;

-- ---------------------------------------------------------------------------

-- View 4: Consultas realizadas por unidade de saúde e tipo de consulta. (Interrogação 19)

CREATE OR REPLACE VIEW consultas_realizadas_unidade_saude_tipo_consulta_view AS
SELECT
    Unidade_Saude.nome AS unidade_saude,
    Consulta.tipo_consulta,
    COUNT(*) AS total_consultas
FROM Consulta
JOIN realiza_med_cons
  ON realiza_med_cons.id_consulta = Consulta.id_consulta
JOIN Medico
  ON Medico.id_profissional_saude = realiza_med_cons.id_profissional_saude
JOIN pertence_dept_prof_saude
  ON pertence_dept_prof_saude.id_profissional_saude = Medico.id_profissional_saude
JOIN tem_unid_saude_dept
  ON tem_unid_saude_dept.id_departamento = pertence_dept_prof_saude.id_departamento
JOIN Unidade_Saude
  ON Unidade_Saude.id_unidade_saude = tem_unid_saude_dept.id_unidade_saude
WHERE Consulta.estado = 'Realizada'
GROUP BY Unidade_Saude.nome, Consulta.tipo_consulta;

-- Exemplo de utilização:
-- SELECT * FROM consultas_realizadas_unidade_saude_tipo_consulta_view
-- ORDER BY unidade_saude, tipo_consulta;
