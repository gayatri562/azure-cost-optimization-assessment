import azure.functions as func
import azure.storage.blob as blob
import json

def main(documents: func.DocumentList):
    blob_service_client = blob.BlobServiceClient.from_connection_string("<blob-connection-string>")
    container_client = blob_service_client.get_container_client("billing-archive")

    for doc in documents:
        doc_json = json.dumps(doc)
        blob_name = f"billing/{doc['id']}.json"
        blob_client = container_client.get_blob_client(blob_name)
        blob_client.upload_blob(doc_json, overwrite=True)
