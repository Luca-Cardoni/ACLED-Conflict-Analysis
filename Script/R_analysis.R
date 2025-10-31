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


# --- 2. INITIAL EXPLORATION (EDA) ---
# Perform a quick check on the data structure to ensure
# it loaded correctly and identify key columns.
acled_data <- ACLED_Yemen_2014.2024

# glimpse() provides a clear overview of column names and data types
glimpse(acled_data)

# View the first few rows to understand the content
head(acled_data)

# List all column names for reference
names(acled_data)


# --- 3. DATA CLEANING & PREPARATION ---
# Our goal is to create a smaller, cleaner dataset to work with.
# We will:
# 1. Select only the columns we need for analysis.
# 2. Convert 'event_date' from a string to a proper Date object.

# List of columns we want to keep
columns_to_keep <- c("event_id_cnty", "event_date", "year", 
                     "event_type", "sub_event_type", 
                     "actor1", "actor2", 
                     "admin1", "admin2", "location", 
                     "latitude", "longitude", "fatalities")

# Use dplyr to pipe operations
acled_clean <- acled_data %>%
  
  # 1. Select only the columns defined above
  select(all_of(columns_to_keep)) %>%
  
  # 2. Convert event_date to Date format
  # ymd() is from the lubridate package and parses "Year-Month-Day"
  mutate(event_date = ymd(event_date))

# Check the new, clean dataframe
cat("--- Cleaned Data Glimpse ---")
glimpse(acled_clean)


# --- 4. TIME SERIES ANALYSIS: FATALITIES OVER TIME ---
# We want to see the trend of violence. 
# Plotting daily points is too noisy.
# Let's aggregate fatalities by month.

# 1. Create a new dataframe, grouped by month
monthly_fatalities <- acled_clean %>%
  
  # Create a new column 'month_year' by rounding the date down to the first of the month
  mutate(month_year = floor_date(event_date, "month")) %>%
  
  # Group by this new monthly column
  group_by(month_year) %>%
  
  # Calculate the sum of fatalities for each month
  summarise(total_fatalities = sum(fatalities))

# 2. Plot the time series
ggplot(monthly_fatalities, aes(x = month_year, y = total_fatalities)) +
  geom_line(color = "#0072B2", alpha = 0.8) + # The main line
  geom_smooth(method = "loess", color = "#D55E00", fill = "#D55E00", alpha = 0.1) + # A smoothing trend line
  labs(
    title = "Fatalities in Yemen Conflict (2014-2024)",
    subtitle = "Aggregated monthly data with smoothing trend",
    x = "Year",
    y = "Total Fatalities per Month"
  ) +
  theme_minimal() # A clean theme


# --- 5. CATEGORICAL ANALYSIS: FATALITIES BY EVENT TYPE ---
# We want to understand what *kind* of events cause the most fatalities.

# 1. Create a summary dataframe
event_summary <- acled_clean %>%
  group_by(event_type) %>%
  summarise(
    total_fatalities = sum(fatalities),
    event_count = n() # Count how many events of each type
  ) %>%
  # Arrange in descending order
  arrange(desc(total_fatalities))

# 2. Print the summary table to the console
cat("--- Summary by Event Type ---")
print(event_summary)

# 3. Plot the summary
ggplot(event_summary, aes(x = reorder(event_type, total_fatalities), y = total_fatalities)) +
  geom_col(fill = "#009E73") + # geom_col is for bar charts
  coord_flip() + # Flip coordinates to make labels readable
  labs(
    title = "Total Fatalities by Event Type in Yemen (2014-2024)",
    subtitle = "Which types of conflict events are the most deadly?",
    x = "Event Type",
    y = "Total Fatalities"
  ) +
  theme_minimal()

# --- 6. NETWORK PREPARATION (FOR GEPHI) ---
#
# Our goal is to create two files:
# 1. EDGES: A list of all interactions (actor1 -> actor2)
# 2. NODES: A unique list of all actors
#
# Based on our analysis (Phase 6), we will *only* focus on the
# two most lethal event types to build a meaningful network of combatants.

# 1. Define the event types we care about
event_filter <- c("Battles", "Explosions/Remote violence")

# 2. Filter our clean data to only these events AND actors that are present
edges_filtered <- acled_clean %>%
  filter(event_type %in% event_filter) %>%
  
  # A network requires two actors. Remove rows where one is missing.
  filter(actor1 != "" & actor2 != "") %>%
  
  # Select only the columns needed for the network
  select(actor1, actor2, fatalities)

# 3. Create the EDGES dataframe
# We group by the interacting pair (actor1, actor2) and sum up
# all their interactions and the total fatalities they caused.
edges_for_gephi <- edges_filtered %>%
  group_by(actor1, actor2) %>%
  summarise(
    # 'Weight' will be the number of times they interacted
    Weight = n(), 
    # We also keep total_fatalities as another useful metric
    total_fatalities = sum(fatalities)
  ) %>%
  # Rename columns to Gephi's required format
  rename(Source = actor1, Target = actor2)

# Check the first few rows
cat("--- Gephi Edges Preview ---")
head(edges_for_gephi)

# 4. Create the NODES dataframe
# The nodes list must be a *unique* list of all actors
# from both the Source and Target columns.
nodes_source <- edges_for_gephi %>% distinct(Source) %>% rename(Id = Source)
nodes_target <- edges_for_gephi %>% distinct(Target) %>% rename(Id = Target)

nodes_for_gephi <- bind_rows(nodes_source, nodes_target) %>%
  distinct(Id) %>%
  
  # Add a 'Label' column, which Gephi uses for text
  mutate(Label = Id)

# Check the first few rows
cat("--- Gephi Nodes Preview ---")
head(nodes_for_gephi)

# 5. Save both files to our 'processed' data folder
# We use write.csv() from base R
write.csv(edges_for_gephi, "Data/Processed/yemen_edges.csv", row.names = FALSE)
write.csv(nodes_for_gephi, "Data/Processed/yemen_nodes.csv", row.names = FALSE)
