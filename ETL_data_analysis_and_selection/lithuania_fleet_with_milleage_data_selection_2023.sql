-- Lithuania vehicle fleet combined with inspection data for the milleage approximation for 2023

-- 1. Merge Lithuania fleet dataset with vehicle inspection dataset based on VIN and additional matching criteria
SELECT 
    regitra.*,  -- All columns from the vehicle registration dataset
    transeksta.pag_metai,
    transeksta.ta_data_1,
    transeksta.ta_data_2,
    transeksta.tad_rida_1,
    transeksta.tad_rida_2,
    transeksta.tad_data_iki
FROM 
    Regitra_aktualus_autoparkas_cleaned AS regitra
LEFT JOIN 
    transeksta_cleaned AS transeksta
ON 
    regitra.vin_hashed = transeksta.vin_hashed -- Join by VIN
    AND regitra.tp_rusis = transeksta.kodas
    AND LOWER(
        CASE 
            WHEN regitra.marke IS NOT NULL AND regitra.modelis IS NOT NULL 
                THEN regitra.marke || ' ' || regitra.modelis -- Concatenate brand and model if both exist
            WHEN regitra.marke IS NOT NULL 
                THEN regitra.marke -- Use brand if model is missing
            WHEN regitra.modelis IS NOT NULL 
                THEN regitra.modelis -- Use model if brand is missing
            ELSE NULL -- Return NULL if both are missing
        END
            ) = LOWER(COALESCE(transeksta.marke_1, transeksta.marke_2)); 


-- 1.1 Count total records and categorize them based on the presence of inspection dates
SELECT 
    COUNT(*) AS total_records,  -- Total number of records
    COUNT(CASE WHEN ta_data_1 IS NOT NULL AND ta_data_2 IS NOT NULL THEN 1 END) AS both_not_null,  -- Records with both dates present
    COUNT(CASE WHEN ta_data_1 IS NOT NULL AND ta_data_2 IS NULL THEN 1 END) AS only_ta_data_1,  -- Records with only `ta_data_1`
    COUNT(CASE WHEN ta_data_1 IS NULL AND ta_data_2 IS NOT NULL THEN 1 END) AS only_ta_data_2,  -- Records with only `ta_data_2`
    COUNT(CASE WHEN ta_data_1 IS NULL AND ta_data_2 IS NULL THEN 1 END) AS both_null,  -- Records where both dates are NULL
    COUNT(pag_metai) AS pag_metai_count  -- Total records with manufacturing year available
FROM 
    sujungtas_transeksta_regitra;


# 1.2
-- Calculate differences in dates and mileages between inspections, and derive mileage per day and per year

SELECT 
    *,
    -- Calculate the difference in days between `ta_data_2` and `ta_data_1`
    CASE 
        WHEN ta_data_1 IS NOT NULL AND ta_data_2 IS NOT NULL 
            THEN DATEDIFF(ta_data_2, ta_data_1)
        ELSE NULL 
    END AS dienu_skirtumas,
    
    -- Calculate the difference in mileage between `tad_rida_2` and `tad_rida_1`
    CASE 
        WHEN tad_rida_1 IS NOT NULL AND tad_rida_2 IS NOT NULL 
            THEN (tad_rida_2 - tad_rida_1)
        ELSE NULL 
    END AS rida_skirtumas,
    
    -- Calculate mileage per day, rounded to 2 decimal places
    CASE 
        WHEN ta_data_1 IS NOT NULL AND ta_data_2 IS NOT NULL 
            AND tad_rida_1 IS NOT NULL AND tad_rida_2 IS NOT NULL 
            AND DATEDIFF(ta_data_2, ta_data_1) > 0
            THEN ROUND((tad_rida_2 - tad_rida_1) / DATEDIFF(ta_data_2, ta_data_1), 2)
        ELSE NULL 
    END AS rida_per_diena,

    -- Calculate mileage per year, assuming 365 days, rounded to 2 decimal places
    CASE 
        WHEN ta_data_1 IS NOT NULL AND ta_data_2 IS NOT NULL 
            AND tad_rida_1 IS NOT NULL AND tad_rida_2 IS NOT NULL
            AND DATEDIFF(ta_data_2, ta_data_1) > 0
            THEN ROUND(((tad_rida_2 - tad_rida_1) / DATEDIFF(ta_data_2, ta_data_1)) * 365, 2)
        ELSE NULL 
    END AS rida_per_metus
FROM sujungtas_transeksta_regitra;

-- 1.2.1 Analyze vehicle type distribution and count records with mileage data

SELECT 
    tp_pavadinimas, 
    COUNT(tp_pavadinimas) AS total_count,  -- Total vehicle type names
    COUNT(CASE WHEN rida_per_metus IS NOT NULL THEN tp_pavadinimas END) AS count_with_rida,  -- Records with positive mileage
    COUNT(CASE WHEN rida_per_metus > 0 THEN tp_pavadinimas END) AS count_with_positive_rida, -- Records with positive mileage
    COUNT(CASE WHEN rida_per_metus < 0 THEN tp_pavadinimas END) AS count_with_negative_rida -- Records with negative mileage
FROM regitra_transeksta_dataset_su_rida
GROUP BY 
    tp_pavadinimas
ORDER BY 
    tp_pavadinimas DESC;


-- 1.2.2 Assign vehicle type codes (`K1`, `K2`, etc.) and descriptions based on vehicle categories
SELECT
    *,    
    CASE 
        WHEN tp_pavadinimas LIKE 'L: Motociklai (L3,L4)' THEN 'K1'
        WHEN tp_pavadinimas LIKE 'M: Lengvieji automobiliai%' THEN 'K2'
        WHEN tp_pavadinimas LIKE 'M: Autobusai%' THEN 'K4'
        WHEN tp_pavadinimas LIKE 'M: Troleibusai' THEN 'K5'
        WHEN tp_pavadinimas LIKE 'N: Krovininiai%' 
            AND tp_pavadinimas NOT LIKE '%vilkikai'
            AND tp_pavadinimas NOT LIKE '%spec. paskirties'
            AND tp_pavadinimas NOT LIKE '%nepatikslinti' THEN 'K6'
        WHEN tp_pavadinimas LIKE 'N: Krovininiai: sunkūs: vilkikai' THEN 'K7'
        WHEN tp_pavadinimas LIKE 'O: Priekabos: sunkios: puspriekabės' THEN 'K8'
        WHEN tp_pavadinimas LIKE 'O: Priekabos%' 
            AND tp_pavadinimas NOT LIKE '%puspriekabės' THEN 'K9'
        WHEN tp_pavadinimas LIKE 'M: Lengvieji automobiliai: spec. paskirties'
             OR tp_pavadinimas LIKE 'N: Krovininiai: lengvi (N1): spec. paskirties'
             OR tp_pavadinimas LIKE 'N: Krovininiai: sunkūs: spec. paskirties'
             THEN 'K10'
        WHEN tp_pavadinimas LIKE 'L: Mopedai (L1,L2)' THEN 'K15'
        
    END AS transporto_priemones_tipas,
    CASE 
        WHEN tp_pavadinimas LIKE 'L: Motociklai (L3,L4)' THEN 'Motociklai'
        WHEN tp_pavadinimas LIKE 'M: Lengvieji automobiliai%' THEN 'Lengvieji automobiliai'
        WHEN tp_pavadinimas LIKE 'M: Autobusai%' THEN 'Autobusai'
        WHEN tp_pavadinimas LIKE 'M: Troleibusai' THEN 'Troleibusai'
        WHEN tp_pavadinimas LIKE 'N: Krovininiai%' 
             AND tp_pavadinimas NOT LIKE '%vilkikai'
             AND tp_pavadinimas NOT LIKE '%spec. paskirties'
             AND tp_pavadinimas NOT LIKE '%nepatikslinti' THEN 'Krovininiai automobiliai'
        WHEN tp_pavadinimas LIKE 'N: Krovininiai: sunkūs: vilkikai' THEN 'Puspriekabių vilkikai'
        WHEN tp_pavadinimas LIKE 'O: Priekabos: sunkios: puspriekabės' THEN 'Puspriekabės'
        WHEN tp_pavadinimas LIKE 'O: Priekabos%' AND tp_pavadinimas NOT LIKE '%puspriekabės' THEN 'Priekabos'
        WHEN tp_pavadinimas LIKE 'M: Lengvieji automobiliai: spec. paskirties'
             OR tp_pavadinimas LIKE 'N: Krovininiai: lengvi (N1): spec. paskirties'
             OR tp_pavadinimas LIKE 'N: Krovininiai: sunkūs: spec. paskirties' THEN 'Specialieji automobiliai'
        WHEN tp_pavadinimas LIKE 'L: Mopedai (L1,L2)' THEN 'Mopedai'
        ELSE 'Iš viso'
    END AS transporto_priemones_paaiskinimas

FROM regitra_transeksta_dataset_su_rida

-- 1.2.3 Analyze the distribution of vehicle types and their detailed descriptions

SELECT 
    transporto_priemones_tipas, 
    transporto_priemones_paaiskinimas,
    COUNT(transporto_priemones_tipas) AS total_count,  --- Total count of vehicle types
    COUNT(CASE WHEN rida_per_metus IS NOT NULL THEN transporto_priemones_tipas END) AS count_with_rida  -- Records with mileage per year
FROM regitra_transeksta_final
GROUP BY 
    transporto_priemones_tipas, transporto_priemones_paaiskinimas
ORDER BY 
    transporto_priemones_tipas ;

