from shiny import App, Inputs, Outputs, Session, render, ui, reactive
import subprocess
import os
from pathlib import Path
import yaml
import time
import pandas as pd

import re
from htmltools import HTML

app_dir = Path(__file__).parent

attachmentDL_path = app_dir / "1-attachments.py"
pdf_to_text_path = app_dir / "2-PDFtoText.py"

header_text = "C:\\Users\\ytn7\\OneDrive - CDC\\CDC\\Wildland FIre Comments\\data\\dog_comments_500rows.csv"
test_output_path = "C:\\Users\\ytn7\\OneDrive - CDC\\CDC\\Wildland FIre Comments\\data\\test_output_rev2.csv"

theme = "minty"

cardCol1 = 9
cardCol2 = 3

# Read and preprocess data
comments_table = pd.read_csv(test_output_path, encoding="UTF-8")
comments_table['cluster_labelled'] = comments_table['cluster_labelled'].astype(str)
comments_table['Prob'] = pd.to_numeric(comments_table['Prob']).round(2)
comments_table['OtherW'] = comments_table['OtherW'].fillna('').str.replace(r'[\[\]\']', '', regex=True)

# Define the path for the YAML file
yaml_path = app_dir / "config.yaml"

# Define params with default values
default_params = {
    'path': '',
    'filename': '',
    'data_dir': '',
    'BERT': {
        'n_neighbors': 10,
        'n_components': 5,
        'min_dist': 0.5,
        'umap_metric': 'cosine',
        'hdbscan_metric': 'euclidean',
        'min_cluster_size': 10,
        'min_samples': 1,
        'cluster_selection_method': 'eom',
        'calculate_probabilities': True,
        'ngram_range_min': 1,
        'ngram_range_max': 3,
        'min_topic_size': 10,
        'nr_topics': 5,
        'top_n_words': 10,
        'output_path': '',
        'stopwords_path': '',
        'stopwords_list': ['word1', 'word2', 'word3'],
    }
}

# def ensure_yaml_file(yaml_path, default_params):
#     # # Check if the YAML file exists
#     # if not os.path.exists(yaml_path):
#     #     # If it doesn't exist, create it with the default parameters
#     #     with open(yaml_path, 'w') as file:
#     #         yaml.dump(default_params, file)
#     #     config = default_params
#     # else:
#     #     # If it exists, read the file
#     #     with open(yaml_path, 'r') as file:
#     #         config = yaml.safe_load(file)
            
#     with open(yaml_path, 'w') as file:
#             yaml.dump(default_params, file)
#         config = default_params
        
#         # Update the current parameters with any missing default parameters
#         def update_params(current, default):
#             if current is None:
#                 current = {}  # Initialize as an empty dictionary if it's None
#             for key, value in default.items():
#                 if isinstance(value, dict):
#                     current[key] = update_params(current.get(key, {}), value)
#                 else:
#                     current.setdefault(key, value)
#             return current
        
#         config = update_params(config, default_params)
        
#         # Write the updated parameters back to the YAML file
#         with open(yaml_path, 'w') as file:
#             yaml.dump(config, file)
    
#     return config

def ensure_yaml_file(yaml_path, default_params):
    with open(yaml_path, 'w') as file:
        yaml.dump(default_params, file)
    
    config = default_params  # Correctly aligned this line with the above block
    
    # Update the current parameters with any missing default parameters
    def update_params(current, default):
        if current is None:
            current = {}  # Initialize as an empty dictionary if it's None
        for key, value in default.items():
            if isinstance(value, dict):
                current[key] = update_params(current.get(key, {}), value)
            else:
                current.setdefault(key, value)
        return current

    config = update_params(config, default_params)

    # Write the updated parameters back to the YAML file
    with open(yaml_path, 'w') as file:
        yaml.dump(config, file)
        
    # Extract BERT
    BERT = default_params['BERT']

    # Loop through the parameters and add them to globals()
    for key, value in BERT.items():
        globals()[key] = value
    
    return config

# Ensure the YAML file is created and updated with default parameters
config = ensure_yaml_file(yaml_path, default_params)

# Get the output_path from the config
output_path = config.get('BERT', {}).get('output_path', '')

# Load the data from the output_path
if os.path.exists(output_path):
    output_file = pd.read_csv(output_path)
else:
    output_file = pd.DataFrame()  # Handle the case where the file doesn't exist
    
# ----------------------------------------------------------------------------------------------------
app_ui = ui.page_fluid(
    # ----------------------------------------------------------------------------------------------------
    ui.tags.head(
        ui.tags.link(rel="stylesheet", href=f"https://stackpath.bootstrapcdn.com/bootswatch/4.5.2/{theme}/bootstrap.css"),
    ),
    # ui.include_css(app_dir / "bootstrap.css"),
    ui.include_css(app_dir / "custom.css"),
    ui.panel_title("Topic Modeling of Public Comments"),
    ui.row(
        ui.column(
            3,
            ui.accordion(
                ui.accordion_panel(
                    "Load Data",
                    ui.row(
                        ui.column(
                            cardCol1,
                            ui.div(
                                ui.input_text("path_input", "Source file path:", value=header_text, width="90%"),
                            ),
                        ),
                        ui.column(
                            3,
                            ui.input_action_button("runLoadData", "GO", class_="btn btn-primary w-100 mt-2"),
                        )
                    ),
                    class_="accordion-panel",
                    open=True,
                ),

# --------------------------------------------------------------------------------

                ui.accordion_panel(
                    "Download Attachments and Extract Text",
                    ui.row(
                        ui.column(
                            cardCol1,
                            "Download all attachments from comments and extract text from them.",
                        ),
                        ui.column(
                            cardCol2,
                            ui.input_action_button("runAttachmentsAndExtract", "GO", class_="btn btn-primary w-100 mt-2")
                        )
                    ),
                    class_="accordion-panel",
                    open=True,
                ),

# --------------------------------------------------------------------------------

                ui.accordion_panel(
                    "Run Topic Modeling",
                    ui.row(
                        ui.column(
                            cardCol1,
                            ui.input_text("outputfile_input", "Output filename:", width="90%", placeholder="C:/path/to/outputfile"),
                            ui.input_text("stopwords_path_input", "Stopwords file path:", width="90%", placeholder="C:/path/to/stopwords"),
                        ),
                        ui.column(
                            cardCol2,
                            ui.input_action_button("runBERT", "GO", class_="btn btn-primary w-100 mt-2")
                        ),
                        ui.div(
                            ui.hr(style="border-bottom: 1px solid #e0e0e0; width: 95%; align-self: center;"),
                            style="display: flex; justify-content: center;"
                        ),
                        ui.row(
                            ui.column(
                                7,
                                ui.input_text("stopwords_list_input", "Stopwords list:", width="80%", placeholder="Enter stopwords here"),
                                ui.input_action_button("stopwords_list_btn", "Add to list", class_="btn btn-primary w-40"),
                            ),
                            ui.column(
                                5,
                                ui.h6("Additional Stopwords", style="color: #969696; font-size: 0.8em; text-align: center; text-decoration: underline;"),
                                ui.output_text("stopwords_list_display"),
                            )
                        ),

# --------------------------------------------------------------------------------

                        ui.div(style="padding-top: 20px;"),
                        ui.accordion(
                            ui.accordion_panel(
                                "BERTopic Parameters",
                                ui.h6("Hover over the input fields to see the tooltip text.", style="color: #707070; font-size: 0.9em; text-align: center;"),
                                ui.div(style="padding-top: 10px;"),
                                ui.layout_columns(
                                    ui.div(
                                        ui.panel_well(
                                            ui.tooltip(ui.input_select("cluster_selection_method", "cluster_selection_method", choices=["eom", "leaf"], selected=default_params['BERT']['cluster_selection_method']), "Select the method for cluster selection.", placement="right"),
                                            ui.tooltip(ui.input_select("metric", "metric", choices=["euclidean", "cosine", "manhattan", "hamming"], selected=default_params['BERT']['metric']), "Select the distance metric.", placement="right"),
                                            ui.tooltip(ui.input_numeric("min_samples", "min_samples", value=default_params['BERT']['min_samples'], min=1), "Minimum number of samples in a cluster.", placement="right"),
                                            ui.tooltip(ui.input_numeric("min_dist", "min_dist", value=default_params['BERT']['min_dist'], min=0.0, max=1.0, step=0.05), "Minimum distance between points.", placement="right"),
                                            ui.tooltip(ui.input_numeric("min_topic_size", "min_topic_size", value=default_params['BERT']['min_topic_size'], min=1, step=1), "Minimum size of a topic.", placement="right"),
                                            ui.tooltip(ui.input_slider("ngram_range", "ngram_range", min=ngram_range_min, max=5, value=[ngram_range_min, ngram_range_max], step=1), "Placeholder tooltip text", placement="right")
                                        ),
                                    ),

# --------------------------------------------------------------------------------

                                    ui.panel_well(
                                        ui.tooltip(ui.input_slider("n_neighbors", "n_neighbors", min=5, max=100, value=default_params['BERT']['n_neighbors'], step=5), "Number of neighbors for UMAP.", placement="right"),
                                        ui.tooltip(ui.input_slider("n_components", "n_components", min=2, max=50, value=default_params['BERT']['n_components'], step=1), "Number of components for UMAP.", placement="right"),
                                        ui.tooltip(ui.input_slider("min_cluster_size", "min_cluster_size", min=2, max=250, value=default_params['BERT']['min_cluster_size'], step=1), "Minimum cluster size.", placement="right"),
                                        ui.tooltip(ui.input_slider("top_n_words", "top_n_words", min=1, max=50, value=default_params['BERT']['top_n_words'], step=1), "Top N words per topic.", placement="right"),
                                        ui.tooltip(ui.input_slider("nr_topics", "nr_topics", min=1, max=100, value=default_params['BERT']['nr_topics'], step=1), "Number of topics.", placement="right"),
                                    ),
                                ),
                                class_="custom-accordion-panel",
                            ),
                        ),
                        class_="accordion-panel custom-accordion-button",
                        open=True,
                    ),
                    class_="accordion-panel",
                    open=True,
                ),
                class_="accordion",
                open=True,
            ),
        ),

# --------------------------------------------------------------------------------

        ui.column(
            9,
            ui.card(
                ui.card_header("Comments Table"),
                ui.layout_sidebar(
                    ui.sidebar(
                        ui.input_select(
                            'cluster', 
                            'Select Topic:', 
                            choices=["All"] + list(comments_table['cluster_labelled'].unique())
                        ),
                    ),
                    ui.output_data_frame("comments_output"),
                ),
                style="height: 100%; max-height: 80vh;"  # Ensure the card does not extend indefinitely
            )
        )
    )
)

# ----------------------------------------------------------------------------------------------------
def server(input: Inputs, output: Outputs, session: Session):
# ----------------------------------------------------------------------------------------------------

    path_input_reactive = reactive.Value("")
    data_reactive = reactive.Value(None)
    
    @output
    @render.data_frame
    def comments_output():
        # Filter the comments_table to include only the desired columns
        # filtered_comments = comments_table[['Title', 'First_Name', 'Last_Name', 'Clean_comment', 'Attachment_Files', 'cluster', 'Prob', 'ID', 'Is_Duplicated', 'FormattedDate', 'OtherW', 'ForServ', 'DuplGr', 'cluster_labelled']]
        filtered_comments = comments_table[['Title', 'First_Name', 'Last_Name', 'Clean_comment', 'cluster', 'Prob', 'cluster_labelled']]
        return render.DataTable(filtered_comments, height="100vh", width="100%", selection_mode="row")
    
# --------------------------------------------------------------------------------
    def load_data():
        path = input.path_input()
        filename = os.path.basename(path)
        data_dir = os.path.dirname(path)
        code_dir = os.path.dirname(app_dir)

        config_path = os.path.join(app_dir, 'config.yaml')

        with open(config_path, 'r') as file:
            config = yaml.safe_load(file)

        config['path'] = path
        config['filename'] = filename
        config['data_dir'] = data_dir
        config['code_dir'] = code_dir

        with open(config_path, 'w') as file:
            yaml.safe_dump(config, file)

# --------------------------------------------------------------------------------

    @reactive.Effect
    @reactive.event(input.runLoadData)
    def _():
        load_data()

# --------------------------------------------------------------------------------

    @output
    @render.text
    def path_input_display():
        return f"Path: {input.path_input()}"

# --------------------------------------------------------------------------------

    @reactive.Effect
    @reactive.event(input.runAttachmentsAndExtract)
    def run_attachments_and_extract():
        path_input = path_input_reactive.get()
        
        if not path_input:
            ui.modal_show(ui.modal(
                ui.p("Please load the data first."),
                title="Error",
                easy_close=True,
            ))
            return
        
        # Set the current working directory to the directory containing the R script
        os.chdir(os.path.dirname(attachmentDL_path))
        
        # Download attachments
        command = f'Rscript attachmentsDL.R "{path_input}"'
        try:
            result_attachments = subprocess.run(command, shell=True, check=True, capture_output=True, text=True)
            
            # Extract text from PDFs
            result_pdf = subprocess.run(["python", str(pdf_to_text_path)], capture_output=True, text=True, check=True)
            
            ui.modal_show(ui.modal(
                ui.p("Attachments downloaded and text extracted successfully."),
                ui.p("Attachments Output:"),
                ui.pre(result_attachments.stdout),
                ui.p("PDF Extraction Output:"),
                ui.pre(result_pdf.stdout),
                title="Execution Result",
                easy_close=True,
            ))
        except subprocess.CalledProcessError as e:
            ui.modal_show(ui.modal(
                ui.p("Execution failed."),
                ui.p("Error:"),
                ui.pre(e.stderr),
                title="Execution Error",
                easy_close=True,
            ))
        except Exception as e:
            ui.modal_show(ui.modal(
                ui.p(f"An unexpected error occurred: {str(e)}"),
                title="Unexpected Error",
                easy_close=True,
            ))

# --------------------------------------------------------------------------------

    @reactive.Effect
    @reactive.event(input.stopwords_list_btn)
    def add_stopword():
        new_stopword = input.stopwords_list_input().strip()
        if new_stopword:
            # Read the existing config.yaml file
            with open(yaml_path, 'r') as file:
                config = yaml.safe_load(file)
            
            stopwords_list = config.get('BERT', {}).get('stopwords_list', [])
            stopwords_list.append(new_stopword)
            
            # Update the config with the new stopwords list
            config['BERT']['stopwords_list'] = stopwords_list
            
            # Write the updated config back to the config.yaml file
            with open(yaml_path, 'w') as file:
                yaml.safe_dump(config, file)
            
            # Clear the input text box
            input.stopwords_list_input.set('')

            # Invalidate the stopwords_list_display to force re-render
            reactive.invalidate_later(0.1, stopwords_list_display)

    @output
    @render.text
    def stopwords_list_display():
        # Read the existing config.yaml file
        with open(yaml_path, 'r') as file:
            config = yaml.safe_load(file)
        
        stopwords_list = config.get('BERT', {}).get('stopwords_list', [])
        return ', '.join(stopwords_list)

# --------------------------------------------------------------------------------

    @reactive.Effect
    @reactive.event(input.runBERT)
    def runBERT():
        params = {
            "n_neighbors": input.n_neighbors(),
            "n_components": input.n_components(),
            "min_dist": input.min_dist(),
            "metric": input.metric(),
            "min_cluster_size": input.min_cluster_size(),
            "min_samples": input.min_samples(),
            "cluster_selection_method": input.cluster_selection_method(),
            "calculate_probabilities": input.calc_probabilities(),
            "ngram_range_min": input.ngram_range_min(),
            "ngram_range_max": input.ngram_range_max(),
            "min_topic_size": input.min_topic_size(),
            "nr_topics": input.nr_topics(),
            "output_path": input.outputfile_input(),
            "stopwords_path": input.stopwords_path_input(),
            "stopwords_list": input.stopwords_list_input().split(','),  # Assuming comma-separated input
            "top_n_words": input.top_n_words(),
        }

        # Define the path to the config.yaml file
        config_path = os.path.join(app_dir, 'config.yaml')

        # Read the existing config.yaml file
        with open(config_path, 'r') as file:
            config = yaml.safe_load(file)

        # Update the BERT in the config
        if 'BERT' not in config:
            config['BERT'] = {}
        config['BERT'].update(params)

        # Write the updated config back to the config.yaml file
        with open(config_path, 'w') as file:
            yaml.safe_dump(config, file)

        # Run the 3-BERT-exp.py script
        try:
            bert_script_path = app_dir / "3-BERT-test.py"
            result = subprocess.run(["python", str(bert_script_path)], capture_output=True, text=True, check=True)
            
            # Reload the output file after BERT script execution
            load_data()
            
            # Show success message
            m = ui.modal(
                ui.p("BERT script executed successfully."),
                ui.p("Output:"),
                ui.pre(result.stdout),
                title="Execution Result",
                easy_close=True,
            )
            ui.modal_show(m)
        except subprocess.CalledProcessError as e:
            # Show error message
            m = ui.modal(
                ui.p("BERT script execution failed."),
                ui.p("Error:"),
                ui.pre(e.stderr),
                title="Execution Error",
                easy_close=True,
            )
            ui.modal_show(m)
        except Exception as e:
            # Show unexpected error message
            m = ui.modal(
                ui.p(f"An unexpected error occurred: {str(e)}"),
                title="Unexpected Error",
                easy_close=True,
            )
            ui.modal_show(m)

# --------------------------------------------------------------------------------

    @reactive.Calc
    def filtered_data():
        word1 = input.word1()
        word2 = input.word2()
        word3 = input.word3()
        
        filtered_df = comments_table[
            comments_table['Comment'].str.contains(word1, case=False, na=False) &
            comments_table['Comment'].str.contains(word2, case=False, na=False) &
            comments_table['Comment'].str.contains(word3, case=False, na=False)
        ]
        
        if input.cluster() == "All":
            return filtered_df[["Document_ID", "Comment", "ForServ", "OtherW", "Prob", "DuplGr"]]
        
        return filtered_df[
            filtered_df['cluster_labelled'] == input.cluster()
        ][["Document_ID", "Comment", "ForServ", "OtherW", "Prob", "DuplGr"]].sort_values("Prob", ascending=False)

# --------------------------------------------------------------------------------

    @output
    @render.data_frame
    def table():
        df = filtered_data()
        return render.DataGrid(
            df,
            row_selection_mode="multiple",
            height="100%",
            width="100%",
            filters=True,
            summary=False,
            highlight=True,
            page_size=25,
        )

# --------------------------------------------------------------------------------

    @reactive.Effect
    @reactive.event(input.word1, input.word2, input.word3)
    def _():
        words = [input.word1(), input.word2(), input.word3()]
        for i, word in enumerate(words, 1):
            if word:
                ui.update_text(f"word{i}", value=HTML(f"<mark>{word}</mark>"))

# ----------------------------------------------------------------------------------------------------

app = App(app_ui, server)