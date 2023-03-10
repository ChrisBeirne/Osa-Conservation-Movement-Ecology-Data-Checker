# Generate plots of error rates over time and other error rate analyses for
# paper as seen here
# https://github.com/SCBI-ForestGEO/continuous_integration/issues/14
library(dplyr)
library(readxl)
library(readr)
library(stringr)
library(here)
library(janitor)
library(lubridate)
library(patchwork)
library(tidyr)
library(ggplot2)



# Load census stem counts --------------------------------
# Get stem counts from main census (copied from Generate_reports.R)
main_census <- 
  "https://raw.githubusercontent.com/SCBI-ForestGEO/SCBI-ForestGEO-Data/master/tree_main_census/data/census-csv-files/scbi.stem3.csv" %>% 
  paste0() %>% 
  read.csv()

## convert dbh to numeric
main_census$dbh <- as.numeric(main_census$dbh)

## only keep trees > 10cm except for fraxinus and Chionanthus virginicus
main_census <- main_census[grepl("^fr..|^ch..", main_census$sp) | (!is.na(main_census$dbh) & main_census$dbh >= 100), ]

## remove trees that are dead
# main_census <- main_census[!main_census$status %in% "D",]
main_census <- main_census[!grepl("DC|DN|DT", main_census$codes), ]

census_quad_counts <- main_census %>%
  group_by(quadrat) %>%
  summarize(n_census = n()) %>%
  rename(quad = quadrat) %>%
  mutate(quad = str_pad(quad, width = 4, side = "left", pad = "0"))


# Load quadrat info --------------------------------
# Get latest FFF
# latest_FFFs <- list.files(here("raw_data/FFF_excel/"), pattern = ".xlsx", full.names = T)
# latest_FFFs <- latest_FFFs[which.max(as.numeric(regmatches(latest_FFFs, regexpr("20\\d\\d", latest_FFFs))))] # take the latest file only
latest_FFFs <- "raw_data/FFF_excel/SCBI Mortality 2022.xlsx" #update this for census 2023
static_FFFs <- "raw_data/FFF_excel/SCBI Mortality static 2022.xlsx" #this is static form that was used for one week during 2022 that is missing one column 

latest_quadrat <- read_xlsx(latest_FFFs, sheet = "Root", .name_repair = "minimal") %>% clean_names()
static_quadrat <- read_xlsx(static_FFFs, sheet = "Root", .name_repair = "minimal") %>% clean_names()

quadrat_info <- rbind(latest_quadrat, static_quadrat)

# Get info on all quadrats censused so far
quadrat_info <- quadrat_info %>%
  select(-submitted_by, -starts_with("form")) %>%
  mutate(
    stem_count = as.numeric(stem_count),
    date_time = mdy(date_time),
    submitted_on = parse_date_time(submitted_on, "m-d-Y H:M p"),
    quad = str_pad(quad, width = 4, side = "left", pad = "0")
  ) %>%
  arrange(date_time) %>%
  # Stem counts from FFF were initially built off wrong census file, 
  # so replace census stem counts from above
  left_join(census_quad_counts, by = "quad") %>%
  select(-stem_count) %>%
  rename(stem_count = n_census)

stems_censused_per_day <- quadrat_info %>%
  group_by(date_time) %>%
  summarize(n_stems = sum(stem_count, na.rm = TRUE))


# Load trace of error reports ---------------------------------------
# Field fix errors per day (missing stems separately)
field_fix_errors <- read_csv("testthat/reports/trace_of_reports/require_field_fix_error_file.csv") %>%
  clean_names() %>%
  filter(error_name != "missing_stem") %>% 
  select(error_name, surveyor_id, submission_id, quad, tag, stem_tag) %>%
  left_join(
    quadrat_info %>% select(submission_id, date_time),
    by = "submission_id"
  ) %>%
  # Determine level of aggregation:
  group_by(date_time) %>%
  summarize(field_fix = n())

# Missing stems per day (split off from field fix errors above)
missing_stems <- read_csv("testthat/reports/trace_of_reports/require_field_fix_error_file.csv") %>%
  clean_names() %>%
  filter(error_name == "missing_stem") %>% 
  select(error_name, surveyor_id, submission_id, quad, tag, stem_tag) %>%
  # Submission ID missing, so need to join by quad instead:
  mutate(quad = str_pad(quad, width = 4, side = "left", pad = "0")) %>% 
  left_join(
    quadrat_info %>% select(quad, date_time),
    by = "quad"
  ) %>%
  # Determine level of aggregation:
  group_by(date_time) %>%
  summarize(missing_stem = n())

# Auto fixes
auto_fix_errors <- read_csv("testthat/reports/trace_of_reports/will_auto_fix_error_file.csv") %>%
  clean_names() %>%
  select(error_name, surveyor_id, submission_id, quad, tag, stem_tag) %>%
  left_join(
    quadrat_info %>% select(submission_id, date_time),
    by = "submission_id"
  ) %>%
  # Determine level of aggregation:
  group_by(date_time) %>%
  summarize(auto_fix = n())

# Duplicated stems
quadrat_censused_duplicated_stems <- read_csv("testthat/reports/trace_of_reports/quadrat_censused_duplicated_stems.csv") %>%
  clean_names() %>%
  select(surveyor_id, submission_id, quad, tag, stem_tag) %>%
  left_join(
    quadrat_info %>% select(submission_id, date_time),
    by = "submission_id"
  ) %>%
  # Count any duplicates only once
  group_by(submission_id, date_time, quad, tag, stem_tag) %>%
  slice(1) %>%
  # Determine level of aggregation:
  group_by(date_time) %>%
  summarize(duplicated_stems = n())



# Merge all data ---------------------------------------
error_rates <-
  # Merge error reports
  field_fix_errors %>%
  left_join(auto_fix_errors, by = "date_time") %>%
  left_join(missing_stems, by = "date_time") %>%
  left_join(quadrat_censused_duplicated_stems, by = "date_time") %>%
  filter(!is.na(date_time)) %>%
  replace(is.na(.), 0) %>%
  pivot_longer(cols = -c(date_time), names_to = "error_type", values_to = "n_errors") %>%
  # Get error rate being sure to account for days where 0 errors occurred
  full_join(stems_censused_per_day, by = "date_time") %>%
  # Aggregate by week: round up using ceiling_date
  mutate(date_time = ceiling_date(date_time, "week")) %>% 
  group_by(date_time, error_type) %>% 
  summarize(n_errors = sum(n_errors, na.rm = TRUE), n_stems = sum(n_stems)) %>% 
  # Compute error rate (filling in with 0's where necessary)
  mutate(errors_per_stem = n_errors / n_stems) %>%
  ungroup() %>% 
  complete(date_time, error_type, fill = list(errors_per_stem = 0)) %>% 
  filter(!is.na(error_type))




# Generate all plots ---------------------------------------
# Standardize date ranges of plots
date_range <- c(
  # Earliest census date
  min(stems_censused_per_day$date_time),
  # Lastest weekly cummulative summary date
  max(stems_censused_per_day$date_time)
)
date_breaks <- seq.Date(
  from = date_range[1], 
  to = date_range[2], 
  by = 1
) %>% 
  ceiling_date("week") %>% 
  unique()
if(length(date_breaks) == 1){
  date_breaks <- c(date_range[1], date_breaks)
}


## Daily new stems censused -----
census_rate_plot <- stems_censused_per_day %>%
  replace(is.na(.), 0) %>%
  ggplot(aes(x = date_time, y = n_stems)) +
  geom_point() +
  geom_line() +
  labs(
    x = "Census date", y = "# of new stems censused",
    title = "Daily new stems censused"
  ) +
  coord_cartesian(
    ylim = c(0, NA)
  ) +
  theme_bw() +
  scale_x_date(limits = date_range, breaks = ymd(date_breaks), date_labels = "%b %d")


## Daily new error analysis -----
error_rate_plot <- error_rates %>%
  ggplot(aes(x = date_time, y = errors_per_stem, col = error_type)) +
  geom_point() +
  geom_line() +
  labs(
    x = "Weekly cummulative summary date", y = "# of errors per stem censused",
    col = "Error type",
    title = "Weekly cummulative new error rate"
  ) +
  coord_cartesian(
    ylim = c(0, NA)
  ) +
  theme_bw() +
  theme(legend.position = "bottom") +
  scale_x_date(limits = date_range, breaks = ymd(date_breaks), date_labels = "%b %d")


# Output
filename <- file.path(here("testthat"), "reports/daily_progress.png")
census_rate_plot / error_rate_plot
ggsave(filename, device = "png", width = 16 / 2, height = 18 / 2.5, units = "in", dpi = 300)

