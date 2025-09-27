from PIL import Image, ImageOps
import os

def resize_and_crop_to_square(input_folder, output_folder, size=256):
	"""
	Resizes and crops all PNG images in a folder to a square thumbnail.
	"""
	# Ensure the output folder exists
	os.makedirs(output_folder, exist_ok=True)

	# Get a list of all files in the input folder
	for filename in os.listdir(input_folder):
		if filename.lower().endswith(('.png')):
			# Construct full file paths
			input_path = os.path.join(input_folder, filename)
			output_path = os.path.join(output_folder, filename)

			try:
				# Open the image file
				with Image.open(input_path) as img:
					# Use ImageOps.fit to resize and crop
					img = ImageOps.fit(img, (size, size), Image.LANCZOS)
					# Save the new image
					img.save(output_path)
					print(f"Resized and cropped: {filename}")
			except Exception as e:
				print(f"Failed to process {filename}: {e}")

if __name__ == "__main__":
	# --- CHANGE THESE PATHS ---
	input_directory = "path/to/your/original/images"
	output_directory = "path/to/your/resized/images"
	
	resize_and_crop_to_square(input_directory, output_directory)
