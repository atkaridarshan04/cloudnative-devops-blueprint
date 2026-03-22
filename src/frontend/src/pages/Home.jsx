// eslint-disable-next-line no-unused-vars
import React, { useEffect, useState } from "react";
import axios from "axios";
import Spinner from "../components/Spinner";
import { Link } from "react-router-dom";
import { MdOutlineAddBox } from "react-icons/md";
import BooksTable from "../components/home/BooksTable";
import BooksCard from "../components/home/BooksCard";
import { useSnackbar } from "notistack";
import { useTheme } from "../context/ThemeContext";

const Home = () => {
  const [books, setBooks] = useState([]);
  const [loading, setLoading] = useState(false);
  const [showType, setShowType] = useState("table");
  const { enqueueSnackbar } = useSnackbar();
  const { dark, setDark } = useTheme();

  useEffect(() => {
    setLoading(true);
    const url = import.meta.env.VITE_API_BACKEND_URL;
    axios
      .get(`${url}/books`)
      .then((response) => {
        setBooks(response.data.data);
        setLoading(false);
      })
      .catch((error) => {
        console.log(error);
        enqueueSnackbar("Error", { variant: "error" });
        setLoading(false);
      });
  }, []);

  return (
    <div className="p-4">
      <div className="bg-purple-700 text-white text-center py-2 rounded-lg mb-4 font-bold tracking-widest text-sm flex justify-between items-center px-4">
        <span>📚 BookStore — v3.0.0</span>
        <button
          onClick={() => setDark(!dark)}
          className="text-xs bg-white text-purple-700 px-3 py-1 rounded-full font-semibold"
        >
          {dark ? "☀️ Light" : "🌙 Dark"}
        </button>
      </div>
      <div className="flex justify-center items-center gap-x-4">
        <button
          className="bg-purple-700 hover:bg-purple-500 text-white px-4 py-1 rounded-lg"
          onClick={() => setShowType("table")}
        >
          Table
        </button>
        <button
          className="bg-purple-700 hover:bg-purple-500 text-white px-4 py-1 rounded-lg"
          onClick={() => setShowType("card")}
        >
          Card
        </button>
      </div>
      <div className="flex justify-between items-center">
        <h1 className="text-3xl my-8">Books List</h1>
        <Link to="/books/create">
          <MdOutlineAddBox className="text-purple-700 text-4xl" />
        </Link>
      </div>
      {loading ? (
        <Spinner />
      ) : showType === "table" ? (
        <BooksTable books={books} />
      ) : (
        <BooksCard books={books} />
      )}
    </div>
  );
};

export default Home;
