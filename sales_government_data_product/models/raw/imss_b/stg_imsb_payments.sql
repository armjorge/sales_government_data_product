WITH PAYMENTS_BASE AS ( 
    SELECT 
        UPPER(FOLIO_FISCAL) AS FOLIO_FISCAL
        , TRIM(REFERENCIA) AS REFERENCIA
        , TRY_CAST(REPLACE(IMPORTE, ',', '') AS NUMBER(38, 2)) AS IMPORTE
        , CLC::VARCHAR AS CLC
        , FILE_NAME
        , ETL_FILE_NAME
    FROM {{ source('IMSS_BIENESTAR', 'PAYMENTS') }} 


)

, PAYMENTS_LATEST AS ( 

    SELECT 
        FOLIO_FISCAL
        , REFERENCIA
        , IMPORTE
        , CLC
        , FILE_NAME
        ,TO_TIMESTAMP(
            REGEXP_REPLACE(
                REGEXP_SUBSTR(ETL_FILE_NAME, '\\d{2}-\\d{2}-\\d{4}\\s+\\d{2}\\s+\\d{2}'), 
                '(\\d{2}-\\d{2}-\\d{4}\\s+\\d{2})\\s+(\\d{2})', 
                '\\1:\\2'
            ), 
            'DD-MM-YYYY HH24:MI'
        ) AS BATCH_DATE
        ,CURRENT_TIMESTAMP() AS ETL_LOAD_DATE
    FROM PAYMENTS_BASE
    QUALIFY ROW_NUMBER() OVER(PARTITION BY FOLIO_FISCAL ORDER BY BATCH_DATE DESC) = 1 

)
SELECT 
    FOLIO_FISCAL
    , REFERENCIA
    , IMPORTE
    , CLC
    , FILE_NAME
    , BATCH_DATE
    , ETL_LOAD_DATE
FROM PAYMENTS_LATEST