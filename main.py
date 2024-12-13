from fastapi import FastAPI, UploadFile, File
from fastapi.responses import HTMLResponse
import os
import subprocess

app = FastAPI()

@app.get("/", response_class=HTMLResponse)
def read_root():
    with open("index.html") as f:
        return HTMLResponse(content=f.read(), media_type="text/html")

@app.post("/upload/")
async def upload_file(file: UploadFile = File(...)):
    file_location = f"/data/input/{file.filename}"
    with open(file_location, "wb") as f:
        f.write(file.file.read())
    return {"info": f"file '{file.filename}' saved at '{file_location}'"}

@app.post("/run_command/")
def run_command(command: str):
    try:
        result = subprocess.run(command, shell=True, capture_output=True, text=True)
        return {"output": result.stdout, "error": result.stderr}
    except Exception as e:
        return {"error": str(e)}

@app.post("/run_script/")
async def run_script():
    result = subprocess.run(["python3", "-m", "demucs", "-d", "cpu", "/data/input/test.mp3"], capture_output=True, text=True)
    return {"output": result.stdout, "error": result.stderr}