# HSAC NBA Project
# Fall 2021

rm(list=ls()) # Removes all objects from the environment
cat('\014') # Clears the console

# Read in the data
players <- read.csv("scraping/players.csv")
salaries <- read.csv("scraping/salaries.csv")
salary_cap <- read.csv("scraping/salary_cap.csv")

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

salaries$normalized_salary <- salaries$salary / salaries$salary_cap
# Add a column "Career" that calculates number of years in career
players$career <- apply(players, 1, FUN = get_career)
# Add a column "Time" that calculates number of years between first contract and highest contract in career
players$time <- apply(players, 1, FUN = get_years)

players$ratio <- players$time / players$career

players

players <- players[players$year <= 2008,]

mean(players$career[players$position != "Center"], na.rm = TRUE)
mean(players$career[players$position == "Center"], na.rm = TRUE)

mean(players$time[players$position != "Center"], na.rm = TRUE)
mean(players$time[players$position == "Center"], na.rm = TRUE)

mean(players$ratio[players$position != "Center"], na.rm = TRUE)
mean(players$ratio[players$position == "Center"], na.rm = TRUE)