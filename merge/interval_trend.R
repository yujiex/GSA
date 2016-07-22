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

library("dygraphs")
library("xts")
library("htmlwidgets")
df = read.csv("csv_FY/temp/MA0131ZZ.csv")
head(df)
tsEnergy = xts(df["Electric_.KWH."], as.POSIXlt(df$Timestamp))
tsOutMild = xts(df["outlier_mild"], as.POSIXlt(df$Timestamp))
tsOutExt = xts(df["outlier_extreme"], as.POSIXlt(df$Timestamp))
head(tsEnergy)
dygraph(cbind(tsOut, tsEnergy, tsOutExt)) %>% dyRangeSelector %>% print()

## test
library("DBI")
library("dygraphs")
library("xts")
x = "MA0131ZZ"
con = dbConnect(drv=RSQLite::SQLite(), dbname="csv_FY/db/interval_ion.db")
p1 = dbGetQuery(con,sprintf('SELECT * FROM electric WHERE Building_Number = \'%s\'', x))
head(p1)
timeseries = xts(p1["Electric_(KWH)"], as.POSIXlt(p1$Timestamp))
head(timeseries)
dygraph(timeseries, xlab='Time', ylab='KWH', main=paste0(x, ' Electric')) %>% dyRangeSelector() %>% print()
