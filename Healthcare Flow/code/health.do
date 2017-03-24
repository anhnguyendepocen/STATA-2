* RA test 
* David and Maria at Stanford
* Arthor: Hulai Zhang

version 14

clear all
set more off
capture log close 

global data "H:\stata\RA task\data"
global output "H:\stata\RA task\output"

log using "$output\health", replace text
* import data and management
import delimited using "$data\test_data.txt", varnames(1) clear
order visit_num, b(ed_tc)
rename xb_lntdc lnStayLength
egen physician = group(phys_name)
capture noisily ssc install labutil
labmask physician, values(phys_name)
* change directory to "H:\stata\RA task\output"
cd "$output"
* generate date time of Arrival, order discharge,and shift
gen double edArrival = clock(ed_tc, "DMY hms")
format edArrival %tc
gen double orderDischarge = clock(dcord_tc, "DMY hms")
format orderDischarge %tc
* check edArrival < orderDischarge
gen errorCharge = 1 if edArrival >= orderDischarge
sort(errorCharge) // 4 entry errors 
* shift begin
gen beginHour_temp = substr(shiftid, 11, 7)
gen beginHour_temp2 = beginHour_temp if beginHour_temp != "noon to"
replace beginHour_temp2 = "12 p.m." if beginHour_temp == "noon to"
gen shiftBegin_temp = substr(shiftid, 1, 9) + " " + beginHour_temp2
gen double shiftBegin = clock(shiftBegin_temp, "DMY h")
format shiftBegin %tc
* shift end
gen endHour_temp = substr(shiftid, -7, .)
gen endHour_temp2 = endHour_temp if endHour_temp != "to noon"
replace endHour_temp2 = "12 p.m." if endHour_temp == "to noon"
gen shiftEnd_temp = substr(shiftid, 1, 9) + " " + endHour_temp2
gen double shiftEnd_temp2 = clock(shiftEnd_temp, "DMY h")
format shiftEnd_temp2 %tc
* encode shiftid
egen shift = group(shiftid)
labmask shift, values(shiftid)
* check shiftEnd >= shiftBegin
gen errorShift = 1 if shiftEnd_temp2 < shiftBegin
gen double shiftEnd = shiftEnd_temp2 if errorShift != 1
replace shiftEnd = shiftEnd_temp2 + msofhours(24) if errorShift == 1
format shiftEnd %tc
* check edArrial in interval [shiftBegin, shiftEnd]
gen inShift = 1 if (edArrival >= shiftBegin)&(edArrival <= shiftEnd)
* prople who waits
gen waiting_temp = 1 if mi(inShift)&(edArrival < shiftBegin) 
tab2 inShift waiting_temp, mi
drop waiting_temp
gen waiting = 1 if mi(inShift)&(orderDischarge > shiftBegin)
tab2 inShift waiting, mi
* calcalute the waiting minutes: divided by 60000 in STATA 14
gen waitingMinutes = (shiftBegin - edArrival)/60000 if mi(inShift)
sort(waitingMinutes)
* drop unnecessary variables
drop ed_tc dcord_tc shiftid phys_name beginHour_temp-shiftBegin_temp ///
	 endHour_temp-shiftEnd_temp2 errorShift
* data entry error that "edArrival > orderDischarge"
drop if errorCharge == 1 // 4 entry errors
* data entry error that [edArrival, orderDischarge] not in [shiftBegin, shiftEnd]
drop if mi(waiting)&(!mi(waitingMinutes)) // 5 entry errors
drop errorCharge inShift
* treatment length in minutes
gen treatmentLength = (orderDischarge - edArrival)/60000
replace treatmentLength = (orderDischarge - edArrival)/60000 - waitingMinutes if !mi(waitingMinutes)

*Q1 summarize the data
foreach var of varlist edArrival-shiftEnd {
	gen `var'Hour = hh(`var')
//	gen `var'Weekday = 
}
* using outreg2 package to generate statstics output table
outreg2 using stats.tex, replace sum(log) eqkeep(N mean sd min max p25 p50 p75) ///
					keep(lnStayLength waitingMinutes-shiftEndHour)
* Q2 before and after shift
gen afterShift = 1 if orderDischarge > shiftEnd
tab2 waiting afterShift, missing
* Q3 hourly pattern
* yline = 1/24 = 0.042
twoway (histogram edArrivalHour, graphregion(color(white)) xtitle("Hour of Patient Visit")  ///
				  bcolor(green) yline(0.042) xlabel(0(2)23) width(1) discrete) (kdensity edArrivalHour),  ///
				  legend(label(1 "Density Histogram") label(2 "K-density Curve")) scheme(s1color)
graph export hourlyPattern.pdf, replace 
tabout edArrivalHour using hourlyPattern.xls, replace cells(freq col)
* Q3 census
gen double shiftLength_temp = (shiftEnd - shiftBegin)/(60*60000)
tab shiftLength_temp, missing //shift length in [2h, 10h]
drop shiftLength_temp
gen double inTreat = (edArrival - shiftEnd)/(60*60000)
replace inTreat = (shiftBegin - shiftEnd)/(60*60000) if waiting == 1
gen double outTreat = (orderDischarge - shiftEnd)/(60*60000)
gen double outTreat_temp = outTreat
replace outTreat = 4 if outTreat_temp >= 4
drop outTreat_temp


forvalues i = 0/10 {
	if (`i' >= 1) & (`i' <= 3) {
		gen indexPos`i' = 0
		gen indexNeg`i' = 0
	}
	else if `i' >=4 {
		gen indexNeg`i' = 0
	}
	else {
	    gen index0 = 0
		replace index0 = 1 if (0 >= inTreat)&(outTreat >=0)
	}
} 
forvalues i =1/3 {
	replace indexPos`i' = 1 if (`i' >= inTreat)&(outTreat >= `i' )
}
forvalues i = 1/10 {
	replace indexNeg`i' = 1 if (-`i' >= inTreat)&(outTreat >= -`i')
}
preserve
	collapse (sum) index0 indexNeg* indexPos*, by(physician shift)
	save "Census.txt", replace
	rename index0 index10
	rename indexPos1 index11
	rename indexPos2 index12
	rename indexPos3 index13
	rename indexNeg10 index0
	rename indexNeg9 index1
	rename indexNeg8 index2
	rename indexNeg7 index3
	rename indexNeg6 index4
	rename indexNeg5 index5
	rename indexNeg4 index6
	rename indexNeg3 index7
	rename indexNeg2 index8
	rename indexNeg1 index9
	order physician shift index0 index1 index2 index3 index4 index5 ///
	      index6 index7 index8 index9 index10 index11 index12 index13
	reshape long index, i(physician shift) j(indexCo)
	rename index numPatient
	gen int index = indexCo -10
	drop indexCo
	graph box numPatient, over(index) nooutsides graphregion(color(white)) ///
							scheme(s1color)
	graph export numPatient.pdf, replace 
	save "Census_reshaped.txt", replace
restore
* Q4 regression
preserve
	graph hbox lnStayLength, over(physician, label(labsize(vsmall))) ///
			nooutsides graphregion(color(white)) scheme(s1color)
	graph export lnStayLength.pdf, replace 
	replace waiting = 0 if mi(waiting)
	capture ssc install estout 
	eststo: reg lnStayLength i.physician, robust
	eststo: reg lnStayLength i.physician waiting inTreat, robust
	esttab using reg.tex, replace label drop(_cons)
restore
		
* done
translate "health.log" "health.pdf", replace
log close
