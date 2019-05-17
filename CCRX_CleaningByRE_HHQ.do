 *CCR# Household Form Cleaning
**Make sure you are using the Household Database with a date
**Should not need to update the dataset directory but if you do, use the command below
*use "$datadir/CCR#_Combined_$date"


***RE/EA specific cleaning
*IF there are exact duplicates, drop 
*If there are households that were entered more than once and hh_duplicate_check is yes for one and no for the other, drop no
*If there are households with same number, but different people listed, add 1000 to one of the household numbers to indicate that the number
*was changed from the original but dont have the correct number

**Examples

*drop if metainstanceID=="uuid:3dd03052-4073-454b-9bee-26179f35047a"
*replace household=household+1000 if metainstanceID=="uuid:f10aad48-7ca4-4da3-9ddf-54718bba9fb4"
*replace FRS_form_name="" if metainstanceID=="uuid:a6a4e656-ecff-4fbd-b239-cf3a9ebf41eb"  & FRS_form_name=="FR:new_town-5-2-Alberta-23"

*RE Rachel McAdams entered same person twice in EA#/strucutre#/household#
*drop if member_number=="uuid:6b13a668-503e-4ec6-813f-497840b65b37/HH_member[7]"
*replace num_HH_members=6 if metainstanceID=="uuid:6b13a668-503e-4ec6-813f-497840b65b37"

**Changing structure numbers**

save, replace
