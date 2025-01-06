-- Lithuanian Vehicle fleet data analysis
-- 1.1 Deduplicate and clean brand and model names, then merge with the main dataset
Regitra_aktualus_autoparkas_cleaned
WITH unique_names_dedup AS (
    SELECT 
        marke, 
        modelis, 
        MAX(cleaned_marke) AS cleaned_marke, 
        MAX(cleaned_modelis) AS cleaned_modelis
    FROM unique_names_regitra
    GROUP BY marke, modelis
)
-- Merge cleaned brand and model names with the `regitra_aktualus_autoparkas` dataset
SELECT 
    a.*, 
    u.cleaned_marke, 
    u.cleaned_modelis
FROM 
    regitra_aktualus_autoparkas a
LEFT JOIN 
    (
        SELECT DISTINCT 
            LOWER(REPLACE(marke, ',', '')) AS marke, 
            LOWER(REPLACE(modelis, ',', '')) AS modelis, 
            cleaned_marke, 
            cleaned_modelis
        FROM unique_names_dedup
    ) u
ON 
    LOWER(REPLACE(a.marke, ',', '')) = u.marke 
    AND LOWER(REPLACE(a.modelis, ',', '')) = u.modelis;

-- 1.2 Count total records and the presence of key columns after merging cleaned data
SELECT 
    COUNT(*) AS total_records,
    COUNT(cleaned_marke) AS cleaned_marke_count,
    COUNT(cleaned_modelis) AS cleaned_modelis_count,
    COUNT(marke) AS original_marke_count,
    COUNT(modelis) AS original_modelis_count
FROM Regitra_aktualus_autoparkas_cleaned;


-- 1.3 Group by VIN and concatenate brand and model data

Filter_data
WITH vin_group AS (
  SELECT 
    vin_hashed,
    tp_kodas_concated, -- Use concatenated code for grouping
    COALESCE(
        CONCAT(cleaned_marke, ' ', cleaned_modelis),
        CONCAT(marke, ' ', modelis)
        ) AS cleaned_marke_modelis,  -- Use cleaned brand and model, fallback to original
    COUNT(DISTINCT tp_id) AS unique_tp_id_kiekis -- Count unique `tp_id`
  FROM 
    regitra_aktualus_autoparkas_cleaned_marke_modelis
  WHERE 
    vin_hashed NOT IN ('e6a069e21889f2a', 'a4816df713a2593') -- We remove these vin_hashed so you can see the real picture, as these are incorrect data
  GROUP BY 
    vin_hashed,
    tp_kodas_concated,
    cleaned_marke_modelis  
)
SELECT *
FROM Regitra_aktualus_autoparkas_cleaned
ORDER BY unique_tp_id_kiekis DESC; -- Surikiuojame pagal unikalaus tp_id kiekį mažėjančia tvarka

-- 1.4 Count the distribution of unique `tp_id` counts and sort by frequency

SELECT
    unique_tp_id_kiekis,
    count(unique_tp_id_kiekis)
FROM Filter_data
group by unique_tp_id_kiekis
order by count(unique_tp_id_kiekis) desc
