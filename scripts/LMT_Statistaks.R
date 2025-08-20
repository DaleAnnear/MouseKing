#!/bin/Rscript

library(optparse)

# Initiate option list
option_list <- list(
  make_option(c("-i", "--input_dir"), type = "character", help = "REQUIRED: Director path containing input sqlite databases (sqlite files must be rebuilt)"),
  make_option(c("-s", "--save_name"), type = "character", help = "REQUIRED: Provide a save name for the results"),
  make_option(c("-o", "--output"), type = "character", help = "REQUIRED: Output directory path")
)

# Parse command-line options
parser <- OptionParser(option_list = option_list)
options <- parse_args(parser)

# Check for required arguments
if (is.null(options$input_dir)) stop("Error: Argument --input_dir is required. Use --help for usage information.")
if (is.null(options$save_name)) stop("Error: Argument --save_name is required. Use --help for usage information.")
if (is.null(options$output)) stop("Error: Argument --output is required. Use --help for usage information.")


# Libraries
library(data.table)
library(ggplot2)
library(dplyr)
library(effsize)
source("/workspace/LMT_functions.R")

### Data Prep ###
# Data Import
df <- data.frame(fread(list.files(path = options$input_dir, pattern = "PCA_data.csv", full.names = TRUE, recursive = TRUE)[1], fill=T))
df$V1 <- NULL
df_beh <- data.frame(fread(list.files(path = options$input_dir, pattern = "Normalised_Input_Data.csv", full.names = TRUE, recursive = TRUE)[1], sep = ";", fill=T))

out_path <- ensure_trailing_slash(options$output)
pcapath <- paste0(out_path, "pca/")
ensure_dir(pcapath)
plotpath <- paste0(out_path, "plots/")
ensure_dir(plotpath)

df_beh <- df_beh %>% select(V1, contains("count_nz"))
df_beh <- df_beh %>% rename(Sample = V1)
df_beh <- merge(df_beh, df[c("Sample","RFID","Genotype")])

# Data treatment
df_ro <- data.frame(fread(list.files(path = options$input_dir, pattern = "PCA_loading_data.csv", full.names = TRUE, recursive = TRUE)[1], sep = ";", fill=T))
df_ro$component <- gsub(" ", "\\.", df_ro$component)
df_ro$component <- gsub("-", "\\.", df_ro$component)
df_ro$behaviour <- gsub("_", "", df_ro$behaviour)
df_ro$component <- gsub(",", "\\.", df_ro$component)
df_ro <- df_ro[rowSums(is.na(df_ro)) <= 1, ]
df_ro$Dim.1 <- as.numeric(df_ro$Dim.1)
df_ro$Dim.2 <- as.numeric(df_ro$Dim.2)
df_ro$Dim.comb <- as.numeric(df_ro$Dim.comb)

### Statistaks ###
# Step 1: Permform manova on top ranked PC's
pc_cols <- grep("^PC\\d+$", names(df), value = TRUE)
pc_cols <- pc_cols[1:5]  # just the top 5 PCs
manova_formula <- as.formula(paste("cbind(", paste(pc_cols, collapse = ", "), ") ~ Genotype"))
manova_result <- manova(manova_formula, data = df)

manova_summary <- capture.output(summary(manova_result))

writeLines("##### MANOVA RESULT #####", paste0(pcapath, options$save_name, "_PC_Statistics.txt"))
con <- file(paste0(pcapath, options$save_name, "_PC_Statistics.txt"), open = "a")

writeLines(as.character(manova_summary), con)
writeLines("\n", con)

# ANOVA for all PC
results <- sapply(paste0("PC", 1:as.numeric(gsub("PC", "", names(df[ncol(df)])))), function(pc) {
  model <- aov(as.formula(paste(pc, "~ Genotype")), data = df)
  summary(model)[[1]][["Pr(>F)"]][1]  # extract p-value
})
writeLines("##### ANOVA RESULT #####", con)
writeLines(capture.output(print(results)), con)
writeLines("\n", con)

# Multiple test correction
p_adj <- p.adjust(results, method = "bonferroni")
sig_pcs <- names(p_adj)[p_adj < 0.05]
sig_pcs <- results[results < 0.05]
mtc_res <- data.frame(PC = names(sig_pcs), p_value = sig_pcs[names(sig_pcs)], adj_p_value = p_adj[names(sig_pcs)])

writeLines("##### MULIPLE TEST CORRECTION #####", con)
writeLines(capture.output(print(mtc_res)), con)
close(con)

# Effect size

# Apply for each behavior in df_ro
df_ro$cohen_d <- sapply(df_ro$component, get_cohen_d)

### Plotting ###
# Plot Boxplots
for (pc in names(sig_pcs)) {
  
  print(pc)
  # Extract adjusted p-value
  p_vals <- mtc_res[mtc_res$PC== pc,]  #p_adj[pc]
  if (p_vals$adj_p_value < 0.05){
    p_val <- p_vals$adj_p_value
    plabel <- paste0("adj pVal (bonferroni) = ", signif(p_val, 3)) } else {
      p_val <- p_vals$p_value
      plabel <- paste0("pVal= ", signif(p_val, 3))
    }
  print(p_val)
  
  # Create basic boxplot
  p <- ggplot(df, aes_string(x = "Genotype", y = pc, fill = "Genotype")) +
    geom_boxplot() +
    theme_minimal() +
    ggtitle(paste(pc, "by Condition")) +
    theme(
      legend.position = "none",
      panel.background = element_rect(fill = "white", color = NA),
      plot.background = element_rect(fill = "white", color = NA)
    ) +
    scale_fill_manual(values = c("#00AFBB", "#FC4E07"))
  
  # Add p-value annotation
  y_max <- max(df[[pc]], na.rm = TRUE)
  y_pos <- y_max + 0.1 * abs(y_max)  # vertical position above the boxplot
  p <- p + annotate("text", x = 1.5, y = y_pos, label = plabel, size = 4)
  
  ggsave(paste0(plotpath, options$save_name, "_", pc, "_Condition_comparison_boxplot.png"), plot = p, width = 6, height = 5, dpi = 300)
  }

list_siG_pcs <- unique(c("PC1", "PC2", names(sig_pcs)))
list_siG_pcs <- list_siG_pcs[list_siG_pcs %in% c("PC1", "PC2", "PC3", "PC4", "PC5")]


for (x in list_siG_pcs){
  pc <- as.numeric(gsub("PC", "", x))
  dim_name <- paste0("Dim.", pc)
  
  df_tmp <- df_ro %>%
    mutate(projected_effect_PC = cohen_d * .data[[dim_name]]) 

  df_tmp$projected_effect_PC_nz <- df_tmp$projected_effect_PC/max(abs(df_tmp$projected_effect_PC))

  df_tmp$Loading <- df_tmp[[dim_name]] 
  df_tmp <- df_tmp[order(-df_tmp$Loading), ]
  df_tmp$behaviour <- factor(df_tmp$behaviour, levels = df_tmp$behaviour)
  
  g <- ggplot(df_tmp, aes_string(x = "behaviour", y = dim_name, fill = "behaviour.group")) +
    geom_bar(stat = "identity") +
    labs(
      title = paste0("PC", pc," loadings"),
      x = "",
      y = "Loading\n",
      fill = "Behaviour Group"  # ← legend title
    ) +
    theme(
      legend.position = "top",
      axis.text.x = element_text(angle = 45, hjust = 1),
      panel.background = element_rect(fill = "white", color = NA),
      plot.background = element_rect(fill = "white", color = NA)
    ) +
    guides(fill = guide_legend(ncol = 3)) +
    scale_fill_manual(values = custom_palette)
  ggsave(paste0(plotpath, options$save_name, "_Loadings_PC",pc,".png"), plot = g, width = 10, height = 8, dpi = 300)

  gg <- df_tmp %>%
    mutate(behaviour = factor(behaviour, levels = behaviour[order(-projected_effect_PC_nz)])) %>%
    ggplot(aes(x = behaviour, y = projected_effect_PC_nz*-1, fill = behaviour.group)) +
    geom_col() +
    coord_flip() +
    theme_minimal() +
    theme(
      panel.background = element_rect(fill = "white", color = NA),
      plot.background = element_rect(fill = "white", color = NA)
    ) +
    labs(
      title = paste0("Projected Genotype Effect on PC", pc," by Behaviour"),
      x = "Behaviour",
      y = paste0("\nProjected Effect Size (Cohen's d × Loading on PC",pc,")"),
      fill = "Behaviour Group"
    ) +
    scale_fill_manual(values = custom_palette) +
    ylim(-1, 1)
  
  ggsave(paste0(plotpath, options$save_name, "_Behaviour_effectsize_PC", as.character(pc), ".png"), plot = gg, width = 10, height = 10, dpi = 300)
}