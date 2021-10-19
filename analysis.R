# HSAC NBA Project
# Fall 2021

rm(list=ls()) # Removes all objects from the environment
cat('\014') # Clears the console

# Read in the data
players <- read.csv("scraping/players.csv")
salaries <- read.csv("scraping/salaries.csv")
salary_cap <- read.csv("scraping/salary_cap.csv")
player_data <- read.csv("scraping/player_data.csv")

summary(player_data)

# Summary statistics
summary(players)
summary(salaries)
summary(salary_cap)

get_career <- function(x) {
  sal <- salaries[salaries$link == x[["link"]],]
  if (nrow(sal) == 0) {
    return(NA)
  }
  return(max(sal$season) - min(sal$season))
}

get_years <- function(x) {
  sal <- salaries[salaries$link == x[["link"]],]
  if (nrow(sal) == 0) {
    return(NA)
  }
  max_sal <- max(sal$salary)
  max_sal_year <- min(sal$season[sal$salary == max_sal])
  first_year <- min(sal$season)
  return(max_sal_year - first_year)
}

get_pts_years <- function(x) {
  dat <- player_data[player_data$link == x[["link"]],]
  if (nrow(dat) == 0) {
    return(NA)
  }
  max_pts <- max(dat$pts_per_g)
  max_ptrs_year <- min(dat$season[dat$pts_per_g == max_pts])
  first_year <- min(dat$season)
  return(max_ptrs_year - first_year)
}

salaries$normalized_salary <- salaries$salary / salaries$salary_cap
# Add a column "Career" that calculates number of years in career
players$career <- apply(players, 1, FUN = get_career)
# Add a column "Time" that calculates number of years between first contract and highest contract in career
players$time <- apply(players, 1, FUN = get_years)

players$time_pts <- apply(players, 1, FUN = get_pts_years)


players$ratio <- players$time / players$career
players$ratio_pts <- players$time_pts / players$career
players$ratio_pts <- ifelse(is.infinite(players$ratio_pts), NA, players$ratio_pts)

players1 <- players[players$year <= 2002,]

mean(players1$career[players1$position != "Center"], na.rm = TRUE)
mean(players1$career[players1$position == "Center"], na.rm = TRUE)

mean(players1$time[players1$position != "Center"], na.rm = TRUE)
mean(players1$time[players1$position == "Center"], na.rm = TRUE)

mean(players1$ratio[players1$position != "Center"], na.rm = TRUE)
mean(players1$ratio[players1$position == "Center"], na.rm = TRUE)

mean(players1$time_pts[players1$position != "Center"], na.rm = TRUE)
mean(players1$time_pts[players1$position == "Center"], na.rm = TRUE)

mean(players1$ratio_pts[players1$position != "Center"], na.rm = TRUE)
mean(players1$ratio_pts[players1$position == "Center"], na.rm = TRUE)

players2 <- players[players$year > 2002 & players$year <= 2018,]

mean(players2$career[players2$position != "Center"], na.rm = TRUE)
mean(players2$career[players2$position == "Center"], na.rm = TRUE)

mean(players2$time[players2$position != "Center"], na.rm = TRUE)
mean(players2$time[players2$position == "Center"], na.rm = TRUE)

mean(players2$ratio[players2$position != "Center"], na.rm = TRUE)
mean(players2$ratio[players2$position == "Center"], na.rm = TRUE)

mean(players2$time_pts[players2$position != "Center"], na.rm = TRUE)
mean(players2$time_pts[players2$position == "Center"], na.rm = TRUE)

mean(players2$ratio_pts[players2$position != "Center"], na.rm = TRUE)
mean(players2$ratio_pts[players2$position == "Center"], na.rm = TRUE)