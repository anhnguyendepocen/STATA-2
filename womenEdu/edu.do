* Family Structure and Education

clear all
set more off 
capture log close

global data "H:\stata\charls\data"
global output "H:\stata\charls\output"

log using "$output\pension", replace

cd "$output" 

use "$data\charls11\demographic_background.dta", clear
* hukou 
gen hukou = bc001 if !mi(bc001)
replace hukou = bc002 if (bc001 != 1)&(bc001 != 2)&(!mi(bc002))
rename bd001 highestEdu
rename be001 miritalStatus
rename bf004 spouseEdu_temp
keep ID-communityID hukou highestEdu miritalStatus spouseEdu_temp
save "parent.dta", replace




use "$data\charls11\family_information.dta", clear

keep if householdID == "265359310"


use "childInfo.dta", clear
keep if (relationship == 7)|(group == 2)
preserve
	collapse highesteducation, by(year)
	graph hbox highesteducation, over(year)
restore
