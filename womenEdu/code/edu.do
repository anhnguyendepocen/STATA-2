* Family Structure and Education
clear all
set more off 
capture log close

global data "H:\stata\charls\data"
global output "H:\stata\charls\output"

log using "$output\edu", replace

cd "$output" 

use "$data\charls11\demographic_background.dta", clear
* gender
bysort householdID: egen rgender_max=max(rgender)
replace rgender = . if rgender != 1 & rgender != 2
replace rgender = 1 if rgender_max == 2 & mi(rgender) 
replace rgender = 2 if rgender_max == 1 & mi(rgender) 
gen female=(rgender==2)
replace female=. if mi(rgender)
* hukou
gen hukou = bc001 if !mi(bc001)
replace hukou = bc002 if (bc001 != 1)&(bc001 != 2)&(!mi(bc002))
replace hukou = . if hukou !=1 & hukou != 2
bysort householdID: egen urban = max(hukou)
replace urban = urban - 1
* education
recode bd001 (1=0) (2/3=1) (4=2) (5=3) (6=4) (7/10=5), gen(edu)
* insert missing value for female
bysort householdID: egen edu_max = max(edu)
replace female = 0 if (female == .)&(edu == edu_max)
replace female = 1 if (female == .)&(edu != edu_max)
bysort householdID: gen familyNum = _N
bysort householdID: egen female_max = max(female)
bysort householdID: egen female_min = min(female)
gen sameGender = 1 if (familyNum == 2)&(female_max == female_min)
replace female = 1 if (sameGender == 1)&(edu != edu_max)
replace female = 0 if (sameGender == 1)&(edu == edu_max)
bysort householdID: egen female_max2 = max(female)
bysort householdID: egen female_min2 = min(female)
gen sameGender2 = 1 if (familyNum == 2)&(female_max2 == female_min2)
bysort householdID: replace female = 0 if (_n == 1)&(sameGender2 == 1)
bysort householdID: replace female = 1 if (_n == 2)&(sameGender2 == 1)
bysort householdID: egen female_max3 = max(female)
bysort householdID: egen female_min3 = min(female)
gen sameGender3 = 1 if (familyNum == 2)&(female_max3 == female_min3)
drop if sameGender3 == 1 
* reshape
keep householdID female urban edu
sort householdID female, stable
reshape wide urban edu, i(householdID) j(female)
rename urban0 urbanDad
rename urban1 urbanMom
rename edu0 eduDad
rename edu1 eduMom
save "parent.dta", replace
* family information for non-resident
use "$data\charls11\family_information.dta", clear
keep householdID ID communityID cb049_1_ cb049_2_ cb049_3_ cb049_4_ cb049_5_ cb049_6_ cb049_7_ cb049_8_ cb049_9_ cb049_10_ cb049_11_ cb049_12_ cb049_13_ cb049_14_ cb051_1_1_ cb051_1_2_ cb051_1_3_ cb051_1_4_  ///
             cb051_1_5_ cb051_1_6_ cb051_1_7_ cb051_1_8_ cb051_1_9_  ///
			 cb051_1_10_ cb051_1_11_ cb051_1_12_ cb051_1_13_ cb051_1_14_ /// 
			 cb051_2_1_ cb051_2_2_ cb051_2_3_ cb051_2_4_ cb051_2_5_ cb051_2_6_  ///
			 cb051_2_7_ cb051_2_8_ cb051_2_9_ cb051_2_10_ cb051_2_11_ cb051_2_12_ cb051_2_13_ cb051_2_14_  ///
			 cb052_1_ cb052_2_ cb052_3_ cb052_4_ cb052_5_ /// 
             cb052_6_ cb052_7_ cb052_8_ cb052_9_ cb052_10_ cb052_11_ cb052_12_  ///
			 cb052_13_ cb052_14_ cb059_1_ cb059_2_ cb059_3_ cb059_4_ cb059_5_ cb059_6_ cb059_8_  /// 
			 cb059_9_ cb060_1_ cb060_2_ cb060_3_ cb060_4_ cb060_5_ cb060_6_ cb060_7_ cb060_8_ cb060_9_ cb060_10_ ///
			 cb064_1_ cb064_2_ cb064_3_ cb064_4_ cb064_5_ cb064_6_ cb064_7_ cb064_8_ cb064_9_ /// 
			 cb064_10_ cb069_1_ cb069_2_ cb069_3_ cb069_4_ cb069_5_ cb069_6_ cb069_7_ cb069_8_ cb069_9_ ///
			 cb069_10_ cb069_11_ cb069_12_ cb069_13_ cb069_14_ cb069_15_ cb069_23_ cb069_25_

forvalues i=1/14{
rename cb051_1_`i'_ cb051_1`i' 
rename cb051_2_`i'_ cb052_2`i' 
rename cb052_`i'_  cb052`i' 
rename cb049_`i'_ cb049`i'
}

forvalues i=1/6{
rename cb059_`i'_ cb059`i'
}
rename cb059_8_ cb0598
rename cb059_9_ cb0599

forvalues i=1/10{
rename cb060_`i'_ cb060`i'
rename cb064_`i'_ cb064`i'
}

forvalues i=1/15{
rename cb069_`i'_ cb069`i'
}
rename cb069_23_ cb06923
rename cb069_25_ cb06925

reshape long cb049 cb051_1 cb052_2 cb052 cb059 cb060 cb064 cb069,i(householdID) j(individual)
rename cb049 female
rename cb051_1 year
rename cb052_2 month
rename cb052 lunar
rename cb060 highesteducation
rename cb059 currenteducation
rename cb069 childincome
rename cb064 financialsupport
gen relationship=.
gen inhome=0
order female year month highesteducation currenteducation financialsupport childincome lunar inhome relationship
replace individual=individual+25
save "nonResident.dta"	,replace
save m1,replace
* family information for resident
use "$data\charls11\household_roster.dta"		 
keep  householdID ID communityID a002_1_ a002_2_ a002_3_ a002_4_ a002_5_ a002_6_ a002_7_ a002_8_ a002_9_ a002_10_ a002_11_ a002_12_ a002_13_ a002_14_ a002_15_ a002_16_ a003_1_1_ a003_1_2_ a003_1_3_ a003_1_4_ a003_1_5_ a003_1_6_ a003_1_7_ a003_1_8_ a003_1_9_ a003_1_10_ a003_1_11_ a003_1_12_ a003_1_13_ a003_1_14_ a003_1_15_ a003_1_16_ a003_2_1_ a003_2_2_ a003_2_3_ a003_2_4_ a003_2_5_ a003_2_6_ a003_2_7_ a003_2_8_ a003_2_9_ a003_2_10_ a003_2_11_ a003_2_12_ a003_2_13_ a003_2_14_ a003_2_15_ a003_2_16_ a014_1_ a014_2_ a014_3_ a014_4_ a014_5_ a014_6_ a014_7_ a014_8_ a014_9_ a014_10_ a014_11_ a014_12_ a014_13_ a015_1_ a015_2_ a015_3_ a015_4_ a015_5_ a015_6_ a015_7_ a015_8_ a015_9_ a015_10_ a015_11_ a015_12_ a015_13_ a015_14_ a015_15_ a015_16_ ///
       a006_1_ a006_2_ a006_3_ a006_4_ a006_5_ a006_6_ a006_7_ a006_8_ a006_9_ a006_10_ a006_11_ a006_12_ a006_13_ a006_14_ a006_15_ a006_16_
forvalues i=1/16{
rename a002_`i'_ a002`i'
rename a003_1_`i'_ a003_1`i'
rename a003_2_`i'_ a003_2`i'
rename a015_`i'_ a015`i'
rename a006_`i'_ a006`i'
}
forvalues i=1/13{
rename a014_`i'_ a014`i'
}
reshape long a002 a006 a003_1 a003_2 a014 a015,i(householdID) j(individual)
rename a002 female
rename a003_1 year
rename a003_2 month
rename a006  relationship
rename a014  currenteducation
rename a015  highesteducation
gen lunar=.
gen inhome=1
gen childincome=.
gen financialsupport=.
order female year month highesteducation currenteducation financialsupport childincome lunar inhome relationship
save "resident.dta",replace
use "resident.dta", clear
keep if relationship==7
save m2,replace

append using m1

save "resident&nonresident",replace
sort householdID
replace month=month+1 if lunar==2
replace year=year+1 if month==13
replace month=1 if month==13
drop if female==.
save "resident&nonresident",replace
replace female=0 if female==1
replace female=1 if female==2
drop if female==.
keep if female==0
drop month highesteducation female currenteducation financialsupport childincome lunar inhome relationship
reshape wide  year,i(householdID) j(individual)
save "allboys", replace
save m2,replace
use "resident&nonresident"
save m1,replace
use m2
use m1
merge m:1 householdID using m2
keep if _merge==3
drop _merge
save "allwithboymatch",replace
 
 use "allwithboymatch
 foreach v of varlist year1-year35{
 gen W`v'=year-`v'
 }
 drop year1-year35
 sort householdID
egen max=rowmax(Wyear1-Wyear35 )
egen min=rowmin(Wyear1-Wyear35 )
egen mean=rowmean(Wyear1-Wyear35)
save "allwithdistancebornwithboy",replace
clear
use "allwithdistancebornwithboy"

foreach v of varlist Wyear1-Wyear35{
gen X`v'=`v'
}

foreach v of varlist Wyear1-Wyear35{
replace `v'=. if `v'==0
}

foreach v of varlist Wyear1-Wyear35{
replace `v'=-`v' if `v'<0
}
egen Min=rowmin(Wyear1-Wyear35)

forvalues i=1/14{
gen min`i'=Min
}
forvalues i=26/35{
gen min`i'=Min
}
gen id=_n
drop min max mean Wyear1-Wyear35
save "allwithdistancebornwithboy",replace
use "allwithdistancebornwithboy"
foreach v of varlist XWyear1-XWyear35{
replace `v'=. if `v'==0
}
reshape long XWyear min,i(id) j(time)
gen k=1 if XWyear==min & XWyear !=. & min !=.
replace k=0 if XWyear==-min & XWyear !=. & min !=.
bysort id: egen g=max(k)
save "longallwithboys",replace
duplicates drop id ,force
keep id g
save m1,replace
use m1
use "allwithdistancebornwithboy"
merge 1:1 id using m1
replace Min=-Min if g==0
rename Min distanceborn
drop min1-min35
drop _merge g
replace female=0 if female==1
replace female=1 if female==2
save "allwithtruedistance",replace


use "allwithtruedistance"
reshape long XWyear, i(id) j(time)
replace distanceborn=0 if XWyear==0
keep if XWyear !=.
sort householdID
gen id2=id
save m1,replace
keep if distanceborn==0
save m2,replace
sort id
by id:egen n=count(id)
drop id
save m2,replace
use m1
drop if distanceborn ==0
keep if XWyear==distanceborn
drop id2
save m3,replace
use m2
use m3
merge m:m householdID time using m2
save m4,replace
sort id
keep if _merge==3
drop _merge
save m4,replace
drop n
bysort id:egen n=count(id)
duplicates drop id time,force
drop n
sort id
by id:egen n=count(id)
sort n
duplicates drop id,force
save m5,replace
keep id2
rename id2 id
duplicates drop id,force
save m6,replace
use m6
use "allwithtruedistance"
merge 1:1 id using m6
keep if _merge==3
drop _merge
save m6,replace
keep id highesteducation currenteducation
rename highesteducation HighEdu
rename currenteducation CurrenEdu
rename id id2
save m7,replace
use m7
use m4
merge m:1 id2 using m7
gen Eduboy=max(HighEdu, CurrenEdu)
gen Eduself=max(highesteducation, currenteducation)
keep if _merge==3
drop _merge
save "all-referenceboyeducation",replace
use "allwithtruedistance"
reshape long XWyear, i(id) j(time)
replace distanceborn=0 if XWyear==0
by id:egen d=max(distanceborn)
drop distanceborn
rename d distanceborn
reshape wide XWyear, i(id) j(time)
save "allwithtruedistance",replace

use "allwithtruedistance.dta", clear
merge m:1 householdID using "parent.dta"
drop _merge
tab highesteducation, mi
recode highesteducation (1=0) (2/3=1) (4=2) (5=3) (6=4) (7/11=5), gen(highestEdu)
recode currenteducation (1/4=1) (5/6=2) (7/10=3) (11/13=4) (14/24=5), gen(currentEdu)
bysort householdID: gen siblings = _N
sort householdID year month, stable
bysort householdID: gen birthOrder = _n
bysort householdID: egen totalFemale = sum(female)
gen totalMale = siblings - totalFemale
drop individual highesteducation currenteducation ///
		XWyear1-XWyear35 relationship financialsupport lunar
		
save "analysis.dta", replace

* drop unqualified observations
drop if mi(highestEdu)&mi(currentEdu)

preserve
	keep if year >= 1965 & year <= 1990
	collapse highestEdu, by(year female)
	twoway (scatter highestEdu year if female == 0, lcolor("93 188 210") mcolor("93 188 210") msymbol(s) connect(1)) ///
			(scatter highestEdu year if female == 1, lcolor("139 0 18") mcolor("139 0 18") msymbol(t) connect(1)),  ///
			ytitle("Mean Education Level") xtitle("Birth Year") graphregion(color(white)) ///
			ylabel(1.5(0.5)3.5) ymtick(##1) xmtick(##5) ///
			legend(label(1 "Male") label(2 "Female") region(lcolor(white))) scheme(s1)  
	graph export "meanEdu.pdf", replace		
restore
* regression
