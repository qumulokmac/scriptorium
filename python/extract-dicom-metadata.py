#!/usr/bin/python3

import pydicom
import json
import xml.etree.ElementTree as ET
import os
import argparse

def extract_dicom_metadata(dicom_file, size_threshold):
    try:
        dataset = pydicom.dcmread(dicom_file)
        metadata = {}
        for elem in dataset:
            if elem.VR != 'SQ' and len(str(elem.value)) <= size_threshold:  # Skip sequences and large fields
                metadata[elem.keyword] = str(elem.value)  # Convert to string to ensure JSON serializability
        print(f"Metadata extracted for file: {dicom_file}")
        return metadata
    except Exception as e:
        print(f"Error reading {dicom_file}: {e}")
        return None

def save_metadata_to_json(metadata, output_file):
    try:
        with open(output_file, 'w') as json_file:
            json.dump(metadata, json_file, indent=4)
        print(f"Metadata saved to {output_file}")
    except Exception as e:
        print(f"Error saving metadata to {output_file}: {e}")

def save_metadata_to_xml(metadata, output_file):
    try:
        root = ET.Element("DICOM_Metadata")
        for key, value in metadata.items():
            elem = ET.SubElement(root, key)
            elem.text = value
        tree = ET.ElementTree(root)
        tree.write(output_file, encoding="utf-8", xml_declaration=True)
        print(f"Metadata saved to {output_file}")
    except Exception as e:
        print(f"Error saving metadata to {output_file}: {e}")

def process_dicom_directory(directory_path, output_directory, output_format, size_threshold):
    if not os.path.exists(output_directory):
        os.makedirs(output_directory)
    
    for root, _, files in os.walk(directory_path):
        for file in files:
            if file.endswith('.DCM'):  # Ensuring correct case for file extension
                dicom_file = os.path.join(root, file)
                print(f"Processing file: {dicom_file}")
                metadata = extract_dicom_metadata(dicom_file, size_threshold)
                if metadata:
                    if output_format == "json":
                        output_file = os.path.join(output_directory, f"{os.path.splitext(file)[0]}.json")
                        save_metadata_to_json(metadata, output_file)
                    elif output_format == "xml":
                        output_file = os.path.join(output_directory, f"{os.path.splitext(file)[0]}.xml")
                        save_metadata_to_xml(metadata, output_file)
                else:
                    print(f"No metadata extracted for file: {dicom_file}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Extract DICOM metadata and save in JSON or XML format.")
    parser.add_argument("--input-dir", required=True, help="Path to the directory containing DICOM files.")
    parser.add_argument("--output-dir", required=True, help="Path to the directory to save the output files.")
    parser.add_argument("--format", choices=["json", "xml"], default="json", help="Output format: json or xml. Default is json.")
    parser.add_argument("--max-size", type=int, default=1000, help="Maximum size (in characters) of fields to include in the output. Default is 1000.")
    args = parser.parse_args()

    print(f"Starting processing DICOM files from {args.input_dir} to {args.output_dir} in {args.format.upper()} format with maximum field size {args.max_size} characters")
    process_dicom_directory(args.input_dir, args.output_dir, args.format, args.max_size)
    print("Processing complete.")