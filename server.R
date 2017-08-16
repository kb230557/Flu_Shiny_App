
#Setting working directory, loading packages, and importing data
library("shiny")
library("dplyr")
library("ggplot2")
library("Cairo")
load("flu.Rdata")

server <- function(input, output) {
  
  #Improves graphics quality
  options(shiny.usecairo=T)
  
  
  #==========================================ED DATA BY SEASON (SERVER)=============================================================#
  
  
  #Selecting data to plot based on user selecter
  userdatayr = reactive({
    return(fluedyr[fluedyr$Season %in% input$seasonpick, ]) #inputID is from user interface - ensures user-selected data is displayed
  })
  
  #Attempted to merge season data with baseline data so hover option would work on baseline data but code didn't work, retained for possible further troubleshooting
  # hoverdata = reactive({
  #   if(input$baselinecheck) {
  #     rbind(userdata(),testdf)
  #   }
  #   else return(userdata())
  # })
  
  #Selecting colors and line types to represent each season -- #### NOTE - Might want to play around more with these
  groupcolorsyr <- c("2010-11" = "#2F6396", "2011-12" = "#B3AFED", "2012-13" = "#6E9DC9", "2013-14" = "#484199", 
                   "2014-15" = "#9BBFE2", "2015-16" = "#52779A", "2016-17" = "#7F79D0", "2017-18" = "#F33535")
                    #If red is too harsh, try #c96e6e
  
  grouplinesyr <- c("2010-11" = 5, "2011-12" = 1, "2012-13" = 4, "2013-14" = 3, 
                  "2014-15" = 1, "2015-16" = 5, "2016-17" = 4, "2017-18" = 1)
  
  
  #Creating plot of user-selected data to use in the download image function 
  edyrplot <- reactive({
    
    ggplot(data = userdatayr(), aes(x = CDC_Week, y = ED_ILI, color = Season)) +
      geom_point(size = 3) + #######Consider size=4 paired with line size = 2 
      geom_line(aes(group = Season, linetype = Season), size = 1) +
      geom_hline(yintercept = ifelse(input$baselinecheck, 1.02, -.1), color = "black", linetype = "F1") +
      labs(title = "Proportion of ED Visits for ILI, Suburban Cook County", x = "MMWR Week", y = "% of Visits for ILI") +
      scale_color_manual(values = groupcolorsyr) +
      scale_linetype_manual(values = grouplinesyr) +
      scale_y_continuous(limits = c(0,6), expand = c(0,0)) +
      theme(plot.title = element_text(size = 16, face = "bold", hjust = 0.5), legend.title = element_text(size = 14, face = "bold"), 
            legend.text = element_text(size = 12), axis.title = element_text(size = 14, face = "bold"), axis.text = element_text(size = 10),
            panel.grid = element_blank(), panel.background = element_blank(), axis.line = element_line())
    
  })
  
  #Creating plot of user-selected data to display on the app (see note below)
  output$seasonplot <- renderPlot({
    
    ########### NOTE - Two lines below is more efficient and legible than repreating same ggplot function from above however, I can't get 
    #hover functionality to work unless renderPlot contains a gglot2 function (and I can't find any solutions that use the downloadHandler
    #without placing the plot in a reactive function)
    # p <- edyrplot()
    # print(p)
    
    ggplot(data = userdatayr(), aes(x = CDC_Week, y = ED_ILI, color = Season)) +
      geom_point(size = 3) + #######Consider size=4 paired with line size = 2 
      geom_line(aes(group = Season, linetype = Season), size = 1) +
      geom_hline(yintercept = ifelse(input$baselinecheck, 1.02, -.1), color = "black", linetype = "F1") +
      labs(title = "Proportion of ED Visits for ILI, Suburban Cook County", x = "MMWR Week", y = "% of Visits for ILI") +
      scale_color_manual(values = groupcolorsyr) +
      scale_linetype_manual(values = grouplinesyr) +
      scale_y_continuous(limits = c(0,6), expand = c(0,0)) +
      theme(plot.title = element_text(size = 16, face = "bold", hjust = 0.5), legend.title = element_text(size = 14, face = "bold"), 
            legend.text = element_text(size = 12), axis.title = element_text(size = 14, face = "bold"), axis.text = element_text(size = 10),
            panel.grid = element_blank(), panel.background = element_blank(), axis.line = element_line())
    
  })
  
  #Creating download image functionality
  output$downloadseason <- downloadHandler(
    filename = "ED_Data_by_Season.png",
    content = function(edyrfile){
      ggsave(edyrfile, plot = edyrplot(), device = "png", height = 3, width = 10, unit = "in")
    }
  )
  
  
  #Generating tooltip data for hovered-over points #######CODE CREDIT: http://www.77dev.com/2016/03/custom-interactive-csshtml-tooltips.html
  output$hover_info_season <- renderUI({
    
    if(!is.null(input$seasonpick)) { #Line added to avoid error caused by geom_hline in plot when no values are selected
      
      hover <- input$plot_hover_season
      point <- nearPoints(userdatayr(), hover, threshold = 5, maxpoints = 1, addDist = TRUE)
      if (nrow(point) == 0) return(NULL)
      
      # calculate point position INSIDE the image as percent of total dimensions
      # from left (horizontal) and from top (vertical)
      left_pct <- (hover$x - hover$domain$left) / (hover$domain$right - hover$domain$left)
      top_pct <- (hover$domain$top - hover$y) / (hover$domain$top - hover$domain$bottom)
      
      # calculate distance from left and bottom side of the picture in pixels
      left_px <- hover$range$left + left_pct * (hover$range$right - hover$range$left)
      top_px <- hover$range$top + top_pct * (hover$range$bottom - hover$range$top)
      
      # create style property fot tooltip
      # background color is set so tooltip is a bit transparent
      # z-index is set so we are sure are tooltip will be on top
      style <- paste0("position:absolute; z-index:100; background-color: rgba(245, 245, 245, 0.85); ",
                      "left:", left_px + 2, "px; top:", top_px + 2, "px;")
      
      # actual tooltip created as wellPanel
      wellPanel(
        style = style,
        p(HTML(paste0("<b> Season: </b>", point$Season, "<br/>",
                      "<b> MMWR Week: </b>", point$CDC_Week, "<br/>",
                      "<b> % of ED Visits for ILI: </b>", point$ED_ILI, "<br/>")))
      )
      
    }
  })
  
  #==========================================ED DATA BY AGE (SERVER)=============================================================#
 
  userdataage = reactive({
    return(fluedage[fluedage$Age_Group %in% input$agepick, ]) 
  })
  
  groupcolorsage <- c("0-4" = "#6E9DC9", "5-17" = "#C96E85", "18-64" = "#6EC985", "65+" = "#C99C6E", "All" = "#979CA1")
  
  grouplinesage <- c("0-4" = 1, "5-17" = 1, "18-64" = 1, "65+" = 1, "All" = 5)
  
  output$ageplot <- renderPlot({
    
    ggplot(data = userdataage(), aes(x = Week_Number, y = ED_ILI, color = Age_Group)) +
      geom_point(size = 3) + #######Consider size=4 paired with line size = 2 
      geom_line(aes(group = Age_Group, linetype = Age_Group), size = 1) +
      labs(title = "Proportion of ED Visits for ILI by Age Group, Suburban Cook County", x = "MMWR Week", y = "% of Visits for ILI") +
      scale_color_manual(values = groupcolorsage, name = "Age Group") +
      scale_linetype_manual(values = grouplinesage, name = "Age Group") +
      scale_y_continuous(limits = c(0,8), expand = c(0,0)) +
      theme(plot.title = element_text(size = 16, face = "bold", hjust = 0.5), legend.title = element_text(size = 14, face = "bold"), 
            legend.text = element_text(size = 12), axis.title = element_text(size = 14, face = "bold"), axis.text = element_text(size = 10),
            panel.grid.major = element_line(color = "#E5E5E5"), panel.grid.minor = element_line(color = "#E5E5E5"),
            panel.background = element_rect(fill = NA), axis.line = element_line())
    
  })
  
  edageplot <- reactive({
    
    ggplot(data = userdataage(), aes(x = Week_Number, y = ED_ILI, color = Age_Group)) +
      geom_point(size = 3) + #######Consider size=4 paired with line size = 2 
      geom_line(aes(group = Age_Group, linetype = Age_Group), size = 1) +
      labs(title = "Proportion of ED Visits for ILI by Age Group, Suburban Cook County", x = "MMWR Week", y = "% of Visits for ILI") +
      scale_color_manual(values = groupcolorsage, name = "Age Group") +
      scale_linetype_manual(values = grouplinesage, name = "Age Group") +
      scale_y_continuous(limits = c(0,8), expand = c(0,0)) +
      theme(plot.title = element_text(size = 16, face = "bold", hjust = 0.5), legend.title = element_text(size = 14, face = "bold"), 
            legend.text = element_text(size = 12), axis.title = element_text(size = 14, face = "bold"), axis.text = element_text(size = 10),
            panel.grid = element_blank(), panel.background = element_blank(), axis.line = element_line())
    
    
  })
  
  output$downloadage <- downloadHandler(
    filename = "ED_Data_by_Age.png",
    content = function(edagefile){
      ggsave(edagefile, plot = edageplot(), device = "png", height = 3, width = 10, unit = "in")
    }
  )
  
  output$hover_info_age <- renderUI({
      
      hover <- input$plot_hover_age
      point <- nearPoints(userdataage(), hover, threshold = 5, maxpoints = 1, addDist = TRUE)
      if (nrow(point) == 0) return(NULL)
      
      left_pct <- (hover$x - hover$domain$left) / (hover$domain$right - hover$domain$left)
      top_pct <- (hover$domain$top - hover$y) / (hover$domain$top - hover$domain$bottom)
      
      left_px <- hover$range$left + left_pct * (hover$range$right - hover$range$left)
      top_px <- hover$range$top + top_pct * (hover$range$bottom - hover$range$top)
      
      style <- paste0("position:absolute; z-index:100; background-color: rgba(245, 245, 245, 0.85); ",
                      "left:", left_px + 2, "px; top:", top_px + 2, "px;")
      wellPanel(
        style = style,
        p(HTML(paste0("<b> Age Group: </b>", point$Age_Group, "<br/>",
                      "<b> MMWR Week: </b>", point$Week_Number, "<br/>",
                      "<b> % of ED Visits for ILI: </b>", point$ED_ILI, "<br/>")))
      )
  })
   
  
  #==========================================LAB DATA (SERVER)=============================================================#
  
  
  
}

