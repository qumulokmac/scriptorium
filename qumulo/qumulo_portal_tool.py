#!/usr/bin/python3
################################################################################
#
# Copyright (c) 2024 Qumulo, Inc. All rights reserved.
#
# NOTICE: All information and intellectual property contained herein is the
# confidential property of Qumulo, Inc. Reproduction or dissemination of the
# information or intellectual property contained herein is strictly forbidden,
# unless separate prior written permission has been obtained from Qumulo, Inc.
#
# qumulo_portal_tool.py
#
# Date: October 20, 2024
# Author: Kevin McDonald (kmac@qumulo.com)
#
# Purpose: Automate the setup of the HUB and SPOKE portal directories and enable portal access
# using the Qumulo Python SDK.
#
################################################################################

from qumulo.rest_client import RestClient
import qumulo.lib.auth
import qumulo.lib.request
import qumulo.rest.fs as fs
import json
import requests
import sys
import urllib3
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

debug = False

def handle_error(error_message):
    print(f"ERROR: {error_message}")
    sys.exit(1)

def load_config(config_file):
    try:
        with open(config_file, 'r') as file:
            config = json.load(file)
            print(f"Configuration loaded successfully from {config_file}")
            return config
    except FileNotFoundError:
        handle_error(f"Configuration file '{config_file}' not found.")
    except json.JSONDecodeError as e:
        handle_error(f"Error decoding JSON from '{config_file}': {e}")

def create_session(ip_address, username=None, password=None, access_token=None):
    try:
        if access_token:
            credentials = qumulo.lib.auth.Credentials(access_token)
            rc = RestClient(ip_address, 8000, credentials)
            print(f"Session established with Qumulo at {ip_address} using access token")
            return rc, credentials.bearer_token, ip_address
        elif username and password:
            rc = RestClient(ip_address, 8000)
            credentials = rc.login(username, password)
            print(f"Session established with Qumulo at {ip_address} using username and password")
            return rc, credentials.bearer_token, ip_address
        else:
            handle_error(f"Credentials are required to create a session with {ip_address}")
    except qumulo.lib.request.RequestError as err:
        handle_error(f"Login error: {err}")
    except Exception as e:
        handle_error(f"Failed to create session with {ip_address}: {e}")

def create_directory_on_hub(rc, hub_base_directory):
    try:
        print(f"Creating directory '{hub_base_directory}' on the HUB...")
        rc.fs.create_directory(name=hub_base_directory, dir_path="/")
        print(f"Directory '{hub_base_directory}' created successfully.")
    except qumulo.lib.request.RequestError as e:
        if "fs_entry_exists_error" in str(e):
            handle_error(f"ERROR: The directory '{hub_base_directory}' already exists on the HUB.")
        else:
            handle_error(f"Error creating directory '{hub_base_directory}' on the HUB: {e}")
    except Exception as e:
        handle_error(f"Unexpected error creating directory '{hub_base_directory}': {e}")

def create_portal_on_spoke(rc, bearer_token, host, hub_ip, spoke_base_directory, hub_base_directory):
    try:
        spoke_root_path = f"/{spoke_base_directory}"
        hub_root_path = f"/{hub_base_directory}"

        print(f"Creating portal from SPOKE to HUB at {hub_ip}...")

        session = requests.Session()
        session.headers.update({
            'Authorization': f'Bearer {bearer_token}',
            'Content-Type': 'application/json'
        })

        response = session.post(f'https://{host}:8000/v1/portal/spokes/',
                                json={'spoke_root': spoke_root_path, 'hub_address': hub_ip, 'hub_root': hub_root_path},
                                verify=False)

        if response.status_code == 200:
            portal_id = int(response.content)
            print(f"Portal created successfully with ID: {portal_id}")
            return portal_id
        elif response.status_code == 400 and b'portal_directory_already_exists_error' in response.content:
            handle_error(f"ERROR: The spoke path '{spoke_root_path}' already exists.")
        else:
            if debug:
                print(f"Response content: {response.content}")
            handle_error(f"Failed to create portal from SPOKE to HUB: {response.content}")
    except Exception as e:
        handle_error(f"Error creating portal from SPOKE to HUB: {e}")

def propose_hub_on_spoke(rc, bearer_token, host, spoke_id, hub_ip, hub_root):
    try:
        print(f"Proposing HUB on SPOKE with ID {spoke_id} to HUB at {hub_ip}...")

        session = requests.Session()
        session.headers.update({
            'Authorization': f'Bearer {bearer_token}',
            'Content-Type': 'application/json'
        })

        response = session.post(f'https://{host}:8000/v1/portal/spokes/{spoke_id}/propose',
                                json={'hub_root': hub_root, 'hub_address': hub_ip, 'hub_port': 3713},
                                verify=False)

        print(f"Response status code: {response.status_code}")
        if debug:
            print(f"Response content: {response.content}")

        if response.status_code == 200:
            hub_root_id = response.json().get('hub_root')
            print(f"HUB proposed successfully with Hub Root ID: {hub_root_id}")
            return hub_root_id
        else:
            handle_error(f"Failed to propose HUB on SPOKE: {response.content}")
    except Exception as e:
        handle_error(f"Error proposing HUB on SPOKE: {e}")

def list_hubs(rc, bearer_token, host, hub_base_directory):
    try:
        print(f"Listing hubs on {host}...")

        session = requests.Session()
        session.headers.update({
            'Authorization': f'Bearer {bearer_token}',
            'Content-Type': 'application/json'
        })

        response = session.get(f'https://{host}:8000/v1/portal/hubs/', verify=False)

        print(f"Response status code: {response.status_code}")
        if debug:
            print(f"Response content: {response.content}")

        if response.status_code == 200:
            hubs = response.json().get('entries', [])
            for hub in hubs:
                if hub.get('root_path', '').strip('/') == hub_base_directory.strip('/'):
                    return hub.get('id')
            handle_error(f"Error: No hub found for path: /{hub_base_directory}")
        else:
            handle_error(f"Failed to list hubs: {response.content}")
    except Exception as e:
        handle_error(f"Error listing hubs: {e}")

def authorize_portal_on_hub(rc, bearer_token, host, hub_root_id, spoke_ip):
    try:
        print(f"Authorizing portal on HUB with Hub Root ID {hub_root_id} and Spoke IP {spoke_ip}...")

        session = requests.Session()
        session.headers.update({
            'Authorization': f'Bearer {bearer_token}',
            'Content-Type': 'application/json'
        })

        response = session.post(f'https://{host}:8000/v1/portal/hubs/{hub_root_id}/authorize',
                                json={'spoke_address': spoke_ip, 'spoke_port': 3713},
                                verify=False)

        print(f"Response status code: {response.status_code}")
        if debug:
            print(f"Response content: {response.content}")

        if response.status_code == 200:
            portal_data = response.json()
            pretty_portal_data = json.dumps(portal_data, indent=4)
            print(f"Portal authorized successfully: \n{pretty_portal_data}")
        else:
            handle_error(f"Failed to authorize portal on HUB: {response.content}")
    except Exception as e:
        handle_error(f"Error authorizing portal on HUB: {e}")

def main():
    try:
        config = load_config('qpt-config.json')

        hub_ip = config['hub_ip_address']
        spoke_ip = config['spoke_ip_address']
        username = config['username']
        password = config['password']
        hub_base_directory = config['portal_hub_base_directory']
        spoke_base_directory = config['portal_spoke_base_directory']

        hub_rc, hub_bearer_token, hub_host = create_session(hub_ip, username=username, password=password)
        spoke_rc, spoke_bearer_token, spoke_host = create_session(spoke_ip, username=username, password=password)
        create_directory_on_hub(hub_rc, hub_base_directory)
        portal_id = create_portal_on_spoke(spoke_rc, spoke_bearer_token, spoke_host, hub_ip, spoke_base_directory, hub_base_directory)
        print(f"Portal ID is: {portal_id}")
        hub_root_id = propose_hub_on_spoke(spoke_rc, spoke_bearer_token, spoke_host, portal_id, hub_ip, f'/{hub_base_directory}')
        correct_hub_id = list_hubs(hub_rc, hub_bearer_token, hub_host, hub_base_directory)
        authorize_portal_on_hub(hub_rc, hub_bearer_token, hub_host, correct_hub_id, spoke_ip)

    except Exception as e:
        handle_error(f"Unexpected error in the main process: {e}")

if __name__ == "__main__":
    main()