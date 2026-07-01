-- =============================================================================
-- PROCEDURE: DD_PRC_BATCH_ENVIO_WORKER
-- Exportado de CD2@2026-07-01 (fonte: banco remoto)
-- =============================================================================

CREATE OR REPLACE PROCEDURE "DD_PRC_BATCH_ENVIO_WORKER" (
  P_WORKER_ID IN VARCHAR2,
  P_LIMIT	  IN NUMBER   DEFAULT 200
) AS
  V_NROCARGA	 NUMBER;
  V_PEND	 NUMBER;
  V_PROGRESSO	 NUMBER;
  V_TS_INICIO	 DATE;
  V_STALE_MIN	 NUMBER := 30;
BEGIN
  IF P_WORKER_ID IS NULL OR TRIM(P_WORKER_ID) IS NULL THEN
    RAISE_APPLICATION_ERROR(-20001, 'P_WORKER_ID OBRIGATORIO');
  END IF;

  UPDATE CD2.DD_SORTER_BATCH_CARGA_CTRL
     SET STATUS = 'PENDENTE',
	 WORKER_ID = NULL,
	 OBS = 'TIMEOUT ' || TO_CHAR(V_STALE_MIN) || 'MIN LIBERADO'
   WHERE STATUS = 'PROCESSANDO'
     AND NVL(DTA_ULTIMO_CICLO, DTA_CLAIM) < SYSDATE - (V_STALE_MIN / 1440);

  BEGIN
    CD2.DD_PRC_BATCH_CARGA_SYNC;
  EXCEPTION
    WHEN OTHERS THEN
      IF SQLCODE = -2049 THEN
	/* Outro worker esta sincronizando a fila: segue com o snapshot atual
	   para nao matar o ciclo por lock distribuido temporario. */
	ROLLBACK;
      ELSE
	RAISE;
      END IF;
  END;

  BEGIN
    SELECT NROCARGA
      INTO V_NROCARGA
      FROM CD2.DD_SORTER_BATCH_CARGA_CTRL
     WHERE STATUS = 'PROCESSANDO'
       AND WORKER_ID = P_WORKER_ID
       AND ROWNUM = 1;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      V_NROCARGA := NULL;
  END;

  IF V_NROCARGA IS NULL THEN
    /* Claim atomico via UPDATE (evita ORA-02014: FOR UPDATE + ORDER BY neste Oracle). */
    IF P_WORKER_ID = 'AUX' THEN
      UPDATE CD2.DD_SORTER_BATCH_CARGA_CTRL
	 SET STATUS = 'PROCESSANDO',
	     WORKER_ID = P_WORKER_ID,
	     DTA_CLAIM = SYSDATE,
	     DTA_ULTIMO_CICLO = SYSDATE,
	     OBS = NULL
       WHERE ROWID = (
	       SELECT RID
		 FROM (
		   SELECT ROWID RID
		     FROM CD2.DD_SORTER_BATCH_CARGA_CTRL
		    WHERE STATUS = 'PENDENTE'
		    ORDER BY PRIORIDADE DESC, VOLS_ELEGIVEIS DESC, NROCARGA DESC
		    FETCH FIRST 1 ROW ONLY
		 )
	     )
      RETURNING NROCARGA INTO V_NROCARGA;
    ELSE
      UPDATE CD2.DD_SORTER_BATCH_CARGA_CTRL
	 SET STATUS = 'PROCESSANDO',
	     WORKER_ID = P_WORKER_ID,
	     DTA_CLAIM = SYSDATE,
	     DTA_ULTIMO_CICLO = SYSDATE,
	     OBS = NULL
       WHERE ROWID = (
	       SELECT RID
		 FROM (
		   SELECT ROWID RID
		     FROM CD2.DD_SORTER_BATCH_CARGA_CTRL
		    WHERE STATUS = 'PENDENTE'
		    ORDER BY PRIORIDADE DESC, VOLS_ELEGIVEIS DESC, NROCARGA DESC
		    FETCH FIRST 1 ROW ONLY
		 )
	     )
      RETURNING NROCARGA INTO V_NROCARGA;
    END IF;

    IF V_NROCARGA IS NULL THEN
      RETURN;
    END IF;

    /* Publica o claim antes do processamento: evita que outros workers
       fiquem esperando a mesma maior carga ate o commit final. */
    COMMIT;
  END IF;

  /* Marca inicio do ciclo: progresso = envio OU buffer gerado durante o ciclo
     (buffer conta como progresso; so BLOQUEIO/ERRO = sem progresso). */
  V_TS_INICIO := SYSDATE;

  CD2.DD_PRC_BATCH_ENVIO(
    P_NROCARGA => V_NROCARGA,
    P_LIMIT    => P_LIMIT
  );

  SELECT COUNT(DISTINCT c.CODBARRAETQ)
    INTO V_PEND
    FROM CD2.DDV_SORTER_CORRELACAO c
    JOIN CD2.DDV_SORTER_CORRELACAO_ENRIQ e
      ON e.CODBARRAETQ = c.CODBARRAETQ
    JOIN CONSINCO.MLO_INTEGRACAOSORTER i
      ON i.CODBARRAETQ = c.CODBARRAETQ
   WHERE e.NROCARGA = V_NROCARGA
     AND NVL(i.INDOPERACAO, ' ') <> 'D'
     AND (
	   UPPER(TRIM(NVL(i.TIPOCARGA, 'E'))) = 'R'
	OR NVL(e.QTD_EMB_SEPARADA, 0) > 0
	 )
     AND NOT EXISTS (
	   SELECT 1
	     FROM CD2.DD_SORTER_EVENTO_CTRL ev
	    WHERE ev.CODBARRAETQ = c.CODBARRAETQ
	      AND ev.ORIGEM = 'ENVIO'
	      AND ev.STATUS_ORIGEM IN ('ENVIADO_INVENT', 'ENVIO_AGG_INVENT')
	 );

  /* Progresso do ciclo: etiquetas desta carga que avancaram (enviadas ou bufferizadas)
     desde V_TS_INICIO. Janela curta + 1 nrocarga => consulta leve. */
  SELECT COUNT(*)
    INTO V_PROGRESSO
    FROM CD2.DD_SORTER_EVENTO_CTRL ev
    JOIN CD2.DDV_SORTER_CORRELACAO_ENRIQ e
      ON e.CODBARRAETQ = ev.CODBARRAETQ
   WHERE e.NROCARGA = V_NROCARGA
     AND ev.ORIGEM = 'ENVIO'
     AND ev.STATUS_ORIGEM IN ('ENVIADO_INVENT', 'ENVIO_AGG_INVENT', 'ENVIO_BUFFER')
     AND ev.DTA_CAPTURA >= V_TS_INICIO;

  IF V_PEND = 0 THEN
    UPDATE CD2.DD_SORTER_BATCH_CARGA_CTRL
       SET STATUS = 'CONCLUIDA',
	   WORKER_ID = NULL,
	   VOLS_ELEGIVEIS = 0,
	   DTA_CONCLUSAO = SYSDATE,
	   DTA_ULTIMO_CICLO = SYSDATE,
	   OBS = 'CARGA CONCLUIDA PELO WORKER ' || P_WORKER_ID
     WHERE NROCARGA = V_NROCARGA;
  ELSIF V_PROGRESSO = 0 THEN
    /* Ciclo sem progresso (nenhum envio/buffer): provavel BLOQUEIO_SEM_CODACESSO/ERRO.
       NAO prende o worker: libera a carga (volta PENDENTE), rebaixa prioridade e
       deixa o worker pegar OUTRA carga no proximo ciclo. Volumes preservados —
       021 reprocessa quando MAP/codacesso for corrigido (sera repega quando a
       fila de prioridade normal esvaziar). */
    UPDATE CD2.DD_SORTER_BATCH_CARGA_CTRL
       SET STATUS = 'PENDENTE',
	   WORKER_ID = NULL,
	   PRIORIDADE = -1,
	   VOLS_ELEGIVEIS = V_PEND,
	   DTA_ULTIMO_CICLO = SYSDATE,
	   OBS = 'SEM PROGRESSO (bloqueio?) - LIBERADA P/ OUTRA CARGA'
     WHERE NROCARGA = V_NROCARGA;
  ELSE
    UPDATE CD2.DD_SORTER_BATCH_CARGA_CTRL
       SET VOLS_ELEGIVEIS = V_PEND,
	   PRIORIDADE = GREATEST(NVL(PRIORIDADE, 0), 0),
	   DTA_ULTIMO_CICLO = SYSDATE
     WHERE NROCARGA = V_NROCARGA;
  END IF;

  COMMIT;
END;
