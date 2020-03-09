# The Graduate School's Admissions Reports

The *Admissions Reports* are provided by [**The Graduate School**](https://graduate.gsu.edu/) at Goergia State University in order to inform college and school leadership on the historical data, recent trends, forecasted applications, and recommended term and program enrollees for upcoming fiscal years. 

## Documentation

This repository contains all documentation necessary to reproduce, in its entirety, the querying, preprocessing, modeling, and report-building tasks necessary to recreate each report, which are included in the following scripts:

* [**Querying & Preprocessing**](https://github.com/jamisoncrawford/admissions/blob/master/2020-02-25_admissions_sql-pull_preprocessing.r)
* [**Static Report Building**](https://github.com/jamisoncrawford/admissions/blob/master/2020-02-27_admissions-report-card_template.rmd)
* [**Interactive Report Building**0(https://github.com/jamisoncrawford/admissions/blob/master/2020-02-27_admissions-report-card_template.rmd)

## Data Sources

All adata are queried from the GSU Data Warehouse and require special permissions for access. Qhile the majority of preprocessing and manipulation and performed in `R`, queries using Oracle SQL Developer pull data using the following scripts.

**All Applications & Main Student Table:** Database `EDWPRD`:

```
SELECT *
FROM edwprd.sdapplications_gr;
   
SELECT *
FROM edwprd.sdapplications_gr a
JOIN edwprd.sdstumain m
     ON a.whkey = m.whkey 
     AND a.term = m.term 
     AND m.census_type = 'C';
```

**Degree Level Validation Codes:** Database `BREPTS`:

```
SELECT *
FROM stvdegc;
```
