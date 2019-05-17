
/*
The purpose of this do file is to select households for reinterview. 

1. Update the macros below to be country and round specific
2. Update the EA that you are selecting
3. Update the variable names that you want to export and keep 
4. The information will export to an excel spreadsheet with the EA name/number
5. Send that information to the supervisor.  They will need to complete the entire 
reinterview questionnaire but will be able to directly compare some information
in the field.

**Use the combined dataset with names to identify households for selection 
for reinterview.  


*May 2, 2016 updated error to get geographic identifiers to export
*/

*******************************************************************************
* SET MACROS: UPDATE THIS SECTION FOR EACH EA THAT NEEDS RE_INTERVIEW INFORMATION
*******************************************************************************

*Dataset date - this is the date of the data you are using to select the 
*the households to reinterview
local datadate 2May2016
*Update the EA name/number
local EA "Odapu_Ogaji"

*******************************************************************************
* SET MACROS: UPDATE THIS SECTION FOR EACH COUNTRY/ROUND - ONLY NEEDS TO BE DONE ONCE
*******************************************************************************


*BEFORE USE THE FOLLOWING NEED TO BE UPDATED:
*Country 
local Country Nigeria

*Round Number
local Round Round3

*Country and Round Abbreviation
local CCRX NGR3

*Combined Dataset Name (must be the version with names)
local CombinedDataset `CCRX'_Combined_`datadate'.dta

*Geographic Identifier
global GeoID "state LGA Locality EA"

*Geographic Identifier lower than EA to household
global GEOID_SH "structure household"

*variables to keep
local varstokeep "RE firstname gender age eligible usual last_night"

**Directory where the Combined dataset is stored
global datadir "/Users/pma2020/Dropbox (Gates Institute)/Nigeria/Data_NotShared/Round3/Data/HHQFQ"

**Directory where the excel files will be exported to
global selectiondir "/Users/pma2020/Dropbox (Gates Institute)/Nigeria/Data_NotShared/Round3/Data/Selection"


*******************************************************************************************
 			******* Stop Updating Macros Here *******
******************************************************************************************* 			


cd "$selectiondir"

set seed 7261982

use "$datadir/`CombinedDataset'", clear
tempfile completetemp
save `completetemp', replace

keep if EA=="`EA'" 
keep if metatag==1

sample 5, count
gen reinterview=1
tempfile temp
keep metainstanceID reinterview
save `temp', replace

use `completetemp', clear
merge m:1 metainstanceID using `temp', nogen

keep if reinterview==1
keep $GeoID $GeoID_SH `varstokeep'

export excel using `CCRX'_ReinterviewInformation_`EA'.xls, firstrow(variables) replace
 

