SET search_path TO bd032_schema, public;

-- ---------------------------------------------------------------------------
-- STORED PROCEDURES
-- ---------------------------------------------------------------------------

-- PROCEDURE: Agendar Consulta
-- Modificar a procedure para forçar um ID maior
CREATE OR REPLACE PROCEDURE agendar_consulta_medico(
    p_id_paciente INT,
    p_id_medico INT,
    p_data_hora TIMESTAMP,
    p_tipo_consulta VARCHAR,
    p_motivo TEXT,
    INOUT p_id_consulta_criada INT DEFAULT NULL
)
AS $$
DECLARE
    v_medico_exists BOOLEAN;
    v_paciente_exists BOOLEAN;
    v_proximo_id INT;
BEGIN
    -- Validar existência do médico
    SELECT EXISTS(SELECT 1 FROM Medico WHERE id_profissional_saude = p_id_medico) INTO v_medico_exists;
    IF NOT v_medico_exists THEN
        RAISE EXCEPTION 'Médico com ID % não existe', p_id_medico;
    END IF;
    
    -- Validar existência do paciente 
    SELECT EXISTS(SELECT 1 FROM Paciente WHERE id_paciente = p_id_paciente) INTO v_paciente_exists;
    IF NOT v_paciente_exists THEN
        RAISE EXCEPTION 'Paciente com ID % não existe', p_id_paciente;
    END IF;
    
    -- Validar data futura da consulta
    IF p_data_hora < CURRENT_TIMESTAMP THEN
        RAISE EXCEPTION 'Não é possível marcar consultas no passado';
    END IF;
    
    -- Obter próximo ID disponível
    SELECT COALESCE(MAX(id_consulta), 0) + 1 INTO v_proximo_id FROM Consulta;
    
    -- Forçar o próximo ID usando OVERRIDING SYSTEM VALUE
    INSERT INTO Consulta (id_consulta, data_hora, tipo_consulta, estado, motivo)
    OVERRIDING SYSTEM VALUE
    VALUES (v_proximo_id, p_data_hora, p_tipo_consulta, 'Marcada', p_motivo)
    RETURNING id_consulta INTO p_id_consulta_criada;

    -- Associar paciente à consulta
    INSERT INTO tem_cons_paci (id_consulta, id_paciente)
    VALUES (p_id_consulta_criada, p_id_paciente);

    -- Associar médico à consulta
    INSERT INTO realiza_med_cons (id_profissional_saude, id_consulta)
    VALUES (p_id_medico, p_id_consulta_criada);
    
    RAISE NOTICE 'Consulta agendada com sucesso. ID da consulta: %', p_id_consulta_criada;
END;
$$ LANGUAGE plpgsql;

-- ---------------------------------------------------------------------------

-- PROCEDURE: Cancelar Consulta
CREATE OR REPLACE PROCEDURE cancelar_consulta(
    p_id_consulta INT
)
AS $$
DECLARE
    v_consulta_exists BOOLEAN;
    v_estado_atual VARCHAR;
BEGIN
    -- Verificar existência da consulta
    SELECT EXISTS(SELECT 1 FROM Consulta WHERE id_consulta = p_id_consulta) INTO v_consulta_exists;
    IF NOT v_consulta_exists THEN
        RAISE EXCEPTION 'Consulta com ID % não existe', p_id_consulta;
    END IF;
    
    -- Obter estado atual da consulta
    SELECT estado INTO v_estado_atual FROM Consulta WHERE id_consulta = p_id_consulta;
    
    -- Validar se já está cancelada
    IF v_estado_atual = 'Cancelada' THEN
        RAISE NOTICE 'Consulta já se encontra cancelada';
        RETURN;
    END IF;
    
    -- Validar se já foi realizada
    IF v_estado_atual = 'Realizada' THEN
        RAISE EXCEPTION 'Não é possível cancelar consultas já realizadas';
    END IF;
    
    -- Cancelar consulta
    UPDATE Consulta 
    SET estado = 'Cancelada' 
    WHERE id_consulta = p_id_consulta;
    
    RAISE NOTICE 'Consulta % cancelada com sucesso', p_id_consulta;
END;
$$ LANGUAGE plpgsql;

-- ---------------------------------------------------------------------------

-- PROCEDURE: Atualizar Consulta Realizada
CREATE OR REPLACE PROCEDURE atualizar_consulta_realizada(
    p_id_consulta INT,
    p_diagnostico TEXT,
    p_observacoes TEXT
)
AS $$
DECLARE
    v_estado_atual VARCHAR;
    v_data_consulta TIMESTAMP;
BEGIN
    -- Verificar existência da consulta
    IF NOT EXISTS (SELECT 1 FROM Consulta WHERE id_consulta = p_id_consulta) THEN
        RAISE EXCEPTION 'Consulta com ID % não existe', p_id_consulta;
    END IF;

    -- Obter estado e data da consulta
    SELECT estado, data_hora INTO v_estado_atual, v_data_consulta FROM Consulta WHERE id_consulta = p_id_consulta;
    
    -- Validar se não está cancelada
    IF v_estado_atual = 'Cancelada' THEN
        RAISE EXCEPTION 'Não é possível atualizar uma consulta cancelada';
    END IF;

    -- Validar se a consulta já ocorreu
    IF v_data_consulta > CURRENT_TIMESTAMP THEN
        RAISE EXCEPTION 'Não é possível atualizar uma consulta que ainda não ocorreu';
    END IF;

    -- Atualizar diagnóstico e observações, e definir estado como 'Realizada'
    UPDATE Consulta
    SET diagnostico = p_diagnostico,
        observacoes = p_observacoes,
        estado = 'Realizada'
    WHERE id_consulta = p_id_consulta;
    
    RAISE NOTICE 'Consulta % atualizada com sucesso - Estado: Realizada', p_id_consulta;
END;
$$ LANGUAGE plpgsql;

-- ---------------------------------------------------------------------------
-- ---------------------------------------------------------------------------
-- Stored funcions para operações complexas (mínimo 5)
-- ---------------------------------------------------------------------------
-- Ex obter todos os médicos de uma determinada especialidade

CREATE OR REPLACE FUNCTION obter_medicos_por_especialidade(especialidade_busca VARCHAR)
RETURNS TABLE(
    id_profissional_saude INT, 
    nome VARCHAR, 
    especialidade VARCHAR,
    anos_experiencia SMALLINT,
    telefone VARCHAR
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        m.id_profissional_saude, 
        ps.nome, 
        m.especialidade,
        m.anos_experiencia,
        ps.telefone
    FROM Medico m
    JOIN Profissional_Saude ps ON m.id_profissional_saude = ps.id_profissional_saude
    WHERE LOWER(m.especialidade) LIKE LOWER('%' || especialidade_busca || '%');
    
    -- Se não encontrar resultados, retorna uma mensagem informativa
    IF NOT FOUND THEN
        RAISE NOTICE 'Nenhum médico encontrado: %', especialidade_busca;
    END IF;
END;
$$ LANGUAGE plpgsql;


-- ---------------------------------------------------------------------------
-- ---------------------------------------------------------------------------
-- Ex obter todas as consultas de um paciente específico

CREATE OR REPLACE FUNCTION obter_consultas_paciente(p_nome_paciente VARCHAR)
RETURNS TABLE(
    id_consulta INT, 
    data_hora TIMESTAMP, 
    tipo_consulta VARCHAR,
    estado VARCHAR, 
    motivo TEXT, 
    diagnostico TEXT,
    nome_medico VARCHAR,
    especialidade_medico VARCHAR,
    nome_paciente VARCHAR
) AS $$
BEGIN
    -- Validar existência do paciente (busca parcial case-insensitive)
    IF NOT EXISTS (
        SELECT 1 FROM Paciente 
        WHERE LOWER(nome) LIKE LOWER('%' || p_nome_paciente || '%')
    ) THEN
        RAISE EXCEPTION 'Nenhum paciente encontrado com o nome: %', p_nome_paciente;
    END IF;
    
    RETURN QUERY
    SELECT 
        c.id_consulta, 
        c.data_hora, 
        c.tipo_consulta, 
        c.estado, 
        c.motivo, 
        c.diagnostico,
        ps.nome AS nome_medico,
        m.especialidade AS especialidade_medico,
        p.nome AS nome_paciente
    FROM Consulta c
    JOIN tem_cons_paci tcp ON c.id_consulta = tcp.id_consulta
    JOIN realiza_med_cons rmc ON c.id_consulta = rmc.id_consulta
    JOIN Medico m ON rmc.id_profissional_saude = m.id_profissional_saude
    JOIN Profissional_Saude ps ON m.id_profissional_saude = ps.id_profissional_saude
    JOIN Paciente p ON tcp.id_paciente = p.id_paciente
    WHERE LOWER(p.nome) LIKE LOWER('%' || p_nome_paciente || '%')
    ORDER BY p.nome, c.data_hora DESC;
    
    IF NOT FOUND THEN
        RAISE NOTICE 'Nenhuma consulta encontrada para pacientes com nome: %', p_nome_paciente;
    END IF;
END;
$$ LANGUAGE plpgsql;





-- ---------------------------------------------------------------------------
-- ---------------------------------------------------------------------------
-- ----------------------------TESTES-----------------------------------------
-- ---------------------------------------------------------------------------
-- ---------------------------------------------------------------------------
-- Chamada 1: Sem retorno do ID
CALL agendar_consulta_medico(1, 5, '2026-12-20 10:00:00', 'Rotina', 'Check-up anual', NULL);

-- Testar atualização de consulta realizada
CALL atualizar_consulta_realizada(2, 'Diagnóstico atualizado', 'Observações adicionais');

-- Testar obtenção de consultas
-- Supondo que o paciente com ID 1 existe e tem consultas
SELECT * FROM obter_consultas_paciente('Silva');      -- Todos os Silva
SELECT * FROM obter_consultas_paciente('Ana');        -- Ana, Anabela, Diana


-- Testar cancelamento
CALL cancelar_consulta(1);



-- Testar obtenção de médicos por especialidade
SELECT * FROM obter_medicos_por_especialidade('Cardiologia');
