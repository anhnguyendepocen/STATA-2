***************************************
* ChettyLab: Intergenerational Mobility
* by Hulai Zhang, 05 March 2017
***************************************

capture log close
set more off
clear all

global data "H:\stata\Chettylab\data"
global output "H:\stata\Chettylab\output"

log using "$output\mobility", replace text

/*Merge cz_names.csv*/
cd "$data"
insheet using "cz_names.csv", delimiter(",") names clear
save "cz_names.dta", replace
insheet using "cz_level_data.csv", delimiter(",") names clear
merge 1:1 cz using "cz_names.dta"
drop _merge
order czname, a(cz)  //order czname after cz
save "cz_merge.dta", replace

cd "$output"
/*Q1 Difference of perm_res_rank_p25 from the national mean*/
//install _GWTMEAN to caculate weighted mean or manually
capture ssc install _GWTMEAN  //install package to caculate weighted mean
tempvar weight_mean
egen `weight_mean'= wtmean(perm_res_rank_p25) if perm_res_rank_p25 != ., weight(population)
gen dif_rank = perm_res_rank_p25 - `weight_mean'
drop `weight_mean'
sort dif_rank, stable
//Grapgh hbar
preserve
drop if dif_rank==.
keep if (_n>=_N-4)|(_n<=5)
gen no_rank=_n
gen cz_name_state=czname+","+stateabbrv
gen last_five = 1 if _n > 5
replace last_five = 0 if _n <=5
export delimited cz-last_five using "Rgraph.csv",replace

//Raw graph by STATA
graph hbar dif_rank , over(cz_name_state, sort(dif_rank) descending) graphregion(color(white))  ///
			ytitle("Diiference from National Mean") scheme(sj)  ///
			saving(dif_rank, replace) 
graph export dif_rank.pdf, replace
//describe other variables of the 10
collapse african_american_share - median_house_value [pw=population], by(last_five)
export delimited using "tenDes.csv", replace
restore

/*Q3*/
//install maptile spmap geo_list
capture ssc install maptile
capture ssc install spmap
maptile_install using "http://files.michaelstepner.com/geo_state.zip"

//Map for state level data
preserve
drop if perm_res_rank_p25==.
collapse perm_res_rank_p25 [pw=population], by(stateabbrv)
rename stateabbrv state
maptile perm_res_rank_p25, geo(state) propcolor revcolor
graph export state_level.pdf, replace
restore

/*Q5 Regressions*/
capture ssc install estout   //install estout for stylelized output
drop if (total_exposure_effect_p25==.)|(perm_res_rank_p25==.)  
//generate standard error, then regress
foreach var of varlist african_american_share - median_house_value {
	egen std_`var'=std(`var') 
	eststo: reg total_exposure_effect_p25 std_`var', robust   //eststo: restore reg result
	eststo: reg total_exposure_effect_p25 std_`var', robust cluster(state_id)
	eststo: reg perm_res_rank_p25 std_`var', robust
	eststo: reg perm_res_rank_p25 std_`var', robust cluster(state_id)
} 
esttab using reg.csv, label nostar replace drop(_cons)  //esttab: output the restored reg result

translate "mobility.log" "mobility.pdf", replace
log close
