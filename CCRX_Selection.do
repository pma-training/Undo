
clear
clear matrix
clear mata
capture log close
set maxvar 15000
set more off
numlabel, add

/*******************************************************************************
*
*  FILENAME:	CCRX_Selection_11May2015
*  PURPOSE:		Generate database of households selected for interview
*  CREATED:		Linnea Zimmerman (lzimme12@jhu.edu)
*  DATA IN:		CCRX_Selection_vX.csv
*  DATA OUT:	`CCRX'_Selection_$date.dta
*  UPDATES:		08/11/2015 by Linnea Zimmerman

*
*******************************************************************************/

*******************************************************************************
* INSTRUCTIONS
*******************************************************************************
*
* 1. Update macros/directories in first section
*
*******************************************************************************
* SET MACROS: UPDATE THIS SECTION FOR EACH COUNTRY/ROUND
*******************************************************************************

clear matrix
clear
set more off

local Country Niger

local CCRX NER2

local Selectioncsv Selection_NER2_v13

local Round Round2

*Supervisory area
local supervisoryarea "level3"

*Update the data directory 
global datadir "~/Dropbox (Gates Institute)/`Country'/Data_NotShared/`Round'/Data"

**Global directory for the dropbox where the csv files are originally stored
global csvdir "~/Dropbox (Gates Institute)/`Country'/pmadatamanagement_`Country'/`Round'/Data/CSV_Files"


*Country specific data directory
*global datadir "~/PMA2020/`Round'/Data"

**Do file directory
global dofiledir "~/Dropbox (Gates Institute)/`Country'/pmadatamanagement_`Country'/`Round'/Cleaning_DoFiles/Current"

cd "$datadir/Selection"

*******************************************************************************
*Stop Updating here
*******************************************************************************


*Create folder called Archived_Data in the Listing Folder
* Zip all of the old versions of the datasets.  Updates the archive rather than replacing so all old versions are still in archive
*capture zipfile `CCRX'*, saving (Archived_Data/ArchivedSelection_$date, replace)

*Delete old versions.  Old version still saved in ArchivedData.zip
capture shell rm `CCRX'_*

clear
capture insheet using "$csvdir/`Selectioncsv'.csv", comma case
tostring _all, replace
save `CCRX'_Selection_$date.dta,replace

clear
capture insheet using "$csvdir/`Selectioncsv'_HH_selectionrpt.csv", comma case
tostring _all, replace
save `CCRX'_SelectionHousehold_$date.dta,replace
tempfile temp

rename PARENT_KEY metainstanceID
save `temp', replace

use `CCRX'_Selection_$date.dta
merge 1:m metainstanceID using `temp', nogen
save, replace

tostring name_typed, replace
rename name_grp* *
rename date_group* *
rename HH_selectiongrp* *
replace your_name=name_typed if your_name_check!="yes"
replace system_date=manual_date if system_date_check!="yes"
replace RE_name=RE_name_other if RE_name_other!="" 
rename your_name Supervisor

drop SETOFHH_selectionrpt your_name_check name_typed system_date_check manual_date  ///
	HH_selectionprompt HH_selectioncheck_grp v* goback goback_2 SDP_selection_prompt start end ///
	deviceid simserial phonenumber KEY RE* max_num_HH too* *logging SDP_check 
 
order SubmissionDate system_date all_selected_HH, last
order metainstanceID, first
sort Supervisor `supervisoryarea' EA  structure household
save, replace


