****PMA 2020 Indonesia Data Quality Checks****
***Version 20 January 2014****
**Third do file in series***

/*This do file labels each variable in the household roster*/


clear
set more off
cd "$datadir"

local today=c(current_date)
local c_today= "`today'"
local date=subinstr("`c_today'", " ", "",.)
local todaystata=clock("`today'", "DMY")
local CCRX $CCRX

local HHQcsv $HHQcsv
local HHQcsv2 $HHQcsv2

	clear
	capture noisily insheet using "$csvdir/`HHQcsv'_hh_rpt.csv", comma case
		
	if _rc==0 {
	tostring *, replace force

	
	save `CCRX'_HHQmember.dta, replace
	
}

/*If you need to add an extra version of the forms, this will check if that
version number exists and add it.  If the version does not, it will continue*/
	
clear

	capture noisily insheet using "$csvdir/`HHQcsv2'_hh_rpt.csv", comma case
if _rc==0 {
	tostring *, replace force

	append using `CCRX'_HHQmember.dta, force
	save, replace	
}	
	
use `CCRX'_HHQmember.dta, clear
************************************************************************************

rename mb_grp* *
rename ms_grp* *
rename nm_grp* *
capture confirm var EA_transfer
if _rc!=0{
capture rename quartier EA
}


**Assign variable labels 

***Clean the HHQ Member information
label var PARENT_KEY			"Unique id household - ODK generate"
label var firstname				"First name of household memeber"
label var respondent_match		"Is respondent in household"
label var gender				"Sex of household member"
label var age					"Age"
label var marital_status		"Marital Status"
label var relationship			"Relationship to head of household"
label var head_check			"Head of household?"
capture label var family_id		"Family ID"
capture rename usual_member usually_live
label var usually_live			"Usually live in household"

label var last_night			"Slept in the household night before"
label var eligible				"Eligible female respondent"
label var FRS_form_name			"Linking ID for Eligible Woman"


destring age, replace
destring respondent_match, replace
destring head_check, replace
capture destring family_id, replace
capture destring EA, replace
destring eligible, replace


numlabel, add

label define yes_no_dnk_nr_list 0 no 1 yes -88 "-88" -99 "-99"
encode more_hh_members, gen(more_hh_membersv2) lab(yes_no_dnk_nr_list)

label define gender_list 1 male 2 female -88 "-88" -99 "-99"
encode gender, gen(genderv2) lab(gender_list)

label define marital_status_list 5 never_married 1 currently_married 2 currently_living_with_partner 3 divorced 4 widow  -99 "-99"
encode marital_status, gen(marital_statusv2) lab(marital_status_list)

label define relationship_list 1 head 2 spouse 3 child 4 child_in_law 5 grandchild 6 parent 7 parent_in_law 8 sibling 9 other 10 help -88 "-88" -99 "-99"
encode relationship, gen(relationshipv2) lab(relationship_list)

encode usually_live, gen(usually_livev2) lab(yes_no_dnk_nr_list)
encode last_night, gen(last_nightv2) lab(yes_no_dnk_nr_list)


unab vars: *v2
local stubs: subinstr local vars "v2" "", all
foreach var in `stubs'{
rename `var' `var'QZ
order `var'v2, after(`var'QZ)
}
rename *v2 *
drop *QZ

*Check for observations that are all duplicates
duplicates report
duplicates drop
rename PARENT_KEY metainstanceID
rename KEY member_number 
duplicates drop member_number, force

rename link_transfer link
drop *_transfer*
rename link link_transfer

drop SETOFhh_rpt
drop firstname_raw

save `CCRX'_HHQmember_`date', replace


