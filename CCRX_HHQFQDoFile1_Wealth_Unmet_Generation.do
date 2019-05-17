clear
clear matrix
clear mata
capture log close
set maxvar 15000
set more off
numlabel, add

/*******************************************************************************
*
*  FILENAME:	CCRX_HHQFQ_Wealth_Unmet_Generation_$date.do
*  PURPOSE:		PMA2020 HHQ/FQ wealth and unmet need generation in preparation for data analysis
*  CREATED:		Qingfeng Li (qli28@jhu.edu)
*  DATA IN:		CCRX_$date_ForAnalysis.dta
*  DATA OUT:	CCRX_WealthScore_$date.dta
*				CCRX_UnmetNeed_$date.dt
*				CCRX_WealthWeightAll_$date.dta
*				CCRX_WealthWeightCompleteHH_$date.dta
*				CCRX_WealthWeightFemale_$date.dta	
*******************************************************************************/

*******************************************************************************
* INSTRUCTIONS
*******************************************************************************
*
* 1. Update macros/directories in first section
*
*******************************************************************************
* SET MACROS AND CORRECT DOI: UPDATE THIS SECTION FOR EACH COUNTRY/ROUND
*******************************************************************************

* Set local macros for country and round
local country "Nigeria-Oyo"
local round "Round5Oyo"
local CCRX "NGOyoR5"
local assets "electricity-boatmotor" 
local water "water_pipe2dwelling-water_sachet"
local wealthgroup 5

* Set macro for date of HHQ/FQ EC recode dataset that intend to use
local datadate "20Dec2017"

* Set directory for country and round 
global datadir "/Users/pma2020/Dropbox (Gates Institute)/Nigeria/Data_NotShared/Round5Oyo/Data/HHQFQ"
cd "$datadir"

* Read in data 
use "/Users/pma2020/Dropbox (Gates Institute)/Nigeria/PMANG_Datasets/RoundOyo/Prelim95/NGROyo_NONAME_ECRecode_20Dec2017.dta"

* Rename and save data
save "`CCRX'_NONAME_ECRecode_`datadate'_100Prelim.dta", replace

*If running before weights are incorporated, will gen weights=1
capture confirm var HHweight
if _rc!=0{
gen HHweight=1
gen FQweight=1
}
tempfile temp
save `temp', replace

*******************************************************************************
* RENAME VARIABLES
*******************************************************************************

* Rename variables
capture rename wall_clock wallclock

*******************************************************************************
* STOP UPDATING MACROS
*******************************************************************************

cd "$datadir"
log using "`CCRX'_HHQFQ_Wealth_Unmet_Generation_$date.log", replace

* Set local/global macros for current date
local today=c(current_date)
local c_today= "`today'"
global date=subinstr("`c_today'", " ", "",.)
local todaystata=clock("`today'", "DMY")

* Keep only completed surveys
keep if HHQ_result==1 

* First, double check HHtag and metatag
	* metatag tags one observation from each form while HHtag tags one observation from each household (in the event that multiple 
	* forms are submitted for the same household then metatag will not equal HHtag. Be clear on whether you want to identify the 
	* the number of households identified or the number of forms completed)

* For weight calculation, use metatag
	* If metatag does not already exist, generate 
capture drop metatag
egen metatag=tag(metainstanceID)
keep if metatag==1

*******************************************************************************
* GENERATE WEALTH QUINTILE
*******************************************************************************

* Tab concatonated assets variable and compare to dichotomous asset variables
tab1 assets
codebook assets 
tab1 `assets', mis
foreach var of varlist `assets' {
sum `var', det
local m=r(mean)
replace `var'=int(`m') if `var'==.
}

* Create dichotomous livestock owned variables
foreach var of varlist *_owned { 
recode `var' -88 -99 88 99 =.
sum `var', det
local m=r(p50)
recode `var' 0/`m'=0 .=0 else=1, gen(`var'01)
tab1 `var', miss
recode `var' .=0
mean `var'
}

* Main material of the floor
tab1 floor, miss
tab1 floor, nolab 
recode floor 10/19 96 =1  -99 .=. else=0, gen(floor_natural)
recode floor 20/29=1 -99 .=. else=0, gen(floor_rudimentary)   
recode floor 30/39=1 -99 .=. else=0 ,gen(floor_finished) 
//recode floor 11=1 .=. else=0, gen(floor_other) 

* Main material of the roof
tab1 roof 
tab roof, nolab 
recode roof 10/19 96=1 -99 .=. else=0, gen(roof_natural) 
recode roof 20/29=1 -99 .=. else=0, gen(roof_rudimentary)
recode roof 30/39=1 .=. else=0, gen(roof_finished) 
//recode roof 14=1 .=. else=0, gen(roof_other) 

* Main material of the exterior walls
tab1 walls
tab walls, nolab 
recode walls 10/19 96=1 -99 .=. else=0, gen(wall_natural) 
recode walls 20/29=1 -99 .=. else=0, gen(wall_rudimentary) 
recode walls 30/39=1 -99 .=. else=0, gen(wall_finished) 

* Recode wall, floor, and roof variables
recode wall_finished .=0
recode wall_rudimentary .=1
recode wall_natural .=0
recode floor_natural .=1
recode floor_rudimentary .=0
recode floor_finished .=0
recode roof_natural .=1
recode roof_rudimentary .=0
recode roof_finished .=0

* Check the page for Country DHS; PDF page 358 of Country 2011 DHS 
	* Improved drinking water sources include: water from pipe/tap, public tap, borehole or pump, protected well, protected spring or rainwater.
	* Improved water sources do not include: vendor-provided water, bottled water, tanker trucks or unprotected wells and springs.

* Generate dichotomous water source variables
tab water_sources_all, mis
gen water_pipe2dwelling= regexm(water_sources_all, ["piped_indoor"]) 
gen water_pipe2yard= regexm(water_sources_all, ["piped_yard"]) 
gen water_publictap= regexm(water_sources_all, ["piped_public"]) 
gen water_tubewell= regexm(water_sources_all, ["tubewell"]) 
gen water_protectedwell= regexm(water_sources_all, ["protected_dug_well"]) 
gen water_unprotectedwell= regexm(water_sources_all, ["unprotected_dug_well"]) 
gen water_protectedspring= regexm(water_sources_all, ["protected_spring"]) 
gen water_unprotectedspring= regexm(water_sources_all, ["unprotected_spring"]) 
gen water_rainwater= regexm(water_sources_all, ["rainwater"]) 
gen water_tankertruck= regexm(water_sources_all, ["tanker"]) 
gen water_cart= regexm(water_sources_all, ["cart"]) 
gen water_surfacewater= regexm(water_sources_all, ["surface_water"])
gen water_bottled= regexm(water_sources_all, ["bottled"]) 
gen water_sachet= regexm(water_sources_all, ["sachet"])
gen water_refill=regexm(water_sources_all, ["refill"])

* Generate dichotomous toilet facility variables
tab sanitation_all, mis
gen toilet_pipedsewer=regexm(sanitation_all, ["flush_sewer"]) 
gen toilet_septictank=regexm(sanitation_all, ["flush_septic"]) 
gen toilet_flushpit=regexm(sanitation_all, ["flushpit"]) 
gen toilet_elsewhere=regexm(sanitation_all, ["flush_elsewhere"]) 
gen toilet_unknown=regexm(sanitation_all, ["flush_unknown"]) 
gen toilet_ventilatedpitlatrine=regexm(sanitation_all, ["vip"]) 
gen toilet_pitlatrinewslab=regexm(sanitation_all, ["pit_with_slab"]) 
gen toilet_pitlatrinewoslab=regexm(sanitation_all, ["pit_no_slab"])
gen toilet_compostingtoilet=regexm(sanitation_all, ["composting"]) 
gen toilet_buckettoilet=regexm(sanitation_all, ["bucket"]) 
gen toilet_hangingtoilet=regexm(sanitation_all, ["hanging"]) 
gen toilet_nofacility=regexm(sanitation_all, ["bush"])
gen toilet_other=regexm(sanitation_all, ["other"]) 
gen toilet_missing=regexm(sanitation_all, ["-99"]) 

* Rename toilet facility options so not included in wealth quintile generation
rename toilet_nofacility notoilet_nofacility
capture rename toilet_bushwater notoilet_bushwater
rename toilet_missing notoilet_missing

* Create temp file for all variables used to generate wealth quintile
tab1 `water' `assets' floor_* wall_* roof_* toilet_* *_owned01, mis
tempfile tem
save `tem', replace

* Create mean tempfile for all variables used to generate wealth quintile
preserve
collapse (mean) `water' `assets' floor_* wall_* roof_* toilet_* *_owned01
tempfile mean
save `mean', replace
restore 

* Create standard deviation tempfile for all variables used to generate wealth quintile
preserve
collapse (sd) `water' `assets' floor_* wall_* roof_* toilet_* *_owned01
tempfile sd
save `sd', replace
restore

* Create count (N) tempfile for all variables used to generate wealth quintile
preserve
collapse (count) `water' `assets' floor_* wall_* roof_* toilet_* *_owned01
tempfile N
save `N', replace
restore 

* Create minimum tempfile for all variables used to generate wealth quintile
preserve
collapse (min) `water' `assets' floor_* wall_* roof_* toilet_* *_owned01
tempfile min
save `min', replace
restore

* Create maximum tempfile for all variables used to generate wealth quintile
preserve
collapse (max) `water' `assets' floor_* wall_* roof_* toilet_* *_owned01
tempfile max
save `max', replace
restore

use `mean', clear
append using `sd'
append using `N'
append using `min'
append using `max'

* Use principal component analysis to generate wealth quintile
use `tem', clear
su `water' `assets' floor_* wall_* roof_* toilet_* *_owned01
pca `water' `assets' floor_* wall_* roof_* toilet_* *_owned01
predict score 
alpha `water' `assets' floor_* wall_* roof_* toilet_* *_owned01
	
* Put into quintiles/tertiles based on weighted households
gen wealthcat=`wealthgroup'
if wealthcat==3 {
xtile wealthtertile=score [pw=HHweight], nq(3)
cap label define wealthtert 1 "Lowest tertile" 2 "Middle tertile"  3 "Highest tertile"
label value wealthtertile wealthtert 

}
else {	
xtile wealthquintile=score [pweight=HHweight], nq(5)
cap label define wealthquint 1 "Lowest quintile" 2 "Lower quintile" 3 "Middle quintile" 4 "Higher quintile" 5 "Highest quintile"
label value wealthquintile wealthquint 
}
drop wealthcat

*******************************************************************************
* SAVE AND MERGE WEALTH QUINTILE DATA
*******************************************************************************

* Keep only wealth quintile, pca score variable, and metainstanceID and save as dataset
keep metainstanceID score wealth*
tempfile wealthscore
save `wealthscore', replace

* Merge wealth score dataset into dataset for analysis 
use `temp'
*use `CCRX'_`date'_ForAnalysis.dta
merge m:1 metainstanceID using `wealthscore', nogen
save "`CCRX'_WealthWeightAll_$date.dta", replace

*******************************************************************************
* GENERATE UNMET NEED
*******************************************************************************

/* Note from DHS:
	Stata program to create Revised unmet need variable as described in 
	Analytical Study 25: Revising Unmet Need for Family Plnaning
	by Bradley, Croft, Fishel, and Westoff, 2012, published by ICF International
	measuredhs.com/pubs/pdf/AS25/AS25.pdf
 	
	Program written by Sarah Bradley and edited by Trevor Croft, last updated 23 January 2011
	SBradley@icfi.com
 	
	This program will work for most surveys. If your results do not match 
	Revising Unmet Need for Family Planning, the survey you are analyzing may require 
	survey-specific programming. See survey-specific link at measuredhs.com/topics/Unmet-Need.cfm */

* Use weighted female dataset with wealth quintile
use "`CCRX'_WealthWeightAll_$date.dta", clear
keep if FRS_result==1 & HHQ_result==1
tempfile temp
save `temp',replace

* Check for missing values 
codebook FQdoi_corrected 

* Split FQdoi_corrected
split FQdoi_corrected, gen(doi_)

* Generate doimonth (month of interview) from first split variable 
gen doimonth=doi_1
tab1 doimonth, mis
replace doimonth=lower(doimonth)
tab1 doimonth, mis
replace doimonth="12" if doimonth=="dec" 
replace doimonth="1" if doimonth=="jan" 
replace doimonth="2" if doimonth=="feb" 
replace doimonth="3" if doimonth=="mar" 
replace doimonth="4" if doimonth=="apr" 
replace doimonth="5" if doimonth=="may" 
replace doimonth="6" if doimonth=="jun"
replace doimonth="7" if doimonth=="jul"
replace doimonth="8" if doimonth=="aug"
replace doimonth="9" if doimonth=="sep"
replace doimonth="10" if doimonth=="oct"
replace doimonth="11" if doimonth=="nov" 
tab1 doimonth, mis

* Generate doiyear (year of interview) from third split variable
gen doiyear=doi_3

* Destring doimonth and doiyear 
destring doimonth doiyear, replace

* Calculate doi in century month code (months since January 1900)
gen doicmc=(doiyear-1900)*12+doimonth 
tab doicmc, mis

* Check the dates to make sure they make sense and correct if they do not
egen tagdoicmc=tag(doicmc)
*br SubmissionDate wrongdate start end system* doi* this* if tagdoicmc==1

* Drop unecessary variables used to generate doicmc
drop tagdoicmc
drop doi_*

* Confirm have only completed HHQ/FQ surveys
keep if FRS_result==1 & HHQ_result==1 
codebook metainstanceID 

* Generate unmet need variable
capture g unmet=.

* Set unmet need to NA for unmarried women if survey only included ever-married women 
tab FQmarital_status, mis
tab FQmarital_status, mis nolab
recode FQmarital_status -99 =.

* Tab desire for more children variable(s) 
des more_children*
tab more_children, mis
tab more_children, mis nolab

* Tab length of time want to wait until next birth variable
tab wait_birth, miss
tab wait_birth, miss nolab
tab wait_birth_pregnant, miss nolab

*******************************************************************************
* GROUP 1: CONTRACEPTIVE USERS 
*******************************************************************************

* Using to limit if wants no more, sterilized, or declared infecund
recode unmet .=4 if cp==1 & (more_children==2 | femalester==1 | malester==1 | more_children==3) 

* Using to space - all other contraceptive users
recode unmet .=3 if cp==1

*******************************************************************************
* GROUP 2: PREGNANT OR POSTPARTUM AMENORRHEIC (PPA) WOMEN 
*******************************************************************************

* Determine who should be in Group 2
* Generate time since last birth (i.e. gap between date of interview and date of last birth)

* Generate month and year of last birth variables
split recent_birth, gen(lastbirth_)
rename lastbirth_1 lastbirthmonth
rename lastbirth_3 lastbirthyear
drop lastbirth_*

* Create numeric month of last birth variable
replace lastbirthmonth=lower(lastbirthmonth)
replace lastbirthmonth="1" if lastbirthmonth=="jan"
replace lastbirthmonth="2" if lastbirthmonth=="feb"
replace lastbirthmonth="3" if lastbirthmonth=="mar"
replace lastbirthmonth="4" if lastbirthmonth=="apr"
replace lastbirthmonth="5" if lastbirthmonth=="may"
replace lastbirthmonth="6" if lastbirthmonth=="jun"
replace lastbirthmonth="7" if lastbirthmonth=="jul"
replace lastbirthmonth="8" if lastbirthmonth=="aug"
replace lastbirthmonth="9" if lastbirthmonth=="sep"
replace lastbirthmonth="10" if lastbirthmonth=="oct"
replace lastbirthmonth="11" if lastbirthmonth=="nov"
replace lastbirthmonth="12" if lastbirthmonth=="dec"

* Destring last birth month and year variables 
destring lastbirth*, replace
tab1 lastbirthmonth lastbirthyear

* Replace last birth month and year equal to missing is year is 2020 (i.e. missing)
replace lastbirthmonth=. if lastbirthyear==2020
recode lastbirthyear 2020=. 

* Generate last birth data in century month code
gen lastbirthcmc=(lastbirthyear-1900)*12+lastbirthmonth

* Generate time since last birth in months variable
gen tsinceb=doicmc-lastbirthcmc

* Generate time since last period in months from v215, time since last menstrual period
replace menstrual_period=. if menstrual_period==-99

* Tab menstrual_period 
tab menstrual_period, mis
tab menstrual_period, mis nolab

**Some women who says years since mp report the actual year
replace menstrual_period_value = menstrual_period_value-doiyear if menstrual_period_value>2000 ///
 & menstrual_period_value!=. & menstrual_period==4 // years


* Generate time since menstrual period variable in months
g tsincep	    	= 	menstrual_period_value if menstrual_period==3 // months
replace tsincep	    = 	int(menstrual_period_value/30) if menstrual_period==1 // days
replace tsincep	    = 	int(menstrual_period_value/4.3) if menstrual_period==2 // weeks
replace tsincep	    = 	menstrual_period_value*12 if menstrual_period==4 // years

* Initialize pregnant (1) or currently postpartum amenorrheic (PPA) women who have not had period since before birth (6)
g pregPPA=1 if pregnant==1 | menstrual_period==6 

* For women with missing data or "period not returned" on date of last menstrual period, use information from time since last period
* If last period is before last birth in last 5 years
replace pregPPA=1 if tsincep> tsinceb & tsinceb<60 & tsincep!=. & tsinceb!=.

* Or if said "before last birth" to time since last period in the last 5 years
replace pregPPA=1 if menstrual_period==-99 & tsinceb<60 & tsinceb!=.

* Select only women who are pregnant or PPA for <24 months
g pregPPA24=1 if pregnant==1 | (pregPPA==1 & tsinceb<24)

* Classify based on wantedness of current pregnancy/last birth
* Generate variable for whether or not wanted last/current pregnancy then, later, or not at all
gen wantedlast=pregnancy_current_desired // currently pregnant
gen m10_1=pregnancy_last_desired // not currently pregnant
replace wantedlast = m10_1 if (wantedlast==. | wantedlast==-99) & pregnant!=1
tab wantedlast
replace wantedlast=. if wantedlast==-99

* Recode as no unmet need if wanted current pregnancy/last birth then/at that time
recode unmet .=7  if pregPPA24==1 & wantedlast==1

* Recode as unmet need for spacing if wanted current pregnancy/last birth later
recode unmet .=1  if pregPPA24==1 & wantedlast==2

* Recode as unmet need for limiting if wanted current pregnancy/last birth not at all
recode unmet .=2  if pregPPA24==1 & wantedlast==3

* Recode unmet need as missing value if "wantedlast" missing and if has been post-partum amenorrheic for less then 24 months
recode unmet .=99 if pregPPA24==1 & wantedlast==.

* Determine if sexually active in last 30 days: less than 4 weeks or less than 30 days
gen sexact=0 
replace sexact=1 if (last_time_sex==2 & last_time_sex_value<=4 & last_time_sex_value>=0) | (last_time_sex==1 & last_time_sex_value<=30 & last_time_sex_value>=0) ///
 | (last_time_sex==3 & last_time_sex_value<=1 & last_time_sex_value>=0)

* If unmarried and not sexually active in last 30 days, assume no need
recode unmet .=97 if FQmarital_status~=1 & FQmarital_status~=2 & sexact!=1

*******************************************************************************
* GROUP 3: DETERMINE FECUNDITY
*******************************************************************************

* Boxes refer to Figure 2 flowchart in DHS Analytics 25 Report 

* Box 1 (applicable only to currently married/cohabiting women)
	* Married 5+ years ago, no children in past 5 years, never used contraception, excluding pregnant and PPA <24 months
	* husband_cohabit_start_current husband_cohabit_start_recent 
	* husband_cohabit_start_recent is first marriage, FQfirstmarriagemonth and FQfirstmarriageyear are dates of first marriage (women married more than once)
	* husband_cohabit_start_current is current marriage (if woman married only once, only have current marriage)
	* If first marriage more than five years ago, never used contraception, and never had child, then infecund

	* Recode month and year of marriage as missing if year of marriage is 2020 (i.e. missing)
	tab1 *marriagemonth *marriageyear, mis
	replace firstmarriagemonth=. if firstmarriageyear==2020
	replace recentmarriagemonth=. if recentmarriageyear==2020
	recode firstmarriageyear 2020=.
	recode recentmarriageyear 2020=.

	* Generate marriage century month code variable
	gen marriagecmc=(firstmarriageyear-1900)*12+firstmarriagemonth
	replace marriagecmc=(recentmarriageyear-1900)*12 + recentmarriagemonth if marriage_history==1

	* Generate time since marriage century month code variable
	gen v512=int((doicmc-marriagecmc)/12)
	tab v512, mis //years since marriage

	* Generate dichotomous infecund variable
	g infec=1 if (FQmarital_status==1 | FQmarital_status==2) & v512>=5 & v512!=. & (tsinceb>59 | ever_birth==0) & fp_ever_used==0 & pregPPA24!=1

* Box 2
	* Declared infecund on future desires for children
	replace infec=1 if more_children==3 // v605==7

* Box 3
	* Menopausal/hysterectomy as reason not using contraception - slightly different recoding in DHS III and IV+
	replace infec=1 if why_not_usingmeno==1

* Box 4
	* Time since last period is >=6 months and not PPA
	replace infec=1 if tsincep>=6 & tsincep!=. & pregPPA!=1

* Box 5
	* Menopausal/hysterectomy for time since last period response
	replace infec=1 if menstrual_period==5
	
	* Never menstruated for time since last period response, unless had a birth in the last 5 years
	replace infec=1 if menstrual_period==7 & (tsinceb>59 | tsinceb==.)

* Box 6
	* Time since last birth>= 60 months and last period was before last birth
	replace infec=1 if menstrual_period==6 & tsinceb>=60 & tsinceb!=.

	* Never had a birth, but last period reported as before last birth - assume code should have been something other than 6
	replace infec=1 if menstrual_period==6 & ever_birth==0

	* Exclude pregnant and PP amenorrheic < 24 months
	replace infec=. if pregPPA24==1
	
	* Recode unmet need 
	recode unmet .=9 if infec==1

*******************************************************************************
* GROUP 4: FECUND WOMEN
*******************************************************************************

* Recode as no unmet need if wants child within 2 years
recode unmet .=7 if more_children==1 & ((wait_birth==1 & wait_birth_value<24) | (wait_birth==2 & wait_birth_value<2) | (wait_birth==3) )  // v605==1, wants within 2 years; wait_birth: 4 months; 5 years

* Recode as unmet need for spacing if wants in 2+ years, wants undecided timing, or unsure if wants
recode unmet .=1 if more_children==-88 | (more_children==1 & ( (wait_birth==1 & wait_birth_value>=24) | (wait_birth==2 & wait_birth_value>=2)) | (wait_birth==-88) | (wait_birth==-99)) //v605>=2 & v605<=4

* Recode as unmet need for limiting if wants no more children
recode unmet .=2 if more_children==2 

* Recode any reamining missing values as "99"
recode unmet .=99

* Label unmet need
capture la def unmet ///
    1 "unmet need for spacing" ///
	2 "unmet need for limiting" ///
	3 "using for spacing" ///
	4 "using for limiting" ///
	7 "no unmet need" ///
	9 "infecund or menopausal" ///
	97 "not sexually active" ///
	98 "unmarried - EM sample or no data" ///
	99 "missing"
la val unmet unmet

* Generate and lable dichotomous unmet need variable
capture recode unmet (1/2=1 "unmet need") (else=0 "no unmet need"), g(unmettot)

* Tab unmet need variable for married or unmarried women
tab unmet
tab unmet if FQmarital_status==1 | FQmarital_status==2

* Keep only certain variables
keep unmet unmettot FQmetainstanceID doi* *cmc tsince* 

* Drop duplicates
duplicates drop FQmetainstanceID, force

*******************************************************************************
* SAVE AND MERGE UNMET NEED DATA, CLOSE LOG
*******************************************************************************

* Save unmet need dataset
tempfile unmet
saveold `unmet', replace 

* Merge unmet need dataset with weighted, wealth quintile dataset containing all data
use "`CCRX'_WealthWeightAll_$date.dta"
merge m:1 FQmetainstanceID using `unmet', nogen
saveold "`CCRX'_WealthWeightAll_$date.dta", replace version(12)

log close
