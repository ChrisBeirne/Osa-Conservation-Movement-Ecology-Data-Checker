##################
# Import data

## Load packages ----
library(googledrive)
library(purrr)
library(readxl)
options(googledrive_quiet = TRUE)

## Authenticate into googledrive service account ----
## 'GOOGLE_AUTHENTICATION_CREDENTIALS' is what we named the Github Secret that 
## contains the credential JSON file
googledrive::drive_auth(path = Sys.getenv("GOOGLE_AUTHENTICATION_CREDENTIALS"))

## Find Google Drive folder 'Centre Circle Data & Info'
data_folder <- drive_ls(path = "08 Databases + Analysis")

## Filter for just the .csv files
data_files <- data_folder[data_folder$name=="1_vulture_capture_database", ]
# dplyr: data_csv <- data_folder %>% filter(str_detect(name, ".csv")) %>% arrange(name)

data_path <- "data"
dir.create(data_path) 
## dir.create will fail if folder already exists so not great for scripts on local but as GHA is 
## creating a new environment every time it runs we won't have that problem here
# normally i prefer using fs::dir_create(data_path)

## download function ----
get_drive_cpl_data <- function(g_id, data_name) {
  cat("\n... Trying to download", data_name, "...\n")
  
  # Wrap drive_download function in safely()
  safe_drive_download <- purrr::safely(drive_download)
  
  ## Run download function for all data files
  dl_return <- safe_drive_download(file = as_id(g_id), path = paste0("data/", data_name), overwrite = TRUE)
  
  ## Log messages for success or failure
  if (is.null(dl_return$result)) {
    cat("\nSomething went wrong!\n")
    dl_error <- as.character(dl_return$error) ## errors come back as lists sometimes so coerce to character
    cat("\n", dl_error, "\n")
  } else {
    res <- dl_return$result
    cat("\nFile:", res$name, "download successful!", "\nPath:", res$local_path, "\n")
  }
}

## Download all files from Google Drive! ----
map2(data_files$id, data_files$name,
     ~ get_drive_cpl_data(g_id = .x, data_name = .y))

cat("\nAll done!\n")

capture_dat <- read_excel("data/1_vulture_capture_database.xlsx", sheet = "database")

write.csv(capture_dat, "testthat/new_data.csv")
