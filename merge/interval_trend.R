library("DBI")
library("dygraphs")
library("xts")
library("htmlwidgets")
## hourly
con = dbConnect(drv=RSQLite::SQLite(), dbname="csv_FY/db/interval_ion.db")

ids = dbGetQuery(con, 'SELECT DISTINCT Building_Number FROM gas')[['Building_Number']]
for (x in ids) {
    query = paste0(sprintf("SELECT Building_Number, SUM([Gas_(CubicFeet)]) AS Gas, Timestamp FROM gas WHERE Building_Number = '%s'", x), " GROUP BY STRFTIME('%Y', Timestamp), STRFTIME('%m', Timestamp), STRFTIME('%d', Timestamp), STRFTIME('%H', Timestamp);")
    p1 = dbGetQuery(con, query)
    head(p1)
    timeseries = xts(p1["Gas"], as.POSIXlt(p1$Timestamp))
    dygraph(timeseries, xlab='Time', ylab='Cubic Feet', main=paste0(x, 'Gas Hourly')) %>% dyRangeSelector() %>% saveWidget(sprintf("plot_interval_hour/%s_gas.html", x), selfcontained=FALSE,libdir="plot_interval_hour")
}

con = dbConnect(drv=RSQLite::SQLite(), dbname="csv_FY/db/interval_ion.db")
ids = dbGetQuery(con, 'SELECT DISTINCT Building_Number FROM electric')[['Building_Number']]
for (x in ids) {
    query = paste0(sprintf("SELECT Building_Number, SUM([Electric_(KWH)]) AS Electric, Timestamp FROM electric WHERE Building_Number = '%s'", x), " GROUP BY STRFTIME('%Y', Timestamp), STRFTIME('%m', Timestamp), STRFTIME('%d', Timestamp), STRFTIME('%H', Timestamp);")
    p1 = dbGetQuery(con, query)
    head(p1)
    timeseries = xts(p1["Electric"], as.POSIXlt(p1$Timestamp))
    dygraph(timeseries, xlab='Time', ylab='KWH', main=paste0(x, 'Electric Hourly')) %>% dyRangeSelector() %>% saveWidget(sprintf("plot_interval_hour/%s_electric.html", x), selfcontained=FALSE,libdir="plot_interval_hour")
}

## original 15 min
con = dbConnect(drv=RSQLite::SQLite(), dbname="csv_FY/db/interval_ion.db")
ids = dbGetQuery(con, 'SELECT DISTINCT Building_Number FROM gas')[['Building_Number']]
for (x in ids[1]) {
    p1 = dbGetQuery(con,sprintf('SELECT * FROM gas WHERE Building_Number = \'%s\'', x)) ## original
    timeseries = xts(p1["Gas_(CubicFeet)"], as.POSIXlt(p1$Timestamp))
    dygraph(timeseries, xlab='Time', ylab='Cubic Feet', main=paste0(x, 'Gas')) %>% dyRangeSelector() %>% saveWidget(sprintf("plot_interval/%s_gas.html", x), selfcontained=FALSE,libdir="plot_interval")
}

ids = dbGetQuery(con, 'SELECT DISTINCT Building_Number FROM electric')[['Building_Number']]
for (x in ids) {
    p1 = dbGetQuery(con,sprintf('SELECT * FROM electric WHERE Building_Number = \'%s\'', x))
    timeseries = xts(p1["Electric_(KWH)"], as.POSIXlt(p1$Timestamp))
    dygraph(timeseries, xlab='Time', ylab='KWH', main=paste0(x, ' Electric')) %>% dyRangeSelector() %>% saveWidget(sprintf("plot_interval/%s_electric.html", x), selfcontained=FALSE,libdir="plot_interval")
}

## after remove outlier
con = dbConnect(drv=RSQLite::SQLite(), dbname="csv_FY/db/interval_ion.db")
ids = dbGetQuery(con, 'SELECT DISTINCT Building_Number FROM gas_outlier_tag')[['Building_Number']]
for (x in ids) {
    print(x)
    p1 = dbGetQuery(con,sprintf('SELECT * FROM gas_outlier_tag WHERE Building_Number = \'%s\' AND outlier == \'0\'', x)) ## original
    timeseries = xts(p1["Gas_(CubicFeet)"], as.POSIXlt(p1$Timestamp))
    dygraph(timeseries, xlab='Time', ylab='Cubic Feet', main=paste0(x, 'Gas')) %>% dyRangeSelector() %>% saveWidget(sprintf("remove_outlier_gas/%s_gas.html", x), selfcontained=FALSE,libdir="remove_outlier_gas")
}

ids = dbGetQuery(con, 'SELECT DISTINCT Building_Number FROM electric_outlier_tag')[['Building_Number']]
for (x in ids) {
    print(x)
    p1 = dbGetQuery(con,sprintf('SELECT * FROM electric_outlier_tag WHERE Building_Number = \'%s\' AND outlier = \'0\'', x))
    timeseries = xts(p1["Electric_(KWH)"], as.POSIXlt(p1$Timestamp))
    dygraph(timeseries, xlab='Time', ylab='KWH', main=paste0(x, ' Electric')) %>% dyRangeSelector() %>% saveWidget(sprintf("remove_outlier_elec/%s_electric.html", x), selfcontained=FALSE,libdir="remove_outlier_elec")
}
