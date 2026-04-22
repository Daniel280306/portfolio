-- Grupo 32 – Daniel Santos nº 64168; Miguel Lopes nº 42081; Miguel Sousa nº 64150

SET search_path TO bd032_schema, public;

-- ===========================================================================
-- ATUALIZAÇÃO DE ESTATÍSTICAS
-- ===========================================================================

ANALYZE Unidade_Saude;
ANALYZE Departamento;
ANALYZE tem_unid_saude_dept;
ANALYZE Profissional_Saude;
ANALYZE pertence_dept_prof_saude;
ANALYZE Medico;
ANALYZE Enfermeiro;
ANALYZE Consulta;
ANALYZE realiza_med_cons;
ANALYZE participa_enf_cons;
ANALYZE Paciente;
ANALYZE tem_cons_paci;
ANALYZE Historico_Medico;
ANALYZE possui_paci_hist_med;
ANALYZE Prescricao;
ANALYZE Medicamento;
ANALYZE contem_presc_medi;

-- ===========================================================================
-- BENCHMARK DE INTERROGAÇÕES (ANTES DA OTIMIZAÇÃO)
-- ===========================================================================

-- 1. Liste o nome dos pacientes, a data/hora da consulta e o nome do médico responsável, apenas para consultas com o estado "Realizada".

EXPLAIN ANALYZE
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
WHERE Consulta.estado = 'Realizada'
ORDER BY Consulta.data_hora DESC;

-- ---------------------------------------------------------------------------

-- 2. Mostre o nome de cada departamento e o número total de profissionais de saúde que nele trabalham.

EXPLAIN ANALYZE
SELECT
    Departamento.nome AS departamento,
    COUNT(pertence_dept_prof_saude.id_profissional_saude) AS num_profissionais
FROM Departamento
LEFT JOIN pertence_dept_prof_saude
       ON pertence_dept_prof_saude.id_departamento = Departamento.id_departamento
GROUP BY Departamento.nome
ORDER BY num_profissionais DESC, Departamento.nome;

-- ---------------------------------------------------------------------------

-- 3. Liste os pacientes que nunca realizaram qualquer consulta.

EXPLAIN ANALYZE
SELECT
    Paciente.nome
FROM Paciente
WHERE NOT EXISTS (
    SELECT 1
    FROM tem_cons_paci
    WHERE tem_cons_paci.id_paciente = Paciente.id_paciente
);

-- ---------------------------------------------------------------------------

-- 4. Liste os médicos que já realizaram mais de 5 consultas (mostrar nome e total).

EXPLAIN ANALYZE
SELECT
    Profissional_Saude.nome AS medico,
    COUNT(realiza_med_cons.id_consulta) AS num_consultas
FROM realiza_med_cons
JOIN Medico
  ON Medico.id_profissional_saude = realiza_med_cons.id_profissional_saude
JOIN Profissional_Saude
  ON Profissional_Saude.id_profissional_saude = Medico.id_profissional_saude
GROUP BY Profissional_Saude.nome
HAVING COUNT(realiza_med_cons.id_consulta) > 5
ORDER BY num_consultas DESC;

-- ---------------------------------------------------------------------------

-- 5. Mostre o número de consultas por departamento (inferindo o departamento do médico que realizou a consulta).

EXPLAIN ANALYZE
SELECT
    Departamento.nome AS departamento,
    COUNT(*) AS total_consultas
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

EXPLAIN ANALYZE
SELECT
    Paciente.nome AS paciente,
    COUNT(DISTINCT realiza_med_cons.id_profissional_saude) AS medicos_distintos
FROM Paciente
JOIN tem_cons_paci
  ON tem_cons_paci.id_paciente = Paciente.id_paciente
JOIN realiza_med_cons
  ON realiza_med_cons.id_consulta = tem_cons_paci.id_consulta
GROUP BY Paciente.nome
HAVING COUNT(DISTINCT realiza_med_cons.id_profissional_saude) > 1
ORDER BY medicos_distintos DESC, Paciente.nome;

-- ---------------------------------------------------------------------------

-- 7. Liste todas as consultas (data/hora e paciente) e, se existir, o(s) enfermeiro(s) participante(s). Mostre "sem enfermeiro" quando não houver.

EXPLAIN ANALYZE
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

EXPLAIN ANALYZE
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
WHERE Medicamento.categoria = 'Antibiótico'
ORDER BY Paciente.nome;

-- ---------------------------------------------------------------------------

-- 9. Mostre os três medicamentos mais prescritos (contando prescrições distintas).

EXPLAIN ANALYZE
SELECT
    Medicamento.nome AS medicamento,
    COUNT(DISTINCT (contem_presc_medi.id_consulta,
                    contem_presc_medi.id_prescricao)) AS total_prescricoes
FROM contem_presc_medi
JOIN Medicamento
  ON Medicamento.id_medicamento = contem_presc_medi.id_medicamento
GROUP BY Medicamento.nome
ORDER BY total_prescricoes DESC, Medicamento.nome
LIMIT 3;

-- ---------------------------------------------------------------------------

-- 10. Liste os médicos (nome e especialidade) que nunca emitiram uma prescrição. (assumindo que quem prescreve é o médico que realizou a consulta que tem prescrição)

EXPLAIN ANALYZE
SELECT
    Profissional_Saude.nome AS medico,
    Medico.especialidade
FROM Medico
JOIN Profissional_Saude
ON Profissional_Saude.id_profissional_saude = Medico.id_profissional_saude
WHERE NOT EXISTS (
    SELECT 1
    FROM realiza_med_cons
    JOIN Prescricao
      ON Prescricao.id_consulta = realiza_med_cons.id_consulta
    WHERE realiza_med_cons.id_profissional_saude = Medico.id_profissional_saude
);

-- ---------------------------------------------------------------------------

-- 11. Mostre, para cada unidade de saúde, o número de departamentos, de médicos e de enfermeiros associados.

EXPLAIN ANALYZE
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

EXPLAIN ANALYZE
SELECT
    pacientes_consultas.id_paciente,
    pacientes_consultas.nome,
    pacientes_consultas.num_consultas,
    AVG(pacientes_consultas.num_consultas) OVER () AS media_consultas_paciente
FROM (
    SELECT
        Paciente.id_paciente,
        Paciente.nome,
        COUNT(tem_cons_paci.id_consulta) AS num_consultas
    FROM Paciente
    LEFT JOIN tem_cons_paci
           ON tem_cons_paci.id_paciente = Paciente.id_paciente
    GROUP BY Paciente.id_paciente, Paciente.nome
) AS pacientes_consultas
ORDER BY pacientes_consultas.num_consultas DESC, pacientes_consultas.nome;

-- ---------------------------------------------------------------------------

-- 13. Mostre o estado do stock de todos os medicamentos, classificando como "Esgotado", "Abaixo do nível mínimo" ou "OK".

EXPLAIN ANALYZE
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

EXPLAIN ANALYZE
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
  AND Consulta.data_hora > NOW()
GROUP BY Profissional_Saude.nome
ORDER BY data_hora_proxima_consulta;

-- ---------------------------------------------------------------------------

-- 15. Liste os médicos cuja carga de trabalho (número de consultas realizadas) nos últimos 30 dias está acima da média.

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
    Profissional_Saude.nome AS medico,
    consultas_ultimos_30_dias.num_consultas
FROM consultas_ultimos_30_dias
JOIN media
  ON consultas_ultimos_30_dias.num_consultas > media.media_consultas
JOIN Profissional_Saude
  ON Profissional_Saude.id_profissional_saude = consultas_ultimos_30_dias.id_profissional_saude
ORDER BY consultas_ultimos_30_dias.num_consultas DESC;

-- ---------------------------------------------------------------------------

-- 16. Para cada paciente, mostre o número total de consultas e a distribuição por estado ("Marcada", "Realizada", "Cancelada").

EXPLAIN ANALYZE
SELECT
    Paciente.id_paciente,
    Paciente.nome,
    COUNT(Consulta.id_consulta) AS total_consultas,
    SUM(CASE WHEN Consulta.estado = 'Marcada' THEN 1 ELSE 0 END) AS consultas_marcadas,
    SUM(CASE WHEN Consulta.estado = 'Realizada' THEN 1 ELSE 0 END) AS consultas_realizadas,
    SUM(CASE WHEN Consulta.estado = 'Cancelada' THEN 1 ELSE 0 END) AS consultas_canceladas
FROM Paciente
LEFT JOIN tem_cons_paci
       ON tem_cons_paci.id_paciente = Paciente.id_paciente
LEFT JOIN Consulta
       ON Consulta.id_consulta = tem_cons_paci.id_consulta
GROUP BY Paciente.id_paciente, Paciente.nome
ORDER BY total_consultas DESC, Paciente.nome;

-- ---------------------------------------------------------------------------

-- 17. Liste as consultas realizadas que não têm qualquer prescrição associada.

EXPLAIN ANALYZE
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
AND NOT EXISTS (
    SELECT 1
    FROM Prescricao
    WHERE Prescricao.id_consulta = Consulta.id_consulta
)
ORDER BY Consulta.data_hora DESC;

-- ---------------------------------------------------------------------------

-- 18. Liste os medicamentos em situação de risco: stock abaixo do nível mínimo e/ou validade a expirar nos próximos 30 dias.

EXPLAIN ANALYZE
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
   OR Medicamento.data_validade <= CURRENT_DATE + INTERVAL '30 days'
ORDER BY estado_stock, Medicamento.data_validade, Medicamento.nome;

-- ---------------------------------------------------------------------------

-- 19. Mostre, para cada unidade de saúde e tipo de consulta, o número total de consultas realizadas.

EXPLAIN ANALYZE
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
GROUP BY Unidade_Saude.nome, Consulta.tipo_consulta
ORDER BY Unidade_Saude.nome, Consulta.tipo_consulta;

-- ---------------------------------------------------------------------------

-- 20. Mostre a timeline do histórico médico de um paciente, ordenada da data mais recente para a mais antiga. (assumindo paciente id = 1; pode-se alterar para outro)

EXPLAIN ANALYZE
SELECT
    Historico_Medico.data_registo,
    Historico_Medico.condicao,
    Historico_Medico.descricao
FROM Historico_Medico
JOIN possui_paci_hist_med
  ON possui_paci_hist_med.id_historico_medico = Historico_Medico.id_historico_medico
JOIN Paciente
  ON Paciente.id_paciente = possui_paci_hist_med.id_paciente
WHERE Paciente.id_paciente = 1
ORDER BY Historico_Medico.data_registo DESC;

-- ===========================================================================
-- BENCHMARK DE PROCEDURES / TRANSAÇÕES
-- ===========================================================================

-- As operações de negócio críticas (atualização de consulta realizada,
-- criação de prescrição, associação de medicamentos e atualização de stock)
-- foram implementadas em procedures e funções no ficheiro procedures.sql.

-- Foi tentado um benchmark automático destas operações com blocos DO,
-- clock_timestamp() e ROLLBACK para não persistir alterações. No entanto,
-- devido a limitações e inconsistências no ambiente de teste (erros de
-- resolução de funções/procedures e de schema), optou-se por deixar esses 
-- blocos comentados para garantir que o ficheiro é executável sem erros.

-- A análise de transações (BEGIN/COMMIT implícitos, ROLLBACK em caso de
-- RAISE EXCEPTION) e a discussão do comportamento em caso de erro são
-- apresentadas no relatório, com base na lógica das procedures definidas.

-- BEGIN; -- Benchmark da procedure atualizar_consulta_realizada
-- DO $$
-- DECLARE
--     start_time timestamp;
--     end_time   timestamp;
--     duracao    interval;
-- BEGIN
--     start_time := clock_timestamp();

--     CALL atualizar_consulta_realizada(33, 'Diagnóstico atualizado', 'Observações adicionais');

--     end_time := clock_timestamp();
--     duracao := end_time - start_time;

--     RAISE NOTICE 'Tempo atualizar_consulta_realizada: %', 
--     duracao;
-- END $$;
-- ROLLBACK;

-- ---------------------------------------------------------------------------

-- BEGIN; -- Benchmark da criação de prescrição + associação de medicamento
-- DO $$
-- DECLARE
--     start_time      timestamp;
--     end_time        timestamp;
--     duracao         interval;
--     v_id_prescricao INT;
-- BEGIN
--     start_time := clock_timestamp();

--     SELECT criar_prescricao(2, 'Tratamento de 7 dias.') -- Criar prescrição
--     INTO v_id_prescricao;

--     PERFORM adicionar_medicamento_prescricao(2, v_id_prescricao, 10); -- Associar medicamento

--     end_time := clock_timestamp();
--     duracao := end_time - start_time;

--     RAISE NOTICE
--         'Tempo criar_prescricao + adicionar_medicamento_prescricao: %',
--         duracao;
-- END $$;
-- ROLLBACK;

-- ---------------------------------------------------------------------------

-- BEGIN; -- Benchmark da procedure atualizar_stock_medicamento
-- DO $$
-- DECLARE
--     start_time timestamp;
--     end_time   timestamp;
--     duracao    interval;
-- BEGIN
--     start_time := clock_timestamp();

--     CALL atualizar_stock_medicamento(1, 50, 'adicionar');

--     end_time := clock_timestamp();
--     duracao := end_time - start_time;

--     RAISE NOTICE
--         'Tempo atualizar_stock_medicamento (adicionar 50 unidades): %',
--         duracao;
-- END $$;
-- ROLLBACK;

-- ===========================================================================
-- BENCHMARK DE ESCRITA (TRADE-OFF COM ÍNDICES)
-- ===========================================================================

-- Estava previsto um teste de INSERT em massa na tabela Consulta, usando
-- generate_series, para medir o impacto da criação de índices em operações
-- de escrita (tempo de INSERT sem índices vs com índices).

-- Esse benchmark foi experimentado com um bloco DO + ROLLBACK, mas gerou
-- erros intermitentes no ambiente (por exemplo, relation "Consulta" does not
-- exist em certas sessões), pelo que foi deixado comentado para manter o 
-- ficheiro estável.

-- O trade-off entre:
--    - leituras mais rápidas (SELECT) graças aos índices, e
--    - escritas mais lentas (INSERT/UPDATE/DELETE) devido à atualização dos
--     índices
-- é discutido no relatório, apoiado nos resultados de EXPLAIN ANALYZE antes
-- e depois da criação de índices nas interrogações selecionadas.

-- BEGIN;
-- DO $$
-- DECLARE
--     start_time timestamp;
--     end_time   timestamp;
--     duracao    interval;
-- BEGIN
--     start_time := clock_timestamp();

--     INSERT INTO Consulta (data_hora, tipo_consulta, estado, motivo)
--     SELECT
--         CURRENT_TIMESTAMP + (i || ' minutes')::interval,
--         'Rotina',
--         'Marcada',
--         'Consulta gerada para benchmark de escrita'
--     FROM generate_series(1, 5000) AS i;

--     end_time := clock_timestamp();
--     duracao := end_time - start_time;

--     RAISE NOTICE 'Tempo INSERT (5000 consultas): %', 
--     duracao;
-- END $$;
-- ROLLBACK;
