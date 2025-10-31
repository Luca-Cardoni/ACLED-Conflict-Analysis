#################################################################
# ACLED CONFLICT ANALYSIS IN YEMEN (2014-2024)
#
# Project: Data Analysis Portfolio
# Author: Luca Cardoni
#
# Purpose:
# This script analyzes the ACLED dataset for the conflict in Yemen.
# It aims to identify trends in violence, key actors, and build
# a network graph for visualization in Gephi.
#
#################################################################


# --- 1. SETUP & LIBRARIES ---
# Load all necessary packages for the analysis

library(data.table) # For fast data loading (fread)
library(dplyr)      # For data manipulation
library(ggplot2)    # For plotting
library(lubridate)  # For date manipulation


# --- 2. LOAD DATA ---
# Define the file path relative to the project root (.Rproj file)
file_path <- "02_data/raw/ACLED_Yemen_2014-2024.csv"

# Load the data using fread, which is highly efficient for large datasets.
acled_data <- fread(file_path)

print(paste("Successfully loaded", nrow(acled_data), "rows."))


# --- 3. INITIAL EXPLORATION (EDA) ---
# Perform a quick check on the data structure to ensure
# it loaded correctly and identify key columns.

# glimpse() provides a clear overview of column names and data types
glimpse(acled_data)

# View the first few rows to understand the content
head(acled_data)

# List all column names for reference
names(acled_data)

# --- 4. DATA CLEANING & PREPARATION ---
# (Inizieremo questa parte dopo che mi avrai mandato l'output)
#
# Our goal here is to:
# 1. Clean column names (e.g., remove spaces, convert to lowercase).
# 2. Convert 'event_date' from string to a proper date object.
# 3. Select only the columns needed for the analysis to save memory.
# ...
