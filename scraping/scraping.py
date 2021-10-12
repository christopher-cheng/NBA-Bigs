import re
import requests
from bs4 import BeautifulSoup
import pandas as pd
from tqdm import tqdm
import os
import csv

# Get player position from player link
def scrape_player_position(player_link):
    s = requests.Session()
    response = s.get(player_link)
    r = response.text
    soup = BeautifulSoup(r, "html.parser")

    meta = soup.find("div", {"id": "meta"})
    ps = meta.find_all("p")

    for p in ps:
        if p.text.find("Position:") != -1:
            return p.text.split()[1]

    return "Unknown"


# Get player data per draft year
def scrape_year(year):

    s = requests.Session()
    response = s.get(
        "https://www.basketball-reference.com/draft/NBA_" + str(year) + ".html"
    )

    r = response.text

    soup = BeautifulSoup(r, "html.parser")
    trs = soup.find("table", {"id": "stats"}).find("tbody").find_all("tr")

    ds = []

    for tr in trs:
        tds = tr.find_all("td")
        if len(tds) > 2:
            player_link = (
                "https://www.basketball-reference.com/" + tds[2].find("a")["href"]
            )
            d = {
                "year": year,
                "pick": tds[0].text,
                "team": tds[1].text,
                "player": tds[2].text,
                "position": scrape_player_position(player_link),
                "link": player_link,
            }
            ds.append(d)

    return ds


# Get salary data from player link
def scrape_player_salary(player_link):
    s = requests.Session()
    response = s.get(player_link)
    r = response.text

    soup = BeautifulSoup(r, "html.parser")

    html_commented = soup.find(string=re.compile('id="all_salaries"'))
    if html_commented is None:
        return None
    soup = BeautifulSoup(html_commented, "html.parser")

    ds = []
    trs = soup.find("table", {"id": "all_salaries"}).find("tbody").find_all("tr")
    for tr in trs:
        th = tr.find("th")
        tds = tr.find_all("td")

        d = {
            "season": th.text,
            "teams": tds[0].text,
            "lg": tds[1].text,
            "salary": tds[2].text,
            "link": player_link,
        }
        ds.append(d)

    return ds


def scrape_salary_cap():
    s = requests.Session()
    response = s.get(
        "https://www.basketball-reference.com/contracts/salary-cap-history.html"
    )
    r = response.text

    soup = BeautifulSoup(r, "html.parser")

    html_commented = soup.find(string=re.compile('id="salary_cap_history"'))
    if html_commented is None:
        return None
    soup = BeautifulSoup(html_commented, "html.parser")

    ds = []
    trs = soup.find("table", {"id": "salary_cap_history"}).find_all(
        "tr", class_=lambda x: x != "thead"
    )
    for tr in trs:
        th = tr.find("th")
        tds = tr.find_all("td")

        d = {
            "season": th.text,
            "salary_cap": tds[0].text,
        }
        ds.append(d)
    print(ds)
    return ds


# Helper function to write to csv
def write_csv(filename, dict_list, overwrite=False):
    if os.path.exists(filename) and not overwrite:
        with open(filename, "a") as f:
            w = csv.DictWriter(f, dict_list[0].keys())
            w.writerows(dict_list)
    else:
        with open(filename, "w") as f:
            w = csv.DictWriter(f, dict_list[0].keys())
            w.writeheader()
            w.writerows(dict_list)


# Scrape draft data
for year in tqdm(range(1989, 2022)):
    ds_year = scrape_year(year)
    write_csv("players.csv", ds_year)

df = pd.read_csv("players.csv")

# Scrape salary data
for link in tqdm(df["Link"].unique()):
    ds = scrape_player_salary(link)
    if ds != None:
        write_csv("salaries_raw.csv", ds)

# Scrape salary cap data
ds = scrape_salary_cap()
write_csv("salary_cap.csv", ds)
df = pd.read_csv("salary_cap.csv")
df["season"] = df["season"].apply(lambda x: str(x).split("-")[0])
df["salary_cap"] = df["salary_cap"].apply(lambda x: int(re.sub("[^0-9]", "", str(x))))
df.to_csv("salary_cap.csv", index=False)

# PROCESSING

# Clean up salary data
df = pd.read_csv("salaries_raw.csv")
df = df.dropna()
df["season"] = df["season"].apply(lambda x: str(x).split("-")[0])

df["salary"] = df["salary"].apply(lambda x: 0 if str(x).find("Minimum") != -1 else x)
df["salary"] = df["salary"].apply(lambda x: int(re.sub("[^0-9]", "", str(x))))

df.to_csv("salaries.csv", index=False)

# Add salary cap data to salaries
df = pd.read_csv("salary_cap.csv")
df_salaries = pd.read_csv("salaries.csv")
df_salaries["salary_cap"] = df_salaries["season"].apply(
    lambda x: max(df[df["season"] == x]["salary_cap"])
)
df_salaries.to_csv("salaries.csv", index=False)
