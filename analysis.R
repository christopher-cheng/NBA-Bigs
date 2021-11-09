# HSAC NBA Project
# Fall 2021

rm(list=ls()) # Removes all objects from the environment
cat('\014') # Clears the console

setwd("~/Desktop/NBA-Bigs") # Set working directory

if (!require(haven)) install.packages("haven"); library(haven)
if (!require(sandwich)) install.packages("sandwich"); library(sandwich)
if (!require(lmtest)) install.packages("lmtest"); library(lmtest)
if (!require(stargazer)) install.packages("stargazer"); library(stargazer)
if (!require(tidyverse)) install.packages("tidyverse"); library(tidyverse)
if (!require(lubridate)) install.packages("lubridate"); library(lubridate)
if (!require(statar)) install.packages("statar"); library(statar)

# Read in the data
players <- read.csv("scraping/players.csv")
salaries <- read.csv("scraping/salaries.csv")
player_data <- read.csv("scraping/player_data.csv")

# Add a column "normalized_salary" which represents each salary as a fraction of the salary cap
salaries$normalized_salary <- salaries$salary / salaries$salary_cap

# The following functions are used with "apply" to generate new columns

calculate_career_length <- function(x) {
  sal <- salaries[salaries$link == x[["link"]],]
  if (nrow(sal) == 0) {
    return(NA)
  }
  return(max(sal$season) - min(sal$season))
}

calculate_max_salary_yrs <- function(x) {
  sal <- salaries[salaries$link == x[["link"]],]
  if (nrow(sal) == 0) {
    return(NA)
  }
  max_sal <- max(sal$normalized_salary)
  max_sal_year <- min(sal$season[sal$normalized_salary == max_sal])
  first_year <- min(sal$season)
  return(max_sal_year - first_year)
}

calculate_good_salary_yrs <- function(x) {
  sal <- salaries[salaries$link == x[["link"]],]
  if (nrow(sal) == 0) {
    return(NA)
  }
  good_sal <- max(sal$normalized_salary) * 0.9
  good_sal_year <- min(sal$season[sal$normalized_salary >= good_sal])
  first_year <- min(sal$season)
  return(good_sal_year - first_year)
}

calculate_max_pts_yrs <- function(x) {
  dat <- player_data[player_data$link == x[["link"]],]
  if (nrow(dat) == 0) {
    return(NA)
  }
  max_pts <- max(dat$pts_per_g)
  max_ptrs_year <- min(dat$season[dat$pts_per_g == max_pts])
  first_year <- min(dat$season)
  return(max_ptrs_year - first_year)
}

calculate_good_pts_yrs <- function(x) {
  dat <- player_data[player_data$link == x[["link"]],]
  if (nrow(dat) == 0) {
    return(NA)
  }
  good_pts <- max(dat$pts_per_g) * 0.9
  good_ptrs_year <- min(dat$season[dat$pts_per_g >= good_pts])
  first_year <- min(dat$season)
  return(good_ptrs_year - first_year)
}

calculate_max_rb <- function(x) {
  dat <- player_data[player_data$link == x[["link"]],]
  if (nrow(dat) == 0) {
    return(NA)
  }
  return(max(dat$trb_per_g))
}

calculate_good_rb_yrs <- function(x) {
  dat <- player_data[player_data$link == x[["link"]],]
  if (nrow(dat) == 0) {
    return(NA)
  }
  good_rb <- max(dat$trb_per_g) * 0.9
  good_rb_yr <- min(dat$season[dat$trb_per_g >= good_rb])
  first_year <- min(dat$season)
  return(good_rb_yr - first_year)
}

is_active_player <- function(x) {
  sal <- salaries[salaries$link == x[["link"]],]
  return(nrow(sal[sal$season == 2020,]))
}
  
calculate_all_star_yrs <- function(x) {
  dat <- player_data[player_data$link == x[["link"]],]
  if (nrow(dat) == 0) {
    return(NA)
  }
  if (nrow(dat[dat$all_star == 1,]) == 0) {
    return(NA)
  }
  all_star_yr = min(dat$season[dat$all_star == 1])
  first_yr = min(dat$season)
  return(all_star_yr - first_yr)
}

calculate_max_salary <- function(x) {
  sal <- salaries[salaries$link == x[["link"]],]
  if (nrow(sal) == 0) {
    return(NA)
  }
  return(max(sal$normalized_salary))
}

calculate_max_pts <- function(x) {
  dat <- player_data[player_data$link == x[["link"]],]
  if (nrow(dat) == 0) {
    return(NA)
  }
  return(max(dat$pts_per_g))
}

## Add a column "career" that calculates number of years in career
players$career <- apply(players, 1, FUN = calculate_career_length)
## Add a column "max_sal_yrs" that calculates number of years between first contract and year with highest contract in career
players$max_sal_yrs <- apply(players, 1, FUN = calculate_max_salary_yrs)
## Add column "good_sal_yrs" that represents the number of years between first year and first year with sal equal to at least 90% of their best sal year
players$good_sal_yrs <- apply(players, 1, FUN = calculate_good_salary_yrs)
## Add column "max_pts_yrs" that represents the number of years between first year and first year with highest ppg
players$max_pts_yrs <- apply(players, 1, FUN = calculate_max_pts_yrs)
## Add column "good_pts_yrs" that represents the number of years between first year and first year with ppg equal to at least 90% of their best ppg year
players$good_pts_yrs <- apply(players, 1, FUN = calculate_good_pts_yrs)
## Add column "is_active" that is 1 if player is currently active and 0 otherwise
players$is_active <- apply(players, 1, FUN = is_active_player)
## Add column "all_star_yrs" that is the number of years it took a player to make their first all star team
players$all_star_yrs <- apply(players, 1, FUN = calculate_all_star_yrs)
## Add column max_sal
players$max_sal <- apply(players, 1, FUN = calculate_max_salary)
## Add column max_pts
players$max_pts <- apply(players, 1, FUN = calculate_max_pts)
## Add column good_rb_yrs
players$good_rb_yrs <- apply(players, 1, FUN = calculate_good_rb_yrs)

players$pts_ratio <- players$good_pts_yrs / players$career
players$sal_ratio <- players$good_sal_yrs / players$career

# Only look at players who have a max_sal at better than 25% percentile, and had a career length of 5 or more years OR 
players <- players[players$max_sal >= quantile(players$max_sal, na.rm=TRUE)[2],]
players <- players[players$career >= 5,]
players <- players[players$is_active == 0 || players$career >= 8,]

# Can we use points as a crude proxy for success? Compare with rebounding.

players$good_pt_rb_diff <- abs(players$good_rb_yrs - players$good_pts_yrs)

mean(players$good_pt_rb_diff,na.rm=TRUE)
median(players$good_pt_rb_diff,na.rm=TRUE)
sd(players$good_pt_rb_diff,na.rm=TRUE)

ggplot(players, aes(x=year)) +
  stat_binmean(aes(y=good_pts_yrs, color="Points"), data=players[grepl("Center", players$position),], n=10, geom="line") + 
  stat_binmean(aes(y=good_pts_yrs, color="Points"), data=players[grepl("Center", players$position),], n=10, geom="point") +
  stat_binmean(aes(y=good_rb_yrs, color="Rebounds"), data=players[grepl("Center", players$position),], n=10, geom="line") + 
  stat_binmean(aes(y=good_rb_yrs, color="Rebounds"), data=players[grepl("Center", players$position),], n=10, geom="point") +
  labs(title="Average years for centers to reach 90% max points and rebounds", 
       y="Years",
       x="Draft Year")

# Points and rebounds seem pretty aligned

# Binscatter plots comparing centers and non-centers

ggplot(players, aes(x=year)) +
  stat_binmean(aes(y=good_pts_yrs, color="Center"), data=players[grepl("Center", players$position),], n=7, geom="line") + 
  stat_binmean(aes(y=good_pts_yrs, color="Center"), data=players[grepl("Center", players$position),], n=7, geom="point") +
  stat_binmean(aes(y=good_pts_yrs, color="Others"), data=players[!grepl("Center", players$position),], n=7, geom="line") + 
  stat_binmean(aes(y=good_pts_yrs, color="Others"), data=players[!grepl("Center", players$position),], n=7, geom="point") +
  labs(title="Average years to reach 90% max pts", 
       y="Years",
       x="Draft Year")

ggplot(players, aes(x=year)) +
  stat_binmean(aes(y=pts_ratio, color="Center"), data=players[grepl("Center", players$position),], n=7, geom="line") + 
  stat_binmean(aes(y=pts_ratio, color="Center"), data=players[grepl("Center", players$position),], n=7, geom="point") +
  stat_binmean(aes(y=pts_ratio, color="Others"), data=players[!grepl("Center", players$position),], n=7, geom="line") + 
  stat_binmean(aes(y=pts_ratio, color="Others"), data=players[!grepl("Center", players$position),], n=7, geom="point") +
  labs(title="Average years to reach 90% max pts ratio", 
       y="Ratio",
       x="Draft Year")

ggplot(players, aes(x=year)) +
  stat_binmean(aes(y=good_sal_yrs, color="Center"), data=players[grepl("Center", players$position),], n=5, geom="line") + 
  stat_binmean(aes(y=good_sal_yrs, color="Center"), data=players[grepl("Center", players$position),], n=5, geom="point") +
  stat_binmean(aes(y=good_sal_yrs, color="Others"), data=players[!grepl("Center", players$position),], n=5, geom="line") + 
  stat_binmean(aes(y=good_sal_yrs, color="Others"), data=players[!grepl("Center", players$position),], n=5, geom="point") +
  labs(title="Average years to reach 90% max sal", 
       y="Years",
       x="Draft Year")

ggplot(players, aes(x=year)) +
  stat_binmean(aes(y=sal_ratio, color="Center"), data=players[grepl("Center", players$position),], n=7, geom="line") + 
  stat_binmean(aes(y=sal_ratio, color="Center"), data=players[grepl("Center", players$position),], n=7, geom="point") +
  stat_binmean(aes(y=sal_ratio, color="Others"), data=players[!grepl("Center", players$position),], n=7, geom="line") + 
  stat_binmean(aes(y=sal_ratio, color="Others"), data=players[!grepl("Center", players$position),], n=7, geom="point") +
  labs(title="Average years to reach 90% max sal ratio", 
       y="Ratio",
       x="Draft Year")