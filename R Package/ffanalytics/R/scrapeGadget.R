#' Scrape gadget. Will be used as addin.
#' @export Run_Scrape
Run_Scrape <- function(){
  curYear <- as.POSIXlt(Sys.Date())$year + 1900
  weekList <- 0:17
  names(weekList) <- c("Season", paste("Week", 1:17))
  ui <- miniPage(
    gadgetTitleBar("Run Data Srape"),
    miniContentPanel(
      fillCol(flex = c(1,9),
              fillRow(
                selectInput("scrapeSeason", "Season", 2008:curYear,
                            selected = curYear, width = "90%"),
                selectInput("scrapeWeek", "Week",weekList, selected = 0, width = "90%"),
                "",""),

              fillRow(
                fillCol(flex = c(1,10),
                        miniButtonBlock(actionButton("allAnalyst", "All"),
                                        actionButton("nonSubs","Free"),
                                        actionButton("noAnalyst", "None")),
                        uiOutput("avail_analysts")),
                fillCol(flex = c(1,10),
                        miniButtonBlock(actionButton("allPosition", "All"),
                                        actionButton("offPosition", "Offense"),
                                        actionButton("nonIdpPosition", "Non-IDP"),
                                        actionButton("noPosition", "None")),
                        checkboxGroupInput("selectPositions", "Select Positions",
                                           position.name))))
    )
  )

  server <- function(input, output, session){
    scrapePeriod <- reactive(dataPeriod(weekNo = as.numeric(input$scrapeWeek),
                                        season = as.numeric(input$scrapeSeason)))

    output$avail_analysts <- shiny::renderUI({

      scrapePeriod <- dataPeriod(weekNo = as.numeric(input$scrapeWeek),
                                 season = as.numeric(input$scrapeSeason))
      analyst_list <- analystOptions(scrapePeriod)
      checkboxGroupInput("selectAnalyst", "Select Analysts", analyst_list)
    })

    observeEvent(input$allAnalyst, {
      allAnalysts <-analystOptions(scrapePeriod())
      updateCheckboxGroupInput(session, "selectAnalyst",
                               selected = as.character(allAnalysts))
    })
    observeEvent(input$nonSubs, {
      allAnalysts <-analystOptions(scrapePeriod())
      subSites <- sites[subscription == 1]
      freeAnalysts <- analysts[!(siteId %in% subSites$siteId)]
      freeAnalysts <- intersect(freeAnalysts$analystId, allAnalysts)
      updateCheckboxGroupInput(session, "selectAnalyst",
                               selected = as.character(freeAnalysts))
    })
    observeEvent(input$noAnalyst, {
      updateCheckboxGroupInput(session, "selectAnalyst", selected = character(0))
    })

    observeEvent(input$allPosition, {
      updateCheckboxGroupInput(session, "selectPositions", selected = position.name)

    })

    observeEvent(input$offPosition, {
      updateCheckboxGroupInput(session, "selectPositions",
                               selected = c("QB", "RB", "WR", "TE"))
    })

    observeEvent(input$nonIdpPosition, {
      updateCheckboxGroupInput(session, "selectPositions",
                               selected = c("QB", "RB", "WR", "TE", "K", "DST"))
    })

    observeEvent(input$noPosition, {
      updateCheckboxGroupInput(session, "selectPositions", selected = character(0))
    })

    observeEvent(input$done,{
      analystVector <- "NULL"
      positionVector <- "NULL"
      if(!is.null(input$selectAnalyst))
        analystVector <- paste0("c(", paste(input$selectAnalyst, collapse = ", "), ")")
      if(!is.null(input$selectPositions))
        positionVector <- paste0("c(\"", paste(input$selectPositions,
                                               collapse = "\", \""), "\")")
      rCode <- paste0("runScrape(week = ", input$scrapeWeek,
                      ", season = ", input$scrapeSeason,
                      ", analysts = ", analystVector,
                      ", positions = ", positionVector, ")")

      rstudioapi::insertText(rCode, id = "#console")
      stopApp()
    }
    )
  }
  runGadget(ui, server, viewer = shiny::dialogViewer("Run a scrape", height = 725,
                                                     width = 800))
}

