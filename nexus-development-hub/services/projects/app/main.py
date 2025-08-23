from fastapi import FastAPI

app = FastAPI()


@app.get("/health")
async def health() -> dict:
    """Health check endpoint."""
    return {"status": "ok"}


@app.get("/")
async def root() -> dict:
    return {"message": "Projects service"}
