import azure.functions as func
from azure.cosmos import CosmosClient
import azure.storage.blob as blob
import json

def main(req: func.HttpRequest) -> func.HttpResponse:
    record_id = req.params.get('id')
    cosmos_client = CosmosClient("<cosmosdb-endpoint>", "<cosmosdb-key>")
    database = cosmos_client.get_database_client("billing-db")
    container = database.get_container_client("billing-records")

    try:
        item = container.read_item(item=record_id, partition_key=record_id)
        return func.HttpResponse(json.dumps(item), status_code=200)
    except:
        blob_service_client = blob.BlobServiceClient.from_connection_string("<blob-connection-string>")
        blob_client = blob_service_client.get_blob_client(container="billing-archive", blob=f"billing/{record_id}.json")
        if blob_client.exists():
            blob_data = blob_client.download_blob().readall()
            return func.HttpResponse(blob_data, status_code=200)
        return func.HttpResponse("Record not found", status_code=404)
