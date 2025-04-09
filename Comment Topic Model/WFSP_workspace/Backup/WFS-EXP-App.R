# Load required packages
library(shiny)
library(DT)       # For DataTables
library(yaml)     # For YAML file handling
library(readr)    # For reading CSV files
library(dplyr)    # For data manipulation
library(stringr)  # For string operations
# library(shinyBS)  # For Bootstrap components (e.g., tooltips)?

# Define paths
app_dir <- getwd()

attachmentDL_path <- file.path(app_dir, 'PDF_download.R')
pdf_to_text_path <- file.path(app_dir, 'PDF_to_text.R')

header_text <- '/Volumes/edav_dev_ddnid_niosh/wfsp/datafiles/wfs_rfi_comments.csv'

output_path <- '/Volumes/edav_dev_ddnid_niosh/wfsp/datafiles/output'

data_dir <- '/Volumes/edav_dev_ddnid_niosh/wfsp/datafiles'

css_dir <- '/Volumes/edav_dev_ddnid_niosh/wfsp/datafiles/custom.css'

# Define the path for the YAML file
yaml_path <- file.path(data_dir, 'config.yaml')

sorted_comments <- file.path(data_dir, 'comments_rev2.csv')

theme <- 'minty'

cardCol1 <- 9
cardCol2 <- 3

# Read and preprocess data
comments_table <- read_csv(sorted_comments)

comments_table$cluster_labelled <- as.character(comments_table$cluster_labelled)

comments_table$Prob <- round(as.numeric(comments_table$Prob), 2)

comments_table$OtherW <- ifelse(
  is.na(comments_table$OtherW),
  '',
  str_replace_all(comments_table$OtherW, '[\\[\\]\']', '')
)

# Define params with default values
default_params <- list(
  filename = 'wfs_rfi_comments.csv',
  data_dir = '/Volumes/edav_dev_ddnid_niosh/wfsp/datafiles/',
  runBERT_params = list(
    n_neighbors = 10,
    n_components = 5,
    min_dist = 0.5,
    metric = 'cosine',
    min_cluster_size = 10,
    min_samples = 1,
    cluster_selection_method = 'eom',
    calculate_probabilities = TRUE,
    ngram_range_min = 1,
    ngram_range_max = 3,
    min_topic_size = 10,
    nr_topics = 5,
    output_path = '',
    stopwords_path = '',
    stopwords_list = c('word1', 'word2', 'word3'),
    top_n_words = 20
  )
)

# Function to ensure YAML file exists and is up-to-date
ensure_yaml_file <- function(yaml_path, default_params) {
  # Write the default parameters to the YAML file
  write_yaml(default_params, yaml_path)
  
  config <- default_params  # Initialize config
  
  # Function to update parameters
  update_params <- function(current, default) {
    if (is.null(current)) {
      current <- list()
    }
    for (key in names(default)) {
      value <- default[[key]]
      if (is.list(value)) {
        current[[key]] <- update_params(current[[key]], value)
      } else {
        if (is.null(current[[key]])) {
          current[[key]] <- value
        }
      }
    }
    return(current)
  }
  
  config <- update_params(config, default_params)
  
  # Write the updated parameters back to the YAML file
  write_yaml(config, yaml_path)
  
  # Extract runBERT_params
  runBERT_params <- default_params$runBERT_params
  
  # Assign parameters to global environment
  list2env(runBERT_params, envir = .GlobalEnv)
  
  return(config)
}

# Ensure the YAML file is created and updated with default parameters
config <- ensure_yaml_file(yaml_path, default_params)

# Get the output_path from the config
output_path <- config$runBERT_params$output_path

# Load the data from the output_path
if (file.exists(output_path) && file.info(output_path)$size > 0) {
  output_file <- read_csv(output_path)
} else {
  output_file <- data.frame()  # Handle the case where the file doesn't exist
}

# Define UI
ui <- fluidPage(
  # tags$head(
  #   tags$link(rel = "stylesheet", href = paste0("https://stackpath.bootstrapcdn.com/bootswatch/4.5.2/", theme, "/bootstrap.css"))
  # ),
  # includeCSS(css_dir),
  titlePanel("Topic Modeling of Public Comments"),
  fluidRow(
    column(
      3,
      bsCollapse(
        id = "accordion",
        open = c("Load Data", "Download Attachments and Extract Text", "Run Topic Modeling"),
        
        bsCollapsePanel(
          "Load Data",
          fluidRow(
            column(
              cardCol1,
              div(
                textInput("path_input", "Source file path:", value = as.character(header_text), width = "90%")
              )
            ),
            column(
              3,
              actionButton("runLoadData", "GO", class = "btn btn-primary w-100 mt-2")
            )
          ),
          style = "info"
        ),
        
        bsCollapsePanel(
          "Download Attachments and Extract Text",
          fluidRow(
            column(
              cardCol1,
              p("Download all attachments from comments and extract text from them.")
            ),
            column(
              cardCol2,
              actionButton("runAttachmentsAndExtract", "GO", class = "btn btn-primary w-100 mt-2")
            )
          ),
          style = "info"
        ),
        
        bsCollapsePanel(
          "Run Topic Modeling",
          fluidRow(
            column(
              cardCol1,
              textInput("outputfile_input", "Output filename:", width = "90%", placeholder = "C:/path/to/outputfile"),
              textInput("stopwords_path_input", "Stopwords file path:", width = "90%", placeholder = "C:/path/to/stopwords")
            ),
            column(
              cardCol2,
              actionButton("runBERT", "GO", class = "btn btn-primary w-100 mt-2")
            )
          ),
          hr(style = "border-bottom: 1px solid #e0e0e0; width: 95%; align-self: center;"),
          fluidRow(
            column(
              7,
              textInput("stopwords_list_input", "Stopwords list:", width = "80%", placeholder = "Enter stopwords here"),
              actionButton("stopwords_list_btn", "Add to list", class = "btn btn-primary w-40")
            ),
            column(
              5,
              h6("Additional Stopwords", style = "color: #969696; font-size: 0.8em; text-align: center; text-decoration: underline;"),
              textOutput("stopwords_list_display")
            )
          ),
          h6("Hover over the input fields to see the tooltip text.", style = "color: #707070; font-size: 0.9em; text-align: center;"),
          br(),
          fluidRow(
            column(
              6,
              wellPanel(
                bsTooltip(
                  selectInput("cluster_selection_method", "cluster_selection_method", choices = c("eom", "leaf"), selected = default_params$runBERT_params$cluster_selection_method),
                  "Select the method for cluster selection.", placement = "right"
                ),
                bsTooltip(
                  selectInput("metric", "metric", choices = c("euclidean", "cosine", "manhattan", "hamming"), selected = default_params$runBERT_params$metric),
                  "Select the distance metric.", placement = "right"
                ),
                bsTooltip(
                  numericInput("min_samples", "min_samples", value = default_params$runBERT_params$min_samples, min = 1),
                  "Minimum number of samples in a cluster.", placement = "right"
                ),
                bsTooltip(
                  numericInput("min_dist", "min_dist", value = default_params$runBERT_params$min_dist, min = 0.0, max = 1.0, step = 0.05),
                  "Minimum distance between points.", placement = "right"
                ),
                bsTooltip(
                  numericInput("min_topic_size", "min_topic_size", value = default_params$runBERT_params$min_topic_size, min = 1, step = 1),
                  "Minimum size of a topic.", placement = "right"
                ),
                bsTooltip(
                  sliderInput("ngram_range", "ngram_range", min = 1, max = 5, value = c(default_params$runBERT_params$ngram_range_min, default_params$runBERT_params$ngram_range_max), step = 1),
                  "Specify the range of n-grams.", placement = "right"
                )
              )
            ),
            column(
              6,
              wellPanel(
                bsTooltip(
                  sliderInput("n_neighbors", "n_neighbors", min = 5, max = 100, value = default_params$runBERT_params$n_neighbors, step = 5),
                  "Number of neighbors for UMAP.", placement = "right"
                ),
                bsTooltip(
                  sliderInput("n_components", "n_components", min = 2, max = 50, value = default_params$runBERT_params$n_components, step = 1),
                  "Number of components for UMAP.", placement = "right"
                ),
                bsTooltip(
                  sliderInput("min_cluster_size", "min_cluster_size", min = 2, max = 250, value = default_params$runBERT_params$min_cluster_size, step = 1),
                  "Minimum cluster size.", placement = "right"
                ),
                bsTooltip(
                  sliderInput("top_n_words", "top_n_words", min = 1, max = 50, value = default_params$runBERT_params$top_n_words, step = 1),
                  "Top N words per topic.", placement = "right"
                ),
                bsTooltip(
                  sliderInput("nr_topics", "nr_topics", min = 1, max = 100, value = default_params$runBERT_params$nr_topics, step = 1),
                  "Number of topics.", placement = "right"
                )
              )
            )
          ),
          style = "info"
        )
      )
    ),
    column(
      9,
      box(
        title = "Comments Table",
        width = 12,
        collapsible = TRUE,
        sidebarLayout(
          sidebarPanel(
            selectInput('cluster', 'Select Topic:', choices = c("All", unique(comments_table$cluster_labelled)))
          ),
          mainPanel(
            DTOutput("comments_output")
          )
        ),
        style = "height: 100%; max-height: 80vh;"
      )
    )
  )
)

# Define Server
server <- function(input, output, session) {
  
  path_input_reactive <- reactiveVal("")
  data_reactive <- reactiveVal(NULL)
  
  # Render the comments table
  output$comments_output <- renderDT({
    filtered_comments <- comments_table %>%
      select(Title, First_Name, Last_Name, Clean_comment, cluster, Prob, cluster_labelled)
    datatable(filtered_comments, options = list(height = "100vh", width = "100%", selection = "single"))
  })
  
  # Function to load data
  load_data <- function() {
    path <- input$path_input
    filename <- basename(path)
    data_dir <- dirname(path)
    app_dir <- dirname(app_dir)
    
    config_path <- file.path(app_dir, 'config.yaml')
    
    if (file.exists(config_path)) {
      config <- yaml.load_file(config_path)
    } else {
      config <- list()
    }
    
    config$path <- path
    config$filename <- filename
    config$data_dir <- data_dir
    config$app_dir <- app_dir
    
    write_yaml(config, config_path)
    
    # Update reactive value
    path_input_reactive(path)
  }
  
  # Observe event for loading data
  observeEvent(input$runLoadData, {
    load_data()
  })
  
  # Output for displaying the path input
  output$path_input_display <- renderText({
    paste0("Path: ", input$path_input)
  })
  
  # Observe event for downloading attachments and extracting text
  observeEvent(input$runAttachmentsAndExtract, {
    path_input <- path_input_reactive()
    
    if (is.null(path_input) || path_input == "") {
      showModal(modalDialog(
        p("Please load the data first."),
        title = "Error",
        easyClose = TRUE
      ))
      return()
    }
    
    # Set the current working directory to the directory containing the R script
    setwd(dirname(attachmentDL_path))
    
    # Download attachments
    command <- paste('Rscript', shQuote(attachmentDL_path), shQuote(path_input))
    tryCatch({
      result_attachments <- system(command, intern = TRUE)
      
      # Extract text from PDFs
      result_pdf <- system(paste('Rscript', shQuote(pdf_to_text_path)), intern = TRUE)
      
      showModal(modalDialog(
        p("Attachments downloaded and text extracted successfully."),
        p("Attachments Output:"),
        pre(paste(result_attachments, collapse = "\n")),
        p("PDF Extraction Output:"),
        pre(paste(result_pdf, collapse = "\n")),
        title = "Execution Result",
        easyClose = TRUE
      ))
    }, error = function(e) {
      showModal(modalDialog(
        p("Execution failed."),
        p("Error:"),
        pre(e$message),
        title = "Execution Error",
        easyClose = TRUE
      ))
    })
  })
  
  # Observe event for adding stopwords
  observeEvent(input$stopwords_list_btn, {
    new_stopword <- str_trim(input$stopwords_list_input)
    if (new_stopword != "") {
      # Read the existing config.yaml file
      config <- yaml.load_file(yaml_path)
      stopwords_list <- config$runBERT_params$stopwords_list
      stopwords_list <- unique(c(stopwords_list, new_stopword))
      # Update the config with the new stopwords list
      config$runBERT_params$stopwords_list <- stopwords_list
      # Write the updated config back to the config.yaml file
      write_yaml(config, yaml_path)
      # Clear the input text box
      updateTextInput(session, "stopwords_list_input", value = "")
    }
  })
  
  # Display the list of stopwords
  output$stopwords_list_display <- renderText({
    # Read the existing config.yaml file
    config <- yaml.load_file(yaml_path)
    stopwords_list <- config$runBERT_params$stopwords_list
    paste(stopwords_list, collapse = ', ')
  })
  
  # Observe event for running BERT
  observeEvent(input$runBERT, {
    params <- list(
      n_neighbors = input$n_neighbors,
      n_components = input$n_components,
      min_dist = input$min_dist,
      metric = input$metric,
      min_cluster_size = input$min_cluster_size,
      min_samples = input$min_samples,
      cluster_selection_method = input$cluster_selection_method,
      calculate_probabilities = TRUE,  # Assuming this is always TRUE
      ngram_range_min = input$ngram_range[1],
      ngram_range_max = input$ngram_range[2],
      min_topic_size = input$min_topic_size,
      nr_topics = input$nr_topics,
      output_path = input$outputfile_input,
      stopwords_path = input$stopwords_path_input,
      stopwords_list = strsplit(input$stopwords_list_input, ',')[[1]],
      top_n_words = input$top_n_words
    )
    
    # Read the existing config.yaml file
    config <- yaml.load_file(yaml_path)
    
    # Update the runBERT_params in the config
    if (is.null(config$runBERT_params)) {
      config$runBERT_params <- list()
    }
    config$runBERT_params <- modifyList(config$runBERT_params, params)
    
    # Write the updated config back to the config.yaml file
    write_yaml(config, yaml_path)
    
    # Run the BERT script
    tryCatch({
      bert_script_path <- file.path(app_dir, "BERTopic-EXP.R")
      result <- system(paste('Rscript', shQuote(bert_script_path)), intern = TRUE)
      
      # Reload the output file after BERT script execution
      load_data()
      
      showModal(modalDialog(
        p("BERT script executed successfully."),
        p("Output:"),
        pre(paste(result, collapse = "\n")),
        title = "Execution Result",
        easyClose = TRUE
      ))
    }, error = function(e) {
      showModal(modalDialog(
        p("BERT script execution failed."),
        p("Error:"),
        pre(e$message),
        title = "Execution Error",
        easyClose = TRUE
      ))
    })
  })
  
  # Reactive expression for filtered data
  filtered_data <- reactive({
    word1 <- input$word1
    word2 <- input$word2
    word3 <- input$word3
    
    filtered_df <- comments_table %>%
      filter(
        str_detect(Comment, regex(word1, ignore_case = TRUE)),
        str_detect(Comment, regex(word2, ignore_case = TRUE)),
        str_detect(Comment, regex(word3, ignore_case = TRUE))
      )
    
    if (input$cluster == "All") {
      return(filtered_df %>% select(Document_ID, Comment, ForServ, OtherW, Prob, DuplGr))
    } else {
      return(
        filtered_df %>%
          filter(cluster_labelled == input$cluster) %>%
          select(Document_ID, Comment, ForServ, OtherW, Prob, DuplGr) %>%
          arrange(desc(Prob))
      )
    }
  })
  
  # Render the filtered table
  output$table <- renderDT({
    df <- filtered_data()
    datatable(
      df,
      options = list(
        pageLength = 25,
        scrollY = "100%",
        scrollX = TRUE,
        dom = 't',
        ordering = FALSE,
        selection = 'multiple'
      ),
      rownames = FALSE
    )
  })
  
  # Observe inputs for word highlighting (requires custom implementation)
  # This part may require additional packages or custom JavaScript for highlighting
}

# Run the application
shinyApp(ui = ui, server = server)