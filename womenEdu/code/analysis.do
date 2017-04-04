clear all
set more off 
capture log close

global data "H:\stata\charls\data"
global output "H:\stata\charls\output"
log using "$output\analysis", replace
cd "$output" 
use "analysis.dta", replace

* data management
drop id ID inhome
rename distanceborn birthDist
rename childincome childIncome
order householdID communityID birthOrder siblings totalFemale totalMale birthDist  ///
	  female highestEdu currentEdu childIncome urbanDad eduDad urbanMom eduMom year month
replace communityID = substr(householdID, 1, 7)
foreach v of varlist birthOrder-year {
	replace `v' = . if mi(`v')
}
label values female lab_female 
label define lab_female 0 "Male" 1 "Female", modify
replace highestEdu = currentEdu if mi(highestEdu)
label values highestEdu lab_highestEdu
label define lab_highestEdu 0 "Illiterate" 1 "Not finish primary school" 2 "Finish primary school"  ///
							3 "Finish middle school" 4 "Finish high school" 5 "College or higher", modify
label values childIncome lab_income
label define lab_income 1 "0" 2 "<2k" 3 "2k-5k" 4 "5k-10k" 5 "10k-20k" 6 "20k-50k" ///
						7 "50k-100k" 8 "100k-150k" 9 "150k-200k" 10 "200k-300k" 11 ">300k"
label values urbanDad lab_urbanDad
label define lab_urbanDad 0 "Rural" 1 "Urban"
label values eduDad lab_eduDad
label define lab_eduDad 0 "Illiterate" 1 "Not finish primary school" 2 "Finish primary school"  ///
							3 "Finish middle school" 4 "Finish high school" 5 "College or higher", modify
label values urbanMom lab_urbanMom
label define lab_urbanMom 0 "Rural" 1 "Urban"
label values eduMom lab_eduMom
label define lab_eduMom 0 "Illiterate" 1 "Not finish primary school" 2 "Finish primary school"  ///
							3 "Finish middle school" 4 "Finish high school" 5 "College or higher", modify
keep if year >= 1965 & year <= 1990
keep if birthDist >=-20 & birthDist <= 20
drop if mi(female)|mi(highestEdu)
drop currentEdu month
foreach v of varlist birthOrder-year {
	tab `v', mi
}
* summary statistics

* visulization
preserve	
	collapse highestEdu, by(year female)
	twoway (scatter highestEdu year if female == 0, lcolor("93 188 210") mcolor("93 188 210") msymbol(s) connect(1)) ///
			(scatter highestEdu year if female == 1, lcolor("139 0 18") mcolor("139 0 18") msymbol(t) connect(1)),  ///
			ytitle("Mean Education Level") xtitle("Birth Year") graphregion(color(white)) ///
			ylabel(1.5(0.5)3.5) ymtick(##1) xmtick(##5) ///
			legend(label(1 "Male") label(2 "Female") region(lcolor(white))) scheme(s1)  
	graph export "meanEdu.pdf", replace		
restore
* regression

* done
log close

