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
  "htmltools",    # For creating HTML elements
  "openai",
  "azure-identity",
  "azure.mgmt.subscription"
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

# Load required libraries upfront
library(shiny)
library(bslib)
library(DT)
library(dplyr)
library(ggplot2)
library(httr)
library(jsonlite)
library(tools)
library(AzureAuth)
library(reticulate)

# Configuration Management
config <- list(
    network = list(
        port = 7821,
        host = "0.0.0.0",
        quiet = TRUE,
        launch.browser = FALSE
    ),
    openai = list(
        endpoint = "https://edav-dev-openai-eastus2-shared.openai.azure.com/",
        api_version = "api-shared-gpt-4-turbo-nofilter",
        api_base = "https://edav-dev-openai-eastus2-shared.openai.azure.com/",
        api_type = "azure",
        api_key = NULL # Will be set after authentication
    ),
    paths = list(
        default_input = "/dbfs/FileStore/data/wfs-rfi-test-cleaned.csv",
        output_dir = "/dbfs/FileStore/data/output/oaitm/"
    )
)

# Retrieve secrets from Azure Databricks using reticulate
dbutils <- import("dbutils")
dbutils <- dbutils$DBUtils(get("spark", envir = .GlobalEnv))

# Set your scope and key names appropriately
tenant_id <- "9ce70869-60db-44fd-abe8-d2767077fc8f"
client_id <- "86dae1ec-7165-409b-81da-c0a4bca42f25"
scope <- "your_scope_name" # Replace with your actual scope name
client_secret <- dbutils$secrets$get(scope = scope, key = "AZURE_CLIENT_SECRET")

# Authenticate with Azure and obtain the access token
credentials <- get_azure_token(
    resource = "https://cognitiveservices.azure.com/.default",
    tenant = tenant_id,
    app = client_id,
    password = client_secret
)
access_token <- credentials$credentials$access_token

# Update the api_key with the access token
config$openai$api_key <- access_token

# UI Definition
ui <- fluidPage(
    titlePanel("Topic Analysis"),
    sidebarLayout(
        sidebarPanel(
            fileInput("file", "Upload file (CSV or TXT)",
                accept = c(".csv", ".txt")
            ),
            actionButton("analyze", "Analyze Topics"),
            downloadButton("downloadData", "Download Results"),
            verbatimTextOutput("debugLog")
        ),
        mainPanel(
            tabsetPanel(
                tabPanel(
                    "Progress",
                    verbatimTextOutput("apiStatus"),
                    verbatimTextOutput("batchProgress")
                ),
                tabPanel(
                    "Results",
                    plotOutput("topicPlot"),
                    tableOutput("keywordTable"),
                    DTOutput("commentTable")
                )
            )
        )
    )
)

# Helper function to read and process input files
read_comments_file <- function(file_path, log_debug) {
    file_ext <- tolower(tools::file_ext(file_path))
    log_debug(sprintf("Processing file with extension: %s", file_ext))

    comments_df <- NULL

    if (file_ext == "csv") {
        comments_df <- tryCatch(
            {
                df <- read.csv(file_path, stringsAsFactors = FALSE)

                if (is.vector(df) && !is.data.frame(df)) {
                    df <- data.frame(comments = df, stringsAsFactors = FALSE)
                    log_debug("Converted single vector to data frame")
                }

                if (!"comments" %in% names(df)) {
                    text_cols <- sapply(df, is.character)
                    if (sum(text_cols) == 1) {
                        names(df)[text_cols] <- "comments"
                        log_debug("Renamed text column to 'comments'")
                    } else {
                        stop("Could not identify comments column in CSV")
                    }
                }

                df
            },
            error = function(e) {
                log_debug(sprintf("CSV reading error: %s", e$message))
                stop(paste("Error reading CSV:", e$message))
            }
        )
    } else if (file_ext == "txt") {
        comments_df <- tryCatch(
            {
                lines <- readLines(file_path, warn = FALSE)
                data.frame(comments = lines, stringsAsFactors = FALSE)
            },
            error = function(e) {
                log_debug(sprintf("TXT reading error: %s", e$message))
                stop(paste("Error reading TXT:", e$message))
            }
        )
    }

    print("Debug - Column names before return:")
    print(names(comments_df))
    print(head(comments_df))

    if (is.null(comments_df) || nrow(comments_df) == 0) {
        stop("No data found in input file")
    }

    if (!"comments" %in% names(comments_df)) {
        stop("Required 'comments' column not found in data")
    }

    comments_df$comments <- tryCatch(
        {
            cleaned <- gsub("\u00A0", " ", comments_df$comments)
            cleaned <- gsub("\r\n|\r|\n", " ", cleaned)
            cleaned <- gsub("\\s+", " ", cleaned)
            trimws(cleaned)
        },
        error = function(e) {
            log_debug(sprintf("Text cleaning error: %s", e$message))
            comments_df$comments
        }
    )

    comments_df <- comments_df[!is.na(comments_df$comments) &
        nchar(trimws(comments_df$comments)) > 0, ]

    return(comments_df)
}

# Function to validate and parse API responses
parse_api_response <- function(response_text) {
    parsed <- tryCatch(
        {
            jsonlite::fromJSON(response_text)
        },
        error = function(e) {
            stop(paste("Failed to parse API response as JSON:", e$message))
        }
    )

    if (!is.list(parsed)) {
        stop("API response is not a list structure")
    }

    if (is.null(parsed$choices) || length(parsed$choices) == 0) {
        stop("No choices found in API response")
    }

    message <- parsed$choices[[1]]$message
    if (is.null(message) || is.null(message$content)) {
        stop("No message content found in API response")
    }

    content <- tryCatch(
        {
            jsonlite::fromJSON(message$content)
        },
        error = function(e) {
            stop(paste("Failed to parse message content as JSON:", e$message))
        }
    )

    if (!is.list(content) || is.null(content$topics) || is.null(content$assignments)) {
        stop("Invalid topic analysis structure in response")
    }

    return(content)
}

# Server function that handles all the application logic
server <- function(input, output, session) {
    # Initialize reactive values
    results <- reactiveVal(NULL)
    status <- reactiveVal("")
    debug_log <- reactiveVal("")
    batch_progress <- reactiveVal("")

    # Enhanced logging function
    log_debug <- function(msg) {
        current <- debug_log()
        calls <- sys.calls()
        current_fn <- deparse(calls[[length(calls) - 1]])
        timestamp <- format(Sys.time(), "%H:%M:%S")
        log_msg <- paste0(timestamp, " - [", current_fn, "] ", msg, "\n")
        debug_log(paste0(current, log_msg))
    }

    # Helper function to inspect objects safely
    inspect_object <- function(obj, name = "object") {
        tryCatch(
            {
                obj_class <- class(obj)
                obj_type <- typeof(obj)
                obj_str <- capture.output(str(obj))
                log_debug(sprintf(
                    "Inspecting %s:\nClass: %s\nType: %s\nStructure:\n%s",
                    name,
                    paste(obj_class, collapse = ", "),
                    obj_type,
                    paste(obj_str, collapse = "\n")
                ))
            },
            error = function(e) {
                log_debug(sprintf("Error inspecting %s: %s", name, e$message))
            }
        )
    }

    # Function to call Azure OpenAI API
    call_azure_openai <- function(prompt) {
        endpoint <- paste0(
            config$openai$endpoint,
            "openai/deployments/",
            config$openai$api_version,
            "/chat/completions?api-version=",
            config$openai$api_version
        )

        body <- list(
            messages = list(
                list(role = "system", content = "You are a topic modeling expert. Return only valid JSON."),
                list(role = "user", content = prompt)
            ),
            temperature = 0.7,
            max_tokens = 2000
        )

        response <- POST(
            url = endpoint,
            add_headers(
                Authorization = paste("Bearer", config$openai$api_key),
                `api-key` = config$openai$api_key,
                `Content-Type` = "application/json"
            ),
            body = toJSON(body, auto_unbox = TRUE)
        )

        content <- content(response, "text", encoding = "UTF-8")
        return(content)
    }

    # Function to perform topic analysis on batches of comments
    perform_topic_analysis <- function(data) {
        print("Debug - Column names in analysis:")
        print(names(data))
        print(str(data))

        log_debug(paste("Processing", nrow(data), "comments"))

        if (!is.data.frame(data) || nrow(data) == 0 || !"comments" %in% names(data)) {
            stop("Invalid input data: Expected data frame with 'comments' column")
        }

        max_comments_per_batch <- 50
        num_batches <- ceiling(nrow(data) / max_comments_per_batch)
        all_assignments <- list()
        all_topics <- list()

        for (batch_num in 1:num_batches) {
            batch_progress(paste("Processing batch", batch_num, "of", num_batches))

            start_idx <- ((batch_num - 1) * max_comments_per_batch + 1)
            end_idx <- min(batch_num * max_comments_per_batch, nrow(data))

            batch_data <- data[start_idx:end_idx, ]
            combined_text <- paste(batch_data$comments, collapse = "\n")

            prompt <- paste(
                "Analyze the following comments and identify the main topics.",
                "For each comment, assign the most relevant topic.",
                "Your response must be a valid JSON object with this exact structure:",
                "{",
                "  \"topics\": [",
                "    {\"name\": \"topic_name\", \"keywords\": [\"word1\", \"word2\"]}",
                "  ],",
                "  \"assignments\": [",
                "    {\"index\": 0, \"topic\": \"topic_name\"}",
                "  ]",
                "}",
                "Do not include any other text or formatting in your response.",
                "\nComments:\n",
                combined_text
            )

            tryCatch(
                {
                    analysis_results <- call_azure_openai(prompt)
                    inspect_object(analysis_results, "batch_results")

                    if (!is.list(analysis_results) ||
                        is.null(analysis_results$topics) ||
                        is.null(analysis_results$assignments)) {
                        log_debug("Invalid results structure")
                        next
                    }

                    batch_offset <- (batch_num - 1) * max_comments_per_batch
                    assignments <- lapply(analysis_results$assignments, function(x) {
                        if (!is.null(x$index)) {
                            x$index <- x$index + batch_offset
                        }
                        return(x)
                    })

                    all_assignments <- c(all_assignments, assignments)
                    all_topics <- c(all_topics, analysis_results$topics)
                },
                error = function(e) {
                    log_debug(paste("Batch error:", e$message))
                }
            )
        }

        if (length(all_assignments) == 0 || length(all_topics) == 0) {
            stop("No valid results obtained")
        }

        # Deduplicate topics while preserving structure
        unique_topic_names <- unique(sapply(all_topics, function(x) x$name))
        unique_topics <- all_topics[match(unique_topic_names, sapply(all_topics, function(x) x$name))]

        return(list(
            topics = unique_topics,
            assignments = all_assignments
        ))
    }

    # Update the analyze button handler
    observeEvent(input$analyze, {
        log_debug("Starting analysis...")

        tryCatch(
            {
                results(NULL)

                data <- tryCatch(
                    {
                        if (!is.null(input$file)) {
                            log_debug(paste("Loading uploaded file:", input$file$name))
                            df <- read_comments_file(input$file$datapath, log_debug)
                        } else {
                            log_debug(paste("Loading default file:", config$paths$default_input))
                            if (!file.exists(config$paths$default_input)) {
                                stop("Default input file not found")
                            }
                            df <- read_comments_file(config$paths$default_input, log_debug)
                        }

                        print("Debug - Column names after reading:")
                        print(names(df))
                        print(head(df))

                        df
                    },
                    error = function(e) {
                        log_debug(paste("Data loading error:", e$message))
                        stop(paste("Failed to load data:", e$message))
                    }
                )

                analysis_results <- perform_topic_analysis(data)
                inspect_object(analysis_results, "analysis_results")

                if (!is.null(analysis_results)) {
                    # Rest of the handler code...
                }
            },
            error = function(e) {
                log_debug(paste("Analysis error:", e$message))
                showNotification(paste("Error:", e$message), type = "error")
            }
        )
    })

    # Create the topic distribution plot
    output$topicPlot <- renderPlot({
        # We require the results to be available before rendering
        req(results())

        # Create a visualization of topic distribution using ggplot2
        results()$data %>%
            # Count the frequency of each topic
            count(topic) %>%
            # Create a bar plot with topics ordered by frequency
            ggplot(aes(x = reorder(topic, n), y = n)) +
            geom_bar(stat = "identity", fill = "steelblue") +
            # Flip coordinates to make long topic names more readable
            coord_flip() +
            labs(
                x = "Topic",
                y = "Number of Comments",
                title = "Topic Distribution"
            ) +
            # Apply a clean, minimal theme for professional appearance
            theme_minimal() +
            # Ensure topic labels are readable
            theme(axis.text.y = element_text(size = 10))
    })

    # Render a table showing topics and their associated keywords
    output$keywordTable <- renderTable({
        req(results())
        # Transform the nested list of topics into a readable data frame
        topics_df <- do.call(rbind, lapply(results()$topics, function(topic) {
            data.frame(
                Topic = topic$name,
                Keywords = paste(topic$keywords, collapse = ", "),
                stringsAsFactors = FALSE
            )
        }))
        topics_df
    })

    # Create an interactive data table showing all comments and their assigned topics
    output$commentTable <- renderDT({
        req(results())
        # Create an interactive table with search, sort, and filter capabilities
        datatable(
            results()$data,
            options = list(
                pageLength = 25, # Show 25 entries per page
                scrollX = TRUE, # Enable horizontal scrolling for wide tables
                order = list(list(2, "desc")) # Default sort by third column descending
            ),
            filter = "top" # Add filter controls at top of each column
        )
    })

    # Enable users to download the analyzed data
    output$downloadData <- downloadHandler(
        filename = function() {
            # Generate a unique filename with timestamp
            paste("topic_analysis_", format(Sys.time(), "%Y%m%d_%H%M%S"), ".csv", sep = "")
        },
        content = function(file) {
            # Ensure results exist before attempting download
            req(results())
            # Write the complete dataset with topic assignments to CSV
            write.csv(results()$data, file, row.names = FALSE)
        }
    )
}

# Launch the Shiny application with the network configuration specified earlier
shinyApp(ui = ui, server = server, options = config$network)