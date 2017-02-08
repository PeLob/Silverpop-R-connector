devtools::load_all('/home/')
library(keboola.r.custom.application)
requestSilverpopEvents(Sys.getenv("KBC_DATADIR"))
