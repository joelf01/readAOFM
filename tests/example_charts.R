library(tidyr)
library(dplyr)
library(here)
library(httr)
library(readxl)
library(zoo)
library(data.table)
library(janitor)
library(stringr)
library(tibble)
library(ggplot2)

library(readAOFM)


## Treasury Bond Coverage Ratio's
p <- read_aofm("tb", "issuance") %>%
  filter(name == "coverage_ratio") %>%
  ggplot(aes(x = date_held
             , y = value
             , colour = as.numeric(difftime(maturity, date_held))/365
  )) +
  geom_point() +
  theme_minimal() +
  xlab("Issuance date") +
  ylab("Coverage ratio") +
  guides(colour=guide_legend(title="Tenor (yrs)")) +
  ggtitle("AOFM Treasury Bond Issuance - Coverage Ratio")
p


## Treasury Bond Annual Issuance Volume
q <- read_aofm("tb", "issuance") %>%
  filter(name == "amount_allotted") %>%
  mutate(year = year(date_held)) %>%
  group_by(year) %>%
  summarise(value = sum(value)) %>%
  ggplot(aes(x = year
             , y = value
  )) +
  geom_col() +
  theme_minimal() +
  xlab("Issuance date") +
  ylab("Issunace Volume") +
  ggtitle("AOFM Treasury Bond Issuance - Annual Volume")
q

