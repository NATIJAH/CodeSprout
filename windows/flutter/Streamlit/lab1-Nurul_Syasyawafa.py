import streamlit as st
from Bio import ExPASy, SwissProt, SeqUtils
from Bio.SeqUtils.ProtParam import ProteinAnalysis

st.title("Lab 1 - NURUL SYASYAWAFA BINTI AMRAN")


seq_id = st.text_input("Enter Uniprot ID", value="P04367")

if st.button("Retrieve"):
    try:
        
        handle = ExPASy.get_sprot_raw(seq_id)
        record = SwissProt.read(handle)

        name = record.entry_name
        description = record.description
        sequence = record.sequence

        analysis = ProteinAnalysis(sequence)
        aa_comp = analysis.count_amino_acids()
        seq_length = len(sequence)
        mw = analysis.molecular_weight()
        pI = analysis.isoelectric_point()

        col1, col2 = st.columns(2)

        with col1:
            st.subheader("Retrieved Protein")
            st.write(f"**Name:** sp|{seq_id}|{name}")
            st.write(f"**Description:** {description}")
            st.write(f"**Sequence:**")
            st.text(sequence)

        with col2:
            st.subheader("Basic Protein Analysis")
            st.write(f"**Sequence Length:** {seq_length}")
            st.write(f"**Amino Acids Composition:** {aa_comp}")
            st.write(f"**Molecular Weight:** {mw}")
            st.write(f"**Isoelectric Point:** {pI}")

    except Exception as e:
        st.error(f"Error retrieving sequence: {e}")


