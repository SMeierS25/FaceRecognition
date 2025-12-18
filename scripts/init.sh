#!/usr/bin/env bash
# init.sh
# # ===========================================================
# Script: init.sh
# Zweck:  Initialisiert die komplette FaceRecognition-Infrastruktur in AWS.
# Autor:  Alexis Karapsias/Sandro Meier/Yven Zuercher / Modul M346
# Region: us-east-1
# ===========================================================
# Voraussetzungen:
# - AWS CLI v2 ist installiert und konfiguriert (Learner Lab).
# - Ausführung auf Linux, macOS oder WSL/Bash unter Windows.
#
# Verwendung:
#   cd scripts
#   chmod +x init.sh
#   ./init.sh
#
# Das Script gibt am Ende alle erzeugten Namen aus.

set -euo pipefail

PROJECT_PREFIX="face-recognition-m346"
TIMESTAMP=$(date +%Y%m%d%H%M%S)

IN_BUCKET="${PROJECT_PREFIX}-${TIMESTAMP}-in"
OUT_BUCKET="${PROJECT_PREFIX}-${TIMESTAMP}-out"
LAMBDA_NAME="${PROJECT_PREFIX}-${TIMESTAMP}-lambda"

LAMBDA_ROLE="LabRole"

ZIP_FILE="lambda.zip"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LAMBDA_DIR="${ROOT_DIR}/lambda"

echo "========================================"
echo "  FaceRecognition Init Script (VocLabs)"
echo "========================================"
echo "Projektverzeichnis: ${ROOT_DIR}"
echo

# 1) S3 Buckets erstellen
echo "[1/4] Erstelle S3-Buckets:"
echo "  IN  Bucket: ${IN_BUCKET}"
echo "  OUT Bucket: ${OUT_BUCKET}"

aws s3 mb "s3://${IN_BUCKET}"
aws s3 mb "s3://${OUT_BUCKET}"

# 2) Lambda ZIP erzeugen
TMP_ZIP="/tmp/${ZIP_FILE}"
echo "Erzeuge ZIP in /tmp: ${TMP_ZIP}"

cd "${LAMBDA_DIR}"
zip -q "${TMP_ZIP}" lambda_function.py
cd "${ROOT_DIR}"


# 3) Lambda-Funktion erstellen
echo
echo "[3/4] Erstelle Lambda-Funktion: ${LAMBDA_NAME}"

LAMBDA_ROLE_ARN=$(
    aws iam get-role \
        --role-name $LAMBDA_ROLE \
        --query Role.Arn \
        --output text
)

aws lambda create-function \
  --function-name "${LAMBDA_NAME}" \
  --runtime python3.12 \
  --role "${LAMBDA_ROLE_ARN}" \
  --handler "lambda_function.lambda_handler" \
  --zip-file "fileb://${TMP_ZIP}" \
  --environment "Variables={OUT_BUCKET=${OUT_BUCKET}}" \
  --timeout 30 \
  --memory-size 256

# 4) S3 Trigger einrichten
echo
# 4) S3 Trigger einrichten
echo
echo "[4/4] Richte S3-Trigger ein..."

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

LAMBDA_ARN=$(aws lambda get-function --function-name "${LAMBDA_NAME}" \
    --query 'Configuration.FunctionArn' --output text)

# Lambda-Berechtigung für S3 hinzufügen (VOC-Labs kompatibel)
aws lambda add-permission \
  --function-name "${LAMBDA_NAME}" \
  --statement-id "s3invoke-${TIMESTAMP}" \
  --action "lambda:InvokeFunction" \
  --principal s3.amazonaws.com \
  --source-arn "arn:aws:s3:::${IN_BUCKET}" \
  --source-account "${ACCOUNT_ID}"

# Benachrichtigungskonfiguration als Datei speichern (VocLabs benötigt das!)
NOTIF_FILE="/tmp/notification.json"

cat > "${NOTIF_FILE}" <<EOF
{
  "LambdaFunctionConfigurations": [
    {
      "Id": "InvokeLambdaOnUpload",
      "LambdaFunctionArn": "${LAMBDA_ARN}",
      "Events": ["s3:ObjectCreated:*"]
    }
  ]
}
EOF

aws s3api put-bucket-notification-configuration \
  --bucket "${IN_BUCKET}" \
  --notification-configuration file://"${NOTIF_FILE}"

echo
echo "========================================"
echo "      Init abgeschlossen!"
echo "========================================"
echo "In-Bucket:      ${IN_BUCKET}"
echo "Out-Bucket:     ${OUT_BUCKET}"
echo "Lambda:         ${LAMBDA_NAME}"
echo "IAM Role:       labRole"
echo
echo "Hinweis:"
echo " Starte den Test mit:"
echo "   ./test.sh ${IN_BUCKET} ${OUT_BUCKET} ../tests/input/dein-bild.jpg"
 