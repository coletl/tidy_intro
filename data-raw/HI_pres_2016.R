rm(list = ls())
gc()

# Cole Tanigawa-Lau
# Sun Dec 10 21:46:01 2017
# Description: Download Hawaii precinct shapefile and precinct-level 2016 election results.

library(data.table)

tmp <- tempfile(fileext = "zip")
download.file("http://files.hawaii.gov/elections/files/GIS/2016/Precincts_2016_01_13b_public.zip",
              tmp)
tmp2 <- unzip(tmp, exdir = "data-raw/")

dir.create("data/hi_precinct")
file.copy(tmp2, 
          gsub("data-raw//Precincts_2016_01_13b_public/", "data/hi_precinct/", 
               tmp2, fixed = TRUE)
          )
unlink(tmp)


results <- fread("http://files.hawaii.gov/elections/files/results/2016/general/media.txt")
fwrite(results, "data-raw/HI_2016GEN_results_raw.csv")

 # Change column names before saving presidential election results in data directory
setnames(results,
         c("precinct", "split_name", "precinct_split_id", "no_reg_voters", 
           "no_ballots", "reporting", "contest_id", "contest_title", "contest_party",
           "choice_id", "cand_name", "choice_party", "cand_type", "votes_absent", 
           "votes_early", "votes_election"))

cn <- c("no_reg_voters", "no_ballots",
        "votes_absent", "votes_early", "votes_election")
pres <- results[contest_id == 1
                ][ ,
                   (cn) := lapply(.SD, as.numeric),
                   .SDcols = cn
                   ][ , 
                      c("split_name", "choice_party", "contest_party", "cand_type") := NULL
                      ]
cands <- data.table(cand_name = unique(pres$cand_name),
                    tag       = c("stein", "johnson", "trump", "clinton", "castle"))
pres[cands,
     cand_name := i.tag,
     on = "cand_name"
     ][ ,
        votes_total := votes_absent + votes_early + votes_election
        ]

pres_long <- melt(pres, 
                  measure.vars = c("votes_absent", "votes_early", "votes_election", "votes_total"))

pres_wide <- dcast(pres_long,
                   ... ~ cand_name + choice_id + variable)
setnames(pres_wide,
         gsub("[0-9]_", "", names(pres_wide)))

pres_tbl <- tibble::as_tibble(pres_wide)

saveRDS(pres_tbl,
        "data/HI_precinct_gen_pres2016.rds")
