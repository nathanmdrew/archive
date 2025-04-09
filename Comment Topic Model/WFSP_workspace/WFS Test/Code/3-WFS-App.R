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


library(shiny) # Load shiny library for web applications
library(dplyr) # Load dplyr for data manipulation
library(stringr) # Load stringr for string operations

filename <- "wfs_analyzed_1-24-25.csv"
file_path <- "/Volumes/edav_dev_ddnid_niosh/wfsp/datafiles/tm/wfs_analyzed_1-24-25.csv"
top_docs_final <- read.csv(paste0(file_path, filename), fileEncoding = "UTF-8") # Read CSV file

top_docs_final$cluster_labelled <- as.character(top_docs_final$cluster_labelled) # Convert cluster_labelled to character
top_docs_final$Prob <- as.numeric(top_docs_final$Prob) # Convert Prob to numeric

top_docs_final$Prob <- round(top_docs_final$Prob, 2) # Round Prob to 2 decimal places
top_docs_final$OtherW <- str_replace_all(top_docs_final$OtherW, "\\[|\\]", "") # Remove square brackets from OtherW
top_docs_final$OtherW <- str_replace_all(top_docs_final$OtherW, "'", "") # Remove single quotes from OtherW

ui <- fluidPage( # Define UI layout
  titlePanel('Topic Modeling of Public Comments'), # Title panel
  helpText("Select a group/cluster from the drop-down menu and learn its documents."), # Help text
  
  textInput("word1", "Search Word 1:"), # Text input for word1
  textInput("word2", "Search Word 2:"), # Text input for word2
  textInput("word3", "Search Word 3:"), # Text input for word3
  
  sidebarLayout( # Sidebar layout
    sidebarPanel( # Sidebar panel
      width = 2, # Set width
      selectInput('cluster', 'Select Group:', choices = c("All", unique(top_docs_final$cluster_labelled)), multiple = FALSE, selected = "All"), # Select input for cluster
      helpText("* Clusters range from 0 to 14\n* **duplicated_empty** means documents that are duplicated or empty") # Help text
    ),
    mainPanel( # Main panel
      width = 10, # Set width
      tabsetPanel( # Tabset panel
        tabPanel( # Tab panel
          title = 'Table of Topic Documents', # Tab title
          p("Table shows documents for each topic."), # Paragraph
          # DTOutput('Table')
          tableOutput('Table') # Table output
        )
      )
    )
  )
)

server <- function(input, output, session) { # Define server logic
  filtered_data <- reactive({ # Reactive expression for filtered data
    word1 <- input$word1 # Get word1 input
    word2 <- input$word2 # Get word2 input
    word3 <- input$word3 # Get word3 input
    
    filtered_top_docs_final <- top_docs_final %>% # Filter top_docs_final
      filter(
        grepl(word1, Comment, ignore.case = TRUE) & # Filter by word1
          grepl(word2, Comment, ignore.case = TRUE) & # Filter by word2
          grepl(word3, Comment, ignore.case = TRUE) # Filter by word3
      )
    
    selected_category <- input$cluster # Get selected cluster
    if (selected_category == "All") { # If "All" is selected
      return(filtered_top_docs_final %>% select(c("Document_ID", "Comment", "ForServ", "OtherW", "Prob", "DuplGr"))) # Return all filtered data
    }
    
    filtered_top_docs_final %>% # Filter by selected cluster
      filter(cluster_labelled %in% input$cluster) %>% # Filter by cluster_labelled
      select(c("Document_ID", "Comment", "ForServ", "OtherW", "Prob", "DuplGr")) %>% # Select columns
      arrange(desc(Prob)) # Arrange by Prob in descending order
  })
  
  # output$Table <- renderDT( # Render data table
  #   filtered_data(), # Use filtered data
  #   caption = "Documents per Group/Cluster", # Table caption
  #   options = list( # Table options
  #     pageLength = 25, # Set page length
  #     searchHighlight = TRUE, # Enable search highlight
  #     search = list(regex = TRUE, search = paste0(" ", input$word1, " ", input$word2, " ", input$word3, " ")) # Set search options
  #   )
  # )
  output$Table <- renderTable( # Render table
    filtered_data(), # Use filtered data
    striped = TRUE, # Add striped rows
    hover = TRUE, # Enable hover effect
    bordered = TRUE # Add borders
  )
}

shinyApp(ui = ui, server = server) # Run the Shiny app
