--Technical inspection data analysis
-- 1. Create a cleaned version of vehicle brand and model data

-- Delete duplicates and map cleaned `marke` and `modelis` values
WITH unique_names_dedup AS (
    SELECT 
        marke, 
        modelis, 
        MAX(cleaned_marke) AS cleaned_marke, 
        MAX(cleaned_modelis) AS cleaned_modelis
    FROM unique_names_regitra
    GROUP BY marke, modelis
)
-- Merge cleaned `marke` and `modelis` values back to the main table.
SELECT 
    a.*, 
    u.cleaned_marke, 
    u.cleaned_modelis,
    u.marke as marke_org,
    u.modelis as modelis_org
FROM 
    transeksta_tech_apziuros a

LEFT JOIN 
    (
        SELECT DISTINCT 
            LOWER(
                CASE 
                    WHEN marke IS NOT NULL AND modelis IS NOT NULL 
                        THEN REPLACE(marke || ' ' || modelis, ',', '') 
                    WHEN marke IS NOT NULL 
                        THEN REPLACE(marke, ',', '')  
                    WHEN modelis IS NOT NULL 
                        THEN REPLACE(modelis, ',', '') 
                    ELSE NULL -- Jei abi yra NULL, grąžiname NULL
                END
            ) AS full_name, 
            cleaned_marke, 
            cleaned_modelis,
            marke,
            modelis
        FROM unique_names_dedup
    ) u
ON 
    LOWER(REPLACE(a.marke, ',', '')) = u.full_name;



-- 1.1 Aggregate data by VIN with logic for key attributes

WITH temp_results AS (
    SELECT 
        vin_hashed,
        MAX(marke) AS marke_1, -- Use the maximum (or consistent) value for `marke`
        MIN(marke) AS marke_2, -- Use the minimum (or consistent) value for `marke`
        cleaned_marke,
        cleaned_modelis,
        kodas,
        MAX(kuras) AS kuras, -- Use the maximum (or consistent) value for `kuras`
        MIN(pag_metai) AS pag_metai,  -- We use the smallest pag_metai as they are should be the same
        -- We take the latest ta_date before 2023-01-01, if there is no such value, we search after 2023-01-01
        COALESCE(
            MAX(CASE WHEN ta_data < '2023-01-01' THEN ta_data END), 
            MIN(CASE WHEN ta_data > '2023-01-01' THEN ta_data END)
        ) AS temp_ta_data_1,
        -- We take the latest ta_date after 2023-01-01
        MAX(CASE WHEN ta_data >= '2023-01-01' THEN ta_data END) AS ta_data_2,  
        -- We take the relevant mileage until 2023-01-01 or, if there is none, we look for it after 2023-01-01
        COALESCE(
            MAX(CASE WHEN ta_data < '2023-01-01' THEN tad_rida END), 
            MIN(CASE WHEN ta_data > '2023-01-01' THEN tad_rida END)
        ) AS temp_tad_rida_1,  
        -- We take mileage after 2023-01-01
        MAX(CASE WHEN ta_data >= '2023-01-01' THEN tad_rida END) AS tad_rida_2,  
        -- We take max tad_date_to
        MAX(tad_data_iki) AS tad_data_iki --Maximum tad_date_to value
    FROM 
        transeksta_cleaned_marke_modelis
    WHERE 
        ta_data >= '2020-01-01' 
        AND ta_data <= '2024-01-01' 
        -- AND vin_hashed NOT IN ('e6a069e21889f2a', 'a4816df713a2593') -- We remove these vin_hashed so you can see the real picture, as these are incorrect data
    GROUP BY 
        vin_hashed,
        cleaned_marke,
        cleaned_modelis,
        kodas
)


-- 1.2 Analyze inspection counts based on ta_data presence

SELECT 
    COUNT(*) AS total_records, -- Total number of records.
    COUNT(CASE WHEN ta_data_1 IS NOT NULL AND ta_data_2 IS NOT NULL THEN 1 END) AS both_not_null, -- Both `ta_data_1` and `ta_data_2` are available.
    COUNT(CASE WHEN ta_data_1 IS NOT NULL AND ta_data_2 IS NULL THEN 1 END) AS only_ta_data_1, -- Only `ta_data_1` is available.
    COUNT(CASE WHEN ta_data_1 IS NULL AND ta_data_2 IS NOT NULL THEN 1 END) AS only_ta_data_2, -- Only `ta_data_2` is available.
    COUNT(CASE WHEN ta_data_1 IS NULL AND ta_data_2 IS NULL THEN 1 END) AS both_null -- Both `ta_data_1` and `ta_data_2` are missing.
FROM transeksta_cleaned;


-- 1.3 Compare counts of matching and non-matching brands

SELECT 
    SUM(CASE WHEN LOWER(marke_1) = LOWER(marke_2) THEN 1 ELSE 0 END) AS vienodi_kiekiai, -- Count where `marke_1` and `marke_2` are identical.
    SUM(CASE WHEN LOWER(marke_1) != LOWER(marke_2) THEN 1 ELSE 0 END) AS skirtingi_kiekiai -- Count where `marke_1` and `marke_2` differ.
FROM transeksta_cleaned;


-- 2. Clear duplicate values between `ta_data_1` and `ta_data_2`, and between `tad_rida_1` and `tad_rida_2`

SELECT 
    vin_hashed,
    marke_1,
    marke_2,
    cleaned_marke,
    cleaned_modelis,
    kodas,
    kuras,
    pag_metai,
    -- If ta_date_1 and ta_date_2 are the same, we clear ta_date_1
    CASE 
        WHEN temp_ta_data_1 = ta_data_2 THEN NULL 
        ELSE temp_ta_data_1 
    END AS ta_data_1,  
    ta_data_2,
    -- If tad_rida_1 and tad_rida_2 are the same, we clear tad_rida_1
    CASE 
        WHEN temp_tad_rida_1 = tad_rida_2 THEN NULL 
        ELSE temp_tad_rida_1 
    END AS tad_rida_1,  
    tad_rida_2,
    tad_data_iki
FROM temp_results
ORDER BY vin_hashed;


-- 2.1 Filter inspections within a specific date range, excluding certain VINs


SELECT 
    vin_hashed,
    cleaned_marke,
    cleaned_modelis,
    kodas,
    COUNT(ta_data) AS kiekis
  FROM 
    transeksta_cleaned_marke_modelis

  where 
    ta_data >= '2020-01-01' and
    ta_data <= '2024-01-01' and
    vin_hashed NOT IN ('e6a069e21889f2a', 'a4816df713a2593') -- We remove these vin_hashed so you can see the real picture, as these are incorrect data

  GROUP BY 
    vin_hashed,
    cleaned_marke,
    cleaned_modelis,
    kodas
  Order by kiekis desc

-- 2.2 Count of inspections per vehicle across the time range

SELECT kiekis, COUNT(kiekis)
FROM isfiltravimas_pagal_ta_data
group by kiekis
order by COUNT(kiekis) desc

-- 2.3 Analyze the distribution of manufacturing years
SELECT 
    pag_metai, 
    COUNT(pag_metai) AS count
FROM transeksta_cleaned_marke_modelis
GROUP BY pag_metai
ORDER BY pag_metai DESC;

-- 2.4 Aggregate count of cleaned brand and model data
SELECT 
    COUNT(*) AS total_records,
    COUNT(cleaned_marke) AS cleaned_marke_count,
    COUNT(cleaned_modelis) AS cleaned_modelis_count,
    COUNT(modelis_org) AS original_model_count
FROM transeksta_cleaned_marke_modelis;
