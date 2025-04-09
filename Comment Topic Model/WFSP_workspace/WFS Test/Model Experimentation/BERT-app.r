file.exists("www/custom.css")


# Define the list of required packages
required_packages <- c(
  "yaml",        # For YAML file handling
  "readr",       # For reading CSV files
  "dplyr",       # For data manipulation
  "stringr",     # For string operations
  "shiny",       # For web applications
  "bslib",       # For bootstrap styling in shiny apps
  "reticulate",  # For Python integration
  "shinyBS",     # For advanced bootstrap components
  "bsplus",      # For additional bootstrap features
  "reactable",   # For rendering interactive tables 
  "shinythemes",
  "htmltools"    # For creating HTML elements
)

# Function to install missing packages
install_if_missing <- function(pkg) {
  if (!require(pkg, character.only = TRUE)) {
    install.packages(pkg, repos = "https://cran.rstudio.com")
  }
}

# Install all missing packages
sapply(required_packages, install_if_missing)

# Load libraries
invisible(lapply(required_packages, library, character.only = TRUE))

# source_path = "/Volumes/edav_dev_ddnid_niosh/wfsp/datafiles/wfs_rfi_comments_rev2.csv",
# final_table = "/Volumes/edav_dev_ddnid_niosh/wfsp/datafiles/output/wfs_rfi_comments_rev2.csv",
# data_dir = "/Volumes/edav_dev_ddnid_niosh/wfsp/datafiles",
# output_path = "/Volumes/edav_dev_ddnid_niosh/wfsp/datafiles/output",
# output_folder = "2024-11-22",    

# source_path = "C:/Users/ytn7/OneDrive - CDC/CDC/Wildland Fire Comments/data/wfs_rfi_comments_rev2.csv",
# final_table = "C:/Users/ytn7/OneDrive - CDC/CDC/Wildland Fire Comments/data/output/wfs_rfi_comments_rev2.csv",
# data_dir = "C:/Users/ytn7/OneDrive - CDC/CDC/Wildland Fire Comments/data/output",
# output_path = "C:/Users/ytn7/OneDrive - CDC/CDC/Wildland Fire Comments/data/output",
# output_folder = "2024-11-22",    

# Write to the YAML file
config_data <- list(
    source_path = "/Volumes/edav_dev_ddnid_niosh/wfsp/datafiles/wfs_rfi_comments.csv",
    final_table = "/Volumes/edav_dev_ddnid_niosh/wfsp/datafiles/output/wfs_rfi_comments_rev2.csv",
    data_dir = "/Volumes/edav_dev_ddnid_niosh/wfsp/datafiles",
    output_path = "/Volumes/edav_dev_ddnid_niosh/wfsp/datafiles/output",
    output_folder = "2024-11-22",    
    BERT_calculate_probabilities = TRUE,
    BERT_cluster_selection_method = "eom",
    BERT_coherence = "u_mass",
    BERT_hdbscan_metric = "euclidean",
    BERT_min_cluster_size = 10,
    BERT_min_components = 5,
    BERT_min_dist = 0.5,
    BERT_min_samples = 1,
    BERT_min_topic_size = 10,
    BERT_model_name = "all-mpnet-base-v2",
    BERT_n_components = 5,
    BERT_n_neighbors = 10,
    BERT_nr_topics = 5,
    BERT_ngram_range_max = 3,
    BERT_ngram_range_min = 1,
    BERT_top_n_words = 20,
    BERT_umap_metric = "cosine",
    BERT_stopwords_path = "",
    BERT_stopwords_list = c("word1", "word2", "word3")
)

yaml_path <- "/Volumes/edav_dev_ddnid_niosh/wfsp/datafiles/config/config.yaml"
# yaml_path <- "C:/Users/ytn7/OneDrive - CDC/CDC/Wildland Fire Comments/data/config/config.yaml"

# Write the data to the YAML file (overwrite if it exists)
write_yaml(config_data, yaml_path)

# Print confirmation
cat("YAML file has been created/overwritten at:", yaml_path, "\n")

if (file.exists(yaml_path)) {
    config_list <- yaml.load_file(yaml_path)
    list2env(config_list, envir = .GlobalEnv)
} else {
    stop("YAML file not found: ", yaml_path)
}

output_dir <- file.path(output_path, output_folder)
print(output_dir)

# source_path <- "C:/Users/ytn7/OneDrive - CDC/CDC/Wildland Fire Comments/data/wfs_rfi_comments_rev2.csv"
# final_table <- "C:/Users/ytn7/OneDrive - CDC/CDC/Wildland Fire Comments/data/output/wfs_rfi_comments_rev2.csv"
# data_dir <- "C:/Users/ytn7/OneDrive - CDC/CDC/Wildland Fire Comments/data"
# output_path <- file.path(data_dir, "output")

app_dir <- getwd()
# css_path <- "/Workspace/DDNID/NIOSH/DSI/WFSP/WFS Test/Model Experimentation/www/custom.css"
# css_path <- "/Workspace/DDNID/NIOSH/DSI/WFSP/WFS Test/Model Experimentation/custom.css"
css_path <- "/dbfs/FileStore/custom.css"
# css_path <- "/Workspace/DDNID/NIOSH/DSI/WFSP/WFS Test/Model Experimentation/custom.css"
file.exists("/dbfs/FileStore/custom.css")
temp_text <- file.path(data_dir, "wfs_rfi_comments.csv")
get_attachments_path <- file.path(app_dir, "get_attachments.py")

utils::globalVariables(c(
    "Comment", "cluster_labelled", "Prob", "OtherW", "ForServ", "DuplGr",
    "Document_ID", "word1", "word2", "word3", "cluster", "top_docs_final"
))

# Initialize an empty data frame in case the file doesn't exist
top_docs_final <- data.frame()

# Load the data with proper error handling
tryCatch(
    {
        if (file.exists(final_table)) {
            top_docs_final <- read.csv(final_table, fileEncoding = "UTF-8")
            print(names(top_docs_final))
            top_docs_final <- top_docs_final %>%
                mutate(
                    cluster_labelled = as.character(cluster_labelled),
                    Prob = round(as.numeric(Prob), 2),
                    OtherW = str_replace_all(OtherW, "\\[|\\]", ""),
                    OtherW = str_replace_all(OtherW, "'", "")
                )
        } else {
            warning("Final table file not found: ", final_table)
        }
    },
    error = function(e) {
        warning("Error loading data: ", e$message)
        top_docs_final <<- data.frame()
    }
)

# Define the desired columns
required_columns <- c(
    "cluster", "Clean_comment", "First_Name", "Last_Name",
    "first_3_words", "OtherW", "ForServ", "DuplGr", "cluster_labelled"
)

# Identify existing columns in the dataset
existing_columns <- intersect(required_columns, colnames(top_docs_final))

# Select only the existing columns
selected_columns <- top_docs_final %>%
    select(all_of(existing_columns))

# Print message for missing columns
missing_columns <- setdiff(required_columns, colnames(top_docs_final))
if (length(missing_columns) > 0) {
    message("The following columns were not found and skipped: ", paste(missing_columns, collapse = ", "))
}

# ------------------------------

ui <- fluidPage(
    theme = bs_theme(bootswatch = "minty"),
    tags$head(
        tags$link(rel = "stylesheet", type = "text/css", href = css_path)
    ),
    div(
        class = "titlePanel",
        titlePanel(h1("Topic Modeling of Public Comments"))
    ),
    div(
        class = "wrapper",
        div(
            class = "sidebar",
            accordion(
                open = TRUE,
                accordion_panel(
                    "Load Data",
                    fluidRow(
                        column(
                            9,
                            textInput("path_input", "Source file path:", value = temp_text, width = "90%")
                            # textInput("path_input", "Enter file path:"),
                        ),
                        column(
                            3,
                            actionButton("loadData_button", "GO", class = "btn btn-primary w-100 mt-2")
                        )
                    ),
                    fluidRow(
                        column(
                            9,
                            p("Download all attachments from comments and extract text from them.")
                        ),
                        column(
                            3,
                            actionButton("runAttachmentsAndExtract", "GO", class = "btn btn-primary w-100 mt-2")
                        )
                    ),
                    fluidRow(
                        column(9),
                        column(
                            3,
                            actionButton("show_table_button", "Show Table", class = "btn btn-custom w-100 mt-2")
                        )
                    ),
                ),
                accordion_panel(
                    "Run Topic Modeling",
                    fluidRow(
                        column(
                            9,
                            textInput("outputfile_input", "Output filename:", width = "90%", placeholder = "C:/path/to/outputfile"),
                            textInput("stopwords_path_input", "Stopwords file path:", width = "90%", placeholder = "C:/path/to/stopwords")
                        ),
                        column(
                            3,
                            actionButton("runBERT", "Run BERT", class = "btn btn-primary w-100 mt-2")
                        )
                    ),
                    br(),
                    fluidRow(
                        column(
                            7,
                            textInput("stopwords_list_input", "Stopwords list:", width = "80%", placeholder = "Enter stopwords here"),
                            actionButton("stopwords_list_btn", "Add to list", class = "btn btn-primary")
                        ),
                        column(
                            5,
                            h6("Additional Stopwords", style = "color: #c0c0c0; font-size: 0.8em; text-align: center;"),
                            hr(),
                            verbatimTextOutput("stopwords_list_display")
                        )
                    ),
                    br(),
                    accordion(
                        accordion_panel(
                            "BERTopic Parameters",
                            p("Hover over the input fields to see descriptions."),
                            fluidRow(
                                column(
                                    6,
                                    selectInput("cluster_selection_method", "Cluster Selection Method",
                                        choices = c("eom" = "eom", "leaf" = "leaf"),
                                        selected = BERT_cluster_selection_method
                                    ),
                                    selectInput("umap_metric", "UMAP Metric",
                                        choices = c("euclidean", "cosine", "manhattan", "hamming"),
                                        selected = BERT_umap_metric
                                    ),
                                    selectInput("hdbscan_metric", "HDBSCAN Metric",
                                        choices = c("euclidean", "cosine", "manhattan", "hamming"),
                                        selected = BERT_hdbscan_metric
                                    ),
                                    selectInput("coherence", "Coherence",
                                        choices = c("u_mass", "c_v", "c_uci", "C_npmi"),
                                        selected = BERT_coherence
                                    ),
                                    numericInput("min_samples", "Minimum Samples",
                                        value = BERT_min_samples,
                                        min = 1
                                    ),
                                    numericInput("min_dist", "Minimum Distance",
                                        value = BERT_min_dist,
                                        min = 0.0, max = 1.0, step = 0.05
                                    ),
                                    numericInput("min_topic_size", "Minimum Topic Size",
                                        value = BERT_min_topic_size,
                                        min = 1, step = 1
                                    )
                                ),
                                column(
                                    6,
                                    sliderInput("n_neighbors", "Number of Neighbors",
                                        min = 5, max = 100,
                                        value = ifelse(is.null(BERT_n_neighbors), 10, BERT_n_neighbors),
                                        step = 5, ticks = FALSE
                                    ),
                                    sliderInput("n_components", "Number of Components",
                                        min = 2, max = 50,
                                        value = ifelse(is.null(BERT_n_components), 5, BERT_n_components),
                                        step = 1, ticks = FALSE
                                    ),
                                    sliderInput("min_cluster_size", "Minimum Cluster Size",
                                        min = 2, max = 250,
                                        value = ifelse(is.null(BERT_min_cluster_size), 10, BERT_min_cluster_size),
                                        step = 1, ticks = FALSE
                                    ),
                                    sliderInput("top_n_words", "Top N Words",
                                        min = 1, max = 50,
                                        value = ifelse(is.null(BERT_top_n_words), 20, BERT_top_n_words),
                                        step = 1, ticks = FALSE
                                    ),
                                    sliderInput("nr_topics", "Number of Topics",
                                        min = 1, max = 100,
                                        value = ifelse(is.null(BERT_nr_topics), 5, BERT_nr_topics),
                                        step = 1, ticks = FALSE
                                    )
                                )
                            )
                        )
                    )
                )
            )
        ),
        # Main content
        div(
            class = "main-content",
            navset_card_pill(
                nav_panel(
                    "Topic Table",
                    # fluidRow(
                    #     textInput("word1", "Search Word 1:", value = ""),
                    #     textInput("word2", "Search Word 2:", value = ""),
                    #     textInput("word3", "Search Word 3:", value = "")
                    # ),
                    reactableOutput("topic_table")
                ),
                nav_panel(
                    "Visual Outputs",
                    div(
                        uiOutput("image_outputs"),
                    )
                ),
                # nav_panel(
                #     "Render Table",
                #     tableOutput("ren_table")
                # )
            )
        )
    )
)

server <- function(input, output, session) {
    params <- list()

    # Function to handle path updates and config changes
    handlePathUpdate <- function(new_source_path, yaml_path) {
        # Check if the file exists
        if (!file.exists(new_source_path)) {
            showNotification("The specified file does not exist. Please check the path and try again.", type = "error")
            return(NULL)
        }

        # Update the global paths
        data_dir <<- dirname(new_source_path)
        filename <- basename(new_source_path)

        # Load the existing config and update the source path
        config <- yaml.load_file(yaml_path)
        config$source_path <- new_source_path
        write_yaml(config, yaml_path)

        # Update the params list with the new final_table path
        params$final_table <<- file.path(data_dir, "final_table.csv") # Adjust the file name as per your requirements

        # Print confirmations
        cat("Updated source_path in config.yaml to:", new_source_path, "\n")
        cat("Updated paths: \n", "Filename:", filename, "\n", "Data Directory:", data_dir, "\n")
        cat("Final table path:", params$final_table, "\n")

        # Show success notification
        showNotification("Paths updated successfully.", type = "message")
    }

    # Observe event to handle user input
    observeEvent(input$loadData_button, {
        req(input$path_input)

        # Call the combined function with user input and YAML file path
        handlePathUpdate(input$path_input, yaml_path)
    })

    observeEvent(input$swButton, {
        7
        words <- strsplit(input$words, "\n")[[1]] # Split the input text by new lines
        words_df <- data.frame(words = words) # Create a data frame

        # Save the data frame to a .csv file
        write.csv(words_df, file = "words.csv", row.names = FALSE)

        # Notify the user
        showModal(modalDialog(
            title = "Success",
            "The words have been saved to words.csv",
            easyClose = TRUE,
            footer = NULL
        ))
    })

    # Function to run the BERT.py script
    runBERTScript <- function() {
        py_run_file("BERT.py")
    }

    # Observe event to handle user input
    observeEvent(input$loadData_button, {
        req(input$path_input)

        # Call the combined function with user input and YAML file path
        handlePathUpdate(input$path_input, yaml_path)
    })

    observeEvent(input$runBERT, {
        runBERTScript()
        showNotification("BERT script has been executed.", type = "message")
    })

    observeEvent(input$swButton, {
        7
        words <- strsplit(input$words, "\n")[[1]] # Split the input text by new lines
        words_df <- data.frame(words = words) # Create a data frame

        # Save the data frame to a .csv file
        write.csv(words_df, file = "words.csv", row.names = FALSE)

        # Notify the user
        showModal(modalDialog(
            title = "Success",
            "The words have been saved to words.csv",
            easyClose = TRUE,
            footer = NULL
        ))
    })

# Render the Reactable table using the selected columns when the button is clicked
observeEvent(input$show_table_button, {
    output$topic_table <- renderReactable({
        req(selected_columns)
        reactable(selected_columns,
            columns = list(
                cluster = colDef(
                    width = 100, # Adjust the width of the cluster column
                    align = "center" # Center align the cluster column
                ),
                Clean_comment = colDef(
                    width = 800, # Add the percentage width
                ),
                First_Name = colDef(
                    width = 150, # Adjust the width of First_Name column
                    align = "center" # Center align the First_Name column
                ),
                Last_Name = colDef(
                    width = 150, # Adjust the width of Last_Name column
                    align = "center" # Center align the Last_Name column
                ),
                first_3_words = colDef(
                    width = 150, # Adjust the width of first_3_words column
                    align = "center" # Center align the first_3_words column
                ),
                OtherW = colDef(
                    width = 150, # Adjust the width of OtherW column
                    align = "center" # Center align the OtherW column
                ),
                ForServ = colDef(
                    width = 150, # Adjust the width of ForServ column
                    align = "center" # Center align the ForServ column
                ),
                DuplGr = colDef(
                    width = 150, # Adjust the width of DuplGr column
                    align = "center" # Center align the DuplGr column
                ),
                cluster_labelled = colDef(
                    width = 150, # Adjust the width of cluster_labelled column
                    align = "center" # Center align the cluster_labelled column
                )
            ),
            defaultColDef = colDef(
                align = "center" # Center align all other columns
            ),
            pagination = TRUE,
            searchable = TRUE,
            sortable = TRUE,
            highlight = TRUE,
            striped = TRUE,
            bordered = TRUE,
            compact = TRUE
        )
    })
})

    output$ren_table <- renderTable( # Render table
        top_docs_final, # Use filtered data
        striped = TRUE, # Add striped rows
        hover = TRUE, # Enable hover effect
        bordered = TRUE # Add borders
    )

    # Create www directory if it doesn't exist
    if (!dir.exists("www")) {
        dir.create("www")
    }

    # Define the output directory
    output_dir <- file.path(output_path, output_folder)
    print(output_dir)

    # Function to copy files to www directory
    copy_files_to_www <- function() {
        png_files <- list.files(output_dir, full.names = TRUE, pattern = "\\.png$")
        dest_files <- file.path("www", basename(png_files))

        mapply(function(src, dst) {
            if (!file.exists(dst) || file.mtime(src) > file.mtime(dst)) {
                file.copy(src, dst, overwrite = TRUE)
            }
        }, png_files, dest_files)

        return(basename(png_files))
    }

    # Reactive to manage files
    output_files <- reactive({
        copied_files <- copy_files_to_www()
        return(copied_files)
    })

    # Create a modal when image is clicked
    observeEvent(input$selected_image, {
        req(input$selected_image)
        showModal(modalDialog(
            tags$div(
                style = "text-align: center;",
                tags$img(
                    src = input$selected_image,
                    style = "max-width: 100%; height: auto;"
                )
            ),
            size = "l",
            easyClose = TRUE,
            footer = modalButton("Close")
        ))
    })

    # Render the thumbnail grid
    output$image_outputs <- renderUI({
        req(output_files())

        if (length(output_files()) == 0) {
            return(div(
                style = "text-align: center; color: #666; padding: 20px;",
                "No PNG files found in the output directory."
            ))
        }

        # Create thumbnail grid
        div(
            style = "display: grid; grid-template-columns: repeat(auto-fill, minmax(200px, 1fr)); gap: 20px; padding: 20px;",
            lapply(output_files(), function(filename) {
                div(
                    style = "background: white; padding: 10px; border-radius: 5px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); cursor: pointer; transition: transform 0.2s;",
                    class = "thumbnail-container",
                    onclick = sprintf("Shiny.setInputValue('selected_image', '%s');", filename),
                    tags$img(
                        src = filename,
                        style = "width: 100%; height: 150px; object-fit: contain;"
                    ),
                    div(
                        style = "text-align: center; margin-top: 10px; color: #666; font-size: 0.9em; word-break: break-word;",
                        filename
                    )
                )
            })
        )
    })
}

shinyApp(ui = ui, server = server)