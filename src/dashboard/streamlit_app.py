import streamlit as st
from src.common.duckdb_client import duckdb_connection
from src.common.config import GOLD_FILES_PATH
import pandas as pd
import plotly.express as px

#GLOBAL VARIABLES
BRAND_ORDER = ["Sony", "Microsoft", "Nintendo"]
BRAND_COLORS = {'Sony': '#003791', 'Nintendo': '#E60012', 'Microsoft': '#107C10'}

#Function to load gold data from parquet files
@st.cache_data(ttl="24h") #Cache the data loading function to improve performance. The data will be reloaded every 24 hours.
def load_gold_data(parquet_file_name:str) -> pd.DataFrame:
    '''
    This function loads the gold data from the parquet files and returns a pandas dataframe. 
    It uses duckdb to read the parquet files and convert them to a dataframe. 
    The parquet file name is passed as an argument to the function.
    '''
    with duckdb_connection() as conn:
        df=  conn.execute(
            f"""
        SELECT
            *   
        FROM read_parquet('{GOLD_FILES_PATH}/{parquet_file_name}.parquet')
    """
    ).df()
    print(f"Loading {parquet_file_name}")
    return df


##Streamlit app
#title
st.title("From PS1 to current generation. Where are the best games?")

#Markdown Introduction comment
st.markdown("Everybody has their favourite console brand, but is it possible to quantify which one has the best games?")

#Loading data
consoles_data=load_gold_data("gold_agg_consoles")
brand_data=load_gold_data("gold_agg_brands")

brand_data["bar_label"] = brand_data["number_of_highly_rated_games"].astype(str) + " out of " + brand_data["number_of_games"].astype(str)
brand_data["brand"]=pd.Categorical(brand_data["brand"], categories=BRAND_ORDER, ordered=True)
brand_data.sort_values("brand", inplace=True)


#Markdown metrics comment
st.markdown("If we aggregate average metacritic scores, from PS1 generation onwards all brands seem quite close to each other. But is that all there is to it?")

#Metrics section
st.header("Average Metacritic score")
cols = st.columns(3)

for col, (_, row) in zip(cols, brand_data.iterrows()):
    with col:                           
        st.metric(label=row['brand'], value=row['avg_metacritic_score']) 



#Markdown bar start comment
st.markdown("Maybe the average metacritic is not the right metric to look at. What if only the share of highly rated games are considered?")

#Brands bar chart
fig_brands = px.bar(
    data_frame=brand_data,
    x='brand',
    y='percentage_of_highly_rated_games',
    labels={"brand": "Brand", "percentage_of_highly_rated_games": "Percentage of Highly Rated Games"},
    title="Percentage of Highly Rated Games by Brand",
    text='bar_label',
    color='brand',
    color_discrete_map=BRAND_COLORS,
    category_orders={"brand": BRAND_ORDER}

)
fig_brands.update_layout(showlegend=False, yaxis_ticksuffix="%")
st.plotly_chart(fig_brands, width='stretch')
st.caption("A game is considered highly rated if it has a metacritic score >=80. All consoles from PS1 onwards are considered (handhelds included). Microsoft obviously does not have handhelds nor PS1 generation equivalents")

#Bar chart end comment
st.markdown("Nintendo does seem to have a small advantage overall. What if we look at the actual consoles rather than the brands only? At the end of the day all of them had more or less successful generations, so what would the picture look like?")


#Consoles scatter plot
fig_consoles = px.scatter(
    data_frame=consoles_data,
    x='number_of_highly_rated_games',
    y='percentage_of_highly_rated_games',
    labels={"number_of_highly_rated_games": "Number of Highly Rated Games", "percentage_of_highly_rated_games": "Percentage of Highly Rated Games"},
    title="Percentage of Highly Rated Games by Console",
    text='console_name',
    color='brand',
    color_discrete_map=BRAND_COLORS,
    size='number_of_games',
    hover_name='console_name'   

)
fig_consoles.update_traces(textposition='top center')
fig_consoles.update_layout(showlegend=True, height=600)

st.plotly_chart(fig_consoles, width='stretch')
st.caption("N64 and Game Boy Color have a very small number of games that skews their score upwards.")

#Methodology, data source & limitations comment
st.markdown("There seems to be a trade-off trend happening. The more highly rated games a console has, the lower the percentage of highly rated games is. This is probably due to the fact that consoles with more games also have more low rated games, which brings down the share.")
with st.expander("Methodology, data source & limitations", expanded=False):
    st.markdown("Data used is collected from RAWG API. The Sample is based on ~7,000 Metacritic-scored games, PS1 generation onwards. Metacric scored games are currently available until end of 2024. Metacritic scores are more generally available for recent games than for older ones.")