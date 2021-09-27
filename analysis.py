import matplotlib.pyplot as plt
import pandas as pd
import numpy as np

df = pd.read_csv("scraping/draft.csv")
df = df[df["Position"] != "Unknown"]
print(df["Position"].unique())


df["Big"] = np.where(df["Position"].str.contains("Center"), 1, 0,)

d = {"Year": [], "% Center": []}

for y in df["Year"].unique():
    df_year = df[df["Year"] == y]
    d["Year"].append(y)
    d["% Center"].append(df_year["Big"].sum() / df_year["Big"].count())

pd.DataFrame(d).to_csv("draft_center_pct.csv")

plt.figure()
plt.scatter(d["Year"], d["% Center"])
plt.show()
