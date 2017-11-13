# Sepsis analysis
## Definition of sepsis
Adult patient with a suspected or comprobated source of infection

#### Systemic inflammatory response syndrome (SIRS)
Clinical manifestations (two or more)
  * Fever > 100.4 F or hypothermia < 98.6 F
  * Leukocytosis > 12,000 cells/mm, Leukopenia < 4,000 cells/mm or >10% bands
  * Tachycarida > 90
  * Hyperventilation > 20 breaths per minute or PaCO2 < 32 mmHg

### Codification of sepsis
| Code        | Name of the code | Requires             |
| ------------|------------------| ---------------------|
| 995.90      | Unspecified SIRS | Underlying condition |
| 995.91      | Sepsis (SIRS due to infectious process without organ dysfunction)           |  Underlying condition, then sepsis code  |
| 995.92      | Severe sepsis (SIRS due to infectious process with organ dysfunction)    |  Underlying condition, severe sepsis code, then organ failure  |


## Exploratory analysis
###### Count patients with sepsis `1,198` or severe sepsis `3,560`
```SQL
select short_title, long_title, j.icd9_code, N
from d_icd_diagnoses d
inner join 
  (SELECT icd9_code, count(distinct subject_id) as N
  FROM mimiciiiv13.DIAGNOSES_ICD
  where ICD9_code in ('99591', '99592')
  group by icd9_code) j on d.icd9_code = j.icd9_code
where d.ICD9_code in ('99591', '99592')
;
```
###### Count adminissions with sepsis `1,271` or severe sepsis `3,912`
```SQL
select long_title as icd9_name, j.icd9_code, N
from d_icd_diagnoses d
inner join 
(SELECT icd9_code, count(distinct hadm_id) as N
FROM mimiciiiv13.DIAGNOSES_ICD
where ICD9_code in ('99591', '99592')
group by icd9_code) j on d.icd9_code = j.icd9_code
where d.ICD9_code in ('99591', '99592')
;
```

###### Search patients with sepsis or severe sepsis


## References 
  * Bone RC, Balk RA, Cerra FB, Dellinger RP, Fein AM, Knaus WA, Schein RM, Sibbald WJ. Definitions for sepsis and organ failure and guidelines for the use of innovative therapies in sepsis. The ACCP/SCCM Consensus Conference Committee. American College of Chest Physicians/Society of Critical Care Medicine.Chest. 1992 Jun;101(6):1644-55.
http://journal.chestnet.org/article/S0012-3692(16)38415-X/fulltext
  * AHIMA
  http://library.ahima.org/doc?oid=70222#.WgnxxLA-dTY
