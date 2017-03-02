*************************
* CLASS 1: STATA basics
*************************

* Instead of typing commands one-by-one interactively, you can type them all in 
* one go within a do-file and simply run the do-file once.
* The results of each command can be recorded in a log-file for review when the 
* do-file has finished running.

* Put a "*", "//" or "/* comment */" before any comment, or anything you want to
* comment out (like a command you do not need). Comments are really helpful when
* coding, so use them! Without comments, nobody will ever know what you are doing.

clear all
* Clears any data currently in STATA's memory. If you try opening a datafile when
* one is already open, you get the erro message: "no; data in memory would be lost".

capture log close
* Closes any log-files that you might have accidentally left open. 
* If there is no log-file already open, then using only the command log close 
* will report the error: "no log file open".
* Using capture tells STATA to ignore any error messages and keep going.

set more off
* When there are a lot of results in the results window, STATA pauses the do-file
* to give you a chance to review each page on-screen and you have to press a key 
* to get more. This command tells STATA to run the entire do-file without pausing.

* List of directories (using macros)
* Macros are named containers for information of any kind. Macros come in two 
* different flavours, local (or temporary) and global.
local data "H:\Class 1\data"
global data "H:\Class 1\data"
global output "H:\Class 1\output"
* Global macros stay in the system and once set, can be accessed by all your commands.
* Globals are called as ${global name}: eg ${data}.
* Local macros and temporary objects are only created within a certain environment
* and only exist within that environment. If you use a local macro in a do-file it,
* you can only use it for code within that do-file.
* Locals are called as `local name': eg `data'.

* Remarks:
* 1. STATA is case sensitive, so it will not recognise the command Local or LOCAL.
* 2. Quotes "" are only needed if the directory or folder name has spaces in it. 
* 3. Note that while Windows uses a backslash "\" to separate folders, Linux and 
*    Unix Mac OS use a slash "/". This will give you trouble if you work with STATA 
*    on a server (e.g., Abacus at the LSE). Since Windows is able to understand
*    a slash as a separator, I suggest that you use slashes instead of backslashes
*    when working with several operating systems.


*******************
* Change directory
*******************

* Set directory of data and working directory
cd "$data"

* Check in which directory you are working
pwd
*present working directory


*****************
* Import data
*****************

* Use STATA data files
use weo_data.dta, clear
* If you do not need all variables in the data set, you can load only some.
*use var1 var2 "filename.dta", clear

* Use Excel file: xlsx files
import excel using data.xlsx, firstrow clear
* The option "first row" forces STATA to use the first row in your spreadsheet 
* as variable names.

* Use Excel file: csv files
insheet using "weo data.csv", delimiter(",") names clear
* The option "names" forces STATA to use the first line in your data for 
* variable names.
* STATA's insheet automatically recognises tab- and comma-delimited data but
* sometimes different delimiters are used, such as ";".

* Before importing excel files, remember:
* 1. The first line in the spreadsheet should have the variable names, and the 
*    second line onwards should have the data. If the top row of the file contains
*    a title then delete this row before saving.
* 2. Any extra lines below the data or to the right of the data (e.g. footnotes) 
*    will also be read in by Stata, so make sure that only the data itself is in 
*    the spreadsheet before saving. If necessary, select all the bottom rows 
*    and/or right-hand columns and delete them.
* 3. The variable names cannot begin with a number. If the file is laid out with
*    years (e.g. 1980, 1985, 1990) on the top line, then Stata could run into problems. 
*    In such instances, place an underscore in front of each number (e.g. select 
*    the row and use the spreadsheet package’s “find and replace” tools): 1980 
*    becomes _1980 and so on.
* 4. Make sure there are no commas in the data as it will confuse Stata about where
*    rows and columns start and finish (again, use “find and replace” to delete 
*    any commas before saving – you can select the entire worksheet in Excel by 
*    clicking on the empty box in the top-left corner, just above 1 and to the left of A).
* 5. Some notations for missing values can confuse Stata, e.g. it will read double
*    dots (..) or hyphens (-) as text. Replace such symbols with single dots (.) 
*    or simply to delete them altogether.


* Change directory to save output
cd "$output"

* Open log-file in directory
log using class1.log, replace text
* The replace option overwrites any long file of the same name, so if you re-run 
* an updated do-file again the old log-file will be replaced with the updated-results.
* By default, STATA uses the its own SMCL format to create log files. The text option
* overrides the default and makes the log file readable in any editor.

*******************
* Viewing the data
*******************

* Variables are organized as column vectors with individual observations in 
* each row. Each row is associated with one observation, that is the 5th row in
* each variable holds the information of the 5th individual, country, firm or 
* whatever information your data entails.

* View the data; cannot modify
browse
* View the data; can modify
edit

* Focus on particular observations
list if _n==5
* _n identifies the line of the observation on the data
* the command "if" allows to restrict the execution of a command to a set of 
* observations for which the condition(s) is satisfied
* Remember to use "==" instead of "=" when implying equality in a logic 
* statement, and "!=" when implying not equal to in a logic statement.
list if _n==_N
* Identifies last observation in the dataset
list in -10/l
* Identifies the last ten observations

****
* Q: What problems can you find with this dataset?
****


************************
* String manipulation 
************************

* STATA stores data either as numeric (numbers) or string (text). 
* Problem: if a variable has commas and/or other text, then STATA will recognise
* it as string. In order to perform numerical analysis with a variable we need 
* to change it to numeric format.

* Remember: missing numeric observations are denoted by a single dot (.), while 
* missing string observations are denoted by blank double quotes (""). 

* Look at how variables are stored
describe

foreach var of varlist v* {
* Repeat the command for all the variables affected by this problem.
* Symbol "*" is used to indicate any possible extension following v (v1, v2,..., v40)

replace `var'=subinstr(`var',",","",.)
* Replace in variable "var.." the comma with nothing at any occurrence
}
*

* Transform variables from strings to numbers
destring v*, replace force
* If "n/a" is still present and we want to transform to missing, we can just add 
* the option "force", so that whatever string there is left will be reported as
* missing "."
* If we wanted to make it a string again, just use "tostring".


**********************************
* Get numerical codes and labels
**********************************

* Generate numeric id variable for countries
egen country_c=group(country)
* Egen command creates also new variables based on summary measures, such as 
* sum, mean, min, max, count...

* Install new command that assigns labels to numeric variables using strings in other variables
capture noisily ssc install labmask
* If not found, you might want to look for it manually
findit labmask
* We see then that the command labmask is one of the commands in a suite called labutil 
capture noisily ssc install labutil
* Once installed, you can get acquainted using the help file
help labmask

* Assign country labels to numeric code (string has to be same within code)
labmask country_c, values(country)

* Usually in Stata, as with most programs, there are many ways of achieving the
* same output.
* Alternative 1: Generate same variable as before (we will use it for a 
* different exercise)
egen country_co=group(country)
* You could do it manually 
* Using defined
label define countries_l 1 "Austria"
* Attaching a value
label values country_co countries_l
* Modify an existing label
label define country_c 18 "Slovakia", modify

* Alternative 2: All in one go. Generate new numeric variable with labels
* using strings
encode country, gen(country_code)


************************************************
* Getting your data right: modify and reshape 
************************************************

* Change names of variables
replace subjectdescriptor="gdp_pc" if subjectdescriptor=="Gross domestic product per capita, constant prices"
replace subjectdescriptor="unemp" if subjectdescriptor=="Unemployment rate"
replace subjectdescriptor="ppgdpsb" if subjectdescriptor=="General government structural balance" & units=="Percent of potential GDP"

/*
Now variable by variable we will:
- save temporarily the dataset
- keep only observation for a given variable
- rename oddly named variables in the correct way
- reshape file to get our panel data
- save dataet containing only one variable
- restore original dataset
*/

* Save results in output directory
cd "$output"

* Example for a single variable: Unemployment
* Take a "snapshot" of the dataset as it stands.
preserve
* Keep only one variable per time
keep if subjectdescriptor=="unemp"
* Run command for renaming over all "wrong variables"
forvalues j=6(1)40{
* Extract year from label
local year: var label v`j'
* Rename variable
rename  v`j' unemp`year'
}
* Change orientation of dataset
reshape long unemp, i(country_code) j(year)
* Save new dataset
save dataunemp, replace
* To save data in Stata 13 format
*saveold dataunemp, replace

* Go back to original dataset by recovering the snapshot you took with "preserve".
restore

* Do the same for:
* 1. GDP per capita 
preserve
keep if subjectdescriptor=="gdp_pc"
forvalues j=6(1)40{
local year: var label v`j'
rename  v`j' gdp_pc`year'
}
reshape long gdp_pc, i(country_code) j(year)
save datagdp_pc, replace
restore
* 2. Government Balance
preserve
keep if subjectdescriptor=="ppgdpsb"
forvalues j=6(1)40{
local year: var label v`j'
rename  v`j' ppgdpsb`year'
}
reshape long ppgdpsb, i(country_code) j(year)
save datappgdpsb, replace
restore

****
* Q: Is there a more efficient way to do this which does not involve copying and
* pasting the same code three times? What would happen if instead of three variables
* we had 3,000 variables?
****

* Yes, we could do all variables in one go using two loops
local vars "gdp_pc unemp ppgdpsb"
foreach var of local vars{
preserve
keep if subjectdescriptor=="`var'"
forvalues j=6(1)40{
local year: var label v`j'
rename  v`j' `var'`year'
}
reshape long `var', i(country_code) j(year)
save new_data`var', replace
restore
}
*

**********************************************
* Merge and append: put your dataset together
**********************************************

* Datasets each with a single variable now exist but are separated:
* We now want to create a joint dataset contaning all the informations to be
* able to work with it.
* As we want variables to be put one next to the other we will use merge
* based on country codes.

* Pick one of the individual datasets
use dataunemp.dta, clear
local vars "gdp_pc ppgdpsb"
foreach var of local vars{
* merge observations 1:1 ("one to one") based on year and country code
merge 1:1 country_code year using data`var'
* Other options: m:1 ("many to one"), 1:m ("one to many"), and m:m ("many to many"),
* although the later not recommended.
* The command "joinby" would make all pairwaise combinations with both datasets.
 
* Explore merge to see how the two dataset were merged
tab _merge
* Codes for _merge
* _merge=1: observation only in master dataset (dataunemp.dta)
* _merge=2: observation only in using dataset (data`var'.dta)
* _merge=3: observation matched, same identifiers present in both using and master 

* Drop _merge (it will be defined everytime the command is run)
drop _merge
}

* Keep only useful variables
keep unemp gdp_pc ppgdpsb year country_code

* Order variables in a dataset
order country_code year unemp gdp_pc ppgdpsb


**************************************
* Preliminary analysis of the data
**************************************

* Summarize unemployment rate
sum unemp
sum unemp, detail
* Summarize unemployment rate by year
bysort year: sum unemp
* Frequency table of one variable 
tab country_code
* Cross-tab of two variables
tab country_code year
* Quick descriptive statistics of certain subgroups
tab country_code, sum(unemp)
* Another helpful command is tabstat.
* Tabstat allows you to save the results in special matrices.



**********************************************
* Generate change in variables over 3 years
**********************************************

* Sort observations
sort country_code year
* In ascending order (A,B,C or 1950, 1951, 1952)
gsort -country_code -year
* In descenting order (Z,Y,X or 1952, 1951, 1950)

* Generate log change of GDP per capita
gen lgdp_pc=log(gdp_pc)

* Generate three-years change in GDP and structural balance by country
bysort country_code: gen change_lgdp_pc = lgdp_pc-lgdp_pc[_n-3]
bysort country_code: gen change_sb_pc = ppgdpsb-ppgdpsb[_n-3]
bysort country_code: gen change_unemp = unemp-unemp[_n-3]


*********************************************************
* Graph Change in GDP over change in structural balance
*********************************************************

* Twoway: graph command that puts together multiple graphs
* Use help twoway to see all the possible graphs which can be combined
* Possible options:
* 1. Scatter:
*    - mlabel(country): use values in country to assign labels to points
*    - mlabp(11): position of the label
*    - lfit: linear fit of the data
* 2. General options:
*    - xline(x): adds vertical line at value x
*    - yline(x): adds horizontal line at value x
*    - x(y)title("..."): axes titles
*    - xlabel(a(b)c): report values on x axis starting from a, with step b until c
*    - legend(off): no legend, "help legend option" for more
*    - saving(... , replace): save graph and replace if already exists
*      IMPORTANT: Stata will report an error if the graph already exists, so
*      always specify that you want to replace it.

* You can use three consecutive slashes (///) to ignore the rest of the line and 
* add the next line at the end of the current line.
twoway (scatter change_lgdp_pc change_sb_pc if year==2012, mlabel(country_code) mlabp(11)) (lfit change_lgdp_pc change_sb_pc  if year==2012), xline(0, lcolor(black)) ///
 yline(0, lcolor(black)) graphregion(color(white)) ytitle("% change in pc GDP") xtitle("Change in structural balance") xlabel(-5(5)20) legend(off) ///
 saving(gdp, replace)
 
twoway (scatter change_unemp change_sb_pc if year==2012, mlabel(country_code) mlabp(4)) (lfit change_unemp change_sb_pc  if year==2012), xline(0, lcolor(black)) ///
 yline(0, lcolor(black)) graphregion(color(white)) ytitle("Change in unemployment rate") xtitle("Change in structural balance") xlabel(-5(5)20) legend(off) ///
 saving(unemp, replace)

* Plot two graphs together
graph combine gdp.gph unemp.gph, graphregion(color(white)) title("Fiscal tightnening and the economy in 2012") note("Source: WEO database;IMF")
graph export fteconomy.pdf, replace

* Imagine you want to plot average GDP per capita for each country, but an average of all years per country.
preserve
collapse gdp_pc, by(country_code)
graph hbar gdp_pc,  over(country_code) graphregion(color(white)) ytitle("US Dollars ($)") title("Average GDP per capita (1980-2014)") note("Source: WEO database;IMF") saving(all_gdp_pc, replace)
graph export all_gdp_pc.pdf, replace
restore

**********************************************************************************
* Further information on graphs: A VISUAL GUIDE TO STATA GRAPHS 
* (free download: http://www.sds.ynu.edu.cn/docs/2011-11/20111105173601685909.pdf)
**********************************************************************************

********************
* Explanatory notes
********************

note: Data used for MSc STATA Course, Class 1.
note gdp_pc: This is per capita.
notes

******************
* Save and close
*****************

* Last but not least: Never forget to backup your work!
save class1.dta, replace
* Save final version of the dataset

log close 
* Closes the log-file

translate "class1.log" "class1.pdf", replace
* Transforms log file to pdf format


* Some shortcuts and tips when working with STATA:
* 1. As you have seen throughout the do-file, most commands can be abbreviated. 
*    For example: summarize to sum, tabulate to tab, save to sa. The abbreviations 
*    are denoted by the underlined part of the command in STATA help file.
* 2. You can also abbreviate variable names when typing. Careful though with possible
*    ambiguities, for example poprural and popurban both could be abbreviated as pop
*    and STATA could pick the wrong one.
* 3. Over time, you will find yourself using the same commands or the same sequence
*    of commands again and again, e.g. the list of commands at the beginning of a 
*    log-file. Save these in a "common commands" text file from which you can cut
*    and past into your do-files.
* 4. In empirical projects, you accumulate a large number of do files, data sets,
*    log files and all sorts of outputs. It is usually a good idea when saving files
*    to add the date they were created and last modified. Also, use lots of comments
*    to remind you of what your do-file actually does!
* 5. When working with large datasets, use the "compress" command and try to drop 
*    everything from the dataset you do not need. If everything else fails, then 
*    apply for an Abacus account. 
