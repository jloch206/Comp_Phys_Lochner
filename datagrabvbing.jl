import XLSX
using Plots
dtable = XLSX.readtable("30_temp.xlsx","30_temp",)
m = hcat(dtable.data...)
temp=m[1:end,2]
humid=m[1:end,4]
plot(temp)
