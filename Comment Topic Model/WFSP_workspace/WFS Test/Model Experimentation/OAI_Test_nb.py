# Databricks notebook source
# MAGIC  %pip install openai azure-identity azure.mgmt.subscription
# MAGIC dbutils.library.restartPython()

# COMMAND ----------

import openai
import pandas as pd
import time
from typing import Dict, List
from azure.identity import ClientSecretCredential
from azure.identity import AzureCliCredential
from azure.mgmt.subscription import SubscriptionClient
import json

# COMMAND ----------

def setup_azure_openai() -> bool:
    """
    Sets up the Azure OpenAI configuration.
    Returns True on success, False on failure.
    """
    try:
        # Retrieve access token using Azure credentials
        credential = ClientSecretCredential(
            tenant_id="9ce70869-60db-44fd-abe8-d2767077fc8f",
            client_id="f2284312-fb8c-42fe-a4a2-aee3004e3c93",
            client_secret=dbutils.secrets.get(scope="dbs-scope-DDNID-NIOSH-WFSP", key="EDAV-NIOSH-DSI-WFSP-DEV-SP")
        )
        
        access_token = credential.get_token("https://cognitiveservices.azure.com/.default").token
        print("Access Token retrieved successfully.")
        
        openai.api_type = "azure_ad"
        openai.api_key = access_token
        openai.api_base = "https://edav-dev-openai-eastus2-shared.openai.azure.com/"
        openai.api_version = "2024-08-01-preview"
        print("Azure OpenAI configured successfully.")
        
    except Exception as e:
        print(f"Error in setting up Azure OpenAI: {str(e)}")
        return False
        
    return True

# COMMAND ----------

def process_comments_batch(comments: List[str], retries: int = 3) -> List[Dict]:
    """
    Process comments in batches with exactly 9 distinct topics.
    Each comment is assigned exactly one primary topic.
    
    Args:
        comments: List of comment strings to process
        retries: Number of retry attempts for API calls
        
    Returns:
        List of dictionaries containing topic assignments and confidence scores
    """
    BATCH_SIZE = 25
    all_results = []
    total_batches = (len(comments) + BATCH_SIZE - 1) // BATCH_SIZE

    TOPICS = [
        "general/non-specific",   
        "Health hazards",      
        "other controls besides ppe",
        "research needs",       
        "wildfire constituents",     
        "Exposures",     
        "Personal Protective Equipment",
        "health equity",        
        "mental health"     
    ]

    for batch_idx in range(0, len(comments), BATCH_SIZE):
        batch = comments[batch_idx:batch_idx + BATCH_SIZE]
        current_batch = batch_idx // BATCH_SIZE + 1
        print(f"\nProcessing batch {current_batch} of {total_batches}")

        formatted_comments = [f"{i + batch_idx}:{comment[:200]}" 
                            for i, comment in enumerate(batch)]
        comments_text = "\n".join(formatted_comments)
        
        prompt = f"""Analyze these wildfire smoke exposure comments.
        Available Topics: {', '.join(TOPICS)}
        
        Target Distribution:
        - general/non-specific: Most common topic, for broad guidelines and protocols
        - Health hazards: Second most common, for specific health risks
        - other controls besides ppe: Third most common, for administrative and engineering controls
        - research needs: Medium frequency, for knowledge gaps and study needs
        - wildfire constituents: Lower frequency, for smoke composition analysis
        - Exposures: Lower frequency, for exposure types and duration
        - Personal Protective Equipment: Lower frequency, for protective gear specifics
        - health equity: Less common, for access and disparity issues
        - mental health: Least common, only for clear mental health focus
        
        Rules:
        1. Assign EXACTLY ONE topic per comment - choose the MOST relevant topic
        2. Use comment_index starting from {batch_idx}
        3. Include confidence score (0.0-1.0)
        4. Only use topics from the provided list - no combinations or variations
        5. Choose topics according to the target distribution while maintaining relevance
        6. Respond with raw JSON only, no code blocks or formatting
        
        Topic Definitions:
        
        - General/Non-Specific: Covers broad safety guidelines and protocols to ensure the health and well-being of wildfire workers, including risk assessments, safety training, and response planning.
        - Health Hazards: Includes risks such as smoke inhalation, heat stress, dehydration, and long-term exposure to toxic chemicals and particulate matter that can affect respiratory and cardiovascular health.
        - Personal Protective Equipment: Focuses on protective gear like flame-resistant clothing, respirators, gloves, and helmets, ensuring proper use and availability to safeguard workers from physical and chemical hazards.
        - Research Needs: Highlights gaps in knowledge and the need for studies on long-term health effects, improved protective gear, exposure monitoring, and predictive safety models for dynamic wildfire conditions.
        - Wildfire Constituents: Examines hazardous components in wildfire smoke and debris, such as fine particulate matter (PM2.5), carbon monoxide, and volatile organic compounds, to assess and mitigate risks.
        - Exposures: Addresses the types, intensity, and duration of exposure to hazards like smoke, heat, and falling debris, emphasizing the need for accurate measurement and mitigation strategies.
        - Health Equity: Focuses on reducing disparities in access to safety resources, training, and healthcare, ensuring all wildfire workers, including those from underserved communities, are protected equally.
        - Mental Health: Stresses the importance of addressing psychological challenges like stress, PTSD, and anxiety faced by wildfire workers through counseling, peer support, and mental health programs.
        - Other Controls Besides PPE: Includes engineering controls, work practices, and administrative measures like air filtration systems, rotational shifts, and evacuation protocols to minimize hazards.

        Here are keywords for the topics to assist. No keywords for the 'General' topic so it doesn't interfere with the other topics.

        Keywords

        Health Hazards
        effects, respiratory, cardiovascular, disease, conditions, symptoms, lungs, illness, inflammation, mortality, morbidity, asthma, injury, breathing, function, adverse, chronic, acute, system, related

        Controls
        breaks, control, areas, systems, provide, measures, equipment, space, facilities, ventilation, prevention, protection, implementation, monitoring, management, procedures, standards, maintenance, operations, practices

        Research Needs
        studies, data, assessment, information, understanding, analysis, development, evaluation, evidence, methods, findings, testing, monitoring, results, investigation, knowledge, measurement, collection, documentation, recommendations

        Wildfire Constituents
        particulate, matter, pm2.5, pollutants, levels, components, concentration, particles, gases, compounds, emissions, chemical, organic, elements, composition, materials, substances, properties, characteristics, aerosols

        Exposures
        quality, monitoring, information, conditions, protection, levels, assessment, data, requirements, measures, control, tracking, surveillance, analysis, measurement, documentation, reporting, evaluation, indicators, trends
        
        PPE
        masks, filtration, protection, filters, equipment, respirators, devices, materials, systems, n95, gear, protective, products, components, design, testing, performance, standards, requirements, specifications

        Health Equity
        language, conditions, vulnerable, groups, individuals, access, resources, populations, communities, barriers, services, support, cultural, socioeconomic, demographics, disparities, needs, factors, status, differences

        Mental Health
        mental, physical, factors, effects, susceptibility, stress, anxiety, cognitive, psychological, emotional, depression, symptoms, conditions, behavioral, functioning, wellbeing, distress, response, trauma, indicators

        Comments:
        {comments_text}

        Return only a JSON array like:
        [
            {{"comment_index": 0, "topics": ["Worker Safety"], "confidence": 0.95}}
        ]"""

        for attempt in range(retries):
            try:
                print(f"\nAttempt {attempt + 1}:")
                response = openai.ChatCompletion.create(
                    engine="api-shared-gpt-4-turbo-nofilter",
                    messages=[
                        {"role": "system", "content": "You are a precise topic classifier. Assign exactly one topic per comment based on relevance and the target distribution pattern. Focus on identifying the most appropriate topic while maintaining natural frequency patterns."},
                        {"role": "user", "content": prompt}
                    ],
                    temperature=0.3,
                    max_tokens=2048
                )
                
                if response and "choices" in response and response.choices:
                    raw_response = response.choices[0].message["content"].strip()
                    print(f"API Response received. Length: {len(raw_response)} characters")
                    
                    # Clean response
                    if "```" in raw_response:
                        raw_response = raw_response.replace("```json", "").replace("```", "").strip()
                    
                    # Extract JSON array
                    start_idx = raw_response.find('[')
                    end_idx = raw_response.rfind(']') + 1
                    if start_idx != -1 and end_idx > start_idx:
                        raw_response = raw_response[start_idx:end_idx]
                    
                    try:
                        batch_results = json.loads(raw_response)
                        print(f"Successfully parsed JSON with {len(batch_results)} results")
                        
                        # Validate results
                        if len(batch_results) == len(batch):
                            # Ensure exactly one valid topic per comment
                            for result in batch_results:
                                if not isinstance(result['topics'], list) or len(result['topics']) != 1 or result['topics'][0] not in TOPICS:
                                    result['topics'] = [TOPICS[0]]  # Default to first topic if invalid
                                    result['confidence'] = 0.5
                                    
                            all_results.extend(batch_results)
                            print(f"Successfully processed batch {current_batch}")
                            break
                        else:
                            raise ValueError("Results count mismatch")
                            
                    except json.JSONDecodeError as je:
                        print(f"JSON parsing error: {je}")
                        raise
                        
            except Exception as e:
                print(f"Error in attempt {attempt + 1}: {str(e)}")
                if attempt < retries - 1:
                    wait_time = 2 ** attempt
                    print(f"Waiting {wait_time} seconds before retry...")
                    time.sleep(wait_time)
        
        if len(all_results) < batch_idx + len(batch):
            print(f"All attempts failed for batch {current_batch}. Creating error entries.")
            error_results = [
                {"comment_index": i + batch_idx, "topics": [TOPICS[0]], "confidence": 0.0}
                for i in range(len(batch))
            ]
            all_results.extend(error_results)

        if current_batch < total_batches:
            print("Waiting 2 seconds before next batch...")
            time.sleep(2)

    return all_results

# COMMAND ----------

def process_comments(input_data, output_path: str) -> None:
    """
    Processes comments and saves results to a CSV file with enhanced error handling
    and data validation.
    
    Args:
        input_data: Either a file path (str) or a pandas DataFrame containing comments
        output_path: Path where the output CSV will be saved
    """
    try:
        # Load data
        if isinstance(input_data, str):
            df = pd.read_csv(input_data)
        elif isinstance(input_data, pd.DataFrame):
            df = input_data
        else:
            raise ValueError("input_data must be a file path (str) or a Pandas DataFrame.")

        # Process comments
        if setup_azure_openai():
            print("Azure OpenAI setup successful, proceeding with processing...")
            
            comments_list = df['comments'].tolist()
            results = process_comments_batch(comments_list)
            
            # Convert results to DataFrame format
            output_records = []
            for result in results:
                output_records.append({
                    'comment_id': result['comment_index'] + 1,
                    'topic': result['topics'][0],
                    'confidence': max(0.0, min(1.0, float(result.get('confidence', 0.0)))),
                    'original_text': comments_list[result['comment_index']]
                })
            
            # Create and save DataFrame
            output_df = pd.DataFrame(output_records)
            output_df.to_csv(output_path, index=False)
            print(f"Results saved to {output_path}")
            
            # Print topic distribution summary
            topic_counts = output_df['topic'].value_counts()
            print("\nTopic Distribution Summary:")
            print(topic_counts.to_string())
            print(f"\nTotal unique topics: {len(topic_counts)}")
            
        else:
            print("Azure OpenAI setup failed. Cannot proceed with processing.")
            
    except Exception as e:
        print(f"Error in processing comments: {str(e)}")
        raise

# COMMAND ----------

input_path = "/Volumes/edav_dev_ddnid_niosh/wfsp/datafiles/wfs-rfi-co.csv"
output_path = "/Volumes/edav_dev_ddnid_niosh/wfsp/datafiles/output/wfs-rfi_oai.csv"

process_comments(input_path, output_path)

# COMMAND ----------

# setup_azure_openai()

# try:
#     response = openai.ChatCompletion.create(
#         engine="api-shared-gpt-4-turbo-nofilter",  # Replace with your deployment name
#         messages=[
#             {"role": "system", "content": "You are a helpful assistant."},
#             {"role": "user", "content": "Test message"}
#         ],
#         temperature=0.3,
#         max_tokens=100
#     )
#     print("API call successful. Response:", response)
# except openai.error.OpenAIError as e:
#     print(f"OpenAI API Error: {e}")