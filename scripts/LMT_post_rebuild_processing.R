# Required libraries
library(optparse)
library(data.table)
library(hms)
source("/workspace/LMT_functions.R")

# Initiate option list
option_list <- list(
  make_option(c("-i", "--input_dir"), type = "character", help = "REQUIRED: Director path containing input sqlite databases (sqlite files must be rebuilt)"),
  make_option(c("-c", "--cage_manifest"), type = "character", help = "REQUIRED: File path to cage manifest file (FORMAT: RFID	Genotype	Cage)"),
  make_option(c("-s", "--save_name"), type = "character", help = "REQUIRED: Provide a save name for the results"),
  make_option(c("-t", "--time_file"), type = "character", help = "File path to cage time (FORMAT: Cage	Treatment	Start_Time	Group)"),
  make_option(c("-o", "--output"), type = "character", help = "REQUIRED: Output directory path"),
  make_option(c("-f", "--frame_filter"), type = "numeric", default = 15, help = "Specify the minimum length length of an event to filter (Default: 15 frames)")
)

# Parse command-line options
parser <- OptionParser(option_list = option_list)
options <- parse_args(parser)

# Check for required arguments
if (is.null(options$input_dir)) stop("Error: Argument --input_dir is required. Use --help for usage information.")
if (is.null(options$cage_manifest)) stop("Error: Argument --cage_manifest is required. Use --help for usage information.")
if (is.null(options$save_name)) stop("Error: Argument --save_name is required. Use --help for usage information.")
if (is.null(options$output)) stop("Error: Argument --output is required. Use --help for usage information.")

outpath <- ensure_trailing_slash(normalizePath(options$output))
outpath <- paste0(outpath, "processed/")
if (!dir.exists(outpath)) {
  dir.create(outpath, recursive = FALSE)
  message("Directory created: ", outpath)
} else {
  message("Directory already exists: ", outpath)
}
options$input_dir <- ensure_trailing_slash(normalizePath(options$input_dir))
options$cage_manifest <- normalizePath(options$cage_manifest)
if (!is.null(options$time_file)) options$time_file <- normalizePath(options$time_file)

if (options$time_file %in% c("NULL", "NA")) options$time_file <- NULL

# Clear workspace and import functions
gc()
condition <- options$save_name
frame_filter <-  options$frame_filter

# Get Mouse Manifests
mouse_mani <- data.frame(fread(file=options$cage_manifest, stringsAsFactors = FALSE))

# Get file containing cage start times
if (is.null(options$time_file) == F) tfile <- data.frame(fread(options$time_file))

# Read in and aggregate event counts
read_and_save_csv(paste0(options$input_dir))
if (is.null(options$time_file) == F) event_times(tfile) else event_times()
aggregate_on_events(frame_filter)
anno_and_clean(mouse_mani)
cage_means(all_events, mouse_mani)

#  Write Mouse Event Counts
all_events$condition <- condition

fwrite(all_events, file=paste0(outpath, condition,"_All_Events_filter_frames_",as.character(frame_filter),".csv"), sep=";", col.names = T, row.names = F, quote = F)
fwrite(All_Events_agg_filtered, file=paste0(outpath, condition,"_Event_Counts_with_duration_filter_frames_",as.character(frame_filter),".csv"), sep=";", col.names = T, row.names = F, quote = F)
fwrite(cage_event_means, file=paste0(outpath, condition,"_Cage_Events_means_filter_frames_",as.character(frame_filter),".csv"), sep=";", col.names = T, row.names = F, quote = F)
fwrite(cage_count_means, file=paste0(outpath, condition,"_Cage_Count_means_filter_frames_",as.character(frame_filter),".csv"), sep=";", col.names = T, row.names = F, quote = F)