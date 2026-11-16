# Container entry point for rebuilding events in one LMT SQLite database in place.
# The bundled LiveMouseTracker Python script performs the database updates.
library(optparse)

option_list <- list(
  make_option(c("-f", "--file"), type = "character", default = NULL,
              help = "Path to the SQLite file", metavar = "character")
)

opt_parser <- OptionParser(option_list = option_list)
opt <- parse_args(opt_parser)

if (is.null(opt$file) ) {
  print_help(opt_parser)
  stop("All arguments must be provided.", call. = FALSE)
}

if (!file.exists(opt$file)) {
  stop(paste("Error: The SQLite file '", opt$file, "' does not exist.", sep = ""))
} else {
    print(system(paste0("echo 'Processing SQlite file: '", opt$file), intern = TRUE))
    # Print the captured Python stdout into the rebuild stage log.
    print(system(paste0("python3 /workspace/lmt-analysis-master/LMT/scripts/Rebuild_All_Events.py ", opt$file), intern = TRUE))  
}
