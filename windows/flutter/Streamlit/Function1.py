from Bio import Entrez
from Bio import SeqIO

Entrez.email = "YOUR EMAIL HERE"
handle = Entrez.efetch(db='protein', id='P04637', rettype='fasta', retmode='text')

record = SeqIO.read(handle, 'fasta')

print(f"Raw record returned: \n{record}")
print(f"\nSequence: \n{record.seq}")
print(f"\nDescription: \n{record.description}")
print(f"\nName: \n{record.name}")
print(f"\nSequence:\n{record.seq}")
print(f"\nDescription:\n{record.description}")
print(f"\nName:\n{record.name}")

from Bio.SeqUtils.ProtParam import ProteinAnalysis

# Calculate length of the protein sequene using len() 
print(len(record.seq))

seq_analysis = ProteinAnalysis(record.seq)

# Get amino acid composition of the protein sequence
print(seq_analysis.count_amino_acids())

# Get the molecular weight of the protein sequence
print(seq_analysis.molecular_weight())

# Get the isoelectric point of the protein sequence
print(seq_analysis.isoelectric_point())

def functionName(parameter1, parameter2):
	# code statements here.
	result = parameter1 + parameter2
	return result

# example of function call
x = functionName(2, 3)

def functionName(parameter1, parameter2):
	# code statements here.
	result1 = parameter1 + parameter2
	result2 = parameter1 * parameter2
	return result1, result2
	
# example of function call
x, y = functionName(2, 3)

import streamlit as st

# you may put all your functions at HERE

st.title('Lab 1 - YOUR NAME HERE')

protein_id = st.text_input('Enter Uniprot ID')
retrieve = st.button('Retrieve')

if retrieve:
    if protein_id!="":
    	# your function calls and execution of processes at HERE
    	
    else:
        st.warning('Please enter Uniprot ID')