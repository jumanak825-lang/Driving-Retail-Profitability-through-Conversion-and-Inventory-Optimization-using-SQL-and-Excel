import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from sklearn.linear_model import LinearRegression

# -------------------------------
# Load Data
# -------------------------------
df = pd.read_csv("retail_data.csv")

# Convert to datetime
df['Date'] = pd.to_datetime(df['Date'])

# -------------------------------
# Basic KPIs
# -------------------------------
df['Conversion'] = (df['Units_Sold'] / df['Footfall']).replace(np.inf, 0)
df['Stock_Cover'] = df['Inventory'] / df['Units_Sold'].replace(0, np.nan)
df['Revenue'] = df['Units_Sold'] * df['Price']

# -------------------------------
# SKU-Level Performance
# -------------------------------
sku_perf = df.groupby("SKU_ID").agg({
    "Units_Sold": "sum",
    "Revenue": "sum",
    "Inventory": "mean",
    "Conversion": "mean"
}).reset_index()

# Identify top 10 and bottom 10 SKUs
top_skus = sku_perf.nlargest(10, "Units_Sold")
poor_skus = sku_perf.nsmallest(10, "Units_Sold")

# -------------------------------
# Shrink / Loss Detection
# -------------------------------
# shrink = expected inventory - actual inventory
df['Expected_Inventory'] = df['Inventory'].shift(1) - df['Units_Sold']
df['Shrink'] = df['Expected_Inventory'] - df['Inventory']

shrink_summary = df.groupby("Store")['Shrink'].sum().sort_values(ascending=False)

# -------------------------------
# Replenishment Efficiency
# -------------------------------
df['OOS_Flag'] = (df['Inventory'] <= 0).astype(int)

oos_rate = df.groupby("SKU_ID")['OOS_Flag'].mean().sort_values(ascending=False)

# -------------------------------
# Footfall → Sales Regression
# -------------------------------
X = df[['Footfall']]
y = df['Units_Sold']

model = LinearRegression()
model.fit(X, y)

print("Footfall elasticity:", model.coef_[0])
print("Intercept:", model.intercept_)

# -------------------------------
# Visualization Examples
# -------------------------------
plt.figure(figsize=(6,4))
plt.scatter(df['Footfall'], df['Units_Sold'], alpha=0.4)
plt.plot(df['Footfall'], model.predict(X), color='red')
plt.xlabel("Footfall")
plt.ylabel("Units Sold")
plt.title("Footfall vs Sales Regression")
plt.show()

# -------------------------------
# Inventory Heatmap
# -------------------------------
inv = df.pivot_table(index="Date", columns="SKU_ID", values="Inventory")
plt.figure(figsize=(10,6))
plt.imshow(inv.T, aspect="auto", cmap="viridis")
plt.colorbar(label="Inventory Level")
plt.title("SKU Inventory Heatmap")
plt.xlabel("Date")
plt.ylabel("SKU")
plt.show()

# -------------------------------
# Recommendations
# -------------------------------
print("\n🔍 Recommendations:")
print("- Improve replenishment for SKUs with high OOS rate.")
print("- Reduce stock for bottom-performing SKUs to cut holding cost.")
print("- Prioritize categories with high conversion but low visibility.")
print("- Investigate stores with persistent shrink values.")
