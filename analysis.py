import matplotlib.pyplot as plt
import pandas as pd
import numpy as np

df = pd.read_csv("scraping/draft.csv")
df = df[df["position"] != "Unknown"]
print(df["position"].unique())


df["big"] = np.where(df["position"].str.contains("Center"), 1, 0,)

d = {"Year": [], "% Center": []}

for y in df["Year"].unique():
    df_year = df[df["year"] == y]
    d["Year"].append(y)
    d["% Center"].append(df_year["big"].sum() / df_year["big"].count())

pd.DataFrame(d).to_csv("draft_center_pct.csv")

plt.figure()
plt.scatter(d["Year"], d["% Center"])
plt.show()
