#!/bin/bash
echo ""
echo "🚀 Custom Document Extraction Lab (GSP1142)"
echo "🙏 Subscribe to Aminex Please: https://www.youtube.com/@kamitabh244"
echo ""

# ---------------------------------------------------------
# User Inputs
# ---------------------------------------------------------
read -p "👉 Enter your GCP Project ID: " PROJECT_ID
read -p "👉 Enter location (us or eu, e.g. us): " LOCATION

# ---------------------------------------------------------
# Enable APIs + Install SDK
# ---------------------------------------------------------
echo "✅ Enabling Document AI API..."
gcloud services enable documentai.googleapis.com

echo "✅ Installing Python SDK..."
pip3 install --upgrade google-cloud-documentai

# ---------------------------------------------------------
# Download sample W2 docs (for upload / import)
# ---------------------------------------------------------
echo "📥 Downloading W-2 sample PDFs..."
gcloud storage cp gs://cloud-samples-data/documentai/Custom/W2/PDF/W2_XL_input_clean_2950.pdf .
gcloud storage cp -r gs://cloud-samples-data/documentai/Custom/W2/AutoLabel ./AutoLabel
gcloud storage cp -r gs://cloud-samples-data/documentai/Custom/W2/JSON-2 ./JSON-2

# ---------------------------------------------------------
# Instructions to user (because schema & training require UI)
# ---------------------------------------------------------
echo ""
echo "⚡ NEXT STEPS (Manual in Console Workbench UI):"
echo "1️⃣ Go to Console → Navigation → Document AI"
echo "2️⃣ Create a Custom Extractor processor → Name: lab-custom-extractor → Location: $LOCATION"
echo "3️⃣ Define Schema fields:"
echo "   - control_number (Number, Optional multiple)"
echo "   - employees_social_security_number (Number, Required multiple)"
echo "   - employer_identification_number (Number, Required multiple)"
echo "   - employers_name_address_and_zip_code (Address, Required multiple)"
echo "   - federal_income_tax_withheld (Money, Required multiple)"
echo "   - social_security_tax_withheld (Money, Required multiple)"
echo "   - social_security_wages (Money, Required multiple)"
echo "   - wages_tips_other_compensation (Money, Required multiple)"
echo "4️⃣ Upload sample W2_XL_input_clean_2950.pdf → Annotate fields manually"
echo "5️⃣ Build processor version with Foundation Model (name: w2-foundation-model)"
echo "6️⃣ Import AutoLabel data (./AutoLabel) with auto-labeling enabled"
echo "7️⃣ Import Prelabeled JSON data (./JSON-2)"
echo "8️⃣ Train New Version (name: w2-custom-model)"
echo ""
echo "🎉 Done! Your Custom Document Extractor processor will train (takes hours)."
echo "🙏 End: Subscribe to Aminex Please: https://www.youtube.com/@kamitabh244"
