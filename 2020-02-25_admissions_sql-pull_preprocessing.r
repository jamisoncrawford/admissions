# GRADUATE ADMISSIONS SQL PULL & PREPROCESSING

    # Date: 2020-02-25
    # R Version: 3.6.1
    # RStudio Version: 1.2.1578
    # OS: Windows 10



# SET WORKING DIRECTORY & PACKAGES

rm(list = ls())                                           # Clear workspace

setwd("~/Graduate School Admissions/sql_approach")        # Set working directory

library(readr)
library(dplyr)
library(tidyr)
library(scales)
library(panthr)
library(stringr)
library(ggplot2)
library(lubridate)                                        # Load required packages

options(scipen = 999)                                     # Disable sci. notation



# SQL QUERIES

    # WPRD: All Applications
    
        # SELECT *
        # FROM edwprd.sdapplications_gr;
    
    # WPRD: Applications & Main Student Table
    
        # SELECT *
        # FROM edwprd.sdapplications_gr a
        # JOIN edwprd.sdstumain m
            # ON a.whkey = m.whkey 
            # AND a.term = m.term 
            # AND m.census_type = 'C';
    
    # BREPTS: Degree Level Validation Codes
    
        # SELECT *
        # FROM stvdegc;



# READ IN DATA, REFORMAT VARS, CLEAN, DECODE, & MERGE DEGREE VALIDATION TABLES

path <- "2020-02-25_current-admissions-data.csv"          # Set file path (applications)

all <- read.csv(path, stringsAsFactors = FALSE) %>%       # Import 'edwprd.sdapplications_gr'
  field_case(case = "snake") %>%                          # Format variable names
  select(term:whkey, decision, college:major, program,
         styp_code, level_code, hours_enrolled,
         degree_level, student_level, matric_term,
         student_level_regents) %>%                       # Reduce variables
  rename(styp = styp_code,                                # Rename 'styp_code'
         reg = student_level_regents) %>%                 # Rename 'student_level_regents'
  filter(reg == 70) %>%                                   # Filter graduate students
  mutate(fiscal_year = term_year_fiscal(term),            # Decode FY
         calendar_year = term_year_calendar(term),        # " calendar year
         season = term_season(term),                      # " term season
         term_full = term_name(term),                     # " full term
         college = decode_college(college),               # " college
         department = decode_department(department),      # " department
         deg_maj = paste0(degree, "-", 
                          decode_major(major),
                          " (", major, ")"),               # Create 'program'
         styp = gsub("^C$", "Continuing", styp),
         styp = gsub("^G$", "New Graduate", styp),
         styp = ifelse(styp != "Continuing" & 
                         styp != "New Graduate", 
                       "Other", styp),                    # Relabel 'styp'
         reg = "Graduate Student")                        # " 'reg'

path <- "2020-02-25_degree-code_validation-tables.csv"    # Set file path (degree codes)

deg <- read_csv(path) %>%                                 # Import degree validation codes
  field_case(case = "snake") %>%                          # Format variable names
  select(stvdegc_code, stvdegc_dlev_code) %>%             # Reduce variables
  rename(degree = stvdegc_code,
         degree_level = stvdegc_dlev_code)                # Reconcile var names

all <- all %>%
  left_join(deg) %>%                                      # Merge degree, apps
  filter(degree_level %in% c("M", "D")) %>%               # Filter masters, doctoral
  rename(deg_lev = degree_level) %>%                      # Rename 'deg_lev'
  mutate(degree = decode_degree(degree),                  # Decode degree
         major = decode_major(major),                     # " major
         enrolled = ifelse(hours_enrolled > 0, 1, 0),     # Calculate 'enrolled'
         deg_lev = gsub("^M$", "Masters", deg_lev),
         deg_lev = gsub("^D$", "Doctoral", deg_lev),      # Relabel degree level
         whkey = as.character(whkey)) %>%                 # Decode degree, major
  select(whkey, term, fiscal_year, matric_term,
         term_full, college, deg_maj, styp, 
         deg_lev, enrolled) %>%                           # Reduce dimensions
  rename(program = deg_maj,
         status = styp,
         degree = deg_lev,
         fy = fiscal_year)                                # Rename variables

all[all == ""] <- NA                                      # Replace blank cells: NA

all <- all %>%
  mutate(status = ifelse(term == matric_term, 
                         "New", "Continuing"))            # Determine "new" actual

enr <- all %>%
  select(-term, -matric_term, -degree)                    # Remove variables

enr <- enr %>%
  group_by(fy, term_full, college, program, status) %>%   # Group on programs by new/con.
  summarize(enrolled = sum(enrolled, na.rm = TRUE)) %>%   # Summarize enrollment
  ungroup() %>%
  mutate(status = tolower(status),
         status = gsub(x = status, "tinuing", "")) %>%    # Spread columns: 'new', 'con'
  spread(status, enrolled) %>%
  rename(enr_con = con,
         enr_new = new) %>%                               # Rename variables
  select(-`<NA>`)                                         # Remove mismatch

# Note: Removed is PHD in Chemistry, CA&S, ~2014

rm(deg)                                                   # Remove object: 'deg'



# PREPROCESS ALL APPLICATIONS, INCLUDING UNENROLLED

path <-"2020-02-27_all-applications_no-stumain.csv"       # File: All applications

all <- read.csv(path, 
                stringsAsFactors = FALSE) %>%             # Read in all applications
  field_case(case = "snake") %>%                          # Format variable names
  select(term, whkey, level_code, decision, 
         hours_enrolled:major) %>%                        # Reduce variables
  mutate(whkey = as.character(whkey),
         fy = term_year_fiscal(term),
         term_full = term_name(term),
         college = decode_college(college),
         program = paste0(degree, "-", 
                          decode_major(major), 
                          " (", major, ")"),
         accepted = ifelse(decision <= 30, 1, 0),
         denied = ifelse(decision >= 40 
                         & decision <= 65, 1, 0),
         enrolled = ifelse(hours_enrolled > 0 & 
                             !is.na(hours_enrolled), 
                           1, 0)) %>%                     # Transform variables
  select(whkey, fy, term_full, college, program, 
         accepted, denied, enrolled)                      # Reduce variables

rm(path)                                                  # Remove objects

all <- all %>%
  group_by(fy, term_full, college, program) %>%           # Group on FY, term, program
  summarize(applied = n(),
            accepted = sum(accepted, na.rm = TRUE),
            denied = sum(denied, na.rm = TRUE),
            enrolled = sum(enrolled, na.rm = TRUE))       # Summarize groupings

all <- enr %>%
  left_join(all) %>%
  select(fy:program, applied:denied, 
         enr_con:enr_new, enrolled)                       # Merge all apps, enrollment

# Note: Merge is concerning; are there "enrollments" that aren't demarcated?

rm(enr)                                                   # Remove objects



# FILL MISSING VALUES FOR NEW/CONT. ENROLLMENT PER TOTAL ENROLLMENT/PROGRAM

for (i in seq_along(all$enrolled)){
  
  if (!is.na(all$enr_con[i]) & !is.na(all$enr_new[i]) & all$enrolled[i] == all$enr_con[i] + all$enr_con[i]){
    
    next
    
  } else if (is.na(all$enr_con[i]) & !is.na(all$enr_new[i]) & all$enrolled[i] != all$enr_new[i]){
    
    all$enr_con[i] <- all$enrolled[i] - all$enr_new[i]
    
  } else if (!is.na(all$enr_con[i]) & is.na(all$enr_new[i]) & all$enrolled[i] != all$enr_con[i]){
    
    all$enr_new[i] <- all$enrolled[i] - all$enr_con[i]
    
  } else if (is.na(all$enr_con[i]) & !is.na(all$enr_new[i]) & all$enrolled[i] == all$enr_new[i]){
    
    all$enr_con[i] <- 0
    
  } else if (!is.na(all$enr_con[i]) & is.na(all$enr_new[i]) & all$enrolled[i] == all$enr_con[i]){
    
    all$enr_new[i] <- 0
    
  }
  
}

rm(i)                                                     # Remove objects



# DEMARCATING SPECIFIC PROGRAMS VIA REGEX PATTERN-MATCHING

    #' Note: Partial discrepancies with OIE's FY Actual 
    #' for total enrollment; OIE calculations neither
    #' documented nor reproducible; ignoring. Dropping 
    #' certificates and non-degree enrollees.

crt <- paste0("^CERG-|^CERM-|^CTL-|^CPH",
              "|^CPED-|^CG-|^CGIS-|^CTL-")                # Certificate patterns

ndg <- "^ND-"                                             # Non-degree pattern
crg <- "^CRG-"                                            # X-register pattern
trg <- "^TRG-"                                            # Transient pattern

all <- all %>%
  mutate(deg = NA,
         deg = ifelse(grepl(crt, program), 
                      "Certificate", deg),
         deg = ifelse(grepl(ndg, program), 
                      "Non-Degree", deg),
         deg = ifelse(grepl(crg, program), 
                      "Cross-Registered", deg),
         deg = ifelse(grepl(trg, program), 
                      "Transient", deg),
         deg = ifelse(is.na(deg), 
                      "Degree", deg)) %>%                 # Relabel degree category
  select(fy:program, deg, applied:enrolled) %>%           # Rearrange vars
  rename(level = deg)                                     # Rename: 'level'

all <- all %>%
  filter(level != "Transient", 
         level != "Cross-Registered")                     # Remove transient, x-reg

rm(crg, crt, ndg, trg)                                    # Remove objects



# ABBREVIATE SCHOOL NAMES FOR REPORTING

col <- unique(all$college)

new <- c("School of Policy Studies",
         "College of Nursing & HP",
         "College of Arts & Sciences",
         "College of Education & HD",
         "College of Business",
         "School of Public Health",
         "College of Law",
         "University-Wide Programs",
         "College of the Arts",
         "Institute for Bio. Sci.")                       # New school names

all[all$college == col[1], "college"] <- new[1]
all[all$college == col[2], "college"] <- new[2]
all[all$college == col[3], "college"] <- new[3]
all[all$college == col[4], "college"] <- new[4]
all[all$college == col[5], "college"] <- new[5]
all[all$college == col[6], "college"] <- new[6]
all[all$college == col[7], "college"] <- new[7]
all[all$college == col[8], "college"] <- new[8]
all[all$college == col[9], "college"] <- new[9]
all[all$college == col[10], "college"] <- new[10]         # Apply new names

rm(col, new)                                              # Rm objects



# SAVE AS RDATA & WRITE TO CSV

save.image("2020-02-21_final-app-data.RData")             # Save workspace

write_csv(all, "2020-02-27_applications-by-program.csv")
