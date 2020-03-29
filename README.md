# The Graduate School's Admissions Reports

The *Admissions Reports* are provided by [**The Graduate School**](https://graduate.gsu.edu/) at Georgia State University in order to inform college and school leadership on the historical data, recent trends, forecasted applications, and recommended term and program enrollees for upcoming fiscal years. 

## Documentation

This repository contains all documentation necessary to reproduce, in its entirety, the querying, preprocessing, modeling, and report-building tasks necessary to recreate each report, which are included in the following scripts:

* [**Querying & Preprocessing**](https://github.com/jamisoncrawford/admissions/blob/master/2020-02-25_admissions_sql-pull_preprocessing.r)
* [**Static Report Building**](https://github.com/jamisoncrawford/admissions/blob/master/2020-02-27_admissions-report-card_template.rmd)
* [**Interactive Report Building**](https://github.com/jamisoncrawford/admissions/blob/master/2020-02-27_admissions-report-card_template.rmd)

## Data Sources

All adata are queried from the GSU Data Warehouse and require special permissions for access. Qhile the majority of preprocessing and manipulation and performed in `R`, queries using Oracle SQL Developer pull data using the following:

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

## Tooling & Extensions

Preprocessing, modeling, and report-building use the following `R` extensions (i.e. packages):

```
library(zoo)
library(readr)
library(dplyr)
library(tidyr)
library(scales)
library(GGally)
library(pander)
library(panthr)
library(ggplot2)
library(stringr)
library(forecast)
library(lubridate)
library(kableExtra)
```

## Package panthr

Notably, I've used my own package, package `panthr`, which must be installed using package `devtools`. Package `panthr` is a domain-specific extension specific to GSU Warehouse data and designed to streamline common preprocessing tasks, such as decoding majors, degrees, and ethnorace per OIE (Office of Institutional Effectiveness) reporting standards, as well as converting terms to academic, calendar, and fiscal years, discretizing GPAs, etc. You can read more about `panthr` in [**this GitHub repository**](https://github.com/jamisoncrawford/panthr). 

Run the following in `R` to install and load package `panthr` into your environment:

```
if(!require(devtools)){install.packages("devtools")}
library(devtools)

install_github(repo = "jamisoncrawford/panthr")
library(panthr)
```

# Report Author

[**Jamison Crawford**](https://www.linkedin.com/in/jamisoncrawford/) is an Institutional Research Associate for The Graduate School at Georgia State University and a Faculty Associate at Arizona State University, where he teaches *Foundations of Data Science* for the MS-PEDA (Program Evaluation & Data Analytics) at the Watts College ([**Email**](mailto:jcrawford52@gsu.edu)).

# Contributors

**Lita Malveaux** is the Director of Graduate Admissions at Georgia State University and contributed significantly towards deciphering admissions data, as well as conceptualizing this project and many of its most important features.
