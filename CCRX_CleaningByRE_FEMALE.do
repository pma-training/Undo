*CCR# Female Form Cleaning
**Make sure you are using the Female Database with a date
*Should automatically use the FRQ but if not, use the directory below
*use "$datadir/CCR#_FRQ_$date.dta"

**Examples

*drop duplicates, drop forms that are incorrectly created

*Drop duplicate RE Celine Dion
*Two forms for same persion in EA1/structure/1household1, first one is only partially complete, second is complete
*drop if metainstanceID=="uuid:5734bec2-e9a7-4dd5-8c80-5475b13f04bd"

***drops duplicate Female**


*RE Jennifer Lopez
*created forms without linking household for EA1/structure/1household1
*drop if metainstanceID=="somemetainstanceID"
/*
*Christine-Nafula 66 Alice & Leah[The data is not completely the same and though the name is the same kept the one done on the 3rd visit
drop if metainstanceID=="uuid:7919e3b6-3e59-45d3-91d7-14bb2aaada3b"
drop if metainstanceID=="uuid:b7a9d82e-679c-45bb-8afb-408b2a750532"
replace  structure=162 if  structure==192 & metainstanceID=="uuid:68437931-e4d2-45f3-8d66-3a412244f19d"
*/
save, replace
