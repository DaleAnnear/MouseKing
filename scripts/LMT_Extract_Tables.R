# Load required libraries
library(RSQLite)
library(optparse)
source("/workspace/LMT_functions.R")

# Define command line options
option_list <- list(
  make_option(c("-f", "--file"), type = "character", default = NULL,
              help = "Path to the SQLite file", metavar = "character"),
  make_option(c("-o", "--output"), type = "character", default = NULL,
              help = "Path to save output", metavar = "character"),
  make_option(c("-s", "--save_name"), type = "character", default = NULL,
              help = "Path to save output", metavar = "character")
)

# Parse command line options
opt_parser <- OptionParser(option_list = option_list)
opt <- parse_args(opt_parser)

# Check if the file option is provided
if (is.null(opt$file) | is.null(opt$output)) {
  print_help(opt_parser)
  stop("All arguments must be provided.", call. = FALSE)
}

opt$output <- ensure_trailing_slash(opt$output)
opt$output <- escape_spaces(opt$output)

# Extract the base name of the file without extension
file_base <- tools::file_path_sans_ext(basename(opt$file))

# Connect to the SQLite database
conn <- dbConnect(SQLite(), dbname = opt$file)

# Define the tables to extract
tables <- c("ANIMAL", "EVENT")

# Function to extract table and save as CSV
extract_and_save <- function(table_name) {
  # Check if the table exists in the database
  if (table_name %in% dbListTables(conn)) {
    # Read the table
    data <- dbReadTable(conn, table_name)

    # Define the output CSV file name
    csv_file <- paste0(opt$output, file_base, "_", table_name, "_", opt$save_name, ".csv")

    # Save the table to a CSV file
    write.csv(data, csv_file, row.names = FALSE)

    print(paste("Table", table_name, "has been saved to", csv_file))
  } else {
    print(paste("Table", table_name, "does not exist in the database."))
  }
}

# Extract and save each table
lapply(tables, extract_and_save)

# Disconnect from the database
dbDisconnect(conn)
