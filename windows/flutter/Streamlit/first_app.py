import streamlit as st

st.title("🎈 My First Streamlit App")
st.write("Hello, this is my first Streamlit web app!")
st.write("Streamlit makes it super easy to build web apps with Python.")

name = st.text_input("Enter your name:")
if name:
    st.success(f"Welcome, {name}! 🎉")
