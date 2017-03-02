************************************************
* Prepare the data for Class 3: Panel exercise
************************************************

capture log close
set more off
clear all

***********************
* Fertility (Eurostat)
***********************

cd "H:\Class 3\panel\data"

import excel using "demo_frate.xls"
drop if _n<10
outsheet using fertility.csv, replace nonames
insheet using  fertility.csv, clear names

destring v*, replace force

reshape long v, i(geotime) j(year)
rename geotime country
rename v fertility_rate
replace year=year+1959

save dataset.dta, replace

********************
* Males (Eurostat)
********************

* Employment
clear all
import excel "lfsi_emp_a(1).xls", clear sheet("Data")
drop if _n<10
outsheet using fertility.csv, replace nonames
insheet using  fertility.csv, clear names

destring v*, replace force

reshape long v, i(geotime) j(year)
rename geotime country
replace year=year+1991
rename v m_emp

merge 1:1 country year using dataset.dta
drop if _merge!=3
drop _merge

save dataset.dta, replace

* Part time
clear all
import excel "lfsi_emp_a(1).xls", clear sheet("Data3")
drop if _n<10
outsheet using fertility.csv, replace nonames
insheet using  fertility.csv, clear names

destring v*, replace force

reshape long v, i(geotime) j(year)
rename geotime country
replace year=year+1991
rename v m_part_time

merge 1:1 country year using dataset.dta
drop if _merge!=3
drop _merge

save dataset.dta, replace

* Temporary contracts
clear all
import excel "lfsi_emp_a(1).xls", clear sheet("Data4")
drop if _n<10
outsheet using fertility.csv, replace nonames
insheet using  fertility.csv, clear names

destring v*, replace force

reshape long v, i(geotime) j(year)
rename geotime country
replace year=year+1991
rename v m_temp_emp

merge 1:1 country year using dataset.dta
drop if _merge!=3
drop _merge

save dataset.dta, replace


*********************
* Females (Eurostat)
*********************

* Employment
clear all
import excel "lfsi_emp_a(1).xls", clear sheet("Data")
drop if _n<10
outsheet using fertility.csv, replace nonames
insheet using  fertility.csv, clear names

destring v*, replace force

reshape long v, i(geotime) j(year)
rename geotime country
replace year=year+1991
rename v f_emp

merge 1:1 country year using dataset.dta
drop if _merge!=3
drop _merge

save dataset.dta, replace

* Part time
clear all
import excel "lfsi_emp_a(1).xls", clear sheet("Data3")
drop if _n<10
outsheet using fertility.csv, replace nonames
insheet using  fertility.csv, clear names

destring v*, replace force

reshape long v, i(geotime) j(year)
rename geotime country
replace year=year+1991
rename v f_part_time

merge 1:1 country year using dataset.dta
drop if _merge!=3
drop _merge

save dataset.dta, replace

* Temporary contracts
clear all
import excel "lfsi_emp_a(1).xls", clear sheet("Data4")
drop if _n<10
outsheet using fertility.csv, replace nonames
insheet using  fertility.csv, clear names

destring v*, replace force

reshape long v, i(geotime) j(year)
rename geotime country
replace year=year+1991
rename v f_temp_emp

merge 1:1 country year using dataset.dta
drop if _merge!=3
drop _merge

* Country correction
replace country="Germany" if country=="Germany (until 1990 former territory of the FRG)"
drop if country==":" | country=="" | country=="Special value:" | country=="Euro area (17 countries)" ///
| country=="Euro area (18 countries)" | country=="Euro area (19 countries)" | country=="European Union (27 countries)" ///
| country=="European Union (29 countries)"

save dataset.dta, replace

*************
*GDP (IMF)
*************

insheet using "gdp.csv", clear names

foreach var of varlist v*{
replace `var'=subinstr(`var',",","",.)
}
*
destring v*, replace force

reshape long v, i(country) j(year)
*data start in 1979
replace year=year+1979
rename v gdp_ppp

merge 1:1 country year using dataset.dta
drop if _merge!=3
drop _merge

save dataset.dta, replace

**************************
* Epl - permanent (OECD)
**************************

insheet using "epl_permanent.csv", clear names

destring v*, replace force

reshape long v, i(country) j(year)
*data start in 1990
replace year=year+1989
rename v epl_permanent

merge 1:1 country year using dataset.dta
drop if _merge!=3
drop _merge

save dataset.dta, replace


**************************
* Epl - temporary (OECD)
**************************

insheet using "epl_temporary.csv", clear names

destring v*, replace force

reshape long v, i(country) j(year)
*data start in 1990
replace year=year+1989
rename v epl_temporary

merge 1:1 country year using dataset.dta
drop if _merge!=3
drop _merge

save dataset.dta, replace


**********************************
* Expenditure - family (Eurostat)
**********************************

import excel using "family expenditure.xls", clear firstrow sheet("Data2")
drop if _n<11
outsheet using fertility.csv, replace nonames
insheet using  fertility.csv, clear names

destring v*, replace force

reshape long v, i(geotime) j(year)
rename geotime country
replace year=year+1989
rename v exp_family

replace country="Germany" if country=="Germany (until 1990 former territory of the FRG)"

merge 1:1 country year using dataset.dta
drop if _merge==2
drop _merge

drop if country==":" | country=="" | country=="Special value:" | country=="Euro area (17 countries)" ///
| country=="Euro area (18 countries)" | country=="Euro area (19 countries)" | country=="European Union (27 countries)" ///
| country=="European Union (29 countries)" | country=="Euro area (12 countries)" |  country=="Euro area (13 countries)" ///
| country=="Euro area (15 countries)" | country=="Euro area (16 countries)" | country=="European Union (25 countries)" ///
| country=="European Union (28 countries)"

label var country "Country"
label var year "Panel year"
label var exp_family "Family expenditure in percentage of GDP"
label var epl_temporary "OECD rigidity index - Temporary contr"
label var epl_permanent "OECD rigidity index - Permanent contr"  
label var  gdp_ppp "GDP in PPP"
label var f_temp_emp "% of temporary contracts - females" 
label var f_part_time "% of part time contracts - females"
label var f_emp "Employment rate of 20-64 - females"
label var m_temp_emp "% of temporary contracts - males" 
label var m_part_time "% of part time contracts - males"
label var m_emp "Employment rate of 20-64 - males"
label var fertility_rate "Fertility rate"

keep fertility_rate m_emp m_part_time m_temp_emp f_emp f_part_time f_temp_emp gdp_ppp epl_permanent epl_temporary exp_family year country

drop if country=="Iceland" | country=="Sweden" | country=="Norway" | country=="Luxembourg"

save dataset.dta, replace
