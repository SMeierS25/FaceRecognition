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

import json
import os
from typing import Any, Dict, List

import boto3

rekognition = boto3.client("rekognition")
s3 = boto3.client("s3")

OUT_BUCKET = os.environ.get("OUT_BUCKET")


def analyze_image(bucket: str, key: str) -> Dict[str, Any]:
    """
    Ruft den AWS Rekognition Dienst 'RecognizeCelebrities' auf.

    :param bucket: Name des S3-Buckets, in dem das Bild liegt.
    :param key: Objekt-Key (Pfad/Dateiname) des Bildes im Bucket.
    :return: Antwort von Rekognition als Python-Dict.
    """
    response = rekognition.recognize_celebrities(
        Image={"S3Object": {"Bucket": bucket, "Name": key}}
    )
    return response


def build_output_key(input_key: str) -> str:
    """
    Erzeugt einen Ausgabedateinamen auf Basis des Input-Filenamens.
    Beispiel: "bilder/test.jpg" -> "bilder/test.json"

    :param input_key: Original-Key des Bildes.
    :return: Key der Ergebnisdatei (JSON).
    """
    if "." in input_key:
        base = input_key.rsplit(".", 1)[0]
    else:
        base = input_key
    return f"{base}.json"


def save_result_to_s3(out_bucket: str, key: str, data: Dict[str, Any]) -> None:
    """
    Speichert die Analyse-Ergebnisse als JSON im Out-Bucket.

    :param out_bucket: Name des Out-Buckets.
    :param key: Ziel-Key (Dateiname) im Out-Bucket.
    :param data: Analyse-Daten als Python-Dict.
    """
    s3.put_object(
        Bucket=out_bucket,
        Key=key,
        Body=json.dumps(data, indent=2),
        ContentType="application/json",
    )