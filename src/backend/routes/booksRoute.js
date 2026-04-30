import express from "express";
import { Book } from "../models/bookModel.js";
import logger from "../logger.js";

const router = express.Router();

router.post("/", async (request, response) => {
  try {
    if (!request.body.title || !request.body.author || !request.body.publishYear) {
      return response.status(400).send({ message: "Send all required fields!" });
    }
    const book = await Book.create(request.body);
    logger.info({ bookId: book._id }, "Book created");
    return response.status(201).send(book);
  } catch (error) {
    logger.error({ err: error }, "Failed to create book");
    response.status(500).send({ message: error.message });
  }
});

router.get("/", async (request, response) => {
  try {
    const books = await Book.find({});
    return response.status(200).json({ count: books.length, data: books });
  } catch (error) {
    logger.error({ err: error }, "Failed to fetch books");
    response.status(500).send({ message: error.message });
  }
});

router.get("/:id", async (request, response) => {
  try {
    const book = await Book.findById(request.params.id);
    return response.status(200).json(book);
  } catch (error) {
    logger.error({ err: error, bookId: request.params.id }, "Failed to fetch book");
    response.status(500).send({ message: error.message });
  }
});

router.put("/:id", async (request, response) => {
  try {
    if (!request.body.title || !request.body.author || !request.body.publishYear) {
      return response.status(400).send({ message: "Send all required fields!" });
    }
    const result = await Book.findByIdAndUpdate(request.params.id, request.body);
    if (!result) return response.status(404).json({ message: "Book not found!" });
    logger.info({ bookId: request.params.id }, "Book updated");
    return response.status(200).json({ message: "Book updated successfully!" });
  } catch (error) {
    logger.error({ err: error, bookId: request.params.id }, "Failed to update book");
    response.status(500).send({ message: error.message });
  }
});

router.delete("/:id", async (request, response) => {
  try {
    const result = await Book.findByIdAndDelete(request.params.id);
    if (!result) return response.status(404).json({ message: "Book not found!" });
    logger.info({ bookId: request.params.id }, "Book deleted");
    return response.status(200).json({ message: "Book deleted successfully!" });
  } catch (error) {
    logger.error({ err: error, bookId: request.params.id }, "Failed to delete book");
    response.status(500).send({ message: error.message });
  }
});

export default router;
