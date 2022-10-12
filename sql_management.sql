-- !preview conn=condb

SELECT * FROM tbl_Biodiv_inhab_LTE_TB
WHERE LAT != "Unknown"
ORDER BY Reference AND `TBE-TB species`
