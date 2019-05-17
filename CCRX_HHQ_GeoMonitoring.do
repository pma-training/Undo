** GPS checks for HHQ survey 
** Authors Ann Rogers - Sally Ann Safi - Beth Larson - Julien Nobili
** Requirements: Listing.dta file (needs to be generated beforehand)
** version 1.1  (April 2019)

**********************Set directory**************************************

local datadir 		$datadir
local dofiles       $dofiledir
local csv_results   $datadir
local Geo_ID 		$Geo_ID
local CCRX			$CCRX
 

*****************Preparation of the Listing file*************************

* Import full country round listing file; Requires to first generate a clean version of the listing.dta, using the Listing.do; 
** Then save the output in your datadir (non-dropbox) **
*** NEEDS TO BE UPDATED BEFORE USE ***

clear 
use BFR5_Listing_22Apr2019.dta

drop if HH_SDP=="SDP"
duplicates drop

destring GPS_HHLatitude, replace
destring GPS_HHLongitude, replace

* Generate XY average per EA (EA centroids creation)
bysort EA: egen centro_latt=mean(GPS_HHLatitude) if GPS_HHLatitude!=0
bysort EA: egen centro_long=mean(GPS_HHLongitude) if GPS_HHLongitude!=0

* Save one observation per EA with average geo-coordinates
egen tag=tag(EA)

preserve
keep if tag==1
keep EA centro_latt centro_long

* Save as temp_listing
tempfile temp_listing_centroids
save `temp_listing_centroids.dta', replace

restore

drop if Occupied_YN_HH=="no"
drop if GPS_HHLatitude==. | GPS_HHLongitude==.

* Convert vars to string and concatenate vars EA + structure_number
egen conc= concat(EA  number_structure_HH), punct("-")

* Keep useful vars and drop duplicates
keep EA GPS_HHLatitude GPS_HHLongitude conc
duplicates drop conc, force

* Save as temp_listing_ready
tempfile temp_listing_ready
save `temp_listing_ready.dta', replace

**********************Preparation of the HHQ file****************

* Use cleaned HHQ dataset from PARENT
clear
use "`datadir'/`CCRX'_HHQ_$date.dta" 

* Keep vars and generate concatanated vars EA + Structure_number
egen conc= concat(EA structure), punct("-")
keep RE `Geo_ID' EA locationLatitude locationLongitude locationAccuracy metainstanceID conc

******* Merge: temp_listing_centroids + HHQ file, then listing_ready + (HHQ+ listing centro)**************

merge m:1 EA using `temp_listing_centroids.dta', gen(centroid_merge)
drop centroid_merge

merge m:1 conc using `temp_listing_ready.dta', gen(ready_merge)
drop if ready_merge==2

************* Gen distances vars (distance from HH to Centroid, and HH to listing's structure***********
destring locationLatitude, replace
destring locationLongitude, replace
destring locationAccuracy, replace

gen distance_2_cent=(((locationLatitude-centro_latt)^2+(locationLongitude-centro_long)^2)^(1/2))*111295
gen distance_2_list=(((locationLatitude-GPS_HHLatitude)^2+(locationLongitude-GPS_HHLongitude)^2)^(1/2))*111295

*********** Generate mean and standard-dev using var distance_cent *************

bysort EA: egen mean_distance_cent=mean(distance_2_cent)
bysort EA: egen sd_distance_cent=sd(distance_2_cent)

************************ Genarate Issues vars **********************************

gen missing_coordinates=1 if  locationLatitude==. | locationLongitude==. 
gen poor_accuracy=1 if locationAccuracy>6 & !missing(locationAccuracy)
gen EA_size_issue=1 if mean_distance_cent<sd_distance_cent
gen HH_suspect_location=1 if ((distance_2_cent-mean_distance_cent)/sd_distance_cent)>=2
gen No_correspondence_HH2listing=1 if ready_merge==1
gen HH_toofar_listing=1 if distance_2_list >101 & !missing(distance_2_list)

********* Keep useful vars and save output files (GIS monitoring) **************

keep RE `Geo_ID' EA locationLatitude locationLongitude locationAccuracy metainstanceID missing_coordinates poor_accuracy EA_size_issue HH_suspect_location No_correspondence_HH2listing HH_toofar_listing
save `CCRX'_HHQ_GISFullcheck_$date.dta, replace 

export delimited using `CCRX'_HHQ_GISFullcheck_$date.csv, replace

************* Output spreadsheet (errors by RE) Errors.xls *********************

collapse(count) missing_coordinates poor_accuracy EA_size_issue HH_suspect_location No_correspondence_HH2listing HH_toofar_listing, by(RE)
export excel RE missing_coordinates poor_accuracy EA_size_issue HH_suspect_location No_correspondence_HH2listing HH_toofar_listing using `CCRX'_HHQFQErrors_$date.xls, firstrow(variables) sh(GPS_check_by_RE) sheetreplace

********************************* Voilà! ****************************************




