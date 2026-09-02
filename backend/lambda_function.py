import os
import re
import uuid
import boto3
from fastapi import FastAPI, HTTPException
from fastapi.responses import JSONResponse, RedirectResponse
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from mangum import Mangum

short_url: str = "https://i-l.ink/"

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

dynamodb = boto3.resource("dynamodb")
table_name = os.environ.get("DYNAMODB_TABLE", "URLMappings")
table = dynamodb.Table(table_name)

url_regex = "^(https?:\/\/(?:www\.|(?!www))[a-zA-Z0-9][a-zA-Z0-9-]+[a-zA-Z0-9]\.[^\s]{2,}|www\.[a-zA-Z0-9][a-zA-Z0-9-]+[a-zA-Z0-9]\.[^\s]{2,}|https?:\/\/(?:www\.|(?!www))[a-zA-Z0-9]+\.[^\s]{2,}|www\.[a-zA-Z0-9]+\.[^\s]{2,})"

class shortenURLRequest(BaseModel):
    long_url: str
    custom_url: str | None = None

@app.get("/")
def read_root():
    return {"message": "Welcome to the URL shortener!"}

@app.get("/{short_code}")
def redirect_to_long_url(short_code: str):
    response = table.get_item(Key={"ShortURL": short_code})
    if "Item" not in response:
        raise HTTPException(status_code=404, detail="Short URL not found")
    
    return RedirectResponse(url=response["Item"]["LongURL"], status_code=301)

@app.post("/Shorten")
async def shorten_url(request: shortenURLRequest):
    long_url = request.long_url
    re_match = re.match(url_regex, long_url)
    
    if not re_match:
        raise HTTPException(status_code=400, detail="Invalid URL format")
    
    try:
        response = table.scan(
            FilterExpression="LongURL = :url",
            ExpressionAttributeValues={":url": long_url}
        )
        if "Items" in response and response["Items"]:
            short_code = response["Items"][0]["ShortURL"]
            short_url = f"{short_url}{short_code}"
            return JSONResponse(content={"short_url": short_url}, status_code=200)
            
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Database error {str(e)}")
    
    if request.custom_url is not None and request.custom_url != "":
        short_code = request.custom_url
    else: 
        short_code = str(uuid.uuid4())[:6]
    
    table.put_item(Item={"ShortURL": short_code, "LongURL": long_url})
    
    short_url = f"{short_url}{short_code}"
    return JSONResponse(content={"short_url": short_url}, status_code=200)

handler = Mangum(app)