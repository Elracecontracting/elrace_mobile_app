# 📥 Face Recognition Model - Download Instructions

## ⚠️ Model File Missing

The Face Recognition system requires a TFLite model file that is **not included** in the repository due to its large size.

## 🔽 Download Model

### Option 1: MobileFaceNet (Recommended - Smaller & Faster)

- **Model:** `mobilefacenet.tflite`
- **Size:** ~4 MB
- **Dimensions:** 112x112 input → 192-dimensional embeddings
- **Download:** [MobileFaceNet TFLite Model](https://github.com/sirius-ai/MobileFaceNet_TF)

### Option 2: FaceNet

- **Model:** `facenet.tflite`
- **Size:** ~23 MB
- **Dimensions:** 160x160 input → 512-dimensional embeddings
- **Download:** [FaceNet TFLite Model](https://github.com/nyoki-mtl/keras-facenet)

## 📦 Installation Steps

1. **Download** one of the models above
2. **Rename** the file to `mobilefacenet.tflite` (or update path in code)
3. **Place** the file in this directory: `assets/`
4. **Verify** the file path in pubspec.yaml:
   ```yaml
   flutter:
     assets:
       - assets/mobilefacenet.tflite
   ```
5. **Run** `flutter pub get`
6. **Restart** the app

## 🔧 Alternative: Use Without Model

If you don't need face recognition immediately:

- The app will continue to work without the model
- Face recognition features will be disabled
- You'll see a warning message in console
- Add the model later when needed

## ✅ Verification

After adding the model, you should see:

```
✅ Face Recognition initialized successfully
```

If the model is missing:

```
⚠️ Face Recognition initialization failed
ℹ️ Face recognition features will be disabled until model file is added
```

## 📚 More Info

See [FACE_RECOGNITION_GUIDE.md](../FACE_RECOGNITION_GUIDE.md) for complete setup instructions.
