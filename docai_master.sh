#!/bin/bash
# ==============================================
# Document AI Lab GSP1142 - Full Automation
# Author: Aminex (https://www.youtube.com/@kamitabh244)
# ==============================================

# 🎥 Banner Start
echo "==============================================="
echo "🚀 Subscribe to Aminex YouTube Channel!"
echo "👉 https://www.youtube.com/@kamitabh244"
echo "==============================================="

# 1. Enable API
echo "🔹 Enabling Document AI API..."
gcloud services enable documentai.googleapis.com

# 2. Install Python Client
echo "🔹 Installing Python Client..."
pip3 install --upgrade google-cloud-documentai google-api-python-client

# 3. Vars
PROJECT_ID=$(gcloud config get-value project)
LOCATION="us"
PROCESSOR_NAME="lab-custom-extractor"
PROCESSOR_TYPE="CUSTOM_EXTRACTION_PROCESSOR"

echo "🔹 Project: $PROJECT_ID"
echo "🔹 Location: $LOCATION"

# 4. Create Processor
echo "🔹 Creating processor..."
PROCESSOR_FULL=$(gcloud documentai processors create \
  --display-name=$PROCESSOR_NAME \
  --type=$PROCESSOR_TYPE \
  --location=$LOCATION \
  --format="value(name)")

PROCESSOR_ID=$(echo $PROCESSOR_FULL | awk -F/ '{print $NF}')
echo "✅ Processor ID: $PROCESSOR_ID"

# 5. Download Data
echo "🔹 Downloading sample data..."
mkdir -p data
cd data
gsutil cp gs://cloud-samples-data/documentai/Custom/W2/PDF/W2_XL_input_clean_2950.pdf .
gsutil -m cp -r gs://cloud-samples-data/documentai/Custom/W2/AutoLabel ./AutoLabel
gsutil -m cp -r gs://cloud-samples-data/documentai/Custom/W2/JSON-2 ./PreLabeled
cd ..

# 6. Apply Schema (Python)
echo "🔹 Defining schema..."
PROJECT_ID=$PROJECT_ID PROCESSOR_ID=$PROCESSOR_ID python3 <<'EOF'
from google.cloud import documentai_v1 as documentai
import os

client = documentai.DocumentProcessorServiceClient()
project_id = os.getenv("PROJECT_ID")
location = "us"
processor_id = os.getenv("PROCESSOR_ID")
name = client.processor_path(project_id, location, processor_id)

schema = documentai.ProcessorSchema(fields=[
    documentai.ProcessorSchema.Field(name="control_number", field_type="NUMBER", occurrence="OPTIONAL_MULTIPLE"),
    documentai.ProcessorSchema.Field(name="employees_social_security_number", field_type="NUMBER", occurrence="REQUIRED_MULTIPLE"),
    documentai.ProcessorSchema.Field(name="employer_identification_number", field_type="NUMBER", occurrence="REQUIRED_MULTIPLE"),
    documentai.ProcessorSchema.Field(name="employers_name_address_and_zip_code", field_type="ADDRESS", occurrence="REQUIRED_MULTIPLE"),
    documentai.ProcessorSchema.Field(name="federal_income_tax_withheld", field_type="MONEY", occurrence="REQUIRED_MULTIPLE"),
    documentai.ProcessorSchema.Field(name="social_security_tax_withheld", field_type="MONEY", occurrence="REQUIRED_MULTIPLE"),
    documentai.ProcessorSchema.Field(name="social_security_wages", field_type="MONEY", occurrence="REQUIRED_MULTIPLE"),
    documentai.ProcessorSchema.Field(name="wages_tips_other_compensation", field_type="MONEY", occurrence="REQUIRED_MULTIPLE"),
])

req = documentai.UpdateProcessorRequest(
    processor=documentai.Processor(name=name, schema=schema),
    update_mask={"paths": ["schema"]}
)
resp = client.update_processor(request=req)
print("✅ Schema updated:", resp.name)
EOF

# 7. Import AutoLabel Dataset
echo "🔹 Importing AutoLabel dataset..."
gcloud documentai dataset import \
  --processor=$PROCESSOR_ID \
  --location=$LOCATION \
  --gcs-prefix=gs://cloud-samples-data/documentai/Custom/W2/AutoLabel

# 8. Import PreLabeled Dataset
echo "🔹 Importing PreLabeled dataset..."
gcloud documentai dataset import \
  --processor=$PROCESSOR_ID \
  --location=$LOCATION \
  --gcs-prefix=gs://cloud-samples-data/documentai/Custom/W2/JSON-2

# 9. Start Training
echo "🔹 Starting training..."
VERSION_NAME="w2-custom-model"
TRAIN_OP=$(gcloud documentai processor-versions train \
  --processor=$PROCESSOR_ID \
  --display-name=$VERSION_NAME \
  --data-split=auto \
  --location=$LOCATION \
  --format="value(name)")

echo "✅ Training job submitted: $TRAIN_OP"

# 10. Training Status Watcher
echo "🔹 Monitoring training status (this may take a while)..."
while true; do
  STATUS=$(gcloud documentai processor-versions describe $TRAIN_OP --location=$LOCATION --format="value(state)")
  echo "   Current Status: $STATUS"
  if [[ "$STATUS" == "DEPLOYED" ]] || [[ "$STATUS" == "FAILED" ]]; then
    break
  fi
  sleep 60
done

echo "✅ Final Training Status: $STATUS"

# 🎥 Banner End
echo "==============================================="
echo "✅ Lab Automation Complete!"
echo "🚀 Don't forget to Subscribe to Aminex"
echo "👉 https://www.youtube.com/@kamitabh244"
echo "==============================================="
