-- This query extracts data for the tutorial in the clinical data analytics book chapter. Only the first icu stays from adult patients are extracted.

create view static_data as
(select icud.subject_id,
        icud.hadm_id,
        icud.icustay_id,                 
        case
         when icud.icustay_admit_age>150 then 91.4 -- Need to figure out age calculation, dateadd()?
         else round(icud.icustay_admit_age,1)
        end as icustay_admit_age,
        icud.gender, 
        dd.admission_type_descr as admission_type,
        case
         when icud.icustay_first_service='FICU' then 'MICU'
         else icud.icustay_first_service
        end as icustay_first_service,
        case
         when icud.hospital_expire_flg='Y' or dp.dod-icud.hospital_disch_dt < 30 then 'Y'     
         else 'N'
        end as thirty_day_mort
 from mimiciiiv13.icustays icud -- changed database name, and database name
 left join mimiciiiv13.ADMISSIONS dd on icud.hadm_id=dd.hadm_id
 left join mimiciiiv13.patients dp on icud.subject_id=dp.subject_id -- changed d_patients to patients
 left join mimiciiiv13.TRANSFERS tr on icud.subject_id=tr.SUBJECT_ID -- added table to get "eventtype"
 where icud.icustay_age_group = 'adult' -- ****need to calculate age and say > 18******    
	and tr.eventtype = "admit"
	and dd.admissions_type = "elective" or "urgent" or "emergency"
   
   -- and icud.subject_icustay_seq = 1 -- *** possible alternative way to figure out 1st icu say
   and icud.icustay_id is not null
)
select * from static_data;

-----------------------------
-- BEGIN EXTRACTION OF LABS
-----------------------------
 create view labevents as
(select icustay_id,        
        itemid,
        charttime,
        valuenum
 from mimiciiiv13.labevents l
 where itemid in (50912, 50971, 50983, 509802, 50882, 51221, 51300, 50931, 50960, 50893, 50970, 50813)
   and icustay_id in (select icustay_id from static_data) 
   and valuenum is not null
)
--select * from labevents;

, labs_raw as
(select distinct icustay_id,        
        itemid,
        first_value(valuenum) over (partition by icustay_id, itemid order by charttime) as first_value
 from small_labevents 
)
--select * from labs_raw;

, labs as
(select *
 from (select * from labs_raw)
      pivot
      (sum(round(first_value,1)) as admit       
       for itemid in 
       ('50912' as cr, -- changed values to mimiciii
        '50971' as k,
        '50983' as na,
        '50902' as cl,
        '50882' as bicarb,
        '51221' as hct,
        '51300' as wbc,
        '50931' as glucose,
        '50960' as mg,
        '50893' as ca,
        '50970' as p,
        '50813' as lactate
       )
      )
)
--select * from labs;
------------------------------
--- END OF EXTRACTION OF LABS
------------------------------

------------------------------------
--- BEGIN EXTRACTION OF VITALS
------------------------------------
, small_chartevents as
(select icustay_id,
        case
         when itemid in (211, 220045) then 'hr'
         when itemid in (52,456, 220052) then 'map'  -- invasive and noninvasive measurements are combined
         when itemid in (51,455, 220050) then 'sbp'  -- invasive and noninvasive measurements are combined
         when itemid in (678, 679, 223761) then 'temp'  -- in Fahrenheit
         when itemid in (646) then 'spo2'    -- no parallel metavision value maybe 220235 (mario help)
         when itemid in (618, 220210) then 'rr'
        end as type,                
        charttime,
        value1num
 from mimiciiiv13.chartevents l
 where itemid in (211,51,52,455,456,678,679,646,618,220045,220052,220050,223761,220210 )-- note: dont have spo2 value yet
   and icustay_id in (select icustay_id from static_data) 
   and value1num is not null
)
--select * from small_chartevents;

, vitals_raw as
(select distinct icustay_id,        
        type,
        first_value(value1num) over (partition by icustay_id, type order by charttime) as first_value
 from small_chartevents 
)
--select * from vitals_raw;

, vitals as
(select *
 from (select * from vitals_raw)
      pivot
      (sum(round(first_value,1)) as admit
       for type in 
       ('hr' as hr,
        'map' as map,
        'sbp' as sbp,
        'temp' as temp,
        'spo2' as spo2,
        'rr' as rr
       )
      )
)
--select * from vitals;
------------------------------------
--- END OF EXTRACTION OF VITALS
------------------------------------

-- Assemble final data
, final_data as
(select s.*,
        v.hr_admit,
        v.map_admit,
        v.sbp_admit,
        v.temp_admit,
        v.spo2_admit,       
        v.rr_admit,       
        l.cr_admit, 
        l.k_admit,
        l.na_admit,
        l.cl_admit,
        l.bicarb_admit,
        l.hct_admit,
        l.wbc_admit,
        l.glucose_admit,
        l.mg_admit,
        l.ca_admit,
        l.p_admit,
        l.lactate_admit
 from static_data s
 left join vitals v on s.icustay_id=v.icustay_id 
 left join labs l on s.icustay_id=l.icustay_id 
)
select * from final_data order by 1,2,3;