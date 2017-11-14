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

###### Create table with patients with sepsis or severe sepsis, admission information and age at the admission
How to calculate age, facts:
  * MIMIC III tutorial propose to calculate age using the first admission time. Many patients have many ICU admissions ,in some cases separated by years.
  * `INTIME` from table `icustays` provides the date and time the patient was transferred into the ICU. 
  * `admittime` from table `admissions` provides the date and time the patient was admitted to the hospital.
  * In some cases the `admittime` preceeds `intime` in othe cases not.
  * Patient >89 get calculate age of hundreds (anonymization tech).

**Conclusion:** calculate the age each time a patient is transferred to ICU.

```SQL
select j.hadm_id, a.admittime, icd9_code, j.subject_id, t.dob,    timestampdiff(YEAR, t.dob, a.admittime) as age_admission, 
ROUND((cast(a.admittime as date) - cast(t.dob as date))/365.242, 2) as age
from admissions a
right join
(SELECT distinct icd9_code,  hadm_id, subject_id
FROM mimiciiiv13.DIAGNOSES_ICD
where ICD9_code in ('99591', '99592')
) j on a.hadm_id = j.hadm_id
left join 
(select subject_id, dob
from patients 
where subject_id in
	(SELECT distinct subject_id
		FROM mimiciiiv13.DIAGNOSES_ICD
		where ICD9_code in ('99591', '99592')
	) 
) t on a.subject_id = t.subject_id

where timestampdiff(YEAR, t.dob, a.admittime) >= 18

;
```

vs mimic proposed calculation
```SQL
SELECT ie.subject_id, ie.hadm_id, ie.icustay_id,
    ie.intime, ie.outtime,
    ROUND((cast(ie.intime as date) - cast(pat.dob as date))/365.242, 2) AS age,
    CASE
        WHEN ROUND((cast(ie.intime as date) - cast(pat.dob as date))/365.242, 2) <= 1
            THEN 'neonate'
        WHEN ROUND((cast(ie.intime as date) - cast(pat.dob as date))/365.242, 2) <= 14
            THEN 'middle'
        -- all ages > 89 in the database were replaced with 300
        WHEN ROUND((cast(ie.intime as date) - cast(pat.dob as date))/365.242, 2) > 100
            then '>89'
        ELSE 'adult'
        END AS ICUSTAY_AGE_GROUP
FROM icustays ie
INNER JOIN patients pat
ON ie.subject_id = pat.subject_id;
```




## References 
  * Bone RC, Balk RA, Cerra FB, Dellinger RP, Fein AM, Knaus WA, Schein RM, Sibbald WJ. Definitions for sepsis and organ failure and guidelines for the use of innovative therapies in sepsis. The ACCP/SCCM Consensus Conference Committee. American College of Chest Physicians/Society of Critical Care Medicine.Chest. 1992 Jun;101(6):1644-55.
http://journal.chestnet.org/article/S0012-3692(16)38415-X/fulltext
  * AHIMA
  http://library.ahima.org/doc?oid=70222#.WgnxxLA-dTY
