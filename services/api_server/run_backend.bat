@echo off
rem Activate virtual environment if it exists, otherwise create one
if exist "venv\Scripts\activate.bat" (
    call venv\Scripts\activate.bat
) else (
    python -m venv venv
    call venv\Scripts\activate.bat
    pip install -r requirements.txt
)
rem Load environment variables from .env if present
if exist ".env" (
    for /f "usebackq delims=" %%A in (".env") do set "%%A"
)
rem Start FastAPI server
uvicorn app.main:app --host 0.0.0.0 --port 8000
