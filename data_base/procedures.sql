-- Grupo 32 – Daniel Santos nº 64168; Miguel Lopes nº 42081; Miguel Sousa nº 64150

SET search_path TO bd032_schema_just_testing, public;

-- ===========================================================================
-- PROCEDURES
-- ===========================================================================

CREATE OR REPLACE PROCEDURE agendar_consulta_paciente_medico ( -- PROCEDURE agenda nova consulta para um paciente e médico
    IN p_id_paciente         INT,
    IN p_id_medico           INT,
    IN p_data_hora           TIMESTAMP,
    IN p_tipo_consulta       VARCHAR(20),
    IN p_motivo              TEXT,
    OUT p_id_consulta_criada INT
)
AS $$
DECLARE
    v_medico_existe   BOOLEAN;
    v_paciente_existe BOOLEAN;
BEGIN
    SELECT EXISTS ( -- Verifica se o paciente existe
        SELECT 1
        FROM Paciente
        WHERE Paciente.id_paciente = p_id_paciente
    )
    INTO v_paciente_existe;

    IF NOT v_paciente_existe THEN
        RAISE EXCEPTION
            'Paciente com ID % não existe.',
            p_id_paciente;
    END IF;

    SELECT EXISTS ( -- Verifica se o médico existe
        SELECT 1
        FROM Medico
        WHERE Medico.id_profissional_saude = p_id_medico
    )
    INTO v_medico_existe;

    IF NOT v_medico_existe THEN
        RAISE EXCEPTION
            'Médico com ID % não existe.',
            p_id_medico;
    END IF;

    IF p_data_hora < CURRENT_TIMESTAMP THEN
        RAISE EXCEPTION
            'Não é possível marcar consultas no passado.';
    END IF;

    INSERT INTO Consulta (data_hora, tipo_consulta, estado, motivo) -- Cria a consulta e devolve o ID
    VALUES (p_data_hora, p_tipo_consulta, 'Marcada', p_motivo)
    RETURNING id_consulta INTO p_id_consulta_criada;

    INSERT INTO tem_cons_paci (id_consulta, id_paciente) -- Associa o paciente à consulta
    VALUES (p_id_consulta_criada, p_id_paciente);

    INSERT INTO realiza_med_cons (id_profissional_saude, id_consulta) -- Associa o médico à consulta
    VALUES (p_id_medico, p_id_consulta_criada);

    RAISE NOTICE
        'Consulta agendada com sucesso. ID: %',
        p_id_consulta_criada;
END;
$$ LANGUAGE plpgsql;

-- ---------------------------------------------------------------------------

CREATE OR REPLACE PROCEDURE cancelar_consulta ( -- PROCEDURE cancela consulta existente
    p_id_consulta INT
)
AS $$
DECLARE
    v_consulta_existe BOOLEAN;
    v_estado_atual    VARCHAR(20);
BEGIN
    SELECT EXISTS ( -- Verifica se a consulta existe
        SELECT 1
        FROM Consulta
        WHERE Consulta.id_consulta = p_id_consulta
    )
    INTO v_consulta_existe;

    IF NOT v_consulta_existe THEN
        RAISE EXCEPTION
            'Consulta com ID % não existe.',
            p_id_consulta;
    END IF;

    SELECT estado -- Obtém o estado atual
    INTO v_estado_atual
    FROM Consulta
    WHERE Consulta.id_consulta = p_id_consulta;

    IF v_estado_atual = 'Cancelada' THEN
        RAISE NOTICE
            'A consulta % já se encontra cancelada.',
            p_id_consulta;
        RETURN;
    END IF;

    IF v_estado_atual = 'Realizada' THEN
        RAISE EXCEPTION
            'Não é possível cancelar consultas já realizadas.';
    END IF;

    UPDATE Consulta -- Atualiza o estado da consulta para "Cancelada"
    SET estado = 'Cancelada',
        motivo = COALESCE(motivo, 'Consulta cancelada.')
    WHERE Consulta.id_consulta = p_id_consulta;

    RAISE NOTICE
        'Consulta % cancelada com sucesso.',
        p_id_consulta;
END;
$$ LANGUAGE plpgsql;

-- ---------------------------------------------------------------------------

CREATE OR REPLACE PROCEDURE atualizar_consulta_realizada ( -- PROCEDURE atualiza consulta para "Realizada"
    p_id_consulta INT,
    p_diagnostico TEXT,
    p_observacoes TEXT
)
AS $$
DECLARE
    v_consulta_existe BOOLEAN;
    v_data_hora       TIMESTAMP;
    v_estado_atual    VARCHAR(20);
BEGIN
    SELECT EXISTS ( -- Verifica se a consulta existe
        SELECT 1
        FROM Consulta
        WHERE Consulta.id_consulta = p_id_consulta
    )
    INTO v_consulta_existe;

    IF NOT v_consulta_existe THEN
        RAISE EXCEPTION
            'Consulta com ID % não existe.',
            p_id_consulta;
    END IF;

    SELECT data_hora, estado -- Obtém estado atual e a data/hora da consulta
    INTO v_data_hora, v_estado_atual
    FROM Consulta
    WHERE Consulta.id_consulta = p_id_consulta;

    IF v_data_hora > CURRENT_TIMESTAMP THEN
        RAISE EXCEPTION
            'Não é possível atualizar uma consulta que ainda não ocorreu.';
    END IF;

    IF v_estado_atual = 'Cancelada' THEN
        RAISE EXCEPTION
            'Não é possível atualizar uma consulta cancelada.';
    END IF;

    UPDATE Consulta -- Atualiza o estado da consulta para "Realizada"; atualiza os dados clínicos
    SET estado = 'Realizada',
        diagnostico = p_diagnostico,
        observacoes = p_observacoes
    WHERE Consulta.id_consulta = p_id_consulta;

    RAISE NOTICE
        'Consulta % atualizada para "Realizada" com sucesso.',
        p_id_consulta;
END;
$$ LANGUAGE plpgsql;

-- ===========================================================================
-- FUNCTIONS
-- ===========================================================================

CREATE OR REPLACE FUNCTION obter_consultas_paciente ( -- FUNCTION obtém consultas de pacientes por nome
    p_nome_paciente VARCHAR(100)
)
RETURNS TABLE (
    id_consulta          INT,
    data_hora            TIMESTAMP,
    tipo_consulta        VARCHAR(20),
    estado               VARCHAR(20),
    motivo               TEXT,
    diagnostico          TEXT,
    nome_medico          VARCHAR(100),
    especialidade_medico VARCHAR(100),
    nome_paciente        VARCHAR(100)
)
AS $$
BEGIN
    IF NOT EXISTS ( -- Verifica se o paciente com nome x existe
        SELECT 1
        FROM Paciente
        WHERE LOWER(Paciente.nome) LIKE LOWER('%' || p_nome_paciente || '%')
    ) THEN
        RAISE EXCEPTION
            'Nenhum paciente encontrado com o nome: %',
            p_nome_paciente;
    END IF;

    RETURN QUERY
    SELECT
        Consulta.id_consulta,
        Consulta.data_hora,
        Consulta.tipo_consulta,
        Consulta.estado,
        Consulta.motivo,
        Consulta.diagnostico,
        Profissional_Saude.nome AS nome_medico,
        Medico.especialidade AS especialidade_medico,
        Paciente.nome AS nome_paciente
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
    WHERE LOWER(Paciente.nome) LIKE LOWER('%' || p_nome_paciente || '%')
    ORDER BY Paciente.nome, Consulta.data_hora DESC;

    IF NOT FOUND THEN
        RAISE NOTICE
            'Nenhuma consulta encontrada para pacientes com nome: %',
            p_nome_paciente;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION criar_prescricao ( -- FUNCTION cria prescrição para uma consulta
    p_id_consulta INT,
    p_descricao   TEXT DEFAULT NULL
)
RETURNS INT
AS $$
DECLARE
    v_id_prescricao INT;
BEGIN
    IF NOT EXISTS ( -- Verifica se a consulta existe
        SELECT 1
        FROM Consulta
        WHERE Consulta.id_consulta = p_id_consulta
    ) THEN
        RAISE EXCEPTION
            'Não é possível criar prescrição: consulta % não existe.',
            p_id_consulta;
    END IF;

    INSERT INTO Prescricao (id_consulta, data_emissao, descricao)
    VALUES (p_id_consulta, CURRENT_DATE, p_descricao)
    RETURNING id_prescricao INTO v_id_prescricao; -- Cria a prescrição e devolve o ID

    RAISE NOTICE
        'Prescrição % criada para a consulta %.',
        v_id_prescricao, p_id_consulta;

    RETURN v_id_prescricao;
END;
$$ LANGUAGE plpgsql;

-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION adicionar_medicamento_prescricao ( -- FUNCTION associa um medicamento a uma prescrição e atualiza o stock do mesmo
    p_id_consulta    INT,
    p_id_prescricao  INT,
    p_id_medicamento INT
)
RETURNS VOID
AS $$
DECLARE
    v_stock_atual INT;
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM Prescricao
        WHERE Prescricao.id_consulta = p_id_consulta
          AND Prescricao.id_prescricao = p_id_prescricao
    ) THEN
        RAISE EXCEPTION
            'Prescrição (% , consulta %) não existe.',
            p_id_prescricao, p_id_consulta;
    END IF;

    SELECT quantidade_stock -- Obtém stock atual
    INTO v_stock_atual
    FROM Medicamento
    WHERE Medicamento.id_medicamento = p_id_medicamento;

    IF v_stock_atual IS NULL THEN
        RAISE EXCEPTION
            'Medicamento com ID % não existe.',
            p_id_medicamento;
    END IF;

    IF v_stock_atual < 1 THEN
        RAISE EXCEPTION
            'Stock insuficiente para o medicamento % (stock atual = 0).',
            p_id_medicamento;
    END IF;

    INSERT INTO contem_presc_medi (id_consulta, id_prescricao, id_medicamento) -- Associa o medicamento à prescrição
    VALUES (p_id_consulta, p_id_prescricao, p_id_medicamento);

    UPDATE Medicamento -- Diminui o stock do medicamento em 1
    SET quantidade_stock = quantidade_stock - 1
    WHERE Medicamento.id_medicamento = p_id_medicamento;

    RAISE NOTICE
        'Medicamento % associado à prescrição % (consulta %). Stock atualizado.',
        p_id_medicamento, p_id_prescricao, p_id_consulta;
END;
$$ LANGUAGE plpgsql;

-- ---------------------------------------------------------------------------

-- Exemplos de utilização:

-- CALL agendar_consulta_paciente_medico(1, 5, '2026-12-20 10:00:00', 'Rotina', 'Check-up anual');
-- CALL cancelar_consulta(1);
-- CALL atualizar_consulta_realizada(2, 'Diagnóstico atualizado', 'Observações adicionais');
-- SELECT * FROM obter_consultas_paciente('Silva');
-- SELECT criar_prescricao(2, 'Tratamento de 7 dias.');
-- SELECT adicionar_medicamento_prescricao(2, 1, 10);
