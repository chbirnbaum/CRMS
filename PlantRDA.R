#REDUNDANCY ANALYSIS (RDA) with forward variable select for Christina
# Load packages
library(vegan)
require(grid)
library(tidyverse)

#Salinity change in subsample==========
env<-read.csv("CRMS_Soil.csv")
str(env)#7384 obs. of  19 variables: // $ StationID: Factor w/ 388 levels
table(env$year)#sampling effort across years
#2006 2007 2008 2009 2011 2012 2014 2015 
#1869 1764 2546  374    3   18  807    3 
#Measurements were very haphazard. I am able to look at the change between 2008 & 2014:
#But First compute:
#CV (coefficient of variation = sd/mean)
#to measure variability in salinity in each plot over time. 
env2<- env[env$year == "2008"|env$year == "2014",]
dim(env2)#3353   19

#Computing 3 Salinity measures in 2008 and 2014 joined together:
env3<-summarise(group_by(env2,StationFront), MeanSalinity=mean(SoilSalinity.ppt),
                SDSalinity=sd(SoilSalinity.ppt),CVSalinity= SDSalinity/MeanSalinity,
                MeanOrganicMatter=mean(OrganicMatter), MeanWetpH= mean(WetSoilpH) )
env3# A tibble: 164 × 4
range(env3$CVSalinity)#0.000000 1.804334

#SUBSET station of year 2008:
Stations2008<-env[env$year == "2008",c("StationFront","year" )]
dim(Stations2008)# 2546    2

#Subset 2008 StationFronts of env3 data
S08<- env3 [ which (env3$StationFront %in%  Stations2008$StationFront), c("StationFront", "MeanSalinity","SDSalinity","CVSalinity","MeanWetpH", "MeanOrganicMatter")]
S08# A tibble: 152 × 6
S08$year <- as.factor("2008")
S08

#GET VEG in 2008 
veg <- read.csv("CRMS_Marsh_Veg.csv")#From cleaned the CRMS_Marsh_Vegetation.csv to suit R.
str(veg)#293726 obs. of  24 variables:

#Join available env data by StationFront with year 2008 env data :
vegEnv<- veg[ which (veg$StationFront  %in%  S08$StationFront), c("In.Out","year", "StationID", "StationFront", "SpecCode", "Cover","CoverTotal", "Community")]
dim(vegEnv)#119590      8
names(vegEnv)#

#veg+Env Data.Frame in YEAR2008:
veg08<- vegEnv[ vegEnv$year=="2008", c("StationID","StationFront","Cover","CoverTotal","SpecCode","Community",  "year","In.Out")]
str(veg08)#10707 obs. of  8 variables:
veg08in <- veg08 [ ! veg08$In.Out == "Out",] #cutting out outside the plot records.
str(veg08in)#6644 obs. of  8 variables:
veg08in$Cover = ifelse(veg08in$Cover == 0, 0, 1) #turning Cover into presence/absence
veg08in<-veg08in[ , -7] #removing year column as it is causing issues with right_join

names(vegEnv08)
vegEnv08<-dplyr::right_join(veg08in,S08, by = "StationFront")
str(vegEnv08)#6647 obs. of  12 variables: NA records exist where not met with veg data
vegEnv08<-vegEnv08[ ! is.na(vegEnv08$StationID),] #removing one NA row
str(vegEnv08)#YAY! 6644 obs.as before joining.

#WE need to spread the VegEnv08 to wide format:
vegEnv08wide<-spread(vegEnv08,key = SpecCode, value = Cover, fill = 0)#species indices can be computed only when species are 
str(vegEnv08wide)#1478 obs. of  260 variables:

#Matrices for RDA (Christina)==================
#Create veg-only matrix for year 2008:
vegData2008 <- vegEnv08wide[,12:260]
range(rowSums(vegData2008))# 1 20 = richness range
sum(vegData2008[is.na(vegData2008)])#ZERO NAs!! YAY!!!

#Create environmental data (soil data)
envData2008<- vegData2008[ , c("year", "MeanSalinity", "Community","CVSalinity","MeanOrganicMatter","MeanWetpH ")]

