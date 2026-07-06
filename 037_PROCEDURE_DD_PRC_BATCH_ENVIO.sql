-- =============================================================================
-- PROCEDURE: DD_PRC_BATCH_ENVIO
-- Exportado de CD2@2026-07-06 (fonte: banco remoto)
-- =============================================================================

CREATE OR REPLACE PROCEDURE       "DD_PRC_BATCH_ENVIO" (
P_PREFIXO_ETIQUETA IN VARCHAR2 DEFAULT '%',
P_LIMIT	     IN NUMBER	 DEFAULT 100,
P_NROCARGA_MIN	   IN NUMBER	 DEFAULT NULL,
P_NROCARGA	   IN NUMBER	 DEFAULT NULL
) AS
V_ERR VARCHAR2(4000);
V_N_ENV  NUMBER := 0;
BEGIN
/* Fase 1 - ENVIO: somente etiquetas ainda nao enviadas ao Invent.
   Performance: P_LIMIT curto por ciclo (job passa 100).
   Ordem: elegiveis primeiro (nrocarga DESC); BLOQUEIO_SEM_CODACESSO por ultimo
   (021 ainda reprocessa — MAP/codacesso pode ter sido corrigido). Gate 021 inalterado. */
FOR R IN (
  SELECT ranked.CODBARRAETQ
    FROM (
	SELECT b.CODBARRAETQ,
	       ROW_NUMBER() OVER (
		 ORDER BY b.prioridade_bloqueio,
			  b.nrocarga DESC,
			  b.CODBARRAETQ
	       ) AS seq
	  FROM (
	    SELECT c.CODBARRAETQ,
		   e.NROCARGA,
		   CASE
		     WHEN EXISTS (
		       SELECT 1
			 FROM CD2.DD_SORTER_EVENTO_CTRL evb
			WHERE evb.CODBARRAETQ = c.CODBARRAETQ
			  AND evb.ORIGEM = 'ENVIO'
			  AND evb.STATUS_ORIGEM = 'BLOQUEIO_SEM_CODACESSO'
		     ) THEN 1
		     ELSE 0
		   END AS prioridade_bloqueio,
		   ROW_NUMBER() OVER (
		     PARTITION BY c.CODBARRAETQ
		     ORDER BY c.CODBARRAETQ
		   ) AS dedupe_rn
	      FROM CD2.DDV_SORTER_CORRELACAO c
	      JOIN CD2.DDV_SORTER_CORRELACAO_ENRIQ e
		ON e.CODBARRAETQ = c.CODBARRAETQ
	      JOIN CONSINCO.MLO_INTEGRACAOSORTER i
		ON i.CODBARRAETQ = c.CODBARRAETQ
	     WHERE c.CODBARRAETQ LIKE P_PREFIXO_ETIQUETA
	       AND (P_NROCARGA IS NULL OR e.NROCARGA = P_NROCARGA)
	       AND (P_NROCARGA IS NOT NULL OR P_NROCARGA_MIN IS NULL OR e.NROCARGA >= P_NROCARGA_MIN)
	       AND (
		     P_NROCARGA IS NOT NULL
		  OR NOT EXISTS (
		       SELECT 1
			 FROM CD2.DD_SORTER_BATCH_CARGA_CTRL cc
			WHERE cc.NROCARGA = e.NROCARGA
			  AND cc.STATUS = 'PROCESSANDO'
		     )
		   )
	       AND (
		     UPPER(TRIM(NVL(i.TIPOCARGA, 'E'))) = 'R'
		  OR NVL(e.QTD_EMB_SEPARADA, 0) > 0
		   )
	       AND NOT EXISTS (
		     SELECT 1
		       FROM CD2.DD_SORTER_EVENTO_CTRL ev
		      WHERE ev.CODBARRAETQ = c.CODBARRAETQ
			AND ev.ORIGEM = 'ENVIO'
			AND ev.STATUS_ORIGEM IN (
			      'ENVIADO_INVENT', 'ENVIO_AGG_INVENT'
			    )
		   )
	  ) b
	 WHERE b.dedupe_rn = 1
    ) ranked
   WHERE ranked.seq <= P_LIMIT
) LOOP
  BEGIN
    CD2.DD_PRC_ENVIA_C5_INVENT(P_CODBARRAETQ => R.CODBARRAETQ);
    V_N_ENV := V_N_ENV + 1;
  EXCEPTION
    WHEN OTHERS THEN
	ROLLBACK;
	V_ERR := SUBSTR(SQLERRM, 1, 3500);
	INSERT INTO CD2.DD_SORTER_EVENTO_CTRL (
	  ID_EVENTO, CODBARRAETQ, ORIGEM, STATUS_ORIGEM, DTA_EVENTO_ORIGEM, DTA_CAPTURA, HASH_EVENTO, OBS
	) VALUES (
	  CD2.SQ_DD_SORTER_EVENTO_CTRL.NEXTVAL,
	  R.CODBARRAETQ,
	  'BATCH',
	  'ERRO_ENVIO',
	  SYSDATE,
	  SYSDATE,
	  R.CODBARRAETQ || '|BATCH|ERRO_ENV|' || TO_CHAR(SYSDATE, 'YYYYMMDDHH24MISS'),
	  V_ERR
	);
	COMMIT;
  END;
END LOOP;
END;
