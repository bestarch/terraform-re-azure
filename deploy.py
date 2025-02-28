import os
import sys
import json
import requests # REST requests
from requests.auth import HTTPBasicAuth
import time
import argparse


def deployDB():
    
    # parser = argparse.ArgumentParser(description="Python script using Jenkins credentials.")
    # parser.add_argument('--CLUSTER_NAME', type=str, help='The API key')
    # parser.add_argument('--CLUSTER_USER_NAME', type=str, help='The DB password')
    # parser.add_argument('--CLUSTER_PASSWORD', type=str, help='SSH username')
  

    # args = parser.parse_args()

    # CLUSTER_NAME = args.CLUSTER_NAME
    # CLUSTER_USER_NAME = args.CLUSTER_USER_NAME
    # CLUSTER_PASSWORD = args.CLUSTER_PASSWORD

    # # Accessing command-line arguments
    # print(f"CLUSTER_NAME: {CLUSTER_NAME}")
    # print(f"CLUSTER_USER_NAME: {CLUSTER_USER_NAME}")
    # print(f"CLUSTER_PASSWORD: {CLUSTER_PASSWORD}")


    CLUSTER_NAME = os.environ.get('CLUSTER_NAME')
    CLUSTER_USER_NAME = os.environ.get('CLUSTER_USER_NAME')
    CLUSTER_PASSWORD = os.environ.get('CLUSTER_PASSWORD')

    print(f"Env variables:: CLUSTER_NAME:{CLUSTER_NAME}, CLUSTER_USER_NAME:{CLUSTER_USER_NAME}, CLUSTER_PASSWORD:{CLUSTER_PASSWORD}")

    if CLUSTER_NAME is None or CLUSTER_USER_NAME is None or CLUSTER_PASSWORD is None:
        print("ERROR: Please set CLUSTER_NAME, CLUSTER_USER_NAME & CLUSTER_PASSWORD environment variables before proceeding further")
        return
    
    print("Create redis database")

    memory_size = 10737418240 #10G

    payload = {
      "name": "stagDB-SBG56HG",
      "memory_size": memory_size,
      "type": "redis",
      "authentication_redis_pass": "admin",
      "proxy_policy": "all-nodes",
      "replication": True
    }

    # Create the database
    #url = "https://" + CLUSTER_NAME + ":9443/v1/bdbs"
    primary_url = "https://redis-poc.dlqueue.com:9443/v1/bdbs"
    print (f"Primary Cluster url: {primary_url}")
    print (f"Payload: {payload}")
    
    headers = {
      "Content-Type": "application/json"
    }

    response = requests.post(
        primary_url,
        verify=False,
        headers=headers,
        #auth=HTTPBasicAuth(CLUSTER_USER_NAME, CLUSTER_PASSWORD),
        auth=HTTPBasicAuth("admin@example.com", "admin"),
        json=payload  
    )

    try:
        result = response.json()

        dr_url = "https://redis-poc-dr.dlqueue.com:9443/v1/bdbs"
        
        payload_dr = {
        "name": "stagDB-SBG56HG-dr",
        "memory_size": memory_size,
        "type": "redis",
        "proxy_policy": "all-nodes",
        "replication": True
        }
        print (f"DR Cluster url: {dr_url}")
        print (f"Payload DR: {payload_dr}")

        response_dr = requests.post(
            dr_url,
            verify=False,
            headers=headers,
            auth=HTTPBasicAuth("admin@example.com", "admin"),
            json=payload_dr  
        )

        result = response_dr.json()
        print(result)  
        return result     
    except:
        print ('Response is not JSON.')
        print (response)
        return response
    

if __name__ == "__main__":
    deployDB()
    
    