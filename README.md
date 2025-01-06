# Final Energy Consumption in Road Transport - Master Thesis Codes

This repository contains the complete set of codes developed for the master's thesis: **Final Energy Consumption in Road Transport by Vehicle Type**. The project focuses on analyzing, cleaning, and modeling real-world data to estimate energy consumption patterns in Lithuania's vehicle fleet.

---

## Project Structure

### **1. Data Preprocessing**
This folder contains scripts and notebooks for cleaning and preparing raw datasets:
- **`GPT-3_5 Turbo Data Cleaning`**: Uses GPT-based automation for cleaning vehicle data with inconsistent or erroneous entries.
- **`Clean and Create CSV Files - Cars and Motorbikes`**: A Jupyter Notebook for structuring and generating cleaned CSV datasets for cars and motorcycles.
- **`Lithuania_fleet_model_brand_cleaning_after_GPT`**: A file dedicated to the post-GPT data cleaning process for Lithuanian vehicle brands and models.
- **`training_dataset_model_brand_cleaning_after_GPT`**: A supplementary script for finalizing cleaned training datasets for vehicle models and brands.

### **2. Data Selection**
Scripts and notebooks used for selecting and analyzing real-world datasets:
- **`europa_real_world_data_vans_cars_cleaning_preprocessing.ipynb`**: Preprocessing and cleaning real-world fuel consumption data for cars and vans in Europe.
- **`fuel_economy_dataset_analysis.ipynb`**: Exploratory analysis and feature extraction from a comprehensive fuel economy dataset.
- **`Web_Scraping_Motorcycles_fuel_consumption.ipynb`**: Python-based script for extracting and cleaning motorcycle fuel consumption data from web sources.

### **3. ETL Data Analysis and Selection**
This folder contains SQL scripts and PySpark-based codes for accessing and analyzing the full Lithuanian vehicle fleet dataset:
- **`lithuania_fleet_with_mileage_data_selection_2023.sql`**: Queries for selecting and extracting key data from the Lithuanian vehicle fleet database.
- **`lithuania_vehicle_fleet_data_analysis.sql`**: SQL-based exploratory data analysis of the Lithuanian vehicle fleet dataset.
- **`technical_inspection_data_analysis.sql`**: Analyzes data from technical inspections to extract mileage and condition metrics.
- **`Modelling_PySpark.ipynb`**: PySpark implementation of preprocessing and modeling pipelines tailored to the large-scale dataset from Lithuania.

### **4. Models**
This folder contains codes related to model development:
- **`modelling.ipynb`**: A comprehensive notebook detailing the modeling processes for fuel consumption estimation, including feature engineering, model training, and evaluation.

