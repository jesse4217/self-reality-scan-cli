import os
import json
import xml.etree.ElementTree as ET
from pathlib import Path

current_dir = Path(__file__).parent
input_folder = current_dir / "input"
output_folder = current_dir / "output"

print(f"Absolute input_folder path: {input_folder.resolve()}")
print(f"Absolute output_folder path: {output_folder.resolve()}")

# Ensure the input and output directories exist
input_folder.mkdir(parents=True, exist_ok=True)
output_folder.mkdir(parents=True, exist_ok=True)

def parse_xmp_file(file_path):
    tree = ET.parse(file_path)
    root = tree.getroot()
    
    # Find the rdf:Description element
    description = root.find('.//{http://www.w3.org/1999/02/22-rdf-syntax-ns#}Description')
    
    if description is None:
        return None

    # Extract attributes
    data = {k.split('}')[-1]: v for k, v in description.attrib.items()}
    
    # Extract Rotation, Position, and DistortionCoeficients
    for element in description:
        tag = element.tag.split('}')[-1]
        data[tag] = element.text.split()

    return data

def collect_xmp_data(directory):
    xmp_data = []
    for filename in os.listdir(directory):
        if filename.lower().endswith('.xmp'):
            file_path = os.path.join(directory, filename)
            data = parse_xmp_file(file_path)
            if data:
                xmp_data.append({
                    'id': len(xmp_data),
                    'filename': filename,
                    'data': data
                })
    return xmp_data

def save_to_json(data, output_file):
    with open(output_file, 'w') as f:
        json.dump(data, f, indent=2)

# Main execution
if __name__ == "__main__":
    output_file = os.path.join(output_folder, 'xmp_data.json')

    xmp_data = collect_xmp_data(input_folder)
    save_to_json(xmp_data, output_file)
    print(f"XMP data has been collected and saved to {output_file}")