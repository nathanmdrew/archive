library(shiny) # Load shiny library for web applications
library(DT) # Load DT library for data tables
library(dplyr) # Load dplyr for data manipulation
library(stringr) # Load stringr for string operations
library(readr)
library(curl)
library(bslib)
library(shinythemes)

# install.packages("xlsx")
# library(xlsx)

datafile <- "wfs_rfi_comments_rev2.csv"

# ══════════ LOAD & PREP DATA ══════════

# Load the CSV file dynamically using the datafile variable
top_docs_final <- read.csv(paste0("/Volumes/edav_dev_ddnid_niosh/wfsp/datafiles/", datafile), fileEncoding = "UTF-8")

# ══════════ APP UI ══════════

# Define the UI layout with cards
ui <- fluidPage(
  theme = bs_theme(bootswatch = "flatly"), # Theme for enhanced styling
  titlePanel("Topic Modeling of Public Comments"),

  # Custom CSS for card borders and height
  tags$style(HTML("
    .card {
      border: 1px solid #ddd;
      border-radius: 4px;
      box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
      height: 100%; /* Set the height of the cards to 100% */
    }
    .shiny-split-layout > div {
      height: 100%; /* Ensure the split layout divs also take full height */
    }
  ")),

  splitLayout(
    cellWidths = c("25%", "25%", "25%", "25%"), # Ensure each card takes up equal width
    card(
      card_header("Load Data"),
      card_body(
        textInput("datafile", "Filename:"), # Text input for file name
        actionButton("downloadButton", "Download Attachments"), # Action button for downloading attachments
        uiOutput("compute")
      )
    ),
    card(
      card_header("Stop Words"),
      card_body(
        p("Provide a custom list of stop words for your data."),
        textAreaInput("words", "Enter words (one per line):", rows = 5),
        actionButton("saveButton", "Save to CSV")
      )
    ),
    card(
      card_header("Run Topic Modeling"),
      actionButton("runButton", "Run Script"),
      uiOutput("compute")
    ),
    card(
      card_header("Load Data V2"),
      fileInput("upload", NULL, buttonLabel = "Upload...", multiple = TRUE),
      tableOutput("files")
    )
  ),

  splitLayout(
    card(
      card_header("Table of Topic Documents"),
      card_body(
         helpText("Select a group/cluster from the drop-down menu and learn its documents."),
      layout_sidebar(
        sidebar = sidebar(
          selectInput("cluster", "Select Topic:", choices = c("All", unique(top_docs_final$cluster_labelled)), selected = "All"),
        ),
        DTOutput("comment_table")
      )
    )
    )
  )

) # ---------- /

# ══════════ SERVER SIDE ══════════

server <- function(input, output, session) { # Define server logic

# ----- Input Stopwords ----- 

  observeEvent(input$swButton, {
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

# ----- Comment Table -----


  filtered_data <- reactive({ # Reactive expression for filtered data
    
    selected_category <- input$cluster # Get selected cluster
    if (selected_category == "All") { # If "All" is selected
      return(top_docs_final %>% select(c("Document_ID", "Comment", "ForServ", "OtherW", "Prob", "DuplGr"))) # Return all filtered data
    }
    
    top_docs_final %>% # Filter by selected cluster
      filter(cluster_labelled %in% input$cluster) %>% # Filter by cluster_labelled
      select(c("Document_ID", "Comment", "ForServ", "OtherW", "Prob", "DuplGr")) %>% # Select columns
      arrange(desc(Prob)) # Arrange by Prob in descending order
  })
  
    # Observe button click event
  observeEvent(input$runButton, {
    
    # Use progress bar to show computation progress
    output$compute <- renderUI({
      withProgress(message = "Calculation in progress", detail = "This may take a while...", {
        
        # Simulate computation with progress bar updates
        for (i in 1:14) {
          incProgress(1/14, detail = paste("Computing..."))
          Sys.sleep(0.1)  # Simulate async behavior with a delay
        }

        "Done computing!"
      })
    })
  })

  output$Table <- renderDT( # Render data table
    filtered_data(), # Use filtered data
    caption = "Documents per Group/Cluster", # Table caption
    options = list( # Table options
      pageLength = 25, # Set page length
      searchHighlight = TRUE, # Enable search highlight
      search = list(regex = TRUE, search = paste0(" ", input$word1, " ", input$word2, " ", input$word3, " ")) # Set search options
    )
  )
  
  observe({ # Observe changes
    # Define a JavaScript function to highlight text in textInputs
    highlight_text_js <- '
      Shiny.addCustomMessageHandler("highlightText", function(message) {
        // Get the text input element by ID
        var inputElement = document.getElementById(message.inputId);
        if (inputElement) {
          // Highlight the specified text in the input element
          var inputValue = inputElement.value;
          var highlightedValue = inputValue.replace(new RegExp(message.text, "gi"), function(match) {
            return "<mark>" + match + "</mark>";
          });
          inputElement.value = highlightedValue;
        }
      });
    '
  })

# // ----- End Comment Table ----- //

# ----- Download Attachments -----

  observeEvent(input$downloadButton, { # Observe button click event
    datafile <- input$datafile # Get datafile input
    attachDL(datafile) # Call attachDL function
  })
}

attachDL <- function(datafile) {
  filepath <- paste0("/Volumes/edav_dev_ddnid_niosh/wfsp/datafiles/", datafile)
  subset_dat <- read.csv(filepath, fileEncoding = "UTF-8") # Read CSV file

  ## file path of the directory to download all attachments to
  dest_dir <- "/Volumes/edav_dev_ddnid_niosh/wfsp/datafiles/Bulk Attachment Download/"

  for(i in c(1:length(subset_dat$Attachment.Files))){
    if(nchar(subset_dat$Attachment.Files[i]) > 0){
      url_str <- subset_dat$Attachment.Files[i] ## entire URL string from Attachment.Files variable
      url_split <- str_split(url_str, pattern = ",") ## makes a list containing each URL in a separate string
      for(j in c(1:length(url_split[[1]]))){ ## downloading each URL
        url <- url_split[[1]][j]
        filename_split <- str_split(url, pattern = "/")
        filename <- paste0(filename_split[[1]][4],sep = "_",filename_split[[1]][5]) ## creating file name from comment ID & attachment number (e.g. CDC-2023-0051-0054_attachment_1)
        file <- paste0(dest_dir,filename)
        curl_download(url,file)
      }
    }
  }
}

# // ----- End Download Attachments ----- //

shinyApp(ui = ui, server = server) # Run the Shiny app