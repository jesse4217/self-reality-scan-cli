from pathlib import Path
from rembg import remove, new_session

# Get the current script's directory
current_dir = Path(__file__).parent

# Define input and output folders relative to the current directory
input_folder = current_dir / "input"
output_folder = current_dir / "output"

print(f"Absolute input_folder path: {input_folder.resolve()}")
print(f"Absolute output_folder path: {output_folder.resolve()}")

# Ensure the input and output directories exist
input_folder.mkdir(parents=True, exist_ok=True)
output_folder.mkdir(parents=True, exist_ok=True)

session = new_session()

# Normalize extensions and make them lower case
extensions = ['.jpg', '.jpeg', '.png', '.dng', '.tiff', '.tif']

# Use a set to avoid duplicates
matching_files = set()

for ext in extensions:
    matching_files.update(
        file for file in input_folder.glob(f'*{ext}')
        if file.suffix.lower() == ext
    )

# Convert set to list if needed
matching_files = list(matching_files)

print(f"Number of matching files: {len(matching_files)}")
print(f"Matching files: {matching_files}")

total_images = len(matching_files)
processed_images = 0

print("Removing Images Background...")
for file in matching_files:
    print(f"Processing: {file.name}")
    input_path = str(file)
    output_path = str(output_folder / (file.stem + "_rmbg" + file.suffix))

    # Open the input file, process it, and save the output
    with open(input_path, 'rb') as input_file:
        with open(output_path, 'wb') as output_file:
            input_data = input_file.read()
            output = remove(input_data, session=session)
            output_file.write(output)
            processed_images += 1
            print(f"Removed Background of {file.name} ({processed_images}/{total_images})")
