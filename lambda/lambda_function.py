"""
lambda_function.py
-------------------
Autor: Alexis Karapsias
Sandro Meier
Yven Zuercher
Datum: 11.12.2025

AWS Lambda-Funktion für das FaceRecognition-Projekt (Modul 346).

Funktion:
- Wird durch ein "ObjectCreated"-Event im In-Bucket ausgelöst.
- Ruft AWS Rekognition (RecognizeCelebrities) auf.
- Speichert die Analyse als JSON-Datei im Out-Bucket.

Voraussetzungen:
- Environment-Variable OUT_BUCKET ist in der Lambda-Konfiguration gesetzt.
- Lambda-Rolle hat folgende Berechtigungen:
  - rekognition:RecognizeCelebrities
  - s3:GetObject auf den In-Bucket
  - s3:PutObject auf den Out-Bucket
"""