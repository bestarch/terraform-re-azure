import os
import sys
import json
import requests # REST requests
from requests.auth import HTTPBasicAuth
import time
import argparse


def deployDB():
    
    parser = argparse.ArgumentParser(description="Python script using Jenkins credentials.")
    parser.add_argument('--CLUSTER_NAME', type=str, help='The API key')
    parser.add_argument('--CLUSTER_USER_NAME', type=str, help='The DB password')
    parser.add_argument('--CLUSTER_PASSWORD', type=str, help='SSH username')
  

    args = parser.parse_args()

    CLUSTER_NAME = args.CLUSTER_NAME
    CLUSTER_USER_NAME = args.CLUSTER_USER_NAME
    CLUSTER_PASSWORD = args.CLUSTER_PASSWORD

    # Accessing command-line arguments
    print(f"CLUSTER_NAME: {CLUSTER_NAME}")
    print(f"CLUSTER_USER_NAME: {CLUSTER_USER_NAME}")
    print(f"CLUSTER_PASSWORD: {CLUSTER_PASSWORD}")


    # CLUSTER_NAME = os.environ.get('CLUSTER_NAME')
    # CLUSTER_USER_NAME = os.environ.get('CLUSTER_USER_NAME')
    # CLUSTER_PASSWORD = os.environ.get('CLUSTER_PASSWORD')

    print(f"Env variables:: CLUSTER_NAME:{CLUSTER_NAME}, CLUSTER_USER_NAME:{CLUSTER_USER_NAME}, CLUSTER_PASSWORD:{CLUSTER_PASSWORD}")

    if CLUSTER_NAME is None or CLUSTER_USER_NAME is None or CLUSTER_PASSWORD is None:
        print("ERROR: Please set CLUSTER_NAME, CLUSTER_USER_NAME & CLUSTER_PASSWORD environment variables before proceeding further")
        return
    
    print("Create redis database")

    payload = {
        "name": "stagDB",
        "memory_size": 12582912,
        "type": "redis",
        "module_list": [
          {
            "module_name": "search"
          },
          {
            "module_name": "json"
          }
        ]
      }

    # Create the database
    url = "https://" + CLUSTER_NAME + ":9443/v1/bdbs"
    print (f"Cluster url: {url}")
    response = requests.post(url, verify=False, auth = HTTPBasicAuth(CLUSTER_USER_NAME, CLUSTER_PASSWORD), json=json.dumps(payload))
    try:
        result = response.json()
        print(result)
        return result
    except:
        print ('Response is not JSON.')
        print (response)
        return response


if __name__ == "__main__":
    deployDB()
    
    