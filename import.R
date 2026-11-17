library(tidyverse)
library(janitor)
library(fs)

# Rebuild data-clean/ from scratch so no stale files survive
if (dir_exists("data-clean")) dir_delete("data-clean")
dir_create("data-clean")

# Fiscal year starts July 1 and is named for the year it ends in,
# so July to September 2026 is "FY27 Q1"
fiscal_quarter <- function(date) {
  fy <- year(date) + (month(date) >= 7)
  q <- ((month(date) - 7) %% 12) %/% 3 + 1
  paste0("FY", fy %% 100, " Q", q)
}

sites <- read_csv("data-raw/sites.csv", show_col_types = FALSE)

visits <- list.files("data-raw/visits", pattern = "\\.csv$", full.names = TRUE) |>
  map(read_csv, col_types = cols(.default = "c")) |>
  list_rbind() |>
  clean_names() |>
  mutate(
    visit_date = mdy(visit_date),
    hh_size = as.integer(hh_size)
  ) |>
  filter(site != "MOB") |>
  distinct(hh_id, visit_date, site, .keep_all = TRUE) |>
  left_join(sites, by = join_by(site == site_code)) |>
  mutate(quarter = fiscal_quarter(visit_date)) |>
  select(hh_id, visit_date, quarter, site_name, hh_size)

write_rds(visits, "data-clean/visits.rds")
