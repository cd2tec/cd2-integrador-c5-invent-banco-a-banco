-- =============================================================================
-- TABLE: DD_SORTER_GPT_RETORNO_FILA
-- Exportado de CD2@2026-07-01 (fonte: banco remoto)
-- =============================================================================

CREATE GLOBAL TEMPORARY TABLE "CD2"."DD_SORTER_GPT_RETORNO_FILA" 
   (	"EMPRESA" NUMBER NOT NULL ENABLE, 
	"ONDA" NUMBER NOT NULL ENABLE, 
	"SEQPRODUTO" NUMBER NOT NULL ENABLE, 
	"LOJA" NUMBER NOT NULL ENABLE, 
	"DATA_FECHAMENTO" DATE
   ) ON COMMIT PRESERVE ROWS
