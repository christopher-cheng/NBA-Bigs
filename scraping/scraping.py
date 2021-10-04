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
                "Year": year,
                "Pick": tds[0].text,
                "Team": tds[1].text,
                "Player": tds[2].text,
                "Position": scrape_player_position(player_link),
                "Link": player_link,
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
            "Season": th.text,
            "Teams": tds[0].text,
            "Lg": tds[1].text,
            "Salary": tds[2].text,
            "Link": player_link,
        }
        ds.append(d)

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
        write_csv("salaries.csv", ds)

