# Shared helpers for importing LMT tables, summarising behaviour and comparing conditions.

# Event import and aggregation ----

# Store ANIMAL and EVENT CSVs in .GlobalEnv using their file stems as R names.
# The timing and aggregation helpers use those names to find and pair the tables.
read_and_save_csv = function(directory) {
  csv_files <- list.files(directory, pattern = ".*(ANIMAL|EVENT).*\\.csv$", full.names = TRUE, recursive = TRUE)
  print(paste0("The folllowing data files were located at directroy ", directory))
  print(csv_files)
  
  for (csv_file in csv_files) {
    data <- data.frame(fread(file=csv_file))

    var_name <- make.names(tools::file_path_sans_ext(basename(csv_file)))

    assign(var_name, data, envir = .GlobalEnv)
  }
}

# Pair each EVENT table with its ANIMAL table and apply the minimum frame count.
# Store per-table summaries as *_agg and combine the individual rows in all_events.
aggregate_on_events = function(frame_filter) {
  object_names <- ls(envir = .GlobalEnv)

  # Exclude summaries that have already been generated from the raw EVENT tables.
  #events_dataframes <- object_names[grepl("EVENT", object_names)]
  events_dataframes <- object_names[grepl("EVENT", object_names) & !grepl("_agg", object_names)]
  
  #allevents <- c()
  
  for (df_name in events_dataframes) {
    print(paste0("Processing table: ", df_name))
    df <- get(df_name, envir = .GlobalEnv)
    # LMT records the first and last frames of each event inclusively.
    df$FRAME.DUR <- df$ENDFRAME - df$STARTFRAME + 1
    animal_name <- gsub("EVENT", "ANIMAL", df_name)
    animal_df <- get(animal_name, envir = .GlobalEnv)
    animal_df <- animal_df[c("ID", "RFID")]
    df <- df[df$FRAME.DUR >= frame_filter,]
    
    ae <- extract_events(df, animal_df)

    if (exists("aem") == T) aem <- rbind(aem, ae) else aem <- ae
    
    #allevents <-  c(allevents, data.frame(ae))
    
    # Both summaries use the same event, local mouse ID and phase keys.
    result_count <- event_counts(df)
    result_dur <- event_timimgs(df)
    
    result <- merge(result_count, result_dur, by=c("NAME","MOUSE","Phase"), all=T)
    result <- merge(result, animal_df, by.x="MOUSE", by.y="ID", all=T)

    #View(result)
    
    # These treatment labels come from the file name and precede the manifest join.
    if (grepl("base", df_name) == T) result$condition <- "baseline" else
      if (grepl("wash", df_name) == T) result$condition <- "washout" else
        if (grepl("mino", df_name) == T) result$condition <- "mino" else
          if (grepl("belu", df_name) == T) result$condition <- "belu" else
            if (grepl("combi", df_name) == T) result$condition <- "combi" else
      result$condition <- "not specified"

    assign(paste0(df_name, "_agg"), result, envir = .GlobalEnv)
  }
  #combined_events <- data.frame(do.call(rbind, allevents))
  assign("all_events", aem, envir = .GlobalEnv)
}

# Combine the *_agg tables, omit selected event codes and join the manifest by RFID.
# Keep the full joins and a complete-case version under separate output names.
anno_and_clean = function(mani){
  
  remove_events <- c("Detection", "Group4", "Head detected", "MACHINE LEARNING ASSOCIATION", "RFID ASSIGN ANONYMOUS TRACK", "RFID MATCH", "RFID MISMATCH", "Train4")
  event_type <- data.frame("Behaviour.Type"=c("Body configuration",  "Body configuration",  "Body configuration",  "Body configuration",  "Body configuration",  "Isolated behaviour", "Isolated behaviour",  "Isolated behaviour", "Position in contact", "Position in contact", "Position in contact", "Position in contact", "Type of contact", "Type of contact", "Type of contact", "Type of contact", "Social configuration", "Social configuration", "Social configuration", "Social configuration", "Social configuration", "Social configuration", "Social approach","Social approach","Social approach", "Social approach", "Social approach", "Social approach" , "Social escape",  "Social escape",  "Social escape",  "Social escape", "Contact sequences", "Contact sequences", "Isolated behaviour", "Social configuration", "Social configuration", "Social configuration", "Isolated behaviour", "Isolated behaviour", "Isolated behaviour"), 
                           "NAME"=c("Look down","Stop","Rearing","WallJump","SAP","Move isolated","Stop isolated","Rear isolated","Move in contact","Rear in contact","Contact","Stop in contact","Side by side Contact","Side by side Contact, opposite way", "Oral-oral Contact","Oral-genital Contact","Group2","Group3","Train2","Train3","Train4","FollowZone Isolated","Social approach","Approach","Approach rear","Approach contact","Group 3 make","Group 4 make","Get away","Break contact","Group 3 break","Group 4 break","seq oral oral - oral genital","seq oral geni - oral oral", "Center Zone", "FollowZone", "Group4", "Nest3_", "Periphery Zone", "Rear at periphery", "Rear in centerWindow"),
                           "Event_Type"=c("Head down","Stop","Rearing","Jump","SAP","Move alone","Stop alone","Rear isolated","Move contact","Rear contact","Contact","Stop in contact","Contact side-side","Contact side-side opposite", "Contact nose-nose","Contact nose-anogenital","Group of 2","Group of 3","Train of 2","Train of 3","Train of 4","Follow","Social approach","Approach from front","Approach from rear","Make Contact","Make a group of 3","Make a group of 4","Get away","Break contact","Break group of 3","Break group of 4","Seq o-o o-g","Seq o-g o-o","Present in Centre","Following","Group of 4","Nesting Together: 3","Present at Periphery", "Rearing at Periphery", "Rearing at Centre"))
  
  object_names <- ls(envir = .GlobalEnv)
  agg_dataframes <- object_names[grepl("_agg", object_names)]
  mdf <- do.call(rbind, lapply(agg_dataframes, get))
  mdf <- mdf[!(mdf$NAME %in% remove_events),]
  
  mdf <- merge(mdf, mani, by = "RFID", all = T)
  
  mdf <- merge(mdf, event_type, by = "NAME", all = T)
  
  assign("All_Events_agg_filtered", mdf[complete.cases(mdf), ], envir = .GlobalEnv)
  assign("All_Events_agg_raw", mdf, envir = .GlobalEnv)
}

# Plotting and statistical helpers ----

# Install any missing analysis packages and attach the complete set.
Libraries = function(){
  list.of.packages <- c("data.table","car", "RSQLite", "reshape2", "plyr", "ggplot2", "zeallot", "dplyr", "Rmisc", "tidyverse", "lme4", "pbkrtest", "gridExtra", "ggsignif", "optparse")
  new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[,"Package"])]
  if (length(new.packages) > 0) install.packages(new.packages)
  for (x in list.of.packages) suppressMessages(library(x, character.only = TRUE))
}

# Compare conditions per event, accounting for cage with a random intercept
# when there are multiple cages. The one-cage branch uses the session's KO/WT ratios.
statistacks_GT = function(counts_df, plot_df){
  if (length(unique(counts_df$Cage)) > 1){
    plot_df <- plot_df[plot_df$N > 4,]
    plot_df$test <- apply(plot_df, 1, function(x){
      myData <- counts_df[counts_df$NAME == x[1],]
      model<-lmer(Count~Condition+(1|Cage),data=myData)
      modelNull<-update(model,.~.-Condition)
      pValue<-KRmodcomp(model,modelNull)$test$p.value[1]
      estimate<-summary(model)$coef[2,1]
      st.error<-summary(model)$coef[2,2]
      return(list("p_value"=pValue, "EST"=estimate, "STD.ER"=st.error))
    })
    plot_df <- plot_df %>% unnest_wider(test) 
  } else if (length(unique(counts_df$Cage)) == 1){
    plot_df$p_value <- apply(plot_df, 1, function(x){
      df <- counts_mean_KO_v_WT_df[counts_mean_KO_v_WT_df$NAME==x[1],]
      if (x[1]=="Group4"){0} else {t.test(df$ratio, mu = 1)$p.value}
    })
  }
  
  plot_df$significance <- apply(plot_df, 1, function(x){
    if (x[1] == "Group4") "" else  
      if (as.numeric(x["p_value"]) < 0.001) "***" else
        if (as.numeric(x["p_value"]) < 0.01) "**" else
          if (as.numeric(x["p_value"]) < 0.05) "*" else ""
  })
  
  return(plot_df)
}

# Compare conditions per event using a cage random intercept for multiple cages.
# For a single cage, test ratios from counts_KO against 1.
statistacks_Con = function(counts_df, counts_KO, plot_df){
  if (length(unique(counts_df$Cage)) > 1){
    plot_df$test <- apply(plot_df, 1, function(x){
      myData <- counts_df[counts_df$NAME == x[1],]
      model<-lmer(Count~Condition+(1|Cage),data=myData)
      modelNull<-update(model,.~.-Condition)
      pValue<-KRmodcomp(model,modelNull)$test$p.value[1]
      estimate<-summary(model)$coef[2,1]
      st.error<-summary(model)$coef[2,2]
      return(list("p_value"=pValue, "EST"=estimate, "STD.ER"=st.error))
    })
    plot_df <- plot_df %>% unnest_wider(test) 
  } else if (length(unique(counts_df$Cage)) == 1){
    plot_df$p_value <- apply(plot_df, 1, function(x){
      df <- counts_KO[counts_KO$NAME==x[1],]
      if (x[1]=="Group4"){0} else {t.test(df$ratio, mu = 1)$p.value}
    })
  }
  
  plot_df$significance <- apply(plot_df, 1, function(x){
    if (x[1] == "Group4") "" else  
      if (as.numeric(x[7]) < 0.001) "***" else
        if (as.numeric(x[7]) < 0.01) "**" else
          if (as.numeric(x[7]) < 0.05) "*" else ""
  })
  
  return(plot_df)
}

# Plot mean event ratios with standard errors and significance annotations.
build_lmt_plot = function(plot_df, yaxis_title, yaxis_limit){
  gz <- ggplot(plot_df, aes(x=Event_Type, y=ratio, fill=Behaviour.Type)) + geom_hline(yintercept = 1, linetype = "dashed", color = "black", size = 0.5) +  coord_cartesian(ylim = c(0, yaxis_limit)) +
    geom_bar(position=position_dodge(), stat="identity") +
    geom_errorbar(aes(ymin=ratio-se, ymax=ratio+se), width=.3, position=position_dodge(.9)) +
    scale_y_continuous(expand = c(0,0)) +
    geom_text(aes(label=significance, y=0.05, fontface = "bold"), angle=90, size=5, vjust=0.6) +
    theme_classic() + 
    theme(panel.spacing = unit(0, "lines"), legend.position = "top", legend.title = element_text(size = 12, face = "bold"), axis.title.y = element_text(size=14), axis.text.y = element_text(face="bold", size=14), axis.text.x=element_text(angle = 45, hjust = 1), axis.title.x = element_blank()) +
    labs(fill = "Behaviour Types", y = yaxis_title)
  return(gz)
}

# Summarise event ratios and order the plot by the session's event_type lookup.
construct_plot_dataframe = function(mean_counts, counts_df, grp_vrs){
  plot_df <- summarySE(mean_counts, measurevar="ratio", groupvars=grp_vrs)
  #plot_df <- statistacks(counts_df, mean_counts, plot_df)
  plot_df <- merge(plot_df, event_type, by="NAME")
  plot_df <- na.omit(plot_df[match(event_type$NAME, plot_df$NAME),])
  plot_df$Event_Type <- factor(plot_df$Event_Type, levels = plot_df$Event_Type)
  plot_df$Behaviour.Type <- factor(plot_df$Behaviour.Type, levels = unique(plot_df$Behaviour.Type))

  return(plot_df)
}

# Run one event-count ANOVA per behaviour for the selected grouping variable.
statistacks_ano = function(plot_df, counts_df, vari){
  
  plot_df$pval <- apply(plot_df, 1, function(x){
    x_df <- counts_df[counts_df$NAME == as.character(x["NAME"]), ]
    if (vari == "Sex") anova_model <- aov(Count ~ Sex, data = x_df) else
      if (vari == "Condition") anova_model <- aov(Count ~ Condition, data = x_df) else
        if (vari == "GT") anova_model <- aov(Count ~ GT, data = x_df)
        df <- data.frame(summary(anova_model)[[1]])
        return(df$Pr..F.[1])
  })
  
  plot_df$significance <- apply(plot_df, 1, function(x){
    if (x[1] == "Group4") "" else  
      if (as.numeric(x["pval"]) < 0.001) "***" else
        if (as.numeric(x["pval"]) < 0.01) "**" else
          if (as.numeric(x["pval"]) < 0.05) "*" else ""
  })
  
  return(plot_df)
}

# Event timing and cage summaries ----

# Add clock times and phase labels to the EVENT tables in .GlobalEnv.
# The start-time lookup matches cage and condition against the table name.
event_times = function(tfile = "") {
  object_names <- ls(envir = .GlobalEnv)
  events_dataframes <- object_names[grepl("EVENT", object_names)]
  for (df_name in events_dataframes) {
    df <- get(df_name, envir = .GlobalEnv)
    if (tfile != ""){
      tfile$check <- apply(tfile, 1, function(x){
        if ( (grepl(gsub("-", ".", as.character(x["Cage"])), df_name) == T | grepl(gsub(" ", "", as.character(x["Cage"])), df_name) == T) & grepl(gsub(" ", "", as.character(x["Condition"])), df_name )) T else F
      })
      start_t <- as_hms(tfile$Start_Time[tfile$check == TRUE])
  } else start_t <- as_hms("00:00:00")
    #start_t <- tfile$Start_Time[tfile$check == TRUE]

    # Convert the start frame to elapsed seconds using the 30 fps assumption.
    df$SECONDFRAME <- round(df$STARTFRAME/30)
    df$time <- as_hms(as.numeric(start_t) + df$SECONDFRAME)
    df$time_actual <- as.numeric(df$time)
    df$time_actual <- ifelse(df$time_actual > 86400, df$time_actual - 86400, df$time_actual)
    df$time_actual <-  as_hms(df$time_actual)
    df$Section <- as.numeric(df$time_actual)
    
    # The clock-time split uses 20:00 and 08:00. The first elapsed hour is
    # labelled Habituation, and remaining daytime events are split at ten hours.
    df$Phase <- ifelse(df$Section > 72000 & df$Section < 86400, "Night", ifelse(df$Section > 0 & df$Section < 28800, "Night", "Day") )
    df$Phase <- ifelse(df$SECONDFRAME < 3600, "Habituation", ifelse(df$Phase == "Day" & df$SECONDFRAME < 36000, "Day1", ifelse(df$Phase == "Day" & df$SECONDFRAME > 36000, "Day2", df$Phase) ) )
    
    assign(df_name, df, envir = .GlobalEnv)
  }
}

# Summarise event durations in frames for each mouse and phase.
# Add a Total row per event and mouse across phases.
event_timimgs = function(df){
  dfx <- mouse_one_col(df)
  
  dur <- aggregate(FRAME.DUR ~ NAME + IDANIMAL + Phase, data = dfx, FUN = function(x) c(sum = sum(x), mean = mean(x), sd = sd(x)))
  dur <- do.call(data.frame, dur)
  dur_tot <- aggregate(FRAME.DUR ~ NAME + IDANIMAL, data = dfx, FUN = function(x) c(sum = sum(x), mean = mean(x), sd = sd(x)))
  dur_tot <- do.call(data.frame, dur_tot)
  names(dur) <- c("NAME", "MOUSE", "Phase", "Total_Dur", "Ave_Dur", "SD_Dur")
  names(dur_tot) <- c("NAME", "MOUSE", "Total_Dur", "Ave_Dur", "SD_Dur")
  dur_tot$Phase <- "Total"
  
  dur <- rbind(dur, dur_tot)
  
  return(dur)  
}

# Count event rows per mouse and phase, then add counts across all phases.
event_counts = function(df){

  dfx <- mouse_one_col(df)
  
  count <- aggregate(FRAME.DUR ~ NAME + IDANIMAL + Phase, data = dfx, FUN = function(x) length = length(x))
  count <- do.call(data.frame, count)
  count_tot <- aggregate(FRAME.DUR ~ NAME + IDANIMAL, data = dfx, FUN = function(x)  length = length(x))
  count_tot <- do.call(data.frame, count_tot)
  names(count) <- c("NAME", "MOUSE", "Phase", "Count")
  names(count_tot) <- c("NAME", "MOUSE", "Count")
  count_tot$Phase <- "Total"
  
  count <- rbind(count, count_tot)
  
  return(count)  
}

# Expand the four participant columns into individual mouse-event rows.
# Retain frame and timing fields and attach the RFID from the ANIMAL table.
extract_events = function(df, animal_df){
  for (x in c("A", "B", "C", "D")){
    animal <- paste0("IDANIMAL", x)
    dfx <- df[c("NAME", animal, "STARTFRAME", "FRAME.DUR", "time", "time_actual", "Section", "Phase")]
    names(dfx) <- c("NAME", "IDANIMAL", "STARTFRAME", "FRAME.DUR", "time", "time_actual", "Section", "Phase")
    dfx <- dfx[complete.cases(dfx), ]
    assign(paste0("df", x), dfx)
  }
  rdf <- rbind(dfA, dfB, dfC, dfD)
  rdf <- merge(rdf, animal_df, by.x="IDANIMAL", by.y="ID", all=T)
  return(rdf)
}

# Join mouse events to the manifest and write two cage summaries to .GlobalEnv.
# The normalisation table uses observed per-mouse counts for each behaviour.
cage_means = function(events, mm){
  
  df <- merge(events, mm, by = "RFID")
  
  ccm_df <- aggregate(FRAME.DUR ~ NAME + Cage + RFID, data = df, FUN = function(x) c("count" = length(x)))
  ccm_df <- aggregate(FRAME.DUR ~ NAME + Cage, data = ccm_df, FUN = function(x) c(sum = sum(x), mean = mean(x), sd = sd(x)))
  ccm_df <- do.call(data.frame, ccm_df)
  names(ccm_df) <- c("NAME", "Cage", "Event_Counts", "Event_Mean", "Event_SD")
  
  # Summarise counts and durations by condition and include an All group for each cage.
  count <- aggregate(FRAME.DUR ~ NAME + Condition + Cage, data = df, FUN = function(x) length = length(x))
  count <- do.call(data.frame, count)
  names(count) <- c("NAME", "Condition", "Cage", "Event_Count")
  count_tot <- aggregate(FRAME.DUR ~ NAME + Cage, data = df, FUN = function(x)  length = length(x))
  count_tot <- do.call(data.frame, count_tot)
  names(count_tot) <- c("NAME", "Cage", "Event_Count")
  count_tot$Condition <- "All"
  countbind <- rbind(count, count_tot)
  
  dur <- aggregate(FRAME.DUR ~ NAME + Condition + Cage, data = df, FUN = function(x) c(sum = sum(x), mean = mean(x), sd = sd(x)))
  dur <- do.call(data.frame, dur)
  names(dur) <- c("NAME", "Condition", "Cage", "Dur_Total", "Dur_Mean", "Dur_SD")
  dur_tot <- aggregate(FRAME.DUR ~ NAME + Cage, data = df, FUN = function(x) c(sum = sum(x), mean = mean(x), sd = sd(x)))
  dur_tot <- do.call(data.frame, dur_tot)
  names(dur_tot) <- c("NAME", "Cage", "Dur_Total", "Dur_Mean", "Dur_SD")
  dur_tot$Condition <- "All"
  durbind <- rbind(dur, dur_tot)
  
  mergedf <- merge(countbind, durbind, by = c("NAME", "Cage", "Condition"))
  mergedf[is.na(mergedf)] <- 0
  
  assign("cage_event_means", mergedf, envir = .GlobalEnv)
  assign("cage_count_means", ccm_df, envir = .GlobalEnv)
}

# Stack participant slots into one mouse ID column for counts and durations.
# An event with multiple identified mice contributes a row for each participant.
mouse_one_col = function(df){
  for (x in c("A", "B", "C", "D")){
    animal <- paste0("IDANIMAL", x)
    dfx <- df[c("FRAME.DUR","NAME", animal, "Phase")]
    names(dfx) <- c("FRAME.DUR","NAME", "IDANIMAL", "Phase")
    dfx <- dfx[complete.cases(dfx), ]
    assign(paste0("df", x), dfx)
  }
  
  dfx <- rbind(dfA, dfB, dfC, dfD)
  return(dfx)
}

# Calculate each cage's total, mean and SD of per-mouse event counts.
cage_count_means = function(x, mouse_mani){
  test <- merge(x, mouse_mani, by="RFID")
  
  test_agg <- aggregate(FRAME.DUR ~ NAME + Cage + RFID, data = test, FUN = function(x) c("count" = length(x)))
  test_agg <- aggregate(FRAME.DUR ~ NAME + Cage, data = test_agg, FUN = function(x) c(total_events = sum(x), mean_events = mean(x), events_sd = sd(x)))
  test_agg <- do.call(data.frame, test_agg)
  names(test_agg) <- c("NAME", "Cage", "Event_Count", "Event_Ave", "Event_sd")
  return(test_agg)
}

# Join event rows to the manifest and summarise count and duration per behaviour and RFID.
agg_all_events = function(df, mm){
  df <- merge(df, mm, by = "RFID")
  df_agg <- aggregate(FRAME.DUR ~ NAME + RFID + Condition + Cage, data = df, FUN = function(x) c(total_count = length(x), total_duration = sum(x), mean_duration = mean(x), duration_sd = sd(x)))
  df_agg <- do.call(data.frame, df_agg)
  names(df_agg) <- c("NAME", "RFID", "Condition", "Cage", "Event_Count", "Duration_Total", "Duration_Mean", "Duration_SD")
  return(df_agg)
}

# Summarise the mean and SD of duration variability for each behaviour and cage.
# PCA uses these statistics to standardise the per-mouse duration SD.
agg_SD = function(df){
  df_agg <- aggregate(SD_Dur ~ NAME + Cage, data = df, FUN = function(x) c(mean_sd = mean(x), sd_sd = sd(x)))
  df_agg <- do.call(data.frame, df_agg)
  names(df_agg) <- c("NAME", "Cage", "SD_Mean", "SD_SD")
  return(df_agg)
}

# Path helpers ----

# Preserve an existing slash or backslash, otherwise append a forward slash.
ensure_trailing_slash <- function(filepath) {
  if (!grepl("/$", filepath) && !grepl("\\\\$", filepath)) {
    filepath <- paste0(filepath, "/")
  }
  return(filepath)
}

# Insert a literal backslash before each space.
escape_spaces <- function(file_path) {
  escaped_path <- gsub(" ", "\\\\ ", file_path)
  return(escaped_path)
}

# Behaviour metadata and PCA contributions ----

# Split each PCA variable name into its LMT behaviour and metric suffix.
# Attach the display label and behavioural domain used in plots.
add_event_meta = function(df){
  #colnames(df)[colnames(df) == "V1"] <- "component"
  df$component <- row.names(df)
  df$behaviour <- apply(df, 1, function(x){
    bev <- strsplit(as.character(x["component"]), "\\.")[[1]][1]
    return(bev)})
  df$behaviour.group <- apply(df, 1, function(x){
    check <- as.character(x["behaviour"])
    filtered_df <- event_types[grep(check, event_types$NAME), ]
    keep <- filtered_df$Behaviour.Type[1]
    return(keep)})
  df$pca.group <- apply(df, 1, function(x){
    spl <- strsplit(as.character(x["component"]), "\\.")[[1]][2]
    return(spl)})
  df <- merge(df, event_types[c("NAME","Event_Type")], by.x = "behaviour", by.y = "NAME")
  return(df)
}

# Map LMT event codes to display labels and behavioural domains.
SP <- data.frame("Behaviour.Type"=c(rep("Spatial Positioning", 4)),
                 "NAME"=c("Center Zone", "Periphery Zone", "Rear at periphery", "Rear in centerWindow"),
                 "Event_Type"=c("Center zone", 	"Periphery zone", 	"Rear at periphery", "Rear at center") )
MB <- data.frame("Behaviour.Type"=c(rep("Motor Behavior & Body Posture", 8)),
                 "NAME"=c("Look down", "Stop", "Rearing", "WallJump", "SAP", "Move isolated", "Stop isolated", "Rear isolated"),
                 "Event_Type"=c("Head down", "Stop", "Rearing", "Jump", "SAP", 	"Move alone", "Stop alone", "Rear alone") )
PSC <- data.frame("Behaviour.Type"=c(rep("Physical Social Contact", 10)),
                 "NAME"=c("Move in contact","Rear in contact","Contact","Stop in contact","Side by side Contact","Side by side Contact, opposite way","Oral-oral Contact","Oral-genital Contact","seq oral oral - oral genita", "seq oral geni - oral oral"),
                 "Event_Type"=c("Move contact","Rear contact","Contact","Stop in contact","Side-side","Side-side opposite","Nose-nose","Nose-anogenital","Seq o-g","Seq o-g o-o") )
IA <- data.frame("Behaviour.Type"=c(rep("Initiation & Approach", 7)),
                 "NAME"=c("Social approach","Approach","Approach rear","Approach contact","Group 3 make","Group 4 make", "FollowZone Isolated"),
                 "Event_Type"=c("Social approach","Approach from front","Approach from rear","Make Contact","Make group of 3" ,"Make group of 4", "Follow") )
GW <- data.frame("Behaviour.Type"=c(rep("Grouping & Withdrawal", 11)),
                 "NAME"=c("Group2","Group3","Train2","Train3","Train4","Get away","Break contact","Group 3 break","Group 4 break","Nest3_","Nest4_"),
                 "Event_Type"=c("Group of 2","Group of 3","Train of 2","Train of 3","Train of 4","Get away","Break contact","Break group of 3","Break group of 4","Nest of 3","Nest of 4") )

event_types <- rbind(SP, MB, PSC, IA, GW)

# Keep domain colours consistent across PCA and univariate plots.
custom_palette <- c("Spatial Positioning"="#00AFBB",
                    "Motor Behavior & Body Posture"="#E7B800",
                    "Physical Social Contact"="#0000FF",
                    "Initiation & Approach"="#FC4E07",
                    "Grouping & Withdrawal"="#9413CB"
                    )

# Extract variable contributions for each principal component and add behaviour metadata.
gather_var_and_meta = function(pca_data, out_path, save_name){
  data <- as.data.frame(get_pca_var(pca_data)$contrib)
  data <- add_event_meta(data)
  return(data)
}

# Calculate a WT-versus-KO effect for one variable in the session's df_beh table.
get_cohen_d <- function(var_name) {
  x <- df_beh %>% filter(Condition == "WT") %>% pull(var_name)
  y <- df_beh %>% filter(Condition == "KO") %>% pull(var_name)
  d <- cohen.d(x, y)$estimate
  return(d)
}

# CLI and output validation ----

# Reject missing or empty values for the caller's required CLI options.
require_options <- function(options, required) {
  missing <- required[vapply(required, function(x) {
    is.null(options[[x]]) || identical(options[[x]], "")
  }, logical(1))]

  if (length(missing)) {
    stop(sprintf(
      "Missing required argument%s: %s\nUse --help for usage information.",
      ifelse(length(missing) > 1, "s", ""),
      paste(paste0("--", missing), collapse = ", ")
    ), call. = FALSE)
  }
}

# Ensure an output directory exists and return its path invisibly.
ensure_dir <- function(path, recursive = FALSE) {
  if (!dir.exists(path)) {
    dir.create(path, recursive = recursive)
    message("Directory created: ", normalizePath(path, mustWork = FALSE))
  } else {
    message("Directory already exists: ", normalizePath(path, mustWork = FALSE))
  }
  invisible(path)
}

# Pairwise effect sizes ----

# Estimate a signed standardised mean difference for one variable.
# Explicit pairs take precedence, then comparisons against a reference group,
# then all pairs. Group order determines the sign of the estimate.
pairwise_cohen_d_str <- function(data, var, condition,
                                 reference = NULL, pairs = NULL,
                                 hedges_correction = TRUE, pooled = TRUE, na_rm = TRUE) {
  stopifnot(is.character(var), length(var) == 1,
            is.character(condition), length(condition) == 1)
  
  df <- data %>%
    transmute(.value = .data[[var]],
              .group = as.character(.data[[condition]])) %>%
    filter(!is.na(.value), !is.na(.group))
  
  lvls <- unique(df$.group)
  if (length(lvls) < 2) stop("Need at least two condition levels.")
  
  pair_df <-
    if (!is.null(pairs)) {
      tibble(group1 = vapply(pairs, `[`, "", 1),
             group2 = vapply(pairs, `[`, "", 2))
    } else if (!is.null(reference)) {
      stopifnot(reference %in% lvls)
      tibble(group1 = reference, group2 = setdiff(lvls, reference))
    } else {
      cmb <- t(combn(lvls, 2))
      tibble(group1 = cmb[,1], group2 = cmb[,2])
    }
  
  purrr::pmap_dfr(pair_df, function(group1, group2) {
    x <- df %>% filter(.group == group1) %>% pull(.value)
    y <- df %>% filter(.group == group2) %>% pull(.value)
    res <- effsize::cohen.d(x, y,
                            hedges.correction = hedges_correction,
                            pooled = pooled,
                            na.rm = na_rm)
    tibble(
      variable   = var,
      condition  = condition,
      group1     = group1,
      group2     = group2,
      n1         = length(x),
      n2         = length(y),
      d          = unname(res$estimate),
      magnitude  = res$magnitude
    )
  }) %>% arrange(group1, group2)
}

# Divide by the largest absolute estimate within each comparison for plotting.
# Scaling preserves the direction of each effect.
add_effect_size <- function(df) {
  df$effect_size <- df$cohens_d / ave(abs(df$cohens_d), df$comp, FUN = max)
  return(df)
}

# Colours for experimental conditions, assigned in the plot's group order.
grp_cols <- c("#00AFBB", "#FC4E07", "darkorchid1", "#E7B800", "#0CB702", "#CC79A7", "red", "gray", "black")
