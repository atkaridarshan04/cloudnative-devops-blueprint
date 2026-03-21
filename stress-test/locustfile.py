from locust import HttpUser, task, between
import random
import json

# Sample data for POST requests
BOOKS = [
    {"title": "Clean Code", "author": "Robert C. Martin", "publishYear": 2008},
    {"title": "The Pragmatic Programmer", "author": "Andrew Hunt", "publishYear": 1999},
    {"title": "Designing Data-Intensive Applications", "author": "Martin Kleppmann", "publishYear": 2017},
    {"title": "Kubernetes in Action", "author": "Marko Luksa", "publishYear": 2018},
    {"title": "Site Reliability Engineering", "author": "Niall Richard Murphy", "publishYear": 2016},
]

class BookStoreUser(HttpUser):
    # Wait 0.5-2s between tasks to simulate realistic user pacing
    wait_time = between(0.5, 2)

    # Tracks book IDs created during the test for GET/PUT/DELETE
    created_ids = []

    @task(5)
    def get_all_books(self):
        """Most frequent - simulates browsing the book list"""
        self.client.get("/books", name="GET /books")

    @task(3)
    def create_book(self):
        """Creates a book and stores its ID for later tasks"""
        book = random.choice(BOOKS).copy()
        book["title"] = f"{book['title']} - {random.randint(1, 9999)}"  # avoid duplicates
        with self.client.post(
            "/books",
            json=book,
            name="POST /books",
            catch_response=True
        ) as resp:
            if resp.status_code == 201:
                BookStoreUser.created_ids.append(resp.json().get("_id"))
            else:
                resp.failure(f"Create failed: {resp.status_code}")

    @task(2)
    def get_book_by_id(self):
        """Fetches a specific book - exercises DB lookup by ID"""
        if BookStoreUser.created_ids:
            book_id = random.choice(BookStoreUser.created_ids)
            self.client.get(f"/books/{book_id}", name="GET /books/:id")

    @task(1)
    def update_book(self):
        """Updates a book - exercises write path"""
        if BookStoreUser.created_ids:
            book_id = random.choice(BookStoreUser.created_ids)
            self.client.put(
                f"/books/{book_id}",
                json={"title": "Updated Title", "author": "Updated Author", "publishYear": 2024},
                name="PUT /books/:id"
            )

    @task(1)
    def health_check(self):
        """Hits the root endpoint - lightweight baseline traffic"""
        self.client.get("/", name="GET /")
