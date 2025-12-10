import streamlit as st
import requests
from Bio.PDB import PDBParser
from io import StringIO
import numpy as np

ATOMIC_MASSES = {
    'H': 1.008,
    'C': 12.001,
    'N': 14.007,
    'O': 15.999,
    'P': 30.974,
    'S': 32.06
}

def get_protein_structure(protID: str) -> str:
    prot = protID.strip()
    if not prot:
        raise ValueError("Empty protein ID")

    url = f"https://files.rcsb.org/download/{prot}.pdb"
    resp = requests.get(url, timeout=15)
    resp.raise_for_status()

    return resp.text

def get_atom_element(atom_name: str) -> str:
    name = atom_name.strip()

    if not name:
        return 'C'

    letters = ''.join([c for c in name if c.isalpha()]).upper()

    if len(letters) >= 2 and letters[:2] in ATOMIC_MASSES:
        return letters[:2]

    return letters[0] if letters else 'C'

def get_structure_info(prot_structure: str) -> dict:
    parser = PDBParser(QUIET=True)
    structure = parser.get_structure('prot', StringIO(prot_structure))

    coords = []
    masses = []

    for atom in structure.get_atoms():
        coord = atom.get_coord()
        element = get_atom_element(atom.get_name())
        mass = ATOMIC_MASSES.get(element, 12.011)

        coords.append(coord)
        masses.append(mass)

    coords = np.array(coords, dtype=float)
    masses = np.array(masses, dtype=float)

    if coords.size == 0:
        raise ValueError("No atoms found in structure")

    total_mass = masses.sum()
    com = (coords * masses[:, None]).sum(axis=0) / total_mass

    diffs = coords - com
    rg2 = (masses * np.sum(diffs * diffs, axis=1)).sum() / total_mass
    rg = float(np.sqrt(rg2))

    com_tuple = (float(com[0]), float(com[1]), float(com[2]))

    safe_pdb = prot_structure.replace("\n", "\\n").replace('"', '\\"')

    html_view = f"""
        <div id="viewer" style="width:100%;height:100%;"></div>
        <script>
            const pdbData = "{safe_pdb}";
            let viewer = $3Dmol.createViewer("viewer", {{ backgroundColor: "white" }});
            viewer.addModel(pdbData, "pdb");
            viewer.setStyle({{}}, {{ cartoon: {{ color: "spectrum" }} }});
            viewer.zoomTo();
            viewer.render();
        </script>
    """

    return {
        "com": com_tuple,
        "Rg": rg,
        "3dview": html_view
    }



st.title("Protein Structure Viewer")

prot_id = st.text_input("Enter Protein ID (PDB ID):")
submitted = st.button("Get Structure")

if submitted:
    try:
        with st.spinner("Fetching protein structure..."):
            pdb_text = get_protein_structure(prot_id)

        with st.spinner("Analyzing structure..."):
            info = get_structure_info(pdb_text)

        st.success("Analysis complete!")
        st.write(f"**Center of Mass:** {info['com']}")
        st.write(f"**Radius of Gyration:** {info['Rg']:.3f}")

        st.subheader("3D Structure View")
        st.components.v1.html(info["3dview"], height=500)

    except Exception as e:
        st.error(f"Error: {e}")

else:
    st.info("Enter a PDB ID and click *Get Structure* to start.")

