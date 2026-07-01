-- =============================================================================
-- JOBS: PROD_ENVIO_3W_RETORNO_6W
-- Exportado de CD2@2026-07-01 (fonte: banco remoto)
-- =============================================================================

-- Jobs de producao ativos em 2026-07-01
-- Envio: 3 workers | Retorno: 6 workers V3


BEGIN
  SYS.DBMS_SCHEDULER.CREATE_JOB(
    job_name        => 'CD2.DD_JOB_BATCH_ENVIO_W1',
    job_type        => 'PLSQL_BLOCK',
    job_action      => q'[BEGIN CD2.DD_PRC_BATCH_ENVIO_WORKER(P_WORKER_ID => 'W1', P_LIMIT => 200); END;]',
    start_date      => SYSTIMESTAMP,
    repeat_interval => 'FREQ=MINUTELY;INTERVAL=5',
    enabled         => TRUE,
    auto_drop       => FALSE,
    comments        => 'Worker W1: 1 NROCARGA por vez'
  );
END;
/


BEGIN
  SYS.DBMS_SCHEDULER.CREATE_JOB(
    job_name        => 'CD2.DD_JOB_BATCH_ENVIO_W2',
    job_type        => 'PLSQL_BLOCK',
    job_action      => q'[BEGIN CD2.DD_PRC_BATCH_ENVIO_WORKER(P_WORKER_ID => 'W2', P_LIMIT => 200); END;]',
    start_date      => SYSTIMESTAMP,
    repeat_interval => 'FREQ=MINUTELY;INTERVAL=5',
    enabled         => TRUE,
    auto_drop       => FALSE,
    comments        => 'Worker W2: 1 NROCARGA por vez'
  );
END;
/


BEGIN
  SYS.DBMS_SCHEDULER.CREATE_JOB(
    job_name        => 'CD2.DD_JOB_BATCH_ENVIO_W3',
    job_type        => 'PLSQL_BLOCK',
    job_action      => q'[BEGIN CD2.DD_PRC_BATCH_ENVIO_WORKER(P_WORKER_ID => 'W3', P_LIMIT => 200); END;]',
    start_date      => SYSTIMESTAMP,
    repeat_interval => 'FREQ=MINUTELY;INTERVAL=5',
    enabled         => TRUE,
    auto_drop       => FALSE,
    comments        => 'Worker W3: 1 NROCARGA por vez'
  );
END;
/


BEGIN
  SYS.DBMS_SCHEDULER.CREATE_JOB(
    job_name        => 'CD2.DD_JOB_BATCH_RETORNO_W1',
    job_type        => 'PLSQL_BLOCK',
    job_action      => q'[BEGIN CD2.DD_PRC_BATCH_RETORNO_V3(P_LIMIT => 100, P_WORKER_ID => 0, P_TOTAL_WORKERS => 6); END;]',
    start_date      => SYSTIMESTAMP,
    repeat_interval => 'FREQ=MINUTELY;INTERVAL=5',
    enabled         => TRUE,
    auto_drop       => FALSE,
    comments        => 'Retorno V3 GPT-first worker 1/6'
  );
END;
/


BEGIN
  SYS.DBMS_SCHEDULER.CREATE_JOB(
    job_name        => 'CD2.DD_JOB_BATCH_RETORNO_W2',
    job_type        => 'PLSQL_BLOCK',
    job_action      => q'[BEGIN CD2.DD_PRC_BATCH_RETORNO_V3(P_LIMIT => 100, P_WORKER_ID => 1, P_TOTAL_WORKERS => 6); END;]',
    start_date      => SYSTIMESTAMP,
    repeat_interval => 'FREQ=MINUTELY;INTERVAL=5',
    enabled         => TRUE,
    auto_drop       => FALSE,
    comments        => 'Retorno V3 GPT-first worker 2/6'
  );
END;
/


BEGIN
  SYS.DBMS_SCHEDULER.CREATE_JOB(
    job_name        => 'CD2.DD_JOB_BATCH_RETORNO_W3',
    job_type        => 'PLSQL_BLOCK',
    job_action      => q'[BEGIN CD2.DD_PRC_BATCH_RETORNO_V3(P_LIMIT => 100, P_WORKER_ID => 2, P_TOTAL_WORKERS => 6); END;]',
    start_date      => SYSTIMESTAMP,
    repeat_interval => 'FREQ=MINUTELY;INTERVAL=5',
    enabled         => TRUE,
    auto_drop       => FALSE,
    comments        => 'Retorno V3 GPT-first worker 3/6'
  );
END;
/


BEGIN
  SYS.DBMS_SCHEDULER.CREATE_JOB(
    job_name        => 'CD2.DD_JOB_BATCH_RETORNO_W4',
    job_type        => 'PLSQL_BLOCK',
    job_action      => q'[BEGIN CD2.DD_PRC_BATCH_RETORNO_V3(P_LIMIT => 100, P_WORKER_ID => 3, P_TOTAL_WORKERS => 6); END;]',
    start_date      => SYSTIMESTAMP,
    repeat_interval => 'FREQ=MINUTELY;INTERVAL=5',
    enabled         => TRUE,
    auto_drop       => FALSE,
    comments        => 'Retorno V3 GPT-first worker 4/6'
  );
END;
/


BEGIN
  SYS.DBMS_SCHEDULER.CREATE_JOB(
    job_name        => 'CD2.DD_JOB_BATCH_RETORNO_W5',
    job_type        => 'PLSQL_BLOCK',
    job_action      => q'[BEGIN CD2.DD_PRC_BATCH_RETORNO_V3(P_LIMIT => 100, P_WORKER_ID => 4, P_TOTAL_WORKERS => 6); END;]',
    start_date      => SYSTIMESTAMP,
    repeat_interval => 'FREQ=MINUTELY;INTERVAL=5',
    enabled         => TRUE,
    auto_drop       => FALSE,
    comments        => 'Retorno V3 GPT-first worker 5/6'
  );
END;
/


BEGIN
  SYS.DBMS_SCHEDULER.CREATE_JOB(
    job_name        => 'CD2.DD_JOB_BATCH_RETORNO_W6',
    job_type        => 'PLSQL_BLOCK',
    job_action      => q'[BEGIN CD2.DD_PRC_BATCH_RETORNO_V3(P_LIMIT => 100, P_WORKER_ID => 5, P_TOTAL_WORKERS => 6); END;]',
    start_date      => SYSTIMESTAMP,
    repeat_interval => 'FREQ=MINUTELY;INTERVAL=5',
    enabled         => TRUE,
    auto_drop       => FALSE,
    comments        => 'Retorno V3 GPT-first worker 6/6'
  );
END;
/
