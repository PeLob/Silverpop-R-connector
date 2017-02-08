#' Sample skeleton for custom science - Main application function
#'
#' @import keboola.r.docker.application
#' @export
#' @param datadir Path to data directory.
doSomething <- function(datadir) {
   

  
	# do something
	app <- DockerApplication$new(datadir)
	app$readConfig()
	
	
	apiURL <- app$getParameters()$apiURL
	Email <- app$getParameters()$Email
	UserName <- app$getParameters()$UserName
	PassWord <- app$getParameters()$PassWord
	
	
	StartDate <- as.character(format(Sys.time()-24*60*60, "%m/%d/%Y %H:%M:%S"))
	EndDate <- as.character(format(Sys.time(), "%m/%d/%Y %H:%M:%S")) #add 24 hours 
		
	  
	# Authentication request
	body1 <- "<Envelope><Body>
	<Login>
	<USERNAME>UserName</USERNAME>
	<PASSWORD>PassWord</PASSWORD>
	</Login>
	</Body></Envelope>"

	body1 <- gsub("UserName", UserName, body1)
	body1 <- gsub("PassWord", PassWord, body1)

	test1 <- POST(url = apiURL, body = body1, 
				  verbose(), content_type("text/xml"))


	parsed <- htmlParse(test1)
	js <- xpathSApply(parsed, "//session_encoding", xmlValue)

	#Gather sessionid for further requests
	jsessionid <- gsub(";","?",js)


	## Date parameters: COULD WE PASS DATE PARAMETERS FROM THE ORCHESTRATION LAYER?
	body2 <- "<Envelope>
			  <Body>   
				<RawRecipientDataExport>    
				<EVENT_DATE_START>StartDate</EVENT_DATE_START>    
				<EVENT_DATE_END>EndDate</EVENT_DATE_END>    
				<MOVE_TO_FTP>TRUE</MOVE_TO_FTP> 
				<EXPORT_FORMAT>0</EXPORT_FORMAT>   
				<EMAIL>Email</EMAIL>    
				<ALL_EVENT_TYPES/>    
				<INCLUDE_INBOX_MONITORING/>   
				</RawRecipientDataExport>  
			  </Body> 
			  </Envelope>"

	# Trick to pass the parameters
	body2 <- gsub("StartDate", StartDate, body2)
	body2 <- gsub("EndDate", EndDate, body2)
	body2 <- gsub("Email", Email, body2)

	test2 <- POST(url = paste(apiURL,jsessionid,sep=""), body = body2
				  ,verbose(), content_type("text/xml"))


	xml_data <- xmlParse(test2)

	## 
	nodes <- getNodeSet(xml_data, "//FILE_PATH")

	## Parse response to Data Frame
	data <- xmlToDataFrame(nodes)

	fname <- as.character(data[[1]])
	
	fname_df <- data.frame(filename = fname)
 


  # write output
   write.csv(fname_df, file = file.path(datadir, "out/tables/last_file.csv"), row.names = FALSE)
  
  
  # Get the file from FTP

	library(RCurl)
	url <- "sftp://transfer6.silverpop.com/download/"
	userpwd <- paste0(UserName,":",PassWord)
	
	last_file_df <- read.csv("in/tables/last_file.csv")
	last_file <- last_file_df[1,1]
	
	zipfile <- getBinaryURL(paste(url,last_file,sep=""), userpwd = userpwd)
	writeBin(zipfile, "test.zip")
	unzip("test.zip")

	csv_file <- gsub("zip","csv",last_file)

	df <- read.csv(csv_file)
	
	write.csv(fname_df, file = file.path(datadir, "out/tables/events.csv"), row.names = FALSE)
}
