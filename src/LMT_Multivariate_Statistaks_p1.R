# Import libraries
library(optparse)
library(data.table)
library(corrr)
library(ggcorrplot)
library(FactoMineR)
library(factoextra)
library(dplyr)
library(tidyr)
library(tidyverse)
library(M3C)
library(ggplot2)
library(ggforce)
source("/workspace/LMT_functions.R")

# Initiate option list
option_list <- list(
  make_option(c("-i", "--input_dir"), type = "character", help = "REQUIRED: Director path containing input sqlite databases (sqlite files must be rebuilt)"),
  make_option(c("-c", "--cage_manifest"), type = "character", help = "REQUIRED: File path to cage manifest file (FORMAT: RFID	Condition	Cage)"),
  make_option(c("-s", "--save_name"), type = "character", help = "REQUIRED: Provide a save name for the results"),
  make_option(c("-o", "--output"), type = "character", help = "REQUIRED: Output directory path")
)

# Parse command-line options
parser <- OptionParser(option_list = option_list)
options <- parse_args(parser)

# Check for required arguments
required <- c("input_dir", "cage_manifest", "save_name", "output")
require_options(options, required)

# Clear workspace and import functions
gc()

# Read in files
mouse_mani <- data.frame(fread(options$cage_manifest))
events <- data.frame(fread(list.files(path = options$input_dir, pattern = "*All_Events_filter_frames_.*\\.csv$", full.names = TRUE, recursive = TRUE)))
events_agg <- data.frame(fread(list.files(path = options$input_dir, pattern = "*Event_Counts_with_duration_filter_frames_.*\\.csv$", full.names = TRUE, recursive = TRUE)))
cage_durs <- data.frame(fread(list.files(path = options$input_dir, pattern = "*Cage_Events_means_filter_frames_.*\\.csv$", full.names = TRUE, recursive = TRUE)))
cage_counts <- data.frame(fread(list.files(path = options$input_dir, pattern = "*Cage_Count_means_filter_frames_.*\\.csv$", full.names = TRUE, recursive = TRUE)))

events_by_cage <- agg_all_events(events, mouse_mani)
events_by_cage <- events_by_cage[!(events_by_cage$NAME %in% c("Detection", "Head detected")),]
out_path <- ensure_trailing_slash(options$output)

out_path <- paste0(out_path, "multivariate/")
ensure_dir(out_path)

# Cage Means
cage_sds <- agg_SD(events_agg)
cage_means <- merge(subset(cage_durs[cage_durs$Condition == "All",], select = -Condition), cage_counts, by = c("NAME", "Cage"))
cage_means <- merge(cage_means, cage_sds, by = c("NAME", "Cage") )
names(cage_means) <- c( "NAME", "Cage" , "x", "Cage_Duration_Total", "Cage_Duration_Mean", "Cage_Duration_SD", "Cage_Count_Total", "Cage_Count_Mean", "Cage_Count_SD", "SD_Mean", "SD_SD")
cage_means <- subset(cage_means, select = -x)

# Normalise Data
norm_base <- events_by_cage
norm_base <- merge(norm_base, cage_means, by = c("NAME", "Cage"))
norm_base$event_count_nz <- (norm_base$Event_Count - norm_base$Cage_Count_Mean)/norm_base$Cage_Count_SD
norm_base$event_dur_nz <- (norm_base$Duration_Mean - norm_base$Cage_Duration_Mean)/norm_base$Cage_Duration_SD
norm_base$sd_nz <- (norm_base$Duration_SD - norm_base$SD_Mean)/norm_base$SD_SD

norm_counts <- norm_base[c("NAME", "RFID", "Condition", "event_count_nz")]
norm_dur <- norm_base[c("NAME", "RFID", "Condition", "event_dur_nz")]
norm_sd <-  norm_base[c("NAME", "RFID", "Condition", "sd_nz")]

# Change Table Format
to_df_wide = function(df){
  df$NAME <- paste0(df$NAME, ".", names(df[ncol(df)]))
  df_long <- df %>% pivot_longer(cols = c(names(df[ncol(df)])), 
                    names_to = "Metric", 
                    values_to = "Value")
  df_wide <- df_long %>% pivot_wider(names_from = NAME, values_from = Value)
  df_wide <- df_wide[, !names(df_wide) %in% "Metric"]
  return(df_wide)
}

data_frames <- list(to_df_wide(norm_counts), to_df_wide(norm_dur), to_df_wide(norm_sd))

# Merge all data frames by "ID"
df_wide <- reduce(data_frames, full_join, by = c("RFID", "Condition"))
df_wide[is.na(df_wide) ] <- 0

# Normalised data to be used in PCA
nz_groups <- c("event_count_nz", "event_dur_nz", "sd_nz", "all")
grp_cols <- c("#00AFBB", "#FC4E07", "darkorchid1", "#E7B800", "#0CB702", "#CC79A7", "red", "gray", "black")

# Build PCA Plots
for (x in nz_groups){
  print(paste0("CONSTRUCTING PCA: ", " ", options$save_name, " - ", x))
  if (x == "all") { numerical_data <- df_wide[3:ncol(df_wide)]
                    fwrite(numerical_data, paste0(out_path, options$save_name, "_Normalised_Input", ".csv"), sep=";", row.names = T, col.names = T, quote = F)
  } else {
      nz_names <- grep(x, names(df_wide))
      nz_names <- names(df_wide)[grep(x, names(df_wide))]
      numerical_data <- df_wide[nz_names]
    }
  numerical_data <- numerical_data[, !sapply(numerical_data, function(col) any(is.infinite(col)))]

  # Calculate PCA data
  data.pca <- prcomp(numerical_data)
  pc_df <- as.data.frame(data.pca$x)
  pc_df$Sample <- rownames(numerical_data)
  group_df <- df_wide[c("RFID")]
  group_df$Sample <- rownames(df_wide)
  group_df$Condition <- df_wide$Condition
  pc_group_df <- left_join(pc_df, group_df, by = "Sample")
  pc_group_df <- pc_group_df[, c("Sample", "RFID", "Condition", setdiff(names(pc_group_df), c("Sample", "RFID", "Condition")))]

  # PCA variance explained
  if (x == "event_count_nz"){
    eigenvalues <- data.pca$sdev^2
    edf <- data.frame("component"=paste0("PC", 1:length(data.pca$sdev)), "sdev"=data.pca$sdev, "eigen"=data.pca$sdev^2)
    edf$var <- edf$eigen / sum(edf$eigen) * 100
    fwrite(edf, paste0(out_path, options$save_name, "_PCA_variances", ".csv"), sep=";", row.names = F, col.names = T, quote = F)
    }

    # Plot PCA
    tiff(paste0(out_path, options$save_name, "_", x, "_PCA.tiff"), units="in", width=7.5, height=5, res=300)
    groups <- as.factor(df_wide$Condition)
    plot_ind <- fviz_pca_ind(data.pca,
               col.ind = groups, # color by groups
               palette = grp_cols,
               addEllipses = TRUE, # Concentration ellipses
               ellipse.type = "confidence",
               legend.title = "Groups",
               repel = TRUE)
    print(plot_ind)
    dev.off()

    # Contributing Factors Arrows 
    tiff(paste0(out_path, options$save_name, "_", x, "_variables.tiff"), units="in", width=7.5, height=5, res=300)
    plot_var <- fviz_pca_var(data.pca,
               col.var = "contrib", # Color by contributions to the PC
               gradient.cols = c("#00AFBB", "#E7B800", "#FC4E07"),
               repel = TRUE)
    print(plot_var)
    dev.off()
}
  
fwrite(pc_group_df, paste0(out_path, options$save_name, "_PCA_data", ".csv"), sep=";", row.names = T, col.names = T, quote = F)

  # Gather Contributing Factors
  contrib_df <- gather_var_and_meta(data.pca, out_path, options$save_name)
  contrib_df <- contrib_df[contrib_df$pca.group == "event_count_nz",
    c("component", grep("Dim", names(contrib_df), value = TRUE), "behaviour", "behaviour.group", "pca.group", "Event_Type")]
  fwrite(contrib_df, paste0(out_path, options$save_name, "_PCA_loadings", ".csv"), sep=";", row.names = F, col.names = T, quote = F)

  # Contributing Factors Boxplots
  gb <- ggplot(contrib_df, aes(x = behaviour.group, y = sqrt(Dim.1^2 + Dim.2^2), fill = behaviour.group)) +
    geom_boxplot() +
    theme_minimal() +
    labs(x = "Behavior Group", y = "Magnitude PC1 and PC2") +
    theme(axis.text.x = element_blank(), axis.title.x = element_blank()) + scale_fill_manual(values = custom_palette)

  tiff(paste0(out_path, options$save_name, "_CF_boxplot",".tiff"), width=7.5, height=5, unit="in", res=300)
  print(gb)
  dev.off()