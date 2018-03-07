# Spatial data

library(dplyr)
library(ggplot2)
# If you can't find the function ggplot2::geom_sf(), 
# you may need to download the development version of ggplot2: devtools::install_github("tidyverse/ggplot2")
library(scales)

library(sf)
  # All functions begin with "st_"
  # Spatial objects are data frames with special geometry columns
  # Neatly integrated with the tidyverse

# Read in precint-level 2016 presidential election results in Hawaii
pres2016 <- readRDS("data/HI_precinct_gen_pres2016.rds")

# Read in as a data frame
# st_read uses other files in the hi_precinct directory, 
# but you need to point it only to the .shp (shapefile)
hi <- st_read("data/hi_precinct/Precincts_2016_01_13b_PUBLIC.shp")
class(hi)

# Handle them like you would any other data frame ----

# Merge with election results data
hi$DP <- as.character(hi$DP)
hi_pres <- left_join(hi, pres2016, by = c(DP = "precinct"))

# Creating new variables
hi_pres2 <- mutate(hi_pres,
                   county_code      = as.numeric(gsub("-[0-9]{2}$", "", DP)),
                   total_pres_votes = castle_votes_total + johnson_votes_total + stein_votes_total + 
                                        clinton_votes_total + trump_votes_total,
                   trump_vshare     = trump_votes_total / total_pres_votes,
                   clinton_vshare   = clinton_votes_total / total_pres_votes
                   )
# ggplot(hi_pres2) + geom_sf(aes(fill = trump_vshare)) + 
#   scale_color_gradient2(low = muted("blue"), high = muted("red")) + theme_bw()

# Subset to Oahu island
oahu_pres <- filter(hi_pres2,
                    between(county_code, 17, 51))


ggplot(oahu_pres) + geom_sf(aes(fill = clinton_vshare)) + 
  scale_fill_gradient2(midpoint = 0.5, mid = "maroon3", high = "mediumblue", low = "red") + 
  theme_bw()

# Highlight where third-party votes decided the precinct winner
oahu_pres2 <- mutate(oahu_pres,
                     pwin3rd = abs(clinton_votes_total - trump_votes_total) <= 
                       stein_votes_total + johnson_votes_total + castle_votes_total
                     )
ggplot(oahu_pres2) + geom_sf(aes(fill = pwin3rd)) + theme_bw()