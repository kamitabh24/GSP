#!/usr/bin/env python3
"""
Custom Document Extraction Lab Automation
Document AI Workbench – End to End
"""

print("🚀 Subscribe to Aminex Please: https://www.youtube.com/@kamitabh244")

from google.cloud import documentai_v1 as documentai

# -----------------------------------------------------------
# User input
# -----------------------------------------------------------
PROJECT_ID = input("👉 Enter your GCP Project ID: ").strip()
LOCATION = input("👉 Enter location (e.g. us, us-central1): ").strip()

client = documentai.DocumentProcessorServiceClient()
parent = f"projects/{PROJECT_ID}/locations/{LOCATION}"

# -----------------------------------------------------------
# 1. Create Processor
# -----------------------------------------------------------
def create_processor():
    processor = documentai.Processor(
        display_name="lab-custom-extractor",
        type_="CUSTOM_EXTRACTION_PROCESSOR",
    )
    response = client.create_processor(parent=parent, processor=processor)
    print("✅ Processor created:", response.name)
    return response.name

# -----------------------------------------------------------
# 2. Define schema (fields)
# -----------------------------------------------------------
def create_schema(processor_name):
    schema_client = documentai.SchemaServiceClient()
    schema = documentai.Schema(
        entity_types=[
            documentai.Schema.EntityType(
                name="control_number", value_type="NUMBER", occurrence_type="OPTIONAL_MULTIPLE"
            ),
            documentai.Schema.EntityType(
                name="employees_social_security_number", value_type="NUMBER", occurrence_type="REQUIRED_MULTIPLE"
            ),
            documentai.Schema.EntityType(
                name="employer_identification_number", value_type="NUMBER", occurrence_type="REQUIRED_MULTIPLE"
            ),
            documentai.Schema.EntityType(
                name="employers_name_address_and_zip_code", value_type="ADDRESS", occurrence_type="REQUIRED_MULTIPLE"
            ),
            documentai.Schema.EntityType(
                name="federal_income_tax_withheld", value_type="MONEY", occurrence_type="REQUIRED_MULTIPLE"
            ),
            documentai.Schema.EntityType(
                name="social_security_tax_withheld", value_type="MONEY", occurrence_type="REQUIRED_MULTIPLE"
            ),
            documentai.Schema.EntityType(
                name="social_security_wages", value_type="MONEY", occurrence_type="REQUIRED_MULTIPLE"
            ),
            documentai.Schema.EntityType(
                name="wages_tips_other_compensation", value_type="MONEY", occurrence_type="REQUIRED_MULTIPLE"
            ),
        ]
    )

    schema_name = f"{processor_name}/schema"
    response = schema_client.update_schema(name=schema_name, schema=schema)
    print("✅ Schema created for:", processor_name)
    return response

# -----------------------------------------------------------
# 3. Import Documents (from GCS)
# -----------------------------------------------------------
def import_documents(processor_name):
    dataset_client = documentai.DatasetServiceClient()

    gcs_input = documentai.GcsPrefix(
        gcs_uri="gs://cloud-samples-data/documentai/Custom/W2/PDF/"
    )
    input_config = documentai.BatchDocumentsInputConfig(gcs_prefix=gcs_input)

    dataset = f"{processor_name}/dataset"
    operation = dataset_client.import_documents(
        name=dataset,
        batch_documents_input_config=input_config,
    )

    print("⏳ Importing documents...")
    result = operation.result()
    print("✅ Documents imported:", result)

# -----------------------------------------------------------
# 4. Train processor version
# -----------------------------------------------------------
def train_processor(processor_name):
    pv_client = documentai.ProcessorVersionServiceClient()
    version = documentai.ProcessorVersion(
        display_name="w2-custom-model",
        document_schema=None
    )
    op = pv_client.train_processor_version(
        parent=processor_name, processor_version=version
    )
    print("⏳ Training started...")
    resp = op.result()
    print("✅ Training complete:", resp.name)
    return resp.name

# -----------------------------------------------------------
# Main Flow
# -----------------------------------------------------------
if __name__ == "__main__":
    processor_name = create_processor()
    create_schema(processor_name)
    import_documents(processor_name)
    train_processor(processor_name)

    print("🎉 Lab automation finished successfully!")
    print("🙏 End: Subscribe to Aminex Please https://www.youtube.com/@kamitabh244")
