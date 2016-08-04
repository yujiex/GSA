library(ggplot2)
library(DBI)
library(RColorBrewer)
library(plyr)
library(stringr)
library(Rmisc)
library(dplyr)
n <- 60
qual_col_pals = brewer.pal.info[brewer.pal.info$category == 'qual',]
col_vector = unlist(mapply(brewer.pal, qual_col_pals$maxcolors, rownames(qual_col_pals)))
con = dbConnect(drv=RSQLite::SQLite(), dbname="csv_FY/db/all.db")

df1 = dbGetQuery(con, 'SELECT DISTINCT Building_Number, Fiscal_Year FROM EUAS_monthly')
df2 = dbGetQuery(con, 'SELECT Building_Number, Cat FROM EUAS_category')
df = merge(x=df1, y=df2, by="Building_Number", all.x=TRUE)
df <- df[df$Fiscal_Year < 2016,]
## qplot(factor(Fiscal_Year), data=df, geom="bar", fill=factor(Cat))
df$Cat <- factor(df$Cat, levels=c("A", "I", "C", "B", "D", "E"))
ggplot(df, aes(Fiscal_Year, fill=Cat)) + geom_bar() + ylab("Building Count") + labs(title="EUAS Building Count By Category") + scale_fill_brewer(palette="Set3")
ggsave(file="plot_FY_annual/quant/building_by_cat.png", width=8, height=4, units="in")

## Building type count by year
colors = (c(brewer.pal(12, 'Set3'), "gray"))
## pie(rep(1,13), col=colors)
df1 = dbGetQuery(con, 'SELECT Building_Number, [Self-Selected_Primary_Function] as Type FROM EUAS_type')
df2 = dbGetQuery(con, 'SELECT DISTINCT Building_Number, Fiscal_Year FROM EUAS_monthly')
df = merge(x=df2, y=df1, by="Building_Number", all.x=TRUE)
df <- df[df$Fiscal_Year < 2016,]
df[is.na(df)] <- 'No Data'
df$Type <- factor(df$Type)
levels(df$Type)
df$Type <- factor(df$Type, levels(df$Type)[c(6, 1, 9, 2, 3, 5, 7, 8, 10:13, 4)])
levels(df$Type)
ggplot(df, aes(x=Fiscal_Year, fill=Type)) + geom_bar() + ylab("Building Count") + labs(title="EUAS Building Type Count by Year") + scale_fill_brewer(palette="Set3") + scale_fill_manual(values=colors)
ggsave(file="plot_FY_annual/quant/type_by_year.png", width=8, height=4, units="in")

## Building type count by cat
## colors = (c(brewer.pal(12, 'Set3'), "gray"))
## pie(rep(1,13), col=colors)
df1 = dbGetQuery(con, 'SELECT Building_Number, [Self-Selected_Primary_Function] as Type FROM EUAS_type')
df2 = dbGetQuery(con, 'SELECT DISTINCT Building_Number, Cat FROM EUAS_monthly')
df = merge(x=df2, y=df1, by="Building_Number", all.x=TRUE)
df[is.na(df)] <- 'No Data'
df$Type <- factor(df$Type)
levels(df$Type)
df$Type <- factor(df$Type, levels(df$Type)[c(6, 1, 9, 2, 3, 5, 7, 8, 10:13, 4)])
levels(df$Type)
df$Cat <- factor(df$Cat, levels=c("A", "I", "C", "B", "D", "E"))
ggplot(df, aes(x=Cat, fill=Type)) + geom_bar() + ylab("Building Count") + labs(title="EUAS Building Type Count By Category") + scale_fill_brewer(palette="Set3") + scale_fill_manual(values=colors)
ggsave(file="plot_FY_annual/quant/type_by_cat.png", width=8, height=4, units="in")

## Use the original count record
## library(ggplot2)
## library(DBI)
## library(RColorBrewer)
## con = dbConnect(drv=RSQLite::SQLite(), dbname="csv_FY/db/all.db")
## df = dbGetQuery(con, 'SELECT DISTINCT Building_Number, Fiscal_Year, Cat FROM EUAS_monthly')
## df$Cat <- factor(df$Cat, levels=c("A", "I", "C", "B", "D", "E"))
## ggplot(df, aes(Fiscal_Year, fill=Cat)) + geom_bar() + ylab("Building Count") + labs(title="EUAS Building Count By Category") + scale_fill_brewer(palette="Set3")

df1 = dbGetQuery(con, 'SELECT Building_Number, Fiscal_Year, status FROM eui_by_fy')
df2 = dbGetQuery(con, 'SELECT Building_Number, Cat FROM EUAS_category')
df = merge(x=df1, y=df2, by="Building_Number", all.x=TRUE)
df <- df[df$Fiscal_Year < 2016,]
df$status <- factor(df$status, levels=c("Electric EUI >= 12 and Gas EUI >= 3", "Low Electric EUI", "Low Gas EUI", "Low Gas and Electric EUI"))
ggplot(df, aes(Fiscal_Year, fill=status)) + geom_bar() + ylab("Building Count") + labs(title="EUAS Gas and Electric EUI By Category") + scale_fill_brewer(palette="Set3") + theme(legend.position="bottom")
ggsave(file="plot_FY_annual/quant/eui_byyear.png", width=8, height=4, units="in")

df1 = dbGetQuery(con, 'SELECT Building_Number, Fiscal_Year, status FROM eui_by_fy')
df2 = dbGetQuery(con, 'SELECT Building_Number, Cat FROM EUAS_category WHERE Cat in (\'A\', \'I\')')
df = merge(x=df1, y=df2, by="Building_Number")
df <- df[df$Fiscal_Year < 2016,]
df$status <- factor(df$status, levels=c("Electric EUI >= 12 and Gas EUI >= 3", "Low Electric EUI", "Low Gas EUI", "Low Gas and Electric EUI"))
ggplot(df, aes(Fiscal_Year, fill=status)) + geom_bar() + ylab("Building Count") + labs(title="Gas and Electric EUI of A + I Building in EUAS By Category") + scale_fill_brewer(palette="Set3") + theme(legend.position="bottom")
ggsave(file="plot_FY_annual/quant/eui_byyear_ai.png", width=8, height=4, units="in")

df = read.csv("input_R/robust_energy.csv")
df$Cat <- factor(df$Cat, levels=c("A", "I", "C", "B", "D", "E"))
ggplot(df, aes(Cat, fill=status)) + geom_bar() + ylab("Building Count") + labs(title="Robust energy by category") + scale_fill_brewer(palette="Set3") + theme(legend.position="bottom")
ggsave(file="plot_FY_annual/quant/robust_energy_cnt.png", width=8, height=4, units="in")

df = read.csv("input_R/cap_op_cnt.csv")
df1 = dbGetQuery(con, 'SELECT DISTINCT Building_Number, Fiscal_Year FROM EUAS_monthly')
df = merge(df1, df, by="Building_Number", all.x=TRUE)
df <- df[df$Fiscal_Year < 2016,]
df$status <- factor(df$status, levels=c("Capital and Operational", "Capital Only", "Operational Only", "No Known Investment"))
ggplot(df, aes(Fiscal_Year, fill=status)) + geom_bar() + ylab("Building Count") + labs(title="Capital vs Operational Investment By Fiscal Year") + scale_fill_brewer(palette="Set3") + theme(legend.position="bottom")
ggsave(file="plot_FY_annual/quant/co_cnt_byyear.png", width=8, height=4, units="in")

df = read.csv("input_R/cap_op_cnt.csv")
df1 = dbGetQuery(con, 'SELECT DISTINCT Building_Number, Fiscal_Year FROM EUAS_monthly')
df = merge(df1, df, by="Building_Number", all.x=TRUE)
df <- df[df$Fiscal_Year < 2016,]
df <- df[df$status != "No Known Investment",]
df$status <- factor(df$status, levels=c("Capital and Operational", "Capital Only", "Operational Only"))
ggplot(df, aes(Fiscal_Year, fill=status)) + geom_bar() + ylab("Building Count") + labs(title="Capital vs Operational Investment By Fiscal Year") + scale_fill_brewer(palette="Set3") + theme(legend.position="bottom") + ylim(0, 500)
ggsave(file="plot_FY_annual/quant/co_cnt_byyear_with.png", width=8, height=4, units="in")

df = read.csv("input_R/cap_op_cnt.csv")
df1 = dbGetQuery(con, 'SELECT Building_Number, Cat FROM EUAS_category')
df = merge(df1, df, by="Building_Number", all.x=TRUE)
df$status <- factor(df$status, levels=c("Capital and Operational", "Capital Only", "Operational Only", "No Known Investment"))
df$Cat <- factor(df$Cat, levels=c("A", "I", "C", "B", "D", "E"))
ggplot(df, aes(Cat, fill=status)) + geom_bar() + ylab("Building Count") + labs(title="Capital vs Operational Investment By Building Category") + scale_fill_brewer(palette="Set3") + theme(legend.position="bottom")
ggsave(file="plot_FY_annual/quant/co_cnt_bycat.png", width=8, height=4, units="in")

library(plyr)
df1 = read.csv("input_R/cap_op_cnt.csv")
df2 = read.csv("input_R/robust_energy.csv")
df2 <- rename(df2, c("status"="energy"))
df1 <- rename(df1, c("status"="investment"))
df = merge(df2, df1, by="Building_Number", all.x=TRUE)
df$investment <- factor(df$investment, levels=c("Capital and Operational", "Capital Only", "Operational Only", "With Investment", "No Known Investment"))
names(df)
ggplot(df, aes(investment, fill=energy)) + geom_bar() + ylab("Building Count") + labs(title="Capital vs Operational Investment Energy Data Quality") + scale_fill_brewer(palette="Set3") + theme(legend.position="bottom")
ggsave(file="plot_FY_annual/quant/co_energy.png", width=8, height=4, units="in")

library(plyr)
library(stringr)
getType <- function(s) {
    if (s %in% c("GSALink", "Advanced Metering", "LEED_EB", "GP", "first fuel", "Shave Energy", "E4")) {
        return("Operational")
    }
    else {
        return("Capital")
    }
}
give.n <- function(x){
return(c(y = median(x)*1.10, label = length(x))) 
}
# function for mean labels
mean.n <- function(x){
return(c(y = median(x)*0.97, label = round(mean(x),2))) 
# experiment with the multiplier to find the perfect position
}
# function for median labels
median.n <- function(x){
return(c(y = median(x)*0.92, label = round(median(x),1))) 
# experiment with the multiplier to find the perfect position
}
actionCountEUIgb <- function(cat, plottype) {
    df1 = dbGetQuery(con, 'SELECT DISTINCT Building_Number, high_level_ECM from EUAS_ecm WHERE high_level_ECM != \'GSALink\'')
    df2 = dbGetQuery(con, 'SELECT Building_Number, ECM_Program from EUAS_ecm_program')
    if (cat == "AI") {
        query = sprintf('SELECT Building_Number, Fiscal_Year, eui from eui_by_fy WHERE Cat in (%s) AND Fiscal_Year in (\'2003\', \'2015\')', '\'A\', \'I\'')
    }
    else {
        query = sprintf('SELECT Building_Number, Fiscal_Year, eui from eui_by_fy WHERE Fiscal_Year in (\'2003\', \'2015\')')
    }
    df3 = dbGetQuery(con, query)
    df1 <- df1[complete.cases(df1),]
    df2 <- df2[complete.cases(df2),]
    print(names(df1))
    print(names(df2))
    df1 <- plyr::rename(df1, c("high_level_ECM"="investment"))
    df2 <- plyr::rename(df2, c("ECM_program"="investment"))
    df = rbind(df1, df2)
    ## need to correct GP
    dfall = merge(df, df3, by="Building_Number", all.x=TRUE)
    dfall$type = sapply(dfall$investment, getType)
    dfall$type <-
        factor(dfall$type, levels=c("Capital", "Operational"))
    dfall <- dfall[complete.cases(dfall),]
    dfall$Fiscal_Year <- factor(dfall$Fiscal_Year)
    dfall$investment <-
    factor(dfall$investment, levels=c("LEED_EB","ESPC","GSALink",
                                      "first fuel",
                                      "Building Tuneup or Utility Improvements",
                                      "HVAC","Lighting",
                                      "Advanced Metering","GP","E4",
                                      "Building Envelope",
                                      "Shave Energy","LEED_NC"))
    dfall %>% dplyr::group_by(investment, Fiscal_Year) %>% dplyr::summarize(median=median(eui)) %>% write.csv(file="/media/yujiex/work/GSA/merge/plot_FY_annual/quant_data/box03vs15.csv")
    p <- ggplot(dfall, aes(x=investment, y=eui, fill=Fiscal_Year))
    if (plottype == "vio") {
        p <- p + geom_violin()
    }
    else if (plottype == "box") {
        p <- p + geom_boxplot()
    }
    p <- p + ylab("kBtu/sq.ft") +
        labs(title=sprintf("Electric + Gas EUI by Energy Investment %s Building in FY2003 vs FY2015", cat)) +
        scale_fill_brewer(palette="Accent") +
        theme(legend.position="bottom") +
        scale_x_discrete(labels = function(x) str_wrap(x, width = 10)) +
        stat_summary(fun.data=give.n, geom="text", fun.y=median, position=position_dodge(width = 0.75), size=3) +
        stat_summary(fun.data=median.n, geom="text", fun.y=median, position=position_dodge(width = 0.75), size=3)
    ggsave(file=sprintf("plot_FY_annual/quant/invest_eui_1315.png", cat, plottype), width=12, height=6, units="in")
    print(p)
}
actionCountEUIgb("AI", "box")

getType <- function(s) {
    if (s %in% c("GSALink", "Advanced Metering", "LEED_EB", "GP", "first fuel", "Shave Energy", "E4")) {
        return("Operational")
    }
    else {
        return("Capital")
    }
}
give.n <- function(x){
return(c(y = median(x)*1.05, label = length(x))) 
}
# function for mean labels
mean.n <- function(x){
return(c(y = median(x)*0.97, label = round(mean(x),2))) 
# experiment with the multiplier to find the perfect position
}
# function for median labels
median.n <- function(x){
return(c(y = median(x)*0.90, label = round(median(x),2))) 
# experiment with the multiplier to find the perfect position
}
actionCountEUI <- function(cat, year, plottype) {
    df1 = dbGetQuery(con, 'SELECT DISTINCT Building_Number, high_level_ECM from EUAS_ecm WHERE high_level_ECM != \'GSALink\'')
    df2 = dbGetQuery(con, 'SELECT Building_Number, ECM_Program from EUAS_ecm_program')
    if (cat == "AI") {
        if (year != "all") {
            query = sprintf('SELECT Building_Number, eui from eui_by_fy WHERE Cat in (%s) AND Fiscal_Year = %s', '\'A\', \'I\'', year)
        }
        else {
            query = sprintf('SELECT Building_Number, eui from eui_by_fy WHERE Cat in (%s)', '\'A\', \'I\'')
        }
    }
    else {
        if (year != "all") {
            query = sprintf('SELECT Building_Number, eui from eui_by_fy WHERE Fiscal_Year = %s', year)
        }
        else {
            query = sprintf('SELECT Building_Number, eui from eui_by_fy', year)
        }
    }
    df3 = dbGetQuery(con, query)
    df1 <- df1[complete.cases(df1),]
    df2 <- df2[complete.cases(df2),]
    df1 <- rename(df1, c("high_level_ECM"="investment"))
    df2 <- rename(df2, c("ECM_program"="investment"))
    df = rbind(df1, df2)
    ## need to correct GP
    dfall = merge(df, df3, by="Building_Number", all.x=TRUE)
    dfall$type = sapply(dfall$investment, getType)
    dfall$type <-
        factor(dfall$type, levels=c("Capital", "Operational"))
    dfall <- dfall[complete.cases(dfall),]
    summary(dfall)
    p <- ggplot(dfall, aes(x=investment, y=eui, fill=type))
    if (plottype == "vio") {
        p <- p + geom_violin()
    }
    else if (plottype == "box") {
        p <- p + geom_boxplot()
    }
    p <- p + ylab("kBtu/sq.ft") +
        labs(title=sprintf("Electric + Gas EUI by Energy Investment %s Building in FY%s", cat, year)) +
        scale_fill_brewer(palette="Accent") +
        theme(legend.position="bottom") +
        scale_x_discrete(labels = function(x) str_wrap(x, width = 10)) +
        stat_summary(fun.data=give.n, geom="text", fun.y=median) +
        stat_summary(fun.data=median.n, geom="text", fun.y=median)
    ggsave(file=sprintf("plot_FY_annual/quant/invest_eui_%s_%s_%s.png", cat, year, plottype), width=12, height=6, units="in")
    if (year != "all") {
        p <- ggplot(df, aes(investment, fill=type))
    } else {
        p <- ggplot(dfall, aes(investment, fill=type))
    }
    p <- p + geom_bar() + ylab("Building Count") +
        labs(title=sprintf("Energy Investment %s Building in FY%s", cat, year)) +
        scale_fill_brewer(palette="Accent") +
        theme(legend.position="bottom") +
        scale_x_discrete(labels = function(x) str_wrap(x, width = 10))
    ggsave(file=sprintf("plot_FY_annual/quant/invest_cnt_%s_%s.png", cat, year, plottype), width=8, height=4, units="in")
}
actionCountEUI("all", "all", "box")
## actionCountEUI("AI", "2015", "box")
## actionCountEUI("AI", "2003", "box")
## actionCountEUI("AI", "2015", "vio")
## actionCountEUI("AI", "2003", "vio")

## average square footage trend
library(Rmisc)
df = dbGetQuery(con, 'SELECT * from EUAS_area')
df <- df[df$Fiscal_Year < 2016,]
df$Fiscal_Year <- factor(df$Fiscal_Year)
dfs <- summarySE(df, measurevar="Gross_Sq.Ft", groupvars=c("Fiscal_Year"))
ggplot(dfs, aes(x=Fiscal_Year, y=Gross_Sq.Ft)) + geom_bar(stat="identity") + geom_errorbar(aes(ymin=Gross_Sq.Ft-ci, ymax=Gross_Sq.Ft+ci), width=.2, position=position_dodge(.9)) + ylab("Average Gross_Sq.Ft")
ggsave(file="plot_FY_annual/quant/ave_area.png", width=8, height=4, units="in")

## average square footage by category
library(Rmisc)
library(ggplot2)
library(DBI)
library(RColorBrewer)
con = dbConnect(drv=RSQLite::SQLite(), dbname="csv_FY/db/all.db")
df1 = dbGetQuery(con, 'SELECT * from EUAS_area')
df2 = dbGetQuery(con, 'SELECT Building_Number, Cat from EUAS_category')
df = merge(df1, df2, by="Building_Number", all.x=TRUE)
df <- df[df$Fiscal_Year < 2016,]
df$Fiscal_Year <- factor(df$Fiscal_Year)
head(df)
dfs <- summarySE(df, measurevar="Gross_Sq.Ft", groupvars=c("Cat", "Fiscal_Year"))
head(dfs)
pd <- position_dodge(0.1)
dfs$Cat <- factor(dfs$Cat, levels=c("A", "I", "C", "B", "D", "E"))
ggplot(dfs, aes(x=Cat, y=Gross_Sq.Ft, fill=Fiscal_Year)) + geom_bar(position=position_dodge(), stat="identity") + ylab("Average Gross_Sq.Ft")
## ggplot(dfs, aes(x=Fiscal_Year, y=Gross_Sq.Ft, color=Cat)) +
##     geom_line(aes(group=Cat), position=pd) +
##     expand_limits(y = 0) +
    ## geom_errorbar(aes(ymin=Gross_Sq.Ft-ci, ymax=Gross_Sq.Ft+ci),
    ##               width=.1, position=pd) +
    ## geom_point(position=pd)
ggsave(file="plot_FY_annual/quant/ave_area_bycat.png", width=8, height=4, units="in")
## ggsave(file="plot_FY_annual/quant/ave_area_bycat_line.png", width=8, height=4, units="in")

## covered by category
df1 = dbGetQuery(con, 'SELECT DISTINCT Building_Number from covered_facility')
df2 = dbGetQuery(con, 'SELECT Building_Number, Cat from EUAS_category')
df3 = dbGetQuery(con, 'SELECT Building_Number, [Self-Selected_Primary_Function] as Type FROM EUAS_type')
df = merge(df1, df2, on='Building_Number')
df <- merge(df, df3, on='Building_Number')
df$Cat <- factor(df$Cat, levels=c("A", "I", "C", "B", "D", "E"))
df$Type <- factor(df$Type)
levels(df$Type)
df$Type <- factor(df$Type, levels(df$Type)[c(4, 1, 6, 2, 3, 5)])
levels(df$Type)
ggplot(df, aes(x=Cat, fill=Type)) + geom_bar() + ylab("Building Count") + xlab("Category") + labs(title="Covered facility by category and type") + scale_fill_brewer(palette="Set3")
ggsave(file="plot_FY_annual/quant/cover_bycat.png", width=8, height=4, units="in")

## area distribution by year cat I
## cat = "I"
cat = "A"
df1 = dbGetQuery(con, 'SELECT * from EUAS_area')
df2 = dbGetQuery(con, 'SELECT Building_Number, Cat from EUAS_category')
df = merge(df1, df2, by="Building_Number", all.x=TRUE)
nrow(df)
df <- df[df$Cat == cat,]
df$Fiscal_Year <- factor(df$Fiscal_Year)
nrow(df)
p <- ggplot(df, aes(x=Fiscal_Year, y=Gross_Sq.Ft))
p <- p + geom_boxplot()
print(p)
ggsave(file=sprintf("plot_FY_annual/quant/area_byyear_%s.png", cat), width=8, height=4, units="in")
