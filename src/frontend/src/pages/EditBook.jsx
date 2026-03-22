// eslint-disable-next-line no-unused-vars
import React, { useState, useEffect } from "react";
import BackButton from "../components/BackButton";
import Spinner from "../components/Spinner";
import axios from "axios";
import { useNavigate, useParams } from "react-router-dom";
import { useSnackbar } from "notistack";
import { useTheme } from "../context/ThemeContext";

const EditBook = () => {
  const [title, setTitle] = useState("");
  const [author, setAuthor] = useState("");
  const [publishYear, setPublishYear] = useState("");
  const [loading, setLoading] = useState(false);
  const navigate = useNavigate();
  const { id } = useParams();
  const { enqueueSnackbar } = useSnackbar();
  const { dark } = useTheme();

  const inputClass = `border-2 border-gray-500 px-4 py-2 w-full ${dark ? "bg-gray-800 text-white" : "bg-white text-gray-900"}`;

  useEffect(() => {
    setLoading(true);
    const url = import.meta.env.VITE_API_BACKEND_URL;
    axios
      .get(`${url}/books/${id}`)
      .then((response) => {
        setAuthor(response.data.author);
        setPublishYear(response.data.publishYear);
        setTitle(response.data.title);
        setLoading(false);
      })
      .catch((error) => {
        setLoading(false);
        alert("An error happened, Please check console!");
        console.log(error);
      });
  }, [id]);

  const handleEditBook = () => {
    const data = { title, author, publishYear };
    setLoading(true);
    const url = import.meta.env.VITE_API_BACKEND_URL;
    axios
      .put(`${url}/books/${id}`, data)
      .then(() => {
        setLoading(false);
        enqueueSnackbar("Book Edited Successfully", { variant: "success" });
        navigate("/");
      })
      .catch((error) => {
        setLoading(false);
        enqueueSnackbar("Error", { variant: "error" });
        console.log(error);
      });
  };

  return (
    <div className="p-4">
      <BackButton />
      <h1 className="text-3xl my-4">Edit Book</h1>
      {loading ? <Spinner /> : ""}
      <div className="flex flex-col border-2 border-purple-400 rounded-xl w-[600px] p-4 mx-auto">
        <div className="my-4">
          <label className="text-xl mr-4 text-gray-500">Title</label>
          <input type="text" value={title} onChange={(e) => setTitle(e.target.value)} className={inputClass} />
        </div>
        <div className="my-4">
          <label className="text-xl mr-4 text-gray-500">Author</label>
          <input type="text" value={author} onChange={(e) => setAuthor(e.target.value)} className={inputClass} />
        </div>
        <div className="my-4">
          <label className="text-xl mr-4 text-gray-500">Publish Year</label>
          <input type="text" value={publishYear} onChange={(e) => setPublishYear(e.target.value)} className={inputClass} />
        </div>
        <button className="p-2 bg-purple-300 m-8" onClick={handleEditBook}>
          Save
        </button>
      </div>
    </div>
  );
};

export default EditBook;
