clear
clear matrix
clear mata
capture log close
set maxvar 15000
set more off
numlabel, add

*******************************************************************************
*
*  FILENAME:	CCRX_Listing_v1_$date.do
*  PURPOSE:		Generates listing database and 
*  CREATED:		Linnea Zimmerman (lzimme12@jhu.edu)
*  DATA IN:		CDR4_Listing_v#.csv
*  DATA OUT:	CDR4_Listing_$date.dta
*  UPDATES:		v2-01Nov2017 Linnea Zimmerman added code to incorporate second csv file
*
*******************************************************************************

*******************************************************************************
* INSTRUCTIONS
*******************************************************************************
*
* 1. Update macros/directories in first section
*
*******************************************************************************
* SET MACROS AND CORRECT DOI: UPDATE THIS SECTION FOR EACH COUNTRY/ROUND
*******************************************************************************


clear matrix
clear
set more off

local today=c(current_date)
local c_today= "`today'"
local date=subinstr("`c_today'", " ", "",.)
di "`date'"

global date=subinstr("`c_today'", " ", "",.)

**Create a folder where you will store Round 1 Data
*In that folder, create a folder called CSV_Files and a folder called Listing
*Within the Listing folder, create a folder called Archived_data
*Use this folder as your data directory and update the global datadir

local Country DRC

local CCRX CDR7

local Round Round7

local Listingcsv CDR7_Listing_v6
local Listingcsv2 CDR7_Listing_v6

local dofiledate 17Jun2015

local GeoID "level1 level2 level3 level4 EA"

local StructureHH "number_structure_HH"
local StructureSDP "number_SDP"


**************** Update to the directories where:

**The csv files are saved
global csvdir "/Users/ealarson/Dropbox (Gates Institute)/7 DRC/PMADataManagement_DRC/Round7/Data/CSV_Files"

**Where you want the datasets to save (DO NOT SAVE ON DROPBOX)
global datadir "/Users/ealarson/Documents/DRC/Data_NotShared/Round7/Listing"

**Where the do files are saved
global dofiledir "/Users/ealarson/Dropbox (Gates Institute)/7 DRC/PMADataManagement_DRC/Round7/Cleaning_DoFiles/Current"


*******************************************************************************************
 			******* Stop Updating Macros Here *******
******************************************************************************************* 			


cd "$datadir/Listing"


*Create folder called Archived_Data in the Listing Folder
* Zip all of the old versions of the datasets.  Updates the archive rather than replacing so all old versions are still in archive
capture zipfile `CCRX'*, saving (Archived_Data/ArchivedListing_$date.zip, replace)

*Delete old versions.  Old version still saved in ArchivedData.zip
shell rm `CCRX'_*

*Added second csv file for multiple versions
tempfile tempList


	clear
	capture insheet using "$csvdir/`Listingcsv'.csv", comma case

	tostring *, replace force
	save `CCRX'_Listing_$date.dta, replace	
	
	clear
	capture insheet using "$csvdir/`Listingcsv2'.csv", comma case
if _rc==0 {
	tostring *, replace force
	save `tempList', replace
	use `CCRX'_Listing_$date.dta
	append using `tempList', force
	save `CCRX'_Listing_$date.dta, replace	
}

**********************
clear


**Merge in household information into structure information


	clear
	capture insheet using "$csvdir/`Listingcsv'_HH_grp.csv", comma case

	tostring *, replace force
	save `CCRX'_ListingHH_$date, replace


clear
	capture insheet using "$csvdir/`Listingcsv2'_HH_grp.csv", comma case
if _rc==0 {
	tostring *, replace force
	save `tempList', replace
	use `CCRX'_ListingHH_$date.dta
	append using `tempList', force
	save `CCRX'_ListingHH_$date.dta, replace	
}
	
	

use `CCRX'_ListingHH_$date.dta
save, replace

**The first database is just the structures, there should not be any duplicate households because households need to be merged in
use `CCRX'_Listing_$date

***Make sure Block Census code for Indonesia is consistent in all entries
capture replace blok_sensus=upper(blok_sensus)

capture rename ea EA
capture rename name_grp* *
capture rename B_grpB your_name
capture rename B_grpB2 name_typed
capture rename B3 your_name_check 
replace your_name=name_typed if your_name_check=="no"
rename your_name RE

*Check for duplicate
destring number_structure_HH, replace
destring number_HH, replace
destring number_SDP, replace

duplicates drop metainstanceID, force
save, replace

clear
use `CCRX'_ListingHH_$date
capture confirm PARENT_KEY
capture duplicates drop KEY, force
rename PARENT_KEY metainstanceID
save, replace
use `CCRX'_Listing_$date.dta

*merge in household group information into structure information
merge 1:m metainstanceID using `CCRX'_ListingHH_$date
drop if EA=="9999"
save `CCRX'_ListingCombined_$date, replace


******************************************************************************************************
*****************CLEAN THE LISTING FORM OF DUPLICATE SUBMISSIONS OR NUMBERING ERRORS*************

**Clean duplicates that are listed below usng the Listing File
run "$dofiledir/`CCRX'_CleaningByRE_LISTING_`dofiledate'.do"
save, replace

*******************************************************************************************************

use `CCRX'_ListingCombined_$date.dta
egen metatag=tag(metainstanceID)
save, replace
keep if metatag==1

sort `GeoID' `StructureHH'
rename duplicate_check IsThisResubmission

duplicates tag `GeoID' `StructureHH' HH_SDP if HH_SDP=="HH", gen(dupHHstructure)
capture duplicates tag `GeoID' `StructureSDP' HH_SDP if HH_SDP=="SDP", gen(dupSDPstructure)


**Keep only the structure numbers that are duplicates.  Even if they are multiHH dwellings, there should not be duplicate structure numbers
**First export out list of duplicate households
preserve
capture confirm variable dupHHstructure
if _rc!=111{

	keep if dupHHstructure!=0 & dupHHstructure!=.
	sort RE `GeoID' `StructureHH' 
	save `CCRX'_ListingDuplicates_$date.dta, replace

	**Dropping the unnecessary variables 
	order metainstanceID RE `GeoID' `StructureHH' HH_SDP Occupied_YN_HH mult_HH number_HH address_description_HH* IsThis* dupHHstructure
	keep metainstanceID RE `GeoID' `StructureHH' HH_SDP  Occupied_YN_HH mult_HH number_HH address_description_HH* IsThis* dupHHstructure

	capture noisily export excel using "`CCRX'_ListingErrors_$date.xls", sh("DupHHStructures") firstrow(variables) replace
if _rc!=198{
	restore
	}
	if _rc==198 { 
		clear
		set obs 1
		gen x="NO DUPLICATE HOUSEHOLD STRUCTURES"
		export excel using `CCRX'_ListingErrors_$date.xls, firstrow(variables) sh("DupHHStructures") sheetreplace
		restore
		} 
	
}

else{
restore
}

***Second export list of duplicate SDPs.  Do separately because there may not be SDPs immediatley, and the code will have errors
*if combine SDP and HH code

capture confirm var dupSDPstructure
	if _rc!=111{
preserve
	keep if dupSDPstructure!=0  
	sort `GeoID' RE `StructureSDP'
	save `tempList', replace
	use `CCRX'_ListingDuplicates_$date.dta, replace
	append using `tempList'
	save, replace
	
	**Dropping the unnecessary variables 
	restore
	
	preserve
	
	keep if dupSDPstructure!=0 & dupSDPstructure!=.
	
	order metainstanceID RE `GeoID' HH_SDP `StructureSDP' address_description_SDP* IsThis*
	keep metainstanceID RE `GeoID' HH_SDP `StructureSDP' address_description_SDP* IsThis* dupSDP*

capture noisily export excel using "`CCRX'_ListingErrors_$date.xls", sh("DupSDPStructures") firstrow(variables) sheetreplace
if _rc!=198{
	restore
	}
	if _rc==198 { 
		clear
		set obs 1
		gen x="NO DUPLICATE SDP STRUCTURES"
		export excel using `CCRX'_ListingErrors_$date.xls, firstrow(variables) sh("DupSDPStructures") sheetreplace
		restore
		} 

}

preserve

gen HH=1 if HH_SDP=="HH"
gen SDP=1 if HH_SDP=="SDP"

collapse (count) HH SDP, by(RE `GeoID')
sort RE EA
rename HH HHStructures 
rename SDP SDPStructures
save `CCRX'_ListingErrors_$date.dta, replace
restore
clear

use `CCRX'_ListingCombined_$date, replace

*check to see if multihousehold dwellings have more than one entry
gen HH=1 if HH_SDP=="HH"
gen SDP=1 if HH_SDP=="SDP"
save, replace

bysort metainstanceID: egen HHcount=total(HH)

preserve
sort  `GeoID' RE number_structure_HH
order RE  `GeoID' HH_SDP `StructureHH' Occupied_YN_HH mult_HH number_HH address*
keep RE `GeoID' HH_SDP `StructureHH' Occupied_YN_HH mult_HH number_HH metatag HHcount address* 

capture export excel using "`CCRX'_ListingErrors_$date.xls" if metatag==1 & HHcount==1 & mult_HH=="yes", sh(MultiHHError) sheetreplace firstrow(variables)
if _rc!=198{
	restore
	}
	if _rc==198 { 
		clear
		set obs 1
		gen x="NO STRUCTURES LISTED AS MULTI-HOUSEHOLD WITH ONLY ONE HOUSEHOLD"
		export excel using `CCRX'_ListingErrors_$date.xls, firstrow(variables) sh("MultiHHError") sheetreplace
		restore
		} 


**Generating the average number of households in the EA and the number of errors (multi with only one HH)
generate multiHHerr=1 if mult_HH=="yes" & HHcount==1
save, replace

tempfile collapse

preserve 
keep if HH==1
collapse (count) HH multiHHerr, by (RE `GeoID' ) 
rename HH NumberHHperEA
rename multiHHerr SingleHHlabeledMulti
save `collapse', replace
restore 

use `CCRX'_ListingErrors_$date.dta
merge 1:1 RE `GeoID' using `collapse', nogen
sort `GeoID' RE
save, replace

use `CCRX'_ListingCombined_$date.dta
**Get average number of households per structure. Have to keep only one structure
preserve 
keep if HH==1 & metatag==1
collapse (mean) HHcount, by (RE `GeoID' ) 
rename HHcount AverageHHperStrc
save `collapse', replace
restore 

use `CCRX'_ListingErrors_$date.dta
merge 1:1 RE `GeoID' using `collapse', nogen
sort `GeoID' RE
save, replace

*Export out forms and total the number of forms where the date is entered incorrectly
use `CCRX'_ListingCombined_$date.dta
preserve
gen datetag=.
split start, gen(start_)
replace datetag=1 if start_3!="2015"
drop start_*
split end, gen(end_)
replace datetag=1 if end_3!="2015"
drop end_*

keep if datetag==1 & metatag==1
capture collapse (sum) datetag if metatag==1, by (RE `GeoID')

	
if _rc!=2000{
	save `collapse', replace
	use `CCRX'_ListingErrors_$date
	merge 1:1 RE `GeoID' using `collapse', nogen
	save, replace
	}
	else {
	clear
	use `CCRX'_ListingErrors_$date
	gen datetag=.
	save, replace
	}


export excel using "`CCRX'_ListingErrors_$date.xls", sh(TotalsByRE) sheetreplace firstrow(variables)

restore

*Export out forms and total the total number of forms uploaded 
use `CCRX'_ListingCombined_$date.dta
preserve 
egen EAtag=tag(`GeoID')
tab EAtag
collapse (sum) HH EAtag SDP
label var HH "Total Households Listed and Uploaded"
label var SDP "Total Private SDP Listed and Uploaded"
label var EAtag "Total EAs with any forms uploaded"
order EAtag HH SDP
save `collapse', replace

export excel using "`CCRX'_ListingErrors_$date.xls", sh(OverallTotal) sheetreplace firstrow(varlabels)
restore


