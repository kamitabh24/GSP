#!/bin/bash
# --------------------------------------
# Google Cloud Document AI - GSP1142 Ultimate Automation
# Master Script (Shell + Python)
# --------------------------------------

# 🎥 YouTube Subscribe Banner (Start)
echo "==============================================="
echo "   🚀 Subscribe to Aminex YouTube Channel!"
echo "   👉 https://www.youtube.com/@kamitabh244"
echo "==============================================="

# 1. Enable Document AI API
echo "🔹 Enabling Document AI API..."
gcloud services enable documentai.googleapis.com

# 2. Install Python Client
echo "🔹 Installing Python Client..."
pip3 install --upgrade google-cloud-documentai

# 3. Set Vars
PROJECT_ID=$(gcloud config get-value project)
LOCATION="us"
PROCESSOR_NAME="lab-custom-extractor"
PROCESSOR_TYPE="CUSTOM_EXTRACTION_PROCESSOR"

echo "🔹 Project: $PROJECT_ID"
echo "🔹 Location: $LOCATION"

# 4. Create Processor
echo "🔹 Creating Custom Extractor Processor..."
PROCESSOR_FULL=$(gcloud documentai processors create \
  --display-name=$PROCESSOR_NAME \
  --type=$PROCESSOR_TYPE \
  --location=$LOCATION \
  --format="value(name)")

PROCESSOR_ID=$(echo $PROCESSOR_FULL | awk -F/ '{print $NF}')
echo "✅ Processor created: $PROCESSOR_ID"

# 5. Download Data
echo "🔹 Downloading sample documents..."
mkdir -p data
cd data
gsutil cp gs://cloud-samples-data/documentai/Custom/W2/PDF/W2_XL_input_clean_2950.pdf .
gsutil -m cp -r gs://cloud-samples-data/documentai/Custom/W2/AutoLabel ./AutoLabel
gsutil -m cp -r gs://cloud-samples-data/documentai/Custom/W2/JSON-2 ./PreLabeled
cd ..

# 6. Create Schema with Python
echo "🔹 Defining processor schema..."
PROJECT_ID=$PROJECT_ID PROCESSOR_ID=$PROCESSOR_ID python3 <<'EOF'
from google.cloud import documentai_v1 as documentai
import os

project_id = os.getenv("PROJECT_ID")
location = "us"
processor_id = os.getenv("PROCESSOR_ID")

client = documentai.DocumentProcessorServiceClient()
processor_name = client.processor_path(project_id, location, processor_id)

schema = documentai.ProcessorSchema(
    fields=[
        documentai.ProcessorSchema.Field(name="control_number", field_type="NUMBER", occurrence="OPTIONAL_MULTIPLE"),
        documentai.ProcessorSchema.Field(name="employees_social_security_number", field_type="NUMBER", occurrence="REQUIRED_MULTIPLE"),
        documentai.ProcessorSchema.Field(name="employer_identification_number", field_type="NUMBER", occurrence="REQUIRED_MULTIPLE"),
        documentai.ProcessorSchema.Field(name="employers_name_address_and_zip_code", field_type="ADDRESS", occurrence="REQUIRED_MULTIPLE"),
        documentai.ProcessorSchema.Field(name="federal_income_tax_withheld", field_type="MONEY", occurrence="REQUIRED_MULTIPLE"),
        documentai.ProcessorSchema.Field(name="social_security_tax_withheld", field_type="MONEY", occurrence="REQUIRED_MULTIPLE"),
        documentai.ProcessorSchema.Field(name="social_security_wages", field_type="MONEY", occurrence="REQUIRED_MULTIPLE"),
        documentai.ProcessorSchema.Field(name="wages_tips_other_compensation", field_type="MONEY", occurrence="REQUIRED_MULTIPLE"),
    ]
)

update_request = documentai.UpdateProcessorRequest(
    processor=documentai.Processor(name=processor_name, schema=schema),
    update_mask={"paths": ["schema"]}
)

updated = client.update_processor(request=update_request)
print("✅ Schema updated for processor:", updated.name)
EOF

# 7. Import AutoLabel Data
echo "🔹 Importing AutoLabel dataset..."
gcloud documentai dataset import \
  --processor=$PROCESSOR_ID \
  --location=$LOCATION \
  --gcs-prefix=gs://cloud-samples-data/documentai/Custom/W2/AutoLabel

# 8. Import Pre-Labeled Data
echo "🔹 Importing Pre-Labeled dataset..."
gcloud documentai dataset import \
  --processor=$PROCESSOR_ID \
  --location=$LOCATION \
  --gcs-prefix=gs://cloud-samples-data/documentai/Custom/W2/JSON-2

# 9. Start Training
echo "🔹 Starting training job..."
gcloud documentai processor-versions train \
  --processor=$PROCESSOR_ID \
  --display-name="w2-custom-model" \
  --data-split=auto \
  --location=$LOCATION

echo "✅ Training submitted. Check status with:"
echo "gcloud documentai processor-versions list --processor=$PROCESSOR_ID --location=$LOCATION"

# 🎥 YouTube Subscribe Banner (End)
echo "==============================================="
echo "   ✅ Setup Complete!"
echo "   🚀 Don't forget to Subscribe to Aminex"
echo "   👉 https://www.youtube.com/@kamitabh244"
echo "==============================================="
