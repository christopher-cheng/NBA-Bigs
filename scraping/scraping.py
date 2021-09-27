import requests
from bs4 import BeautifulSoup
import pandas as pd
from tqdm import tqdm
from hf import hf


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
            }
            ds.append(d)

    return ds


for year in tqdm(range(2001, 2022)):
    ds_year = scrape_year(year)
    hf.write_csv("draft.csv", ds_year)
