import pandas as pd

# Read the vouchers.txt file (assuming tab or comma separated)
df = pd.read_csv('vouchers.txt', sep=None, engine='python')

# Filter in the first column
df_filtered = df.iloc[:, :1]

print(df_filtered.head())