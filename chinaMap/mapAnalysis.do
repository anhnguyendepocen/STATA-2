use "H:\stata\charls\data\chinaMap\china_label", clear
gen x = uniform()
format x %9.3g
spmap x using "H:\stata\charls\data\chinaMap\china_map.dta", /// 
  id(id) clnumber(8) fcolor(Heat) ndfcolor(none)
