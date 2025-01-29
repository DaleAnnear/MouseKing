# Load required libraries
library(optparse)

# Define command line options
option_list <- list(
  make_option(c("-f", "--file"), type = "character", default = NULL,
              help = "Path to the SQLite file", metavar = "character")
)

# Parse command line options
opt_parser <- OptionParser(option_list = option_list)
opt <- parse_args(opt_parser)

# Check if the file option is provided
if (is.null(opt$file) ) {
  print_help(opt_parser)
  stop("All arguments must be provided.", call. = FALSE)
}

# Check if the SQLite file exists
if (!file.exists(opt$file)) {
  stop(paste("Error: The SQLite file '", opt$file, "' does not exist.", sep = ""))
} else {
    print(system(paste0("echo 'Processing SQlite file: '", opt$file), intern = TRUE))
    print(system(paste0("python3 /workspace/lmt-analysis-master/LMT/scripts/Rebuild_All_Events.py ", opt$file), intern = TRUE))  
} 