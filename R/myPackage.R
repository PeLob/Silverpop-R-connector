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
	
	
	StartDate <- as.character(format(Sys.time()-24*60*60*730, "%m/%d/%Y %H:%M:%S"))
	#StartDate <- as.character(format(Sys.time()-24*60*60*365, "%m/%d/%Y %H:%M:%S"))
	#EndDate <- as.character(format(Sys.time(), "%m/%d/%Y %H:%M:%S")) #add 24 hours
	EndDate <- as.character(format(Sys.time()-24*60*60*365, "%m/%d/%Y %H:%M:%S"))
		
	  
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
				<ExportTable>    
				<MOVE_TO_FTP>TRUE</MOVE_TO_FTP> 
				<EXPORT_FORMAT>0</EXPORT_FORMAT>   
				<EMAIL>Email</EMAIL> 
				<TABLE_ID>117655</TABLE_ID>
  				</ExportTable>  
			  </Body> 
			  </Envelope>"

	# Trick to pass the parameters
	#body2 <- gsub("StartDate", StartDate, body2)
	#body2 <- gsub("EndDate", EndDate, body2)
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
  
  
  
}
