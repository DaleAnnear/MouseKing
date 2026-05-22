#!/bin/Rscript

library(optparse)

# Initiate option list
option_list <- list(
  make_option(c("-i", "--input_dir"), type = "character", help = "REQUIRED: Director path containing input sqlite databases (sqlite files must be rebuilt)"),
  make_option(c("-m", "--cage_manifest"), type = "character", help = "REQUIRED: File path to cage manifest file (FORMAT: RFID	Genotype	Cage)"),
  make_option(c("-s", "--save_name"), type = "character", help = "REQUIRED: Provide a save name for the results"),
  make_option(c("-o", "--output"), type = "character", help = "REQUIRED: Output directory path")
)

# Parse command-line options
parser <- OptionParser(option_list = option_list)
options <- parse_args(parser)

library(data.table)
library(dplyr)
library(ggplot2)
source("/workspace/LMT_functions.R")

input_path <- list.files(path = options$input_dir, pattern = "*All_Events_filter_frames_.*\\.csv$", full.names = TRUE, recursive = TRUE)[1]
mani_path <- options$cage_manifest
cage_path <- list.files(path = options$input_dir, pattern = "*Cage_Count_means_filter_frames_.*\\.csv$", full.names = TRUE, recursive = TRUE)[1]
out_path <- paste0(ensure_trailing_slash(options$output), "")
unipath <- paste0(out_path, "univariate/")
ensure_dir(unipath)

event_df <- data.frame(fread(input_path, colClasses = c(RFID = "character")))
event_df$RFID <- paste0("00", event_df$RFID)
mani_df <- data.frame(fread(mani_path, colClasses = c(RFID = "character")))
cage_df <- data.frame(fread(cage_path))

events_by_cage <- agg_all_events(event_df, mani_df)
events_by_cage <- events_by_cage[!(events_by_cage$NAME %in% c("Detection", "Head detected")),]
events_by_cage <- merge(events_by_cage, cage_df, by=c("NAME", "Cage"))
events_by_cage$event_count_nz <- (events_by_cage$Event_Count - events_by_cage$Event_Mean)/events_by_cage$Event_SD

cons <- unique(events_by_cage$Condition)
comparisons <- apply(combn(cons, 2), 2, paste, collapse = "_vs_")
comparisons

all_results_df <- data.frame()

for (x in comparisons) {
  parts <- unlist(strsplit(x, "_vs_"))
  
  df <- events_by_cage[events_by_cage$Condition %in% parts, ]
  df$Condition <- factor(df$Condition, levels = parts)
  
  df <- df %>%
    group_by(NAME) %>%
    filter(n_distinct(Condition) == 2) %>%
    ungroup()
  
  df <- df[complete.cases(df), ]
  
  results <- df %>%
    group_by(NAME) %>%
    summarise(
      p_value = wilcox.test(event_count_nz ~ Condition, alternative = "two.sided")$p.value,
      cohens_d = effsize::cohen.d(event_count_nz ~ Condition, hedges.correction = TRUE)$estimate,
      .groups = "drop"
    ) %>%
    mutate(
      p_adj = p.adjust(p_value, method = "BH"),
      comp = x
    )
  
  all_results_df <- bind_rows(all_results_df, results)
  all_results_df <- all_results_df[complete.cases(all_results_df),]
}

all_results_df <- merge(all_results_df, event_types)
all_results_df$effect_size <- ave(
  all_results_df$cohens_d,
  all_results_df$comp,
  FUN = normalise_cohens_d
)

all_results_df <- all_results_df %>% mutate(color = custom_palette[Behaviour.Type])
all_results_df$color <- ifelse(all_results_df$p_adj > 0.05, "#A9A9A9", all_results_df$color)
all_results_df$legend <- ifelse(all_results_df$p_adj > 0.05, "Non-significant", all_results_df$Behaviour.Type)

res_agg <- all_results_df %>% count(legend, color, comp)
res_agg$legend <- factor(
  res_agg$legend,
  levels = c(
    "Non-significant",
    "Grouping & Withdrawal",
    "Initiation & Approach",
    "Motor Behavior & Body Posture",
    "Physical Social Contact",
    "Spatial Positioning"
  )
)
res_agg <- res_agg[order(res_agg$legend), ]
cols <- res_agg %>%
  distinct(legend, color) %>%
  tibble::deframe()

gg <- ggplot(res_agg, aes(x = comp, y = n, fill = legend)) +
  geom_col(width = 0.72, color = "white", linewidth = 0.3) +
  scale_fill_manual(
    values = cols,
    breaks = levels(res_agg$legend)
  ) +
  scale_y_continuous(
    limits = c(0, 40),
    expand = expansion(mult = c(0, 0.05))
  ) +
  labs(
    x = "Comparison",
    y = "Behavioral events in domain",
    fill = NULL
  ) +
  theme_classic(base_size = 12) +
  theme(
    axis.text.x = element_text(angle = 35, hjust = 1, vjust = 1),
    axis.title.x = element_text(margin = margin(t = 10)),
    axis.title.y = element_text(margin = margin(r = 10)),
    legend.position = "right",
    legend.title = element_blank(),
    legend.key.height = unit(0.5, "cm"),
    plot.margin = margin(t = 15, r = 30, b = 25, l = 20)
  )

tiff(paste0(unipath, "Univariate_Behavioural_Domains_", options$save_name, ".tiff"), width=7.5, height=7.5, unit="in", res=300)
print(gg)
dev.off()

# Effect size plotting
for (y in unique(all_results_df$comp)) {
  df_tmp <- all_results_df[all_results_df$comp == y, ]

  df_tmp <- df_tmp[complete.cases(df_tmp),]

  gg_eff <- df_tmp %>%
    mutate(Event_Type = factor(Event_Type, levels = Event_Type[order(effect_size)])) %>%
    ggplot(aes(x = Event_Type, y = effect_size, fill = Behaviour.Type)) +
    geom_col() +
    coord_flip() +
    theme_minimal() +
    theme(
      panel.background = element_rect(fill = "white", color = NA),
      plot.background = element_rect(fill = "white", color = NA)
    ) +
    labs(
      title = paste0("Condition Effect by Behaviour (", y, ")"),
      x = "Behaviour",
      y = "Effect Size (normalized Cohen's d)",
      fill = "Behaviour Group"
    ) +
    scale_fill_manual(values = custom_palette) +
    ylim(-1, 1)

  tiff(paste0(unipath, "Univariate_Behaviour_effectsize_", y, "_", options$save_name, ".tiff"), width=10, height=10, unit="in", res=300)
  print(gg_eff)
  dev.off()
}

fwrite(all_results_df[c("NAME","p_value","p_adj","cohens_d","effect_size","comp","Behaviour.Type","Event_Type")], paste0(unipath, "Univariate_Analysis_Behavioural_Domain_", options$save_name, ".txt"), sep=";")
