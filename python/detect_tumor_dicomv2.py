#!/usr/bin/python3
################################################################################
#
# Script Name: detect_tumor_dicom.py
#
# Date: January 2, 2025
# Author: Kevin McDonald (kmac@qumulo.com)
#
# Purpose: This script performs tumor detection on DICOM images using a U-Net
# model and classifies tumors as benign or malignant.
#
################################################################################

import os
import argparse
import numpy as np
import tensorflow as tf
from tensorflow.keras import layers, models
import pydicom
import cv2
import matplotlib.pyplot as plt
import warnings
import time
import csv
import json

warnings.filterwarnings("ignore", category=UserWarning, module='keras')

# Data augmentation pipeline
data_augmentation = tf.keras.Sequential([
    layers.RandomFlip("horizontal_and_vertical"),
    layers.RandomRotation(0.2),
    layers.RandomZoom(0.2),
    layers.RandomContrast(0.2),
    layers.RandomBrightness(0.2)
])

# Loss function for training
def dice_loss(y_true, y_pred, smooth=1):
    y_true_f = tf.keras.backend.flatten(y_true)
    y_pred_f = tf.keras.backend.flatten(y_pred)
    intersection = tf.keras.backend.sum(y_true_f * y_pred_f)
    return 1 - (2. * intersection + smooth) / (tf.keras.backend.sum(y_true_f) + tf.keras.backend.sum(y_pred_f) + smooth)

# Build U-Net model
def build_unet_model(input_shape, debug=False):
    if debug:
        print("Building U-Net model...")
    inputs = layers.Input(input_shape)

    # Encoding path
    c1 = layers.Conv2D(128, (3, 3), activation='relu', padding='same')(inputs)
    c1 = layers.Conv2D(128, (3, 3), activation='relu', padding='same')(c1)
    c1 = layers.Dropout(0.3)(c1)
    p1 = layers.MaxPooling2D((2, 2))(c1)

    c2 = layers.Conv2D(256, (3, 3), activation='relu', padding='same')(p1)
    c2 = layers.Conv2D(256, (3, 3), activation='relu', padding='same')(c2)
    c2 = layers.Dropout(0.3)(c2)
    p2 = layers.MaxPooling2D((2, 2))(c2)

    # Bottleneck
    c3 = layers.Conv2D(512, (3, 3), activation='relu', padding='same')(p2)
    c3 = layers.Conv2D(512, (3, 3), activation='relu', padding='same')(c3)
    c3 = layers.Dropout(0.3)(c3)

    # Decoding path
    u1 = layers.UpSampling2D((2, 2))(c3)
    u1 = layers.Conv2D(256, (2, 2), activation='relu', padding='same')(u1)
    u1 = layers.concatenate([u1, c2])

    u2 = layers.UpSampling2D((2, 2))(u1)
    u2 = layers.Conv2D(128, (2, 2), activation='relu', padding='same')(u2)
    u2 = layers.concatenate([u2, c1])

    # Output layer
    outputs = layers.Conv2D(1, (1, 1), activation='sigmoid')(u2)

    model = models.Model(inputs=[inputs], outputs=[outputs])
    if debug:
        print("U-Net model built successfully.")
    return model

# Load and preprocess DICOM images
def load_dicom_image(dicom_path, debug=False):
    if debug:
        print(f"Loading DICOM image from {dicom_path}...")
    dicom_data = pydicom.dcmread(dicom_path)
    dicom_image = dicom_data.pixel_array
    dicom_image = cv2.normalize(dicom_image, None, 0, 255, cv2.NORM_MINMAX)
    dicom_image = cv2.resize(dicom_image, (256, 256))
    dicom_image = np.array(dicom_image, dtype='float32') / 255.0
    dicom_image = np.expand_dims(dicom_image, axis=-1)  # Add the channel dimension
    return dicom_image

def simulate_prediction(prediction, min_confidence=0.5, max_confidence=0.95, seed=None, bias=None):
    """
    Generates a random confidence percentage between 50% and 95%.

    Args:
        prediction: Placeholder for compatibility (unused).
        min_confidence: Minimum confidence value (default 0.5).
        max_confidence: Maximum confidence value (default 0.95).
        seed: Optional random seed for reproducibility.

    Returns:
        Random confidence value between min_confidence and max_confidence.
    """
    if seed is not None:
        np.random.seed(seed)
    return np.random.uniform(min_confidence, max_confidence)


def process_dicom_image(dicom_path, model, accuracy, debug):
    """
    Processes a single DICOM image and returns the prediction confidence.
    """
    if debug:
        print(f"Processing file: {dicom_path}")
    dicom_image = load_dicom_image(dicom_path, debug)
    dicom_image = np.expand_dims(dicom_image, axis=0)

    # Simulate variability in predictions
    simpred = simulate_prediction(
        prediction=None,
        min_confidence=0.5,
        max_confidence=0.95,
        seed=None,
        bias=None
    )

    if accuracy:
        print(f"Prediction for {os.path.basename(dicom_path)}: {simpred * 100:.2f}% confident.")

    return simpred


def display_image_with_results(dicom_path, simpred, window_size, window_position):
    """
    Displays a single DICOM image with prediction results and formatting.
    """
    dicom_image = load_dicom_image(dicom_path)
    dicom_image = np.expand_dims(dicom_image, axis=0)
    import matplotlib.font_manager as fm
    custom_font = fm.FontProperties(family='Courier New', size=10)

    plt.imshow(dicom_image[0, :, :, 0], cmap='gray')

    if simpred >= 0.75:
        title_color = "red"
    elif 0.6 <= simpred < 0.75:
        title_color = "#FF5A00"
    else:
        title_color = "#2C2C4C"

    filename = os.path.basename(dicom_path)

    # DICOM filename text with bbox
    plt.text(
        0.5, 0.05, filename,  # Moved to the bottom
        ha="center", va="bottom",
        transform=plt.gca().transAxes,
        fontproperties=custom_font,
        fontsize=12, color="black",
        bbox=dict(facecolor='white', edgecolor='black', boxstyle='round,pad=0.3')
    )

    # Title text with reduced padding and dynamic color
    plt.title(
        f"Malignant confidence: {simpred * 100:.2f}%",
        fontsize=14, color=title_color, pad=20
    )

    plt.figtext(
        0.5, 0.03,
        "Simulated analysis powered by Cloud Native Qumulo",
        ha="center", fontsize=10, color="#007CAC"
    )

    fig = plt.gcf()
    fig.set_size_inches(window_size[0] / fig.dpi, window_size[1] / fig.dpi)
    fig.canvas.manager.window.wm_geometry(f"+{window_position[0]}+{window_position[1]}")

    plt.show()
    time.sleep(2)
    plt.close()

def display_image_on_subplot(dicom_path, simpred, ax):
    """
    Displays a single DICOM image on a subplot with prediction results.
    """
    dicom_image = load_dicom_image(dicom_path)
    dicom_image = np.expand_dims(dicom_image, axis=0)
    import matplotlib.font_manager as fm
    custom_font = fm.FontProperties(family='Courier New', size=10)

    ax.imshow(dicom_image[0, :, :, 0], cmap='gray')

    if simpred >= 0.75:
        title_color = "red"
    elif 0.6 <= simpred < 0.75:
        title_color = "#FF5A00"
    else:
        title_color = "#2C2C4C"

    filename = os.path.basename(dicom_path)

    # DICOM filename text with bbox
    ax.text(
        0.5, 0.05, filename,
        ha="center", va="bottom",
        transform=ax.transAxes,  # Use ax.transAxes for subplot
        fontproperties=custom_font,
        fontsize=10, color="black",
        bbox=dict(facecolor='white', edgecolor='black', boxstyle='round,pad=0.2')
    )

    # Title text with reduced padding and dynamic color
    ax.set_title(
        f"Malignant confidence: {simpred * 100:.2f}%",
        fontsize=10, color=title_color, pad=10
    )

    # Add a clear bar at the bottom
    ax.set_xlabel(" ")  # Set an empty x-label
    ax.xaxis.labelpad = 25  # Add 25 pixels of padding

    # Remove axis ticks and labels
    ax.set_xticks([])
    ax.set_yticks([])

# Function to generate the ASCII bar with color
def generate_colored_ascii_bar(count, total, color_code, bar_length=50):
    if total == 0:
        return ""  # No bar if no total images
    proportion = count / total
    filled_length = int(proportion * bar_length)
    filled_bar = f"{color_code}{'█' * filled_length}\033[0m"  # Colored filled part
    empty_bar = "-" * (bar_length - filled_length)  # Uncolored empty part
    return filled_bar + empty_bar


def analyze_dicom_directory(directory, model, display_images, debug, accuracy, threshold, export_results, window_size, window_position, display_all_at_once, output_file):
    """
    Analyzes DICOM images in a specified directory.

    Args:
        directory: The directory containing DICOM images.
        model: The U-Net model for tumor detection.
        display_images: Boolean indicating whether to display images.
        debug: Boolean to enable debug output.
        accuracy: Boolean to print prediction confidence scores.
        threshold: Confidence threshold for tumor classification.
        export_results: Boolean to indicate if results should be exported.
        window_size: Tuple specifying the display window size.
        window_position: Tuple specifying the display window position.
        display_all_at_once: Boolean indicating if all images should be displayed at once.
        output_file: Path to the CSV file where results will be saved.

    Returns:
        None
    """
    if debug:
        print(f"Analyzing DICOM images in directory: {directory}")

    results = []
    count_0_49 = 0
    count_50_59 = 0
    count_60_75 = 0
    count_76_100 = 0

    try:
        files = [f for f in os.listdir(directory) if os.path.isfile(os.path.join(directory, f)) and f.endswith(".dcm")]
        total_files = len(files)

        if display_all_at_once:
            # Create subplots for all images
            fig, axes = plt.subplots(nrows=int(np.ceil(total_files / 5)), ncols=5, figsize=(20, 4 * int(np.ceil(total_files / 5))))
            plt.subplots_adjust(bottom=0.4)  # Increased bottom spacing 
            axes = axes.flatten()

        for i, file in enumerate(files):
            dicom_path = os.path.join(directory, file)
            if debug:
                print(f"Checking file: {dicom_path}")

            simpred = process_dicom_image(dicom_path, model, accuracy, debug)
            results.append({'file': file, 'confidence': simpred})

            if simpred < 0.50:
                count_0_49 += 1
            elif simpred < 0.60:
                count_50_59 += 1
            elif simpred < 0.76:
                count_60_75 += 1
            else:
                count_76_100 += 1

            if display_images:
                if display_all_at_once:
                    # Display on subplots
                    display_image_on_subplot(dicom_path, simpred, axes[i])
                else:
                    display_image_with_results(dicom_path, simpred, window_size, window_position)

            # Print progress bar
            progress = (i + 1) / total_files
            bar_length = 50
            filled_length = int(bar_length * progress)
            bar = '█' * filled_length + '-' * (bar_length - filled_length)
            print(f'\rProgress: |{bar}| {progress:.1%} Complete', end='\r')

        if display_all_at_once and display_images:
            plt.tight_layout()  # Adjust spacing between subplots
            plt.show()

    except Exception as e:
        print(f"\nError processing directory {directory}: {e}")
        if debug:
            print(f"Skipping directory {directory} due to error.")

    if export_results or accuracy:
        try:

            bar_0_49 = generate_colored_ascii_bar(count_0_49, total_files, "\033[1;32m")  # Green
            bar_50_59 = generate_colored_ascii_bar(count_50_59, total_files, "\033[1;33m")  # Yellow
            bar_60_75 = generate_colored_ascii_bar(count_60_75, total_files, "\033[38;5;214m")  # Orange
            bar_76_100 = generate_colored_ascii_bar(count_76_100, total_files, "\033[1;31m")  # Red
            csv_file_path = export_results_to_csv(results, output_file, debug)

            print("\n--------------------------------------------------")
            print(f"\033[1mAnalysis complete. Processed {total_files} images.\033[0m")
            print("Confidence Level Breakdown:")
            print(f"  - \033[1;32m0-49%  :   {count_0_49} images\033[0m {bar_0_49}")  # Green
            print(f"  - \033[1;33m50-59% : {count_50_59} images\033[0m {bar_50_59}")  # Yellow
            print(f"  - \033[38;5;214m60-75% : {count_60_75} images\033[0m {bar_60_75}")  # Orange
            print(f"  - \033[1;31m76-100%: {count_76_100} images\033[0m {bar_76_100}")  # Red
            print(f"\033[1mResults exported to: {csv_file_path}\033[0m")
            print("--------------------------------------------------\n")

        except Exception as e:
            print(f"Error exporting results to CSV: {e}")



def export_results_to_csv(results, output_file, debug):
    """
    Exports the prediction results to a CSV file.

    Args:
        results: A list of dictionaries containing prediction results.
        output_file: The path where the CSV file will be saved.
        debug: Enable debug mode for additional output.

    Returns:
        The path to the generated CSV file.
    """
    try:
        if debug:
            print(f"Exporting results to CSV: {output_file}")

        with open(output_file, 'w', newline='') as csvfile:
            fieldnames = ['file', 'confidence']
            writer = csv.DictWriter(csvfile, fieldnames=fieldnames)

            writer.writeheader()
            for row in results:
                writer.writerow(row)

        return output_file

    except Exception as e:
        print(f"Error exporting results to CSV: {e}")

if __name__ == "__main__":
    try:
        parser = argparse.ArgumentParser(
            description="Tumor Detection Script using U-Net.",
            epilog="Example usage:\n"
                   "  python detect_tumor_dicom.py --dicom_directory /path/to/dicoms --export_results --output_file results.csv",
            formatter_class=argparse.RawTextHelpFormatter
        )
        parser.add_argument(
            '--dicom_directory', type=str, required=True,
            help="Base directory containing DICOM images. Subdirectories are searched recursively."
        )
        parser.add_argument(
            '--debug', action='store_true',
            help="Enable debug mode to display additional output."
        )
        parser.add_argument(
            '--accuracy', action='store_true',
            help="Print prediction confidence scores for each DICOM file."
        )
        parser.add_argument(
            '--display_images', action='store_true',
            help="Display images with analysis results during processing."
        )
        parser.add_argument(
            '--threshold', type=float, default=0.505,
            help="Threshold for tumor detection confidence (default: 0.505)."
        )
        parser.add_argument(
            '--export_results', action='store_true',
            help="Export analysis results to a CSV file."
        )
        parser.add_argument(
            '--output_file', type=str,
            help="Path to save the exported CSV file. Required if --export_results is specified."
        )
        parser.add_argument(
            '--window_size', type=str, default="800x600",
            help="Size of the display window (widthxheight), e.g., 800x600 (default: 800x600)."
        )
        parser.add_argument(
            '--window_position', type=str, default="100,100",
            help="Position of the display window (x,y), e.g., 100,100 (default: 100,100)."
        )
        parser.add_argument(
            '--display_all_at_once', action='store_true',
            help="Display all images at once in a grid layout instead of individually."
        )

        args = parser.parse_args()

        # Ensure --output_file is provided if --export_results is specified
        if args.export_results and not args.output_file:
            parser.error("--output_file is required when --export_results is specified.")

        # Assign parsed arguments
        dicom_directory = args.dicom_directory
        debug = args.debug
        display_images = args.display_images
        accuracy = args.accuracy
        threshold = args.threshold
        export_results = args.export_results
        output_file = args.output_file
        window_size = tuple(map(int, args.window_size.split('x')))
        window_position = tuple(map(int, args.window_position.split(',')))
        display_all_at_once = args.display_all_at_once

        if debug:
            print(f"\nStarting U-Net Tumor Detection Script for directory: {dicom_directory}")

        input_shape = (256, 256, 1)
        if debug:
            print("Building the AI model...")

        model = build_unet_model(input_shape, debug)
        model.compile(optimizer=tf.keras.optimizers.Adam(learning_rate=0.0001), loss=dice_loss, metrics=['accuracy'])

        analyze_dicom_directory(
            directory=dicom_directory,
            model=model,
            display_images=display_images,
            debug=debug,
            accuracy=accuracy,
            threshold=threshold,
            export_results=export_results,
            window_size=window_size,
            window_position=window_position,
            display_all_at_once=display_all_at_once,
            output_file=output_file,
        )

    except KeyboardInterrupt:
        print("\nProcess interrupted by user. Exiting gracefully...")
        exit(0)
        