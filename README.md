# Simple Memo Application

A simple memo application built with Next.js (frontend) and FastAPI + SQLAlchemy (backend).

## Features

- Create, view, and delete memos
- Dark mode that persists using localStorage
- RESTful API backend
- SQLite database for storage

## Project Structure

```
simple-memo-app/
├── backend/     # FastAPI application
└── frontend/    # Next.js application
```

## Setup and Run

### Backend

```bash
# Navigate to backend directory
cd backend

# Create a virtual environment
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Run the server
uvicorn main:app --reload
```

The backend server will run at http://localhost:8000. API documentation is available at http://localhost:8000/docs.

### Frontend

```bash
# Navigate to frontend directory
cd frontend

# Install dependencies
npm install

# Run the development server
npm run dev
```

The frontend application will run at http://localhost:3000.
