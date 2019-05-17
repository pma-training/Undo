clear
clear matrix
clear mata
capture log close
set maxvar 15000
set more off
numlabel, add

/*******************************************************************************
*
*  FILENAME:	PMA_HHQFQ_2Page_Analysis_$date.do
*  PURPOSE:		PMA2020 HHQ/FQ two page data analysis
*  CREATED:		Linnea Zimmerman (lzimme12@jhu.edu)
*  DATA IN:		CCRX_WealthWeightFemale_$date.dta
*  DATA OUT:	CCRX_HHQFQ_2Page_Analysis_$date.dta
*
*******************************************************************************/

*******************************************************************************
* INSTRUCTIONS
*******************************************************************************
*
* 1. Update macros/directories in first section
* 2. If using source of method by method figure, uncomment last section
*	 and update coding
*
*******************************************************************************
* SET MACROS: UPDATE THIS SECTION FOR EACH COUNTRY/ROUND
*******************************************************************************

* Set macros for country and round
local country "Nigeria"
local round "Round5Oyo"
local CCRX "NGOyoR5"

* Set macros for contraceptive methods
local mcp "(current_methodnumEC>=1 & current_methodnumEC>>=19)"
local tcp "(current_methodnumEC>=30 & current_methodnumEC<=39)"

* Set macro for date of most recently generated weighted HHQ/FQ dataset with wealth and unmet need variables that intend to use
local datadate "23Feb2018"

* Set macros for data sets
local householddata "/Users/ealarson/Documents/Côte d'Ivoire/Data_NotShared/Round1/HHQFQ/Analysis - 02.23.2018/CIR1_WealthWeightAll_8Aug2018.dta"

* Set macro for directory/file of program to calculate medians 
local medianfile "/Users/ealarson/Dropbox (Gates Institute)/1 DataManagement_General/DataRoutines/PMA_SOI_2P/DoFiles/Current/PMA2020_MedianDefineFn_simple_9Mar2015.do"
*local medianfile "C:\Users\Shulin\Dropbox (Gates Institute)/DataRoutines/PMA_SOI_2P/DoFiles/Current/PMA2020_MedianDefineFn_simple_9Mar2015.do"

* Set directory for country and round
global datadir "/Users/ealarson/Documents/Côte d'Ivoire/Data_NotShared/Round1/HHQFQ/Analysis - 02.23.2018"
cd "$datadir"

* Set local/global macros for current date
local today=c(current_date)
local c_today= "`today'"
global date=subinstr("`c_today'", " ", "",.)

* Create log
log using "`CCRX'_HHQFQ_2Page_Analysis.log", replace

*******************************************************************************
* PREPARE DATA FOR ANALYSIS
*******************************************************************************

* First use household data to show response rates
use "`householddata'",clear
preserve
keep if metatag==1 
gen responserate=0 if HHQ_result>=1 & HHQ_result<6
replace responserate=1 if HHQ_result==1
label define responselist 0 "Not complete" 1 "Complete"
label val responserate responselist

tabout responserate using "`CCRX'_HHQFQ_2Page_Analysis_Output_$date.xls", replace ///
	cells(freq col) h2("Household response rate") f(0 1) clab(n %)
restore

* Response rate among all women
gen FQresponserate=0 if eligible==1 & last_night==1
replace FQresponserate=1 if FRS_result==1 & last_night==1
label define responselist 0 "Not complete" 1 "Complete"
label val FQresponserate responselist

tabout FQresponserate if HHQ_result==1 using "`CCRX'_HHQFQ_2Page_Analysis_Output_$date.xls", append ///
	cells(freq col) h2("Female response rate") f(0 1) clab(n %)	
	
* Restrict analysis to women who completed questionnaire and households with completed questionnaire
keep if FRS_result==1 & HHQ_result==1

* Restrict analysis to women who slept in the house the night before (de facto)
keep if last_night==1

* Save data set so can replicate analysis results later
save "`CCRX'_HHQFQ_2Page_Analysis_$date.dta", replace

* Check for duplicates 
duplicates report FQmetainstanceID
codebook FQmetainstanceID

* Set survey weights
svyset EA [pweight=FQweight]

* Generate variable that represents number of observations
gen one=FRS_result
label var one "All women"

* Generate dichotomous "married" variable to represent all women married or currently living with a man
gen married=(FQmarital_status==1 | FQmarital_status==2)
label variable married "Married or currently living with a man"

* Generate dichotomous sexually active unmarried women variable
cap drop umsexactive
gen umsexactive=0 
replace umsexact=1 if married==0 & ((last_time_sex==2 & last_time_sex_value<=4 & last_time_sex_value>=0) | (last_time_sex==1 & last_time_sex_value<=30 & last_time_sex_value>=0) ///
 | (last_time_sex==3 & last_time_sex_value<=1 & last_time_sex_value>=0))

*Generate sexually active variable
gen sexactive= (last_time_sex==2 & last_time_sex_value<=4 & last_time_sex_value>=0) | (last_time_sex==1 & last_time_sex_value<=30 & last_time_sex_value>=0) ///
 | (last_time_sex==3 & last_time_sex_value<=1 & last_time_sex_value>=0) 
* Generate 0/1 urban/rural variable

capture confirm var ur 
if _rc==0 {
gen urban=ur==1
label variable urban "Urban/rural place of residence"
label define urban 1 "Urban" 0 "Rural"
label value urban urban
tab urban, mis
}
else {
gen urban=1
label variable urban "No urban/rural breakdown"
}

* Label yes/no response options
capture label define yesno 0 "No" 1 "Yes"
foreach x in married umsexactive sexactive {
	label values `x' yesno
	}

* Tabout count of all women, unweighted
*tabout one using "`CCRX'_HHQFQ_2Page_Analysis_Output_$date.xls", replace cells(freq) h2("All women (unweighted)") f(0)

/* Tabout count of all women, weighted (should be same as unweighted count of all women)
tabout one [aw=FQweight] using "`CCRX'_HHQFQ_2Page_Analysis_Output_$date.xls", append cells(freq) h2("All women (weighted)") f(0)

* Tabout count of all married women, unweighted
*tabout married if married==1 using "`CCRX'_HHQFQ_2Page_Analysis_Output_$date.xls", append cells (freq) h2("Married women (unweighted)") f(0)

* Tabout count of all married women, weighted
tabout married if married==1 [aw=FQweight] using "`CCRX'_HHQFQ_2Page_Analysis_Output_$date.xls", append cells(freq) h2("Married women (weighted)") f(0)

* Tabout count of unmarried sexually active women, unweighted
*tabout umsexactive if umsexactive==1  using "`CCRX'_HHQFQ_2Page_Analysis_Output_$date.xls", append cells(freq) h2("Unmarried sexually active (unweighted)") f(0)

* Tabout count of unmarried sexually active women, weighted
tabout umsexactive if umsexactive==1 [aw=FQweight] using "`CCRX'_HHQFQ_2Page_Analysis_Output_$date.xls", append cells(freq) h2("Unmarried sexually active (weighted)") f(0)
*/

*******************************************************************************
* FIRST PAGE
*******************************************************************************

*******************************************************************************
* CONTRACEPTIVE PREVALENCE RATE
*******************************************************************************

* Set macros for contraceptive methods
local mcp "(current_methodnumEC>=1 & current_methodnumEC<=19)"
local tcp "(current_methodnumEC>=30 & current_methodnumEC<=39)"

* Generate numeric current method variable that includes emergency contraception
capture gen current_methodnumEC=current_recent_methodEC if cp==1
label variable current_methodnumEC "Current contraceptive method, including EC (numeric)"

* Generate dichotomous current use of modern contraceptive variable
capture gen mcp=`mcp'
label variable mcp "Current use of modern contraceptive method"

* Generate dichotomous current use of traditional contraceptive variable
capture gen tcp=`tcp'
label variable tcp "Current use of traditional contraceptive method"

* Generate dichotomous current use of any contraceptive variable
capture gen cp= current_methodnumEC>=1 & current_methodnumEC<40
label variabl cp "Current use of any contraceptive method"

* Generate dichotomous current use of long acting contraceptive variable
capture drop longacting
capture gen longacting=current_methodnumEC>=1 & current_methodnumEC<=4
label variable longacting "Current use of long acting contraceptive method"

* Label yes/no response options
foreach x in cp mcp tcp longacting {
	label values `x' yes_no_dnk_nr_list
	} 

* Tabout weighted proportion of contracpetive use (overall, modern, traditional, long acting) among all women
tabout cp mcp longacting [aw=FQweight] using "`CCRX'_HHQFQ_2Page_Analysis_Output_$date.xls", append oneway c(col) f(1) clab(%) npos(row)  h2("CPR/mCPR/Long-acting - all women (weighted)") 

* Tabout weighted proportion of contracpetive use (overall, modern, traditional, long acting) among married women
tabout cp mcp longacting if married==1 [aw=FQweight] using "`CCRX'_HHQFQ_2Page_Analysis_Output_$date.xls", append oneway c(col) f(1) clab(%) npos(row)  h2("CPR/mCPR/Long-acting - married women (weighted)") 

*******************************************************************************
* UNMET NEED
*******************************************************************************

* Label variables for tabout
label variable unmet "Unmet need (categorical)"
label variable unmettot "Unmet need (dichotomous)"

* Generate total demand = current use + unmet need
gen totaldemand=0
replace totaldemand=1 if cp==1 | unmettot==1
label variable totaldemand "Has contraceptive demand, i.e. current user or unmet need"

* Generate total demand staisfied - CONFIRM INDICATOR CODED CORRECTLY
gen totaldemand_sat=0 if totaldemand==1
replace totaldemand_sat=1 if totaldemand==1 & mcp==1
label variable totaldemand_sat "Contraceptive demand satisfied by modern method"

* Generate categorical unmet need, traditional method, modern method variable
gen cont_unmet=0 if married==1
replace cont_unmet=1 if unmettot==1
replace cont_unmet=2 if tcp==1
replace cont_unmet=3 if mcp==1
label variable cont_unmet "Unmet need, traditional method, and modern method prevalence among married women"
label define cont_unmetl 0 "None" 1 "Unmet need" 2 "Traditional contraceptive use" 3 "Modern contraceptive use"
label values cont_unmet cont_unmetl

* Label yes/no response options
foreach x in totaldemand totaldemand_sat {
	label values `x' yesno
	}
	
* Tabout weighted proportion of unmet need (categorical and dichotomous) among all women 
tabout unmettot unmet [aw=FQweight] using "`CCRX'_HHQFQ_2Page_Analysis_Output_$date.xls", append oneway c(col) f(1) clab(%) npos(row)  h2("Unmet need (categorical and dichotomous) - all women (weighted)") 

* Tabout weighted proportion of unmet need (categorical dichotomous) among married women 
tabout unmettot unmet [aw=FQweight] if married==1 using "`CCRX'_HHQFQ_2Page_Analysis_Output_$date.xls", append oneway c(col) f(1) clab(%) npos(row)  h2("Unmet need (categorical and dichotomous) - married women (weighted)") 

* Tabout weighted proportion of unmet need (categorical dichotomous) among unmarried sexually active women 
*capture tabout unmettot unmet [aw=FQweight] if umsexactive==1 using "`CCRX'_HHQFQ_2Page_Analysis_Output_$date.xls", append oneway c(col) f(1) clab(%) npos(row)  h2("Unmet need (categorical and dichotomous) - unmarried sexually active women (weighted)") 

* Tabout weighted proportion of total demand among all women 
tabout totaldemand [aw=FQweight] using "`CCRX'_HHQFQ_2Page_Analysis_Output_$date.xls", append oneway c(col) f(1) clab(%) npos(row)  h2("Total demand for contraception - all women (weighted)") 

* Tabout weighted proportion of total demand among all women 
tabout totaldemand_sat [aw=FQweight] using "`CCRX'_HHQFQ_2Page_Analysis_Output_$date.xls", append oneway c(col) f(1) clab(%) npos(row)  h2("Contraceptive demand satisfied by modern method- all women (weighted)") 

* Tabout weighted proportion of total demand among married women 
tabout totaldemand [aw=FQweight] if married==1 using "`CCRX'_HHQFQ_2Page_Analysis_Output_$date.xls", append oneway c(col) f(1) clab(%) npos(row)  h2("Total demand for contraception - married women (weighted)") 

* Tabout weighted proportion of total demand among married women 
tabout totaldemand_sat [aw=FQweight] if married==1 using "`CCRX'_HHQFQ_2Page_Analysis_Output_$date.xls", append oneway c(col) f(1) clab(%) npos(row)  h2("Contraceptive demand satisfied by modern method- married women (weighted)") 

* Tabout weighted proportion of total demand among married women 
tabout totaldemand_sat wealth [aw=FQweight] if married==1 using "`CCRX'_HHQFQ_2Page_Analysis_Output_$date.xls", append c(col) f(1) clab(%) npos(row)  h1("Contraceptive demand satisfied by wealth - married women (weighted)") 

*******************************************************************************
* FERTILITY INDICATORS
*******************************************************************************

* Generate variables like in DHS, bith date in cmc
gen birthmonth2=birthmonth
replace birthmonth=6 if birthmonth==-88
gen v011=(birthyear-1900)*12 + birthmonth 

*******************************************************************************
* UNINTENDED BIRTHS
*******************************************************************************

* Codebook recent births unintended: last birth/current pregnancy wanted then, later, not at all
codebook pregnancy_last_desired 
codebook pregnancy_current_desired 

* Recode "-99" as "." to represent missing
recode pregnancy_last_desired -99 =.
recode pregnancy_current_desired -99 =.

* Generate wantedness variable that combines results from last birth and current pregnancy questions
gen wanted=1 if pregnancy_last_desired==1 | pregnancy_current_desired==1 
replace wanted=2 if pregnancy_last_desired==2 | pregnancy_current_desired==2 
replace wanted=3 if pregnancy_last_desired==3 | pregnancy_current_desired==3 
label variable wanted "Intendedness of previous birth/current pregnancy (categorical): then, later, not at all"
label def wantedlist 1 "then" 2 "later" 3 "not at all"
label val wanted wantedlist
tab wanted, mis

* Generate dichotomous intendedness variables that combines births wanted "later" or "not at all"
gen unintend=1 if wanted==2 | wanted==3
replace unintend=0 if wanted==1
label variable unintend "Intendedness of previous birth/current pregnancy (dichotomous)"
label define unintendl 0 "intended" 1 "unintended"
label values unintend unintendl

* Tabout intendedness and wantedness among women who had a birth in the last 5 years or are currently pregnant
tabout unintend wanted [aw=FQweight] if tsinceb<60 | pregnant==1 using "`CCRX'_HHQFQ_2Page_Analysis_Output_$date.xls", append oneway c(col) f(1) clab(%) npos(row) 	///
h2("Intendedness (dichotomous and categorical) among women who had a birth in the last 5 years or are currently pregnant (weighted)")

*******************************************************************************
* CURRENT USE AND UNMET NEED AMONG MARRIED WOMEN BY WEALTH
*******************************************************************************

* Tabout current use and unmet need among married women of reproductive age, by wealth quintile (weighted)
tabout wealth cont_unmet[aw=FQweight] if married==1 using "`CCRX'_HHQFQ_2Page_Analysis_Output_$date.xls", append c(row) f(1) clab(%) npos(row) h1("Unmet need, traditional method, and modern method prevalence among married women (weighted)")

*******************************************************************************
* METHOD MIX PIE CHART 
*******************************************************************************

* Label variables
label variable current_recent_method "Current or recent method"

* Tabout current/recent method if using modern contraceptive method, among married women
tabout current_methodnumEC [aweight=FQweight] if mcp==1 & married==1 & cp==1 using "`CCRX'_HHQFQ_2Page_Analysis_Output_$date.xls", append oneway c(col) f(1) clab(%) npos(row)  h2("Method mix - married women (weighted)")

* Tabout current/recent method if using modern contraceptive method, among unmarried sexually active women
capture tabout current_methodnumEC [aweight=FQweight] if mcp==1 & umsexactive==1 & cp==1 using "`CCRX'_HHQFQ_2Page_Analysis_Output_$date.xls", append oneway c(col) f(1) clab(%) npos(row)  h2("Method mix - unmarried sexually active women (weighted)") 

gen current_methodnumEC2=current_methodnumEC
replace current_methodnumEC2=0 if current_methodnumEC2==. | current_methodnumEC2==-99
replace current_methodnumEC2=30 if current_methodnumEC>=30 & current_methodnumEC<=39
label copy methods_list methods_list2
label define methods_list2 0 "Not using" 30 "Traditional methods", modify
label val current_methodnumEC2 methods_list2

*******************************************************************************
* SECOND PAGE
*******************************************************************************

*******************************************************************************
* CHOICE INDICATORS BY WEALTH
*******************************************************************************

* Method chosen self of jointly
tab fp_final_decision if cp==1
gen methodchosen=1 if fp_final_decision==1 | fp_final_decision==4 | fp_final_decision==5
replace methodchosen=0 if fp_final_decision==2 | fp_final_decision==3
replace methodchosen=0 if fp_final_decision==-99 | fp_final_decision==6 

label variable methodchosen "Who chose method?"
label define methodchosenl 0 "Not self" 1 "Self, self/provider, self/partner"
label values methodchosen methodchosenl

* Generate dichotomous would return to provider/refer relative to provider variable
recode return_to_provider -88 -99=0
recode refer_to_relative -88 -99=0

gen returnrefer=1 if return_to_provider==1 & refer_to_relative==1 & cp==1
replace returnrefer=0 if cp==1 & (return_to_provider==0 | refer_to_relative==0)
label variable returnrefer "Would return to provider and refer a friend or family member"
label values returnrefer yesno

* Tabout who chose method (weighted) by wealth quintile among current users
tabout methodchosen wealth [aweight=FQweight] if mcp==1 using "`CCRX'_HHQFQ_2Page_Analysis_Output_$date.xls", append c(col) f(1) clab(%) npos(row)  h1("Method chosen - current modern user (weighted)")

* Tabout obtained method of choice by wealth (weighted) among current users
recode fp_obtain_desired -88 -99=0
tabout fp_obtain_desired wealth [aweight=FQweight] if mcp==1 using "`CCRX'_HHQFQ_2Page_Analysis_Output_$date.xls", append c(col) f(1) clab(%) npos(row)  h1("Obtained method of choice by wealth - current modern user (weighted)")

* Tabout told of other methods by wealth (weighted) among current users
recode fp_told_other_methods -88 -99=0
tabout fp_told_other_methods wealth [aweight=FQweight] if mcp==1 using "`CCRX'_HHQFQ_2Page_Analysis_Output_$date.xls", append c(col) f(1) npos(row)  h1("Told of other methods by wealth - current modern user (weighted)")

* Tabout counseled on side effects by wealth (weighted) among current users
recode fp_side_effects -88 -99=0
tabout fp_side_effects wealth [aweight=FQweight] if mcp==1 using "`CCRX'_HHQFQ_2Page_Analysis_Output_$date.xls", append c(col) f(1) npos(row)  h1("Told about side effects by wealth - current modern user (weighted)")

gen fees_paid_lastvisit=0 if method_fees==0
replace fees_paid_lastvisit=1 if method_fees>0 & method_fees!=.
replace fees_paid_lastvisit=1 if method_fees==-88

label var fees_paid_lastvisit "Did you pay for services the last time you obtained FP?"
label define yesno_list 1 "yes" 0 "no"
label val fees_paid_lastvisit yesno_list


* Tabout paid for services by wealth (weighted) among current users 
tabout fees_paid_lastvisit wealth [aweight=FQweight] if mcp==1 using "`CCRX'_HHQFQ_2Page_Analysis_Output_$date.xls", append c(col) f(1) npos(row)  h1("REWORDED QUESTION FROM PREVIOUS ROUNDS Paid for FP services at last visit by wealth - current modern user (weighted)")

* Tabout would return to provider by wealth (weighted) among current users
tabout returnrefer wealth [aweight=FQweight] if mcp==1 using "`CCRX'_HHQFQ_2Page_Analysis_Output_$date.xls", append c(col) f(1) npos(row)  h1("Return to/refer provider by wealth - current modern user (weighted)") 

*******************************************************************************
* RECEIVED A METHOD FROM A PUBLIC SDP
*******************************************************************************

* Generate dichotomous variable for public versus not public source of family planning
recode fp_provider_rw (1/19=1 "public") (-88 -99=0) (nonmiss=0 "not public"), gen(publicfp_rw)
label variable publicfp_rw "Respondent or partner for method for first time from public family planning provider"

* Tabout whether received contraceptive method from public facility by wealth (weighted) among current users
tabout publicfp_rw wealth if mcp==1 [aw=FQweight] using "`CCRX'_HHQFQ_2Page_Analysis_Output_$date.xls", append c(col) f(1) npos(row)  h1("Respondent/partner received method from public facility initially by wealth - current modern user (weighted)") 

* Tabout percent unintended births is the only indicator in the section not restricted to current users (all others restricted to current users)
tabout unintend wealth [aweight=FQweight] if tsinceb<60 | pregnant==1 using "`CCRX'_HHQFQ_2Page_Analysis_Output_$date.xls", append c(col) f(1) npos(row)  h1("Percent unintended by wealth - current user (weighted)") 

save "`CCRX'_HHQFQ_2Page_Analysis_$date.dta", replace

*******************************************************************************
* REASON FOR NON-USE
*******************************************************************************
* Collapse reasons into five categories
	* Perceived not at risk (not married, lactating, infrequent/no sex, husband away, menopausal, subfecund, fatalistic)
	* Infrequent/no sex/husband away 
	gen nosex=0 if why_not_using!="" 
	replace nosex=1 if (why_not_usinghsbndaway==1 | why_not_usingnosex==1)

	* Menopausal/subfecund/amenorhheic
	gen meno=0 if why_not_using!="" 
	replace meno=1 if why_not_usingmeno==1 | why_not_usingnomens==1 | why_not_usingsubfec==1 

	* Lactating
	gen lactate=0 if why_not_using!=""
	replace lactate=1 if why_not_usingbreastfd==1

	* Combined no need
	gen noneed=0 if why_not_using!="" 
	replace noneed=1 if nosex==1|meno==1|lactate==1|why_not_usinguptogod==1
	label variable noneed "Perceived not at risk"
	tab noneed [aw=FQweight]

	* Not married is separate category
	gen notmarried=0 if why_not_using!=""
	replace notmarried=1 if why_not_usingnotmarr==1
	label variable notmarried "Reason not using: not married"
	tab notmarried [aw=FQweight]

	* Method related includes fear of side effects, health concers, interferes wth bodies natural processes, inconvenient to use
	* Health concerns
	gen methodrelated=0 if why_not_using!=""
	replace methodrelated=1 if (why_not_usinghealth==1 | why_not_usingbodyproc==1| why_not_usingfearside==1 | why_not_usinginconv==1)
	label variable methodrelated "Reason not using: method or health-related concerns"
	tab methodrelated [aw=FQweight]

	* Opposition includes personal, partner, other, religious 
	gen opposition=0 if why_not_using!=""
	replace opposition=1 if why_not_usingrespopp==1|why_not_usinghusbopp==1|why_not_usingotheropp==1| why_not_usingrelig==1 
	label variable opposition "Reason not using: opposition to use"
	tab opposition [aw=FQweight]	 
	 
	* Access/knowledge
	gen accessknowledge=0 if why_not_using!=""
	replace accessknowledge=1 if why_not_usingdksource==1 | why_not_usingdkmethod==1 | why_not_usingaccess==1 | why_not_usingcost==1 |	///
	why_not_usingprfnotavail==1 | why_not_usingnomethod==1
	label variable accessknowledge "Reason not using: lack of access/knowledge"
	tab accessknowledge [aw=FQweight]

	* Other/no response/don't know
	gen othernoresp=0 if why_not_using!=""
	replace othernoresp=1 if ( why_not_usingother==1 | why_not_using=="-88" | why_not_using=="-99" )
	label variable othernoresp "Reason not using: other"
	tab othernoresp [aweight=FQweight] 

	* Label yes/no response options
	foreach x in noneed nosex notmarried methodrelated opposition accessknowledge othernoresp {
	label values `x' yesno
	}
	
* Tabout reasons for not using contraception among all women wanting to delay the next birth for 2 or more yeras
tabout notmarried noneed methodrelated opposition accessknowledge othernoresp [aweight=FQweight] using "`CCRX'_HHQFQ_2Page_Analysis_Output_$date.xls",	///
append oneway c(freq col) f(0 1) npos(row) 	h2("Reasons for non-use - among all women wanting to delay (weighted)") 

*Drop ammened birthmonth and keep original coding
drop birthmonth
rename birthmonth2 birthmonth
save "`CCRX'_HHQFQ_2Page_Analysis_$date.dta", replace

*******************************************************************************
* MEANS AND MEDIANS
*******************************************************************************

* Generate age at first marriage by "date of first marriage - date of birth"
	* Get the date for those married only once from FQcurrent*
	* Get the date for those married more than once from FQfirst*

* marriage cmc already defined in unmet need 

* Run code to generate medians 
run "`medianfile'"
capture drop one

* Generate median age of first marriage 
capture drop agemarriage
gen agemarriage=(marriagecmc-v011)/12
label variable agemarriage "Age at first marriage (25 to 49 years)"
*hist agemarriage  if FQ_age>=25 & FQ_age<50
save, replace
save tem, replace

**Install the new command needed for the change
ssc install listtab, all replace
* Median age at marriage among all women who have married
preserve
pma2020mediansimple tem agemarriage 25 
gen urban="All Women"
tempfile total
save `total', replace 
restore

preserve
keep if urban==0
capture codebook metainstanceID
if _rc!=2000{ 
save tem, replace
pma2020mediansimple tem agemarriage 25
gen urban="Rural"
tempfile rural
save `rural', replace
}
restore 

preserve
keep if urban==1
capture codebook metainstanceID
if _rc!=2000{ 
save tem, replace
pma2020mediansimple tem agemarriage 25
gen urban="Urban"
tempfile urban
save `urban', replace
}
restore 

preserve
use `total', clear
capture append using `rural'
capture append using `urban'

listtab urban median , appendto("`CCRX'_HHQFQ_2Page_Analysis_Output_$date.xls") rstyle(tabdelim) headlines("Median age at marriage among all women who have married- by urban/rural (weighted)") footlines(" ")
restore

*Median age at first sex among all women who have had sex
preserve
keep if age_at_first_sex>0 & age_at_first_sex<50 
save tem, replace
pma2020mediansimple tem age_at_first_sex 15
gen urban="All Women"
tempfile total
save `total', replace
restore

preserve 
keep if age_at_first_sex>0 & age_at_first_sex<50 & urban==0
capture codebook metainstanceID
if _rc!=2000 {
save tem, replace
pma2020mediansimple tem age_at_first_sex 15
gen urban="Rural"
tempfile rural
save `rural', replace 
}
restore

preserve 
keep if age_at_first_sex>0 & age_at_first_sex<50 & urban==1 
capture codebook metainstanceID
if _rc!=2000 {
save tem, replace
pma2020mediansimple tem age_at_first_sex 15
gen urban="Urban"
tempfile urban
save `urban',replace
}
restore

preserve
use `total', clear
capture append using `rural'
capture append using `urban'
listtab urban median , appendto("`CCRX'_HHQFQ_2Page_Analysis_Output_$date.xls") rstyle(tabdelim)  headlines("Median age at first sex - among all women who have had sex by urban/rural(weighted)") footlines(" ")
restore

* Median age at first contraceptive use among all women who have ever use contraception
preserve
keep if fp_ever_used==1 & age_at_first_use>0
save tem, replace
pma2020mediansimple tem age_at_first_use 15
gen urban="All Women"
tempfile total
save `total', replace
restore

preserve
keep if fp_ever_used==1 & age_at_first_use>0 & urban==0
capture codebook metainstanceID
if _rc!=2000 {
save tem, replace
pma2020mediansimple tem age_at_first_use 15
gen urban="Rural"
tempfile rural
save `rural', replace
}
restore

preserve
keep if fp_ever_used==1 & age_at_first_use>0 & urban==1
capture codebook metainstanceID
if _rc!=2000 {
save tem, replace
pma2020mediansimple tem age_at_first_use 15
gen urban="Urban"
tempfile urban
save `urban', replace
}
restore

preserve
use `total', clear
append using `rural'
append using `urban'
listtab urban median , appendto("`CCRX'_HHQFQ_2Page_Analysis_Output_$date.xls") rstyle(tabdelim)  headlines("Median age at first contraceptive use - among all women who have used contraception by urban/rural (weighted)") footlines(" ")
restore

* Generate age at first birth by subtracting birth date from age at first birth and dividing by hours in a year
capture drop agefirstbirth
capture replace first_birthSIF=recent_birthSIF if birth_events==1
capture replace first_birthSIF=recent_birthSIF if children_born==1 
gen agefirstbirth=hours(first_birthSIF-birthdateSIF)/8765.81

* Median age at first birth among all women who have ever given birth
preserve
keep if ever_birth==1
save tem, replace
pma2020mediansimple tem agefirstbirth 25
gen urban="All Women"
tempfile total
save `total', replace
restore

preserve
keep if ever_birth==1 & birth_events_rw!=. & birth_events_rw!=-99 & urban==0
capture codebook metainstanceID 
if _rc!=2000 {
save tem, replace
pma2020mediansimple tem agefirstbirth 25
gen urban="Rural"
tempfile rural
save `rural', replace
}
restore

preserve
keep if ever_birth==1 & birth_events_rw!=. & birth_events_rw!=-99 & urban==1
capture codebook metainstanceID 
if _rc!=2000 {
save tem, replace
pma2020mediansimple tem agefirstbirth 25
gen urban="Urban"
tempfile urban
save `urban', replace
}
restore

preserve
use `total', clear
append using `rural'
append using `urban'
listtab urban median , appendto("`CCRX'_HHQFQ_2Page_Analysis_Output_$date.xls") rstyle(tabdelim)  headlines("Median age at first birth - among all women who have given birth by urban/rural(weighted)") footlines(" ")
restore

* Percent of women age 18-24 having first birth by age 18 
capture drop birth18
gen birth18=0 if FQ_age>=18 & FQ_age<25
replace birth18=1 if agefirstbirth<18 & birth18==0
label variable birth18 "Birth by age 18 (18-24)"
tab birth18 [aw=FQweight]
tab urban birth18 [aw=FQweight], row

* Percent received FP information from visiting provider or health care worker at facility
recode visited_by_health_worker -99=0
recode facility_fp_discussion -99=0
gen healthworkerinfo=0
replace healthworkerinfo=1 if visited_by_health_worker==1 | facility_fp_discussion==1
label variable healthworkerinfo "Received family planning info from provider in last 12 months"
tab healthworkerinfo [aweight=FQweight]
tab urban healthworkerinfo [aweight=FQweight], row

* Percent with exposure to family planning media in past few months
gen fpmedia=0
replace fpmedia=1 if fp_ad_radio==1 | fp_ad_magazine==1 | fp_ad_tv==1
label variable fpmedia "Exposed to family planning media in last few months"
tab fpmedia [aw=FQweight]
tab urban fpmedia [aw=FQweight], row

* Label yes/no response options
foreach x in healthworkerinfo fpmedia {
	label values `x' yesno
	}
	
* Tabout mean no. of living children at first contraceptive use among women who have ever used contraception 
replace age_at_first_use_children=0 if ever_birth==0 & fp_ever_used==1
tabout urban [aweight=FQweight] if fp_ever_used==1 & age_at_first_use_children>=0 using "`CCRX'_HHQFQ_2Page_Analysis_Output_$date.xls", append sum c(mean age_at_first_use_children) f(3) npos(row)  h2("Mean number of children at first contraceptive use - among all women who have used contraception (weighted)") 

* Tabout birth by age 18 among all women by urban/rural, weighted
tabout birth18 urban [aweight=FQweight] using "`CCRX'_HHQFQ_2Page_Analysis_Output_$date.xls", append c(col) f(1) npos(row)  h1("Birth by age 18 (18-24) - among all women (weighted)") 

* Tabout received family planning information from provider in last 12 months among all women by urban/rural, weighted
tabout healthworkerinfo urban [aweight=FQweight] using "`CCRX'_HHQFQ_2Page_Analysis_Output_$date.xls", append c(col) f(1) npos(row)  h1("Received FP info. from provider in last 12 months - among all women (weighted)") 

* Tabout received family planning information from provider in last 12 months among all women by urban/rural, weighted
tabout fpmedia urban [aweight=FQweight] using "`CCRX'_HHQFQ_2Page_Analysis_Output_$date.xls", append c(col) f(1) npos(row)  h1("Exposed to FP media in last few months - among all women (weighted)") 

*******************************************************************************
* ALTERNATIVE INDICATORS IF FEWER THAN 50 UNMARRIED SEXUALLY ACTIVE WOMEN
*******************************************************************************

* Percent women 18-24 who are married by age 18
gen married18=0 if FQ_age>=18 & FQ_age<25
replace married18=1 if agemarriage<18 & married18==0
label variable married18 "Married by age 18"
tab married18 [aw=FQweight]
tab urban married18 [aw=FQweight], row

* Percent women 18-24 who have had first birth by age 18
*Already defined
	
* Percent women 18-24 who have had first contraceptive use by age 18
gen fp18=0 if FQ_age>=18 & FQ_age<25
replace fp18=1 if age_at_first_use>0 & age_at_first_use<18 & fp18==0 
label variable fp18 "Used contraception by age 18"
tab fp18 [aw=FQweight]
tab urban fp18 [aw=FQweight], row

* Percent women who had first sex by age 18
gen sex18=0 if FQ_age>=18 & FQ_age<25
replace sex18=1 if age_at_first_sex>0 & age_at_first_sex<18 & sex18==0 
label variable sex18 "Had first sex by age 18"
tab sex18 [aw=FQweight]
tab urban sex18 [aw=FQweight], row

* Label yes/no response options
foreach x in married18 birth18 fp18 sex18 {
	label values `x' yesno
	}
	
* Tabout married by 18, first birth before 18, contraceptive use by 18, first sex by 18 among women age 18-24 (weighted)
tabout married18 sex18 fp18 birth18 [aw=FQweight] if FQ_age>=18 & FQ_age<25 using "`CCRX'_HHQFQ_2Page_Analysis_Output_$date.xls", append oneway c(col) f(1) clab(%) npos(row) 	///
h2("Married by 18, first sex by 18, contraceptive use by 18, first birth before 18 - women age 18-24 (weighted)") 


* Age specific rates of long, short, tcp and unmet need
gen lstu=1 if longacting==1
replace lstu=2 if longacting!=1 & mcp==1
replace lstu=3 if tcp==1
replace lstu=4 if unmettot==1
replace lstu=5 if lstu==. 
label define lstul 1 "Long acting" 2 "Short acting" 3 "Traditional" 4 "Unmet need" 5 "Not using/no need"
label val lstu lstul

egen age5=cut(FQ_age), at(15(5)50)

tabout age5 lstu [aw=FQweight] using "`CCRX'_HHQFQ_2Page_Analysis_Output_$date.xls", append ///
cells(row) h1("Use/need by age - all women (weighted)") f(2)

*******************************************************************************
* DEMOGRAPHIC VARIABLES
*******************************************************************************

recode school -99=.
tabout age5  [aw=FQweight] using "`CCRX'_HHQFQ_2Page_Analysis_Output_$date.xls",  append  ///
c(freq col) f(0 1) clab(n %) npos(row)  h2("Distribution of de facto women by age - weighted")

tabout school  [aw=FQweight] using "`CCRX'_HHQFQ_2Page_Analysis_Output_$date.xls",  append  ///
c(freq col) f(0 1) clab(n %) npos(row)  h2("Distribution of de facto women by education - weighted")

tabout FQmarital_status [aw=FQweight] using "`CCRX'_HHQFQ_2Page_Analysis_Output_$date.xls",  append  ///
c(freq col) f(0 1) clab(n %) npos(row)  h2("Distribution of de facto women by marital status - weighted")

tabout wealth  [aw=FQweight] using "`CCRX'_HHQFQ_2Page_Analysis_Output_$date.xls",  append  ///
c(freq col) f(0 1) clab(n %) npos(row)  h2("Distribution of de facto women by wealth - weighted")

tabout sexactive  [aw=FQweight] using "`CCRX'_HHQFQ_2Page_Analysis_Output_$date.xls",  append  ///
c(freq col) f(0 1) clab(n %) npos(row)  h2("Distribution of de facto women by sexual activity - weighted")

capture tabout urban [aw=FQweight] using "`CCRX'_HHQFQ_2Page_Analysis_Output_$date.xls",  append ///
c(freq col) f(0 1) clab(n %) npos(row)  h2("Distribution of de facto women by urban/rural - weighted")


*******************************************************************************
* CLOSE
*******************************************************************************

log close
