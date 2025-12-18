#!/usr/bin/env bash
# test.sh
# ===========================================================
# Script: test.sh
# Zweck:  Testet die FaceRecognition-Infrastruktur
# Autor:  Alexis Karapsias/Sandro Meier/Yven Zuercher / Modul M346
# Region: us-east-1
# ===========================================================
# Testet die FaceRecognition-Infrastruktur:
# - lädt ein Testbild in den In-Bucket hoch
# - wartet, bis im Out-Bucket eine JSON mit dem gleichen Namen existiert
# - lädt das Ergebnis herunter
# - gibt die erkannten Personen mit Trefferwahrscheinlichkeit aus
#
# Verwendung:
#   cd scripts
#   chmod +x test.sh
#   ./test.sh <IN_BUCKET> <OUT_BUCKET> <PFAD_ZUM_BILD>
#
# Beispiel:
#   ./test.sh face-recognition-m346-20251201093000-in \
#             face-recognition-m346-20251201093000-out \
#             ../tests/input/celeb.jpg

set -euo pipefail

if [[ $# -ne 4 ]]; then
  echo "Usage: $0 <IN_BUCKET> <OUT_BUCKET> <IMAGE_FILE> <LAMBDA_NAME>"
  exit 1
fi

IN_BUCKET="$1"
OUT_BUCKET="$2"
IMAGE_FILE="$3"
LAMBDA_NAME="$4"

if [[ ! -f "${IMAGE_FILE}" ]]; then
  echo "Fehler: Datei nicht gefunden: ${IMAGE_FILE}"
  exit 1
fi

echo "========================================"
echo " FaceRecognition Direkt-Test (ohne S3 Trigger)"
echo "========================================"
echo "In-Bucket:   ${IN_BUCKET}"
echo "Out-Bucket:  ${OUT_BUCKET}"
echo "Bilddatei:   ${IMAGE_FILE}"
echo

# Namen aufbereiten
BASENAME="$(basename "${IMAGE_FILE}")"
NAME_NO_EXT="${BASENAME%.*}"
RESULT_KEY="${NAME_NO_EXT}.json"
LOCAL_RESULT="../tests/output/${RESULT_KEY}"

mkdir -p ../tests/output

echo "[1/4] Lade Bild in den In-Bucket hoch..."
aws s3 cp "${IMAGE_FILE}" "s3://${IN_BUCKET}/${BASENAME}"


echo
echo "[2/3] Warte auf Ergebnis im Out-Bucket (${RESULT_KEY})..."

MAX_WAIT_SECONDS=30
ELAPSED=0
SLEEP=2

