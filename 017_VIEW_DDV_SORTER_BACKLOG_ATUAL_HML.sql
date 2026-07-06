-- =============================================================================
-- VIEW: DDV_SORTER_BACKLOG_ATUAL_HML
-- Exportado de CD2@2026-07-06 (fonte: banco remoto)
-- =============================================================================

CREATE OR REPLACE VIEW CD2."DDV_SORTER_BACKLOG_ATUAL_HML" AS
SELECT
  STATUS_CONCILIACAO,
  COUNT(*) AS QTD
FROM CD2.DDV_SORTER_PENDENCIAS
GROUP BY STATUS_CONCILIACAO
