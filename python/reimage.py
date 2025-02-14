#!/usr/bin/python3
##########################################################################################
# Script to automate reimaging physical HP nodes via the HP iLO using Redfish API.
#
# Script Name:  reimage_hpilo_redfish.py
# Date:         October 24, 2024
# Author:       Kevin McDonald (kmac@qumulo.com)
#
# This script performs the following actions:
# - Read iLO IP addresses from a file.
# - Create a session with each iLO using Redfish API.
# - Perform a full iLO reset at the start.
# - Power down the server if it is currently powered on.
# - Set One-Time Boot to Virtual CD-ROM.
# - Unmount and eject any existing virtual media.
# - Insert an ISO image as virtual media.
# - Power on the server.
# - Delete the session to log out.
#
# Requirements:
# - Python 3
# - requests library (pip install requests)
# - HP iLO with Redfish API enabled
##########################################################################################

import requests
import json
import time

requests.packages.urllib3.disable_warnings(requests.packages.urllib3.exceptions.InsecureRequestWarning)

ILO_IP_FILE = "ilo_ips.txt"
USERNAME = "YOURUSERNAME"
PASSWORD = "YOURPASSWORD
ISO_URL = "http://YOURIPADDR/usb_factory_reset.iso"

def create_redfish_session(host, username, password):
    login_url = f"https://{host}/redfish/v1/SessionService/Sessions"
    login_payload = {
        "UserName": username,
        "Password": password
    }

    print(f"[*] Establishing session with iLO at {host}...")
    response = requests.post(login_url, json=login_payload, verify=True)

    if response.status_code == 201:
        session_token = response.headers['X-Auth-Token']
        session_location = response.headers['Location']
        print("[+] Session created successfully.")
        return session_token, session_location
    else:
        print(f"[!] Failed to create session. Status code: {response.status_code}")
        print(f"[!] Response: {response.json()}")
        return None, None

def reset_ilo(host, session_token):
    reset_url = f"https://{host}/redfish/v1/Managers/1/Actions/Manager.Reset/"
    headers = {
        "X-Auth-Token": session_token
    }
    reset_payload = {
        "ResetType": "GracefulRestart"
    }

    print(f"[*] Resetting iLO for host {host}...")
    response = requests.post(reset_url, headers=headers, json=reset_payload, verify=True)

    if response.status_code == 200:
        print("[+] iLO reset successfully. Waiting for iLO to reboot...")
        time.sleep(120)  # Wait 2 minutes for the iLO to come back up
    else:
        print(f"[!] Failed to reset iLO. Status code: {response.status_code}")
        print(f"[!] Response: {response.json()}")

def fetch_system_info(host, session_token):
    system_url = f"https://{host}/redfish/v1/Systems/1/"
    headers = {
        "X-Auth-Token": session_token
    }

    print("[*] Fetching system information...")
    response = requests.get(system_url, headers=headers, verify=True)

    if response.status_code == 200:
        print("[+] System information fetched successfully.")
        system_info = response.json()
        return system_info
    else:
        print(f"[!] Failed to fetch system information. Status code: {response.status_code}")
        print(f"[!] Response: {response.json()}")
        return None

def power_down_system(host, session_token):
    power_url = f"https://{host}/redfish/v1/Systems/1/Actions/ComputerSystem.Reset/"
    headers = {
        "X-Auth-Token": session_token
    }
    power_payload = {
        "ResetType": "ForceOff"
    }

    system_info = fetch_system_info(host, session_token)
    if system_info and system_info.get('PowerState') == 'On':
        print("[*] Powering down the server...")
        response = requests.post(power_url, headers=headers, json=power_payload, verify=True)
        if response.status_code == 200:
            print("[+] Server powered down successfully.")
        else:
            print(f"[!] Failed to power down the server. Status code: {response.status_code}")
            print(f"[!] Response: {response.json()}")
    else:
        print("[+] Server is already powered down.")


def set_boot_order_to_cdrom(host, session_token):
    boot_url = f"https://{host}/redfish/v1/Systems/1/"
    headers = {
        "X-Auth-Token": session_token,
        "Content-Type": "application/json"
    }

    boot_payload = {
        "Boot": {
            "BootSourceOverrideTarget": "Cd", 
            "BootSourceOverrideEnabled": "Once" 
        }
    }

    print("[*] Setting CD-ROM as the one-time boot device for the next boot...")
    response = requests.patch(boot_url, headers=headers, json=boot_payload, verify=True)

    if response.status_code == 200 or response.status_code == 202:
        print("[+] One-time boot set to CD-ROM for the next boot.")
    else:
        print(f"[!] Failed to set boot source override. Status code: {response.status_code}")
        try:
            print(f"[!] Response: {response.json()}")
        except ValueError:
            print(f"[!] Response (non-JSON): {response.text}")

def check_virtual_media_status(host, session_token):
    media_url = f"https://{host}/redfish/v1/Managers/1/VirtualMedia/2/"
    headers = {
        "X-Auth-Token": session_token
    }

    print("[*] Checking existing virtual media connections...")
    response = requests.get(media_url, headers=headers, verify=True)

    if response.status_code == 200:
        media_info = response.json()
        inserted = media_info.get('Inserted', False)
        print(f"[+] Virtual media status: {'Inserted' if inserted else 'Not Inserted'}")
        return inserted
    else:
        print(f"[!] Failed to check virtual media status. Status code: {response.status_code}")
        print(f"[!] Response: {response.json()}")
        return False

def unmount_virtual_media(host, session_token):
    media_url = f"https://{host}/redfish/v1/Managers/1/VirtualMedia/2/"
    headers = {
        "X-Auth-Token": session_token
    }
    unmount_payload = {
        "Image": None  
    }

    print("[*] Unmounting current virtual media...")
    response = requests.patch(media_url, headers=headers, json=unmount_payload, verify=True)

    if response.status_code == 200:
        print("[+] Virtual media unmounted successfully.")
    else:
        print(f"[!] Failed to unmount virtual media. Status code: {response.status_code}")
        print(f"[!] Response: {response.json()}")

def eject_virtual_media(host, session_token):
    unmount_virtual_media(host, session_token) 

    media_url = f"https://{host}/redfish/v1/Managers/1/VirtualMedia/2/"
    headers = {
        "X-Auth-Token": session_token
    }
    eject_payload = {
        "Inserted": False
    }

    print("[*] Ejecting currently inserted virtual media...")
    response = requests.patch(media_url, headers=headers, json=eject_payload, verify=True)

    if response.status_code == 200:
        print("[+] Virtual media ejected successfully.")
    else:
        print(f"[!] Failed to eject virtual media. Status code: {response.status_code}")
        print(f"[!] Response: {response.json()}")

def insert_virtual_media(host, session_token, iso_url):
    if check_virtual_media_status(host, session_token):
        eject_virtual_media(host, session_token)

    media_url = f"https://{host}/redfish/v1/Managers/1/VirtualMedia/2/"
    headers = {
        "X-Auth-Token": session_token
    }
    media_payload = {
        "Image": iso_url,
        "Inserted": True
    }

    print(f"[*] Inserting virtual media from {iso_url} to CD-ROM...")
    response = requests.patch(media_url, headers=headers, json=media_payload, verify=True)

    if response.status_code == 200:
        print("[+] Virtual media inserted successfully on CD-ROM.")
    else:
        print(f"[!] Failed to insert virtual media. Status code: {response.status_code}")
        print(f"[!] Response: {response.json()}")

def power_on_system(host, session_token):
    power_url = f"https://{host}/redfish/v1/Systems/1/Actions/ComputerSystem.Reset/"
    headers = {
        "X-Auth-Token": session_token
    }
    power_payload = {
        "ResetType": "On"
    }

    system_info = fetch_system_info(host, session_token)
    if system_info and system_info.get('PowerState') == 'Off':
        print("[*] Powering on the server...")
        response = requests.post(power_url, headers=headers, json=power_payload, verify=True)
        if response.status_code == 200:
            print("[+] Server powered on successfully.")
        else:
            print(f"[!] Failed to power on the server. Status code: {response.status_code}")
            print(f"[!] Response: {response.json()}")
    else:
        print("[+] Server is already powered on.")


def delete_redfish_session(session_url, session_token):
    headers = {
        "X-Auth-Token": session_token
    }

    print("[*] Deleting session...")
    response = requests.delete(session_url, headers=headers, verify=True)

    if response.status_code in [200, 204]:
        print("[+] Session deleted successfully.")
    else:
        print(f"[!] Failed to delete session. Status code: {response.status_code}")
        try:
            print(f"[!] Response: {response.json()}")
        except ValueError:
            print("[!] No response body.")

def main():
    with open(ILO_IP_FILE, 'r') as ip_file:
        ilo_ips = [line.strip() for line in ip_file.readlines()]

    for ILO_IP in ilo_ips:
        print(f"[*] Processing iLO at {ILO_IP}...")

        session_token, session_url = create_redfish_session(ILO_IP, USERNAME, PASSWORD)

        if session_token:
            reset_ilo(ILO_IP, session_token)

            session_token, session_url = create_redfish_session(ILO_IP, USERNAME, PASSWORD)

            if session_token:
                power_down_system(ILO_IP, session_token)
                set_boot_order_to_cdrom(ILO_IP, session_token)
                insert_virtual_media(ILO_IP, session_token, ISO_URL)
                power_on_system(ILO_IP, session_token)
                delete_redfish_session(session_url, session_token)
            else:
                print(f"[!] Failed to re-establish session after iLO reset for {ILO_IP}.")
        else:
            print(f"[!] Session could not be created for {ILO_IP}. Skipping.")

if __name__ == "__main__":
    main()
