#!/bin/Rscript

# Test condition differences in PCA scores and relate them to individual behaviours.
# This stage reads the CSVs exported by the preceding PCA stage.

library(optparse)

# Command-line options ----
option_list <- list(
  make_option(c("-i", "--input_dir"), type = "character", help = "REQUIRED: Director path containing input sqlite databases (sqlite files must be rebuilt)"),
  make_option(c("-s", "--save_name"), type = "character", help = "REQUIRED: Provide a save name for the results"),
  make_option(c("-o", "--output"), type = "character", help = "REQUIRED: Output directory path"),
  make_option(c("-r", "--ref"), type = "character", help = "OPTIONAL: Reference group for Cohen D value calculation")
)

parser <- OptionParser(option_list = option_list)
options <- parse_args(parser)

if (is.null(options$input_dir)) stop("Error: Argument --input_dir is required. Use --help for usage information.")
if (is.null(options$save_name)) stop("Error: Argument --save_name is required. Use --help for usage information.")
if (is.null(options$output)) stop("Error: Argument --output is required. Use --help for usage information.")

library(data.table)
library(ggplot2)
library(dplyr)
library(effsize)
library(purrr)
library(rlang)
source("/workspace/LMT_functions.R")

# Prepare PCA scores, variance and normalised counts ----
# The scores come from the combined PCA, and the variance table comes from the count-only fit.
df <- data.frame(fread(list.files(path = options$input_dir, pattern = "PCA_data.csv", full.names = TRUE, recursive = TRUE)[1], fill=T))
df$V1 <- NULL
df <- df[!is.na(df$Condition) & nzchar(trimws(df$Condition)), ]
if (length(unique(df$Condition)) < 2L) {
  stop("PCA statistics require mice from at least two conditions in the PCA scores. Check the Condition and RFID columns in the cage manifest.")
}
df_beh <- data.frame(fread(list.files(path = options$input_dir, pattern = "Normalised_Input.csv", full.names = TRUE, recursive = TRUE)[1], sep = ";", fill=T))
edf <- data.frame(fread(list.files(path = options$input_dir, pattern = "PCA_variances.csv", full.names = TRUE, recursive = TRUE)[1], sep = ";", fill=T))

out_path <- ensure_trailing_slash(options$output)
pcapath <- paste0(out_path, "multivariate/")
ensure_dir(pcapath)

# Join the count features to each mouse and condition using the exported row ID.
df_beh <- df_beh %>% select(V1, contains("count_nz"))
df_beh <- df_beh %>% rename(Sample = V1)
df_beh <- merge(df_beh, df[c("Sample","RFID","Condition")])

# Match the contribution table's feature names to the normalised count columns.
df_ro <- data.frame(fread(list.files(path = options$input_dir, pattern = "PCA_loadings.csv", full.names = TRUE, recursive = TRUE)[1], sep = ";", fill=T))
df_ro$component <- gsub(" ", "\\.", df_ro$component)
df_ro$component <- gsub("-", "\\.", df_ro$component)
df_ro$behaviour <- gsub("_", "", df_ro$behaviour)
df_ro$component <- gsub(",", "\\.", df_ro$component)
df_ro <- df_ro[rowSums(is.na(df_ro)) <= 1, ]
dim_cols <- grep("Dim", names(df_ro), value = TRUE)
df_ro[dim_cols] <- lapply(df_ro[dim_cols], as.numeric)

# Test condition differences in the component scores ----
pc_cols <- grep("^PC\\d+$", names(df), value = TRUE)
if (!length(pc_cols)) stop("No PC scores found in the PCA data.")

# prcomp can export PCs with only numerical noise, e.g. PC4 for four mice.
pc_sds <- vapply(df[pc_cols], function(scores) {
  scores <- scores[is.finite(scores)]
  if (length(scores) < 2L) return(0)
  sd(scores)
}, numeric(1))
testable_pcs <- pc_cols[pc_sds > max(pc_sds) * sqrt(.Machine$double.eps)]

# Start with the leading PCs. For a one-way model the number of responses
# cannot exceed the number of complete mice minus the number of conditions.
max_pcs <- min(5L, nrow(df) - length(unique(df$Condition)))
manova_candidates <- head(testable_pcs, max_pcs)
manova_summary <- "MANOVA skipped: at least two informative PCs with sufficient complete observations and residual degrees of freedom are required."
for (pc_count in rev(seq_along(manova_candidates))) {
  if (pc_count < 2L) break
  manova_pcs <- head(manova_candidates, pc_count)
  complete_rows <- rowSums(!is.finite(as.matrix(df[manova_pcs]))) == 0L
  manova_data <- df[complete_rows, ]
  n_conditions <- length(unique(manova_data$Condition))
  residual_df <- nrow(manova_data) - n_conditions
  if (n_conditions < 2L || residual_df < pc_count) next

  response <- as.matrix(manova_data[manova_pcs])
  manova_result <- manova(response ~ Condition, data = manova_data)
  # Even with enough mice, the residuals can be rank deficient.
  result <- tryCatch(summary(manova_result), error = identity)
  if (inherits(result, "error")) {
    manova_summary <- paste("MANOVA skipped:", conditionMessage(result))
    next
  }

  manova_summary <- c(
    sprintf("Components: %s (n = %d mice, residual df = %d)",
            paste(manova_pcs, collapse = ", "), nrow(manova_data), residual_df),
    capture.output(print(result))
  )
  break
}

writeLines("##### MANOVA RESULT #####", paste0(pcapath, options$save_name, "_PC_Statistics.txt"))
con <- file(paste0(pcapath, options$save_name, "_PC_Statistics.txt"), open = "a")

writeLines(as.character(manova_summary), con)
writeLines("\n", con)

# Fit a separate ANOVA for each informative component with usable mouse scores.
results <- setNames(rep(NA_real_, length(pc_cols)), pc_cols)
results[testable_pcs] <- vapply(testable_pcs, function(pc) {
  pc_data <- df[is.finite(df[[pc]]), ]
  n_conditions <- length(unique(pc_data$Condition))
  if (n_conditions < 2L || nrow(pc_data) <= n_conditions) return(NA_real_)
  model <- aov(reformulate("Condition", response = pc), data = pc_data)
  summary(model)[[1]][["Pr(>F)"]][1]
}, numeric(1))
writeLines("##### ANOVA RESULT #####", con)
writeLines(capture.output(print(results)), con)
writeLines("\n", con)

# Report Bonferroni-adjusted p-values and use raw p-values to select additional plots.
p_adj <- p.adjust(results, method = "bonferroni", n = sum(!is.na(results)))
sig_pcs <- names(results)[!is.na(results) & results < 0.05]
mtc_res <- data.frame(PC = names(results), p_value = results, adj_p_value = p_adj[names(results)])

writeLines("##### MULIPLE TEST CORRECTION #####", con)
writeLines(capture.output(print(mtc_res)), con)
close(con)

# Estimate signed, Hedges-corrected effects for the normalised counts ----
# A reference condition limits the comparisons and is placed first in each pair.
behs <- names(df_beh)[!(names(df_beh) %in% c("Sample", "RFID", "Condition"))]
if (is.null(options$ref) == T){
  df_cd <- purrr::map_dfr(behs, ~ pairwise_cohen_d_str(df_beh, var = .x, condition = "Condition"))
} else {
  df_cd <- purrr::map_dfr(behs, ~ pairwise_cohen_d_str(df_beh, var = .x, condition = "Condition", reference = options$ref))
}
df_cd$comps <- paste0(df_cd$group1, "_vs_", df_cd$group2)
df_cd <- df_cd[complete.cases(df_cd),]

# Plot PC1, PC2 and components with raw p-values below 0.05 ----
plot_pcs <- intersect(c("PC1", "PC2", sig_pcs), pc_cols)
for (pc in plot_pcs) {
  vari <- round(as.numeric(edf$var[edf$component == pc][1]))
  # Display the adjusted p-value when it is below 0.05. Otherwise display the raw value.
  p_vals <- mtc_res[mtc_res$PC== pc,]
  if (is.na(p_vals$p_value)) {
    plabel <- "p-value unavailable"
  } else if (p_vals$adj_p_value < 0.05){
    p_val <- p_vals$adj_p_value
    plabel <- paste0("adj pVal (bonferroni) = ", signif(p_val, 3)) } else {
      p_val <- p_vals$p_value
      plabel <- paste0("pVal= ", signif(p_val, 3))
    }

  p <- ggplot(df, aes_string(x = "Condition", y = pc, fill = "Condition")) +
    geom_boxplot() +
    theme_minimal() +
    ggtitle(paste0(pc, " (", vari, "%) ", "by Condition")) +
    theme(
      legend.position = "none",
      panel.background = element_rect(fill = "white", color = NA),
      plot.background = element_rect(fill = "white", color = NA)
    ) +
    scale_fill_manual(values = grp_cols)

  y_max <- max(df[[pc]], na.rm = TRUE)
  y_pos <- y_max + 0.1 * abs(y_max)  # vertical position above the boxplot
  p <- p + annotate("text", x = 1.5, y = y_pos, label = plabel, size = 4)

  ggsave(paste0(pcapath, options$save_name, "_", pc, "_Condition_comparison_boxplot.png"), plot = p, width = 6, height = 5, dpi = 300)
  }

# Plot component contributions and contribution-weighted effects ----
for (x in plot_pcs){
  print(paste0("CONSTRUCTING PCA loading and effect size plots: ", x))
  pc <- as.numeric(gsub("PC", "", x))
  dim_name <- paste0("Dim.", pc)
  if (!dim_name %in% dim_cols) next
  df_tmp <- df_ro
  df_tmp$Loading <- df_tmp[[dim_name]] 
  df_tmp <- df_tmp[order(-df_tmp$Loading), ]
  df_tmp$behaviour <- factor(df_tmp$behaviour, levels = df_tmp$behaviour)

  # Order behaviours by their contribution to this component.
  g <- ggplot(df_tmp, aes_string(x = "behaviour", y = dim_name, fill = "behaviour.group")) +
    geom_bar(stat = "identity") +
    labs(
      title = paste0("PC", pc," loadings"),
      x = "",
      y = "Loading\n",
      fill = "Behaviour Group"
    ) +
    theme(
      legend.position = "top",
      axis.text.x = element_text(angle = 45, hjust = 1),
      panel.background = element_rect(fill = "white", color = NA),
      plot.background = element_rect(fill = "white", color = NA)
    ) + 
    guides(fill = guide_legend(ncol = 3)) +
    scale_fill_manual(values = custom_palette)
  ggsave(paste0(pcapath, options$save_name, "_Loadings_PC",pc,".png"), plot = g, width = 10, height = 8, dpi = 300)
  
  # Weight each pairwise effect by its component contribution and rescale
  # by the largest absolute weighted effect for that component and comparison.
  for (y in unique(df_cd$comps)) {
      
      df_tmp <- merge(
        df_ro,
        df_cd[df_cd$comps == y, c("variable", "group1", "group2", "comps", "d")],
        by.x = "component",
        by.y = "variable"
      )
      
      df_tmp <- df_tmp %>%
        mutate(projected_effect_PC = d * .data[[dim_name]])
      
      df_tmp$projected_effect_PC_nz <- df_tmp$projected_effect_PC / max(abs(df_tmp$projected_effect_PC))
      
      # Store the plotted values alongside the raw pairwise effects.
      colname <- paste0("projected_effect_PC", pc, "_nz")
      if (!colname %in% names(df_cd)) {
        df_cd[[colname]] <- NA_real_
      }
      
      idx <- df_cd$comps == y & df_cd$variable %in% df_tmp$component
      match_idx <- match(df_cd$variable[idx], df_tmp$component)
      df_cd[idx, colname] <- df_tmp$projected_effect_PC_nz[match_idx]
      df_tmp <- df_tmp[complete.cases(df_tmp),]
      
      gg <- df_tmp %>%
        mutate(behaviour = factor(behaviour, levels = behaviour[order(-projected_effect_PC_nz)])) %>%
        ggplot(aes(x = behaviour, y = projected_effect_PC_nz, fill = behaviour.group)) +
        geom_col() +
        coord_flip() +
        theme_minimal() +
        theme(
          panel.background = element_rect(fill = "white", color = NA),
          plot.background = element_rect(fill = "white", color = NA)
        ) +
        labs(
          title = paste0("Projected Condition Effect on PC", pc, " by Behaviour"),
          x = "Behaviour",
          y = paste0("\nProjected Effect Size (Cohen's d × Loading on PC", pc, ")"),
          fill = "Behaviour Group"
        ) +
        scale_fill_manual(values = custom_palette) +
        ylim(-1, 1)
      
      ggsave(
        paste0(pcapath, options$save_name, "_Behaviour_effectsize_PC_", as.character(pc), "_", y, ".png"),
        plot = gg, width = 10, height = 10, dpi = 300
      )
  }
}

# Export complete rows with both raw effects and the scaled values used in the plots.
df_cd <- df_cd[complete.cases(df_cd),]
fwrite(df_cd, paste0(pcapath, options$save_name, "_EffectSize_data", ".csv"), sep=";", row.names = F, col.names = T, quote = F)
