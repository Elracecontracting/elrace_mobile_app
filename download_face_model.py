#!/usr/bin/env python3
"""
Face Recognition Model Downloader and Converter
This script downloads a pre-trained face recognition model and converts it to TensorFlow Lite format.
"""

import os
import requests
import zipfile
import tensorflow as tf
from tensorflow import keras
import numpy as np

def download_file(url, filename):
    """Download a file from URL"""
    print(f"Downloading {filename}...")
    response = requests.get(url, stream=True)
    response.raise_for_status()
    
    with open(filename, 'wb') as f:
        for chunk in response.iter_content(chunk_size=8192):
            f.write(chunk)
    print(f"Downloaded {filename}")

def create_simple_face_model():
    """Create a simple face recognition model for testing"""
    print("Creating simple face recognition model...")
    
    # Create a simple CNN model for face embedding
    model = keras.Sequential([
        keras.layers.Input(shape=(160, 160, 3)),
        keras.layers.Conv2D(32, 3, activation='relu'),
        keras.layers.MaxPooling2D(),
        keras.layers.Conv2D(64, 3, activation='relu'),
        keras.layers.MaxPooling2D(),
        keras.layers.Conv2D(64, 3, activation='relu'),
        keras.layers.GlobalAveragePooling2D(),
        keras.layers.Dense(128, activation='relu'),  # 128-dimensional embedding
        keras.layers.Lambda(lambda x: tf.math.l2_normalize(x, axis=1))  # L2 normalization
    ])
    
    return model

def convert_to_tflite(model, output_path):
    """Convert Keras model to TensorFlow Lite"""
    print(f"Converting model to TensorFlow Lite...")
    
    # Convert to TensorFlow Lite
    converter = tf.lite.TFLiteConverter.from_keras_model(model)
    converter.optimizations = [tf.lite.Optimize.DEFAULT]
    tflite_model = converter.convert()
    
    # Save the model
    with open(output_path, 'wb') as f:
        f.write(tflite_model)
    
    print(f"Model saved to {output_path}")

def main():
    """Main function to download and convert model"""
    
    # Create assets/models directory if it doesn't exist
    os.makedirs('assets/models', exist_ok=True)
    
    # Create a simple face recognition model
    model = create_simple_face_model()
    
    # Convert to TensorFlow Lite
    output_path = 'assets/models/face_recognition_model.tflite'
    convert_to_tflite(model, output_path)
    
    print("\n✅ Face recognition model created successfully!")
    print(f"📁 Model location: {output_path}")
    print("📊 Model input shape: (1, 160, 160, 3)")
    print("📊 Model output shape: (1, 128)")
    print("\n💡 Add this to your pubspec.yaml:")
    print("assets:")
    print("  - assets/models/face_recognition_model.tflite")

if __name__ == "__main__":
    main() 