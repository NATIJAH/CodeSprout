import requests
import pandas as pd
import networkx as nx
import streamlit as st
from io import StringIO

def retrieve_ppi_biogrid(target_protein):
    url = (
         "https://webservice.thebiogrid.org/interactions/?"
        f"searchNames=true&geneList={target_protein}&taxId=9606"
        "&format=tab2&accesskey=YOUR_BIOGRID_KEY"
    )

    response = requests.get(url)

    if response.status_code !=200:
        st.error("Error retrieving data from BioGRID.")
        return None
    
    data = StringIO(response.text)
    df = pd.read_csv(data, sep="\t")

    return df

def retrieve_ppi_string(target_protein):
    url = (
        "https://string-db.org/api/tsv/network?"
        f"identifiers={target_protein}&species=9606"
    )

    response = requests.get(url)

    if response.status_code != 200:
        st.error("Error retrieving data from STRING.")
        return None

    data = StringIO(response.text)
    df = pd.read_csv(data, sep="\t")

    return df

def generate_network(df):
    
    G = nx.Graph()

    
    colA = df.columns[0]
    colB = df.columns[1]

    for _, row in df.iterrows():
        G.add_edge(row[colA], row[colB])

    return G

def get_centralities(G):

    degree = nx.degree_centrality(G)
    betweenness = nx.betweenness_centrality(G)
    closeness = nx.closeness_centrality(G)
    eigenvector = nx.eigenvector_centrality(G, max_iter=500)
    pagerank = nx.pagerank(G)

    return [
        {"name": "Degree Centrality", "values": degree},
        {"name": "Betweenness Centrality", "values": betweenness},
        {"name": "Closeness Centrality", "values": closeness},
        {"name": "Eigenvector Centrality", "values": eigenvector},
        {"name": "PageRank", "values": pagerank},
    ]

st.title("Human Protein-Protein Interaction Explorer")

protein = st.text_input("Enter protein ID (e.g., TP53)")
db_choice = st.selectbox("Choose database", ["BioGRID", "STRING"])

if st.button("Retrieve PPI"):
    if db_choice == "BioGRID":
        df = retrieve_ppi_biogrid(protein)
    else:
        df = retrieve_ppi_string(protein)

    if df is not None and len(df) > 0:

        col1, col2 = st.columns(2)

        # --- LEFT COLUMN ---
        with col1:
            st.subheader("PPI Data Information")
            st.dataframe(df)

            # Generate network
            G = generate_network(df)

            st.write(f"**Number of nodes:** {G.number_of_nodes()}")
            st.write(f"**Number of edges:** {G.number_of_edges()}")

            # Draw network
            plt.figure(figsize=(6, 6))
            pos = nx.spring_layout(G, seed=42)
            nx.draw(G, pos, with_labels=True, node_size=500, font_size=8)
            st.pyplot(plt)

        # --- RIGHT COLUMN ---
        with col2:
            st.subheader("Centrality Measures")

            centrality_list = get_centralities(G)

            for cent in centrality_list:
                st.markdown(f"### {cent['name']}")
                df_cent = pd.DataFrame.from_dict(cent["values"], orient="index", columns=["value"])
                st.dataframe(df_cent.sort_values("value", ascending=False))

            else:
                st.error("No PPI data found for this protein.")