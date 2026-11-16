# Export the ANIMAL and EVENT tables from one LMT database as CSVs under tables/.
library(RSQLite)
library(optparse)
source("/workspace/LMT_functions.R")

option_list <- list(
  make_option(c("-f", "--file"), type = "character", default = NULL,
              help = "Path to the SQLite file", metavar = "character"),
  make_option(c("-o", "--output"), type = "character", default = NULL,
              help = "Path to save output", metavar = "character"),
  make_option(c("-s", "--save_name"), type = "character", default = NULL,
              help = "Path to save output", metavar = "character")
)

opt_parser <- OptionParser(option_list = option_list)
opt <- parse_args(opt_parser)

if (is.null(opt$file) | is.null(opt$output)) {
  print_help(opt_parser)
  stop("All arguments must be provided.", call. = FALSE)
}

opt$output <- ensure_trailing_slash(opt$output)
opt$output <- escape_spaces(opt$output)

# Use the database stem and batch label to identify each cage export.
file_base <- tools::file_path_sans_ext(basename(opt$file))

conn <- dbConnect(SQLite(), dbname = opt$file)

path <- paste0(opt$output, "tables/")
if (!dir.exists(path)) {
  dir.create(path, recursive = FALSE)
  message("Directory created: ", path)
} else {
  message("Directory already exists: ", path)
}

tables <- c("ANIMAL", "EVENT")

# Log missing tables and skip their CSV exports.
extract_and_save <- function(table_name) {
  if (table_name %in% dbListTables(conn)) {
    data <- dbReadTable(conn, table_name)

    csv_file <- paste0(path, file_base, "_", table_name, "_", opt$save_name, ".csv")

    write.csv(data, csv_file, row.names = FALSE)

    print(paste("Table", table_name, "has been saved to", csv_file))
  } else {
    print(paste("Table", table_name, "does not exist in the database."))
  }
}

lapply(tables, extract_and_save)

dbDisconnect(conn)
