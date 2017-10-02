###############################################################################
# 
#               RRRRRRR
#               RRR   RRR
#               RRR   RRR
#               RRRRRRR
#               RRR   RRR
#               RRR    RRR
#               RRR    RRR
#               RRR    RRR
#               
#       West Michigan R Users Group
#
###############################################################################
# 
#   TITLE:   An introduction to mapping in R
#           
#   AUTHOR:  Paul Egeler
#
#   CONTACT: paulegeler .at. gmail .dot. com  
#   
#   DATE:    21 Mar 2017
#   
#   PURPOSE: 
# 
# A major part of a geographer's work is quantitative
# thinking and statistics. Likewise, statisticians and 
# analyists often work with and visualize spatial data. 
# Since geographic data is so ubiquitous in manifold fields,
# analysts of all stripes should have some basic geographic
# literacy.
# 
# R has a wide array of packages available which assist
# in manipulating, analyzing, and visualizing geographic data. 
# These tools, combined with R's analytics and automation 
# capabilities make it a great platform for simple or repetitive 
# mapping projects. These mapping tools can also add flair to 
# other analytic works or dashboards. 
# 
#   LICENSE: 
#
# Released under GPL v2. AS IS. NO WARRANTY!!!
#
###############################################################################
#
#   Resources:
#
# Spatial Cheatsheet
#  http://www.maths.lancs.ac.uk/~rowlings/Teaching/UseR2012/cheatsheet.html
# 
# ggmap: Spatial Visualization with ggplot2
#  https://journal.r-project.org/archive/2013-1/kahle-wickham.pdf
# 
# R package documentation
#  https://cran.r-project.org/web/packages/available_packages_by_name.html
#
#
###############################################################################

###############
# Loading Packages
###############

# First I want to ask you some questions:
library(tcltk)

# Message box to ask if it's OK to install packages on your computer
OK2Install = tkmessageBox(
  title = "Question! Pregunta!",
  message = paste("Install required packages? \r\n\n",
                  "Saying YES will  load all packages used in this demo.",
                  "Any package that is not previously installed will be",
                  "installed automatically. \r\n",
                  "Saying NO will attempt to load, but will not install."
                  ),
  icon = "question", 
  type = "yesno"
)

# Now that we've gotten that out of the way...
# This is the list of libraries we'll use:
libs = c(
  "magrittr",       # Ceci n'est pas une pipe
  "scales",         # Gives us color options
  "maps",           # Basic mapping package
  "maptools",       # Mapping tools
  "mapdata",        # Additional map data
  "raster",         # Rasters and plotting
  "rgdal",          # Projections/transformations
  "rgeos",          # API interface for GEOS
  "sp",             # Low level control of geospatial data
  "ggmap",          # Mapping with ggplot2
  "choroplethr",    # Easy choropleth maps
  "OpenStreetMap",  # Interface for Open Street Map API
  "RgoogleMaps"     # Interface for Google Maps API
  )

# Automated loading of libraries
if (tclvalue(OK2Install) == "yes") {
## Define function for loading multiple packages
## c/o stevenworthington github, ipak.R
## https://gist.github.com/stevenworthington/3178163
  ipak <- function(pkg){
    new.pkg <- pkg[!(pkg %in% installed.packages()[ ,"Package"])]
    if (length(new.pkg)) 
      install.packages(new.pkg, dependencies = TRUE)
    sapply(pkg, require, character.only = TRUE)
  }
  
  ipak(libs)
} else {
  sapply(libs,require, character.only = TRUE)
}

rm(list=c("OK2Install","libs"))


###############
# maps pkg
###############

# Some basic maps are available
map("state",
    regions = "michigan:south", 
    fill = TRUE, 
    col = "Green", 
    bg = "lightblue"
  )
map.cities(us.cities, country = "MI")
par("usr") # Lat/Long


###############
# RgoogleMaps
###############

# Geocode our current location (get lat and long coordiates)
current.location.coords = getGeoCode("401 Fulton St W, Grand Rapids, MI 49504")
current.location.coords

# Define a marker
current.location.marker = 
  paste0(
    "&markers=color:blue|label:Here|",
    current.location.coords[1],
    ",",
    current.location.coords[2]
)

# Call to Google Maps API to get map
our.google.map = GetMap(center = current.location.coords, 
                 zoom = 12,
                 markers = current.location.marker
                 )

# Plot map object
PlotOnStaticMap(our.google.map)
par("usr") # ???

###############
# OpenStreetMap
###############

# Get the boundaries our our previous map
bbox = unlist(our.google.map$BBOX)
names(bbox) = c("lower","left","upper","right")
bbox

# Replicate our previous map
our.osm.map = openmap(
  c(bbox["upper"],bbox["left"]),
  c(bbox["lower"],bbox["right"]),
  type = "osm"
)

plot(our.osm.map)
par("usr") # Mercator projection

# There are a lot of styles. Type ?openmap in console to explore
our.bing.map = openmap(
  c(bbox["upper"],bbox["left"]),
  c(bbox["lower"],bbox["right"]),
  type = "bing"
)

plot(our.bing.map) # Areal photography

# Add our current location
#  First we must project our coordinates to mercator
current.loc.mercator = 
  SpatialPoints(
    as.matrix(t(rev(current.location.coords))),
    CRS("+proj=longlat +datum=WGS84")
    ) %>%
  spTransform(osm())

# Then we can plot
plot(current.loc.mercator, 
     col="white",
     bg="blue",
     pch = 21, 
     cex = 2, 
     add = TRUE
     )

# Add some data to our location
raster::text(current.loc.mercator,
     lab = "Grand Valley\r\nState University",
     halo = TRUE,
     pos = 3,
     offset = 0.5
)

###############
# ggmap
###############
our.ggmap = qmap("Grand Valley State University, Pew Campus", zoom = 12)
our.ggmap
par("usr") # Lat/Long

our.ggmap2 = our.ggmap +
  geom_point(aes(x = current.location.coords[2], 
                 y = current.location.coords[1]),
             show.legend = FALSE,
             color = "blue",
             size = 5,
             alpha = 0.5
  ) +
  geom_label(aes(x = current.location.coords[2], 
                 y = current.location.coords[1]),
             label = "Grand Valley State University",
             position = position_nudge(y = 0.008)
  )


our.ggmap2

# ggmap also gives us a new geocode function
geocode(c("Grand Valley State University, Pew Campus",
          "Grand Valley State University, Allendale Campus"
), output = "more")

###############
# chloroplethr
###############

# This is a demo that came with the package
data(continental_us_states)
data(df_pop_state)
state_choropleth(df_pop_state, 
                 title         = "US 2012 State Population Estimates",
                 legend        = "Population",
                 zoom          = continental_us_states, 
                 reference_map = TRUE)

###############
# Roll your own
###############

# Set working directory to location where shapefiles are stored
setwd("C:/") # Wherever you keep your TIGER files

# Find out the fips code for MI
state.fips[state.fips$abb == "MI",]

## Read in shapefiles
# These shapefiles came from US Census TIGER
# https://www.census.gov/geo/maps-data/data/tiger-cart-boundary.html
# https://www.census.gov/cgi-bin/geo/shapefiles/index.php?year=2016&layergroup=Roads

# Counties
shp.cnty = readShapePoly("CB/Counties/cb_2015_us_county_20m.shp") %>%
  subset(STATEFP == 26)

# States
shp.state = readShapePoly("CB/Counties/cb_2015_us_county_20m.shp")

# Urban areas
shp.urb = readShapePoly("CB/Urban Areas/cb_2015_us_ua10_500k.shp")

# Primary and secondary roads
shp.roads = readShapeLines("Roads/PriSec/tl_2016_26_prisecroads.shp")

## Grab some unemployment data from BLS to add to our county shapefile
unemployment = read.fwf(
  "http://www.bls.gov/lau/laucnty15.txt",
  skip = 6,
  n = 3219,
  widths = diff(c(0,16,21,29,80,86,100,115,125,132)+1),
  col.names = c(
    "LAUS.code",
    "STATEFP",
    "COUNTYFP",
    "County.Name",
    "Year",
    "Labor.Force",
    "Employed",
    "Unemp.Lvl",
    "Unemp.Rate"
  ),
  colClasses = c(
    "character",
    "character",
    "character",
    "character",
    "integer",
    "character",
    "character",
    "character",
    "numeric"
  )
)

unemployment[which(sapply(unemployment, class) == "character")] %<>%
  sapply(trimws)

unemployment %<>% subset(STATEFP == "26")

unemployment[,6] %<>% gsub(",","",.) %>% as.integer
unemployment[,7] %<>% gsub(",","",.) %>% as.integer
unemployment[,8] %<>% gsub(",","",.) %>% as.integer

shp.cnty %<>% merge(unemployment, by = c("STATEFP","COUNTYFP"))

shp.cnty@data %>% head

## Begin plotting

png("unemployment.png", w = 1600, h = 2000)

# Get extent of subset
min.max = summary(shp.cnty)$bbox

# Set up a plotting area
plot(
  main = "",
  x = min.max["x",],
  y = min.max["y",],
  type = "n", 
  xlab="", 
  ylab = "",
  axes = FALSE
)

# Find maximum limits of drawing area
drawing.area = par()$usr

# Find extent to be used for clipping
#cp = as(extent(drawing.area), "SpatialPolygons")

# Frame the blue background
rect(
  drawing.area[1],
  drawing.area[3],
  drawing.area[2],
  drawing.area[4],
  col = "light blue",
  border = "black"
)

# Plot the state lines
plot(
  shp.state,
  add = TRUE,
  col = "darkolivegreen1",
  border = "darkolivegreen",
  lwd = 2
)

# Plot the urban areas
plot(
  shp.urb,
  add = TRUE,
  col = alpha("light gray",0.4),
  border = "gray"
)

# Plot the roads
plot(
  shp.roads, 
  add = TRUE, 
  col = col_factor("Reds", domain = NULL)(shp.roads@data$RTTYP),
  lwd = 1
)

# Label the counties
raster::text(
  shp.cnty,
  sprintf("%3.1f%%",shp.cnty@data$Unemp.Rate),
  cex = 2.5,
  col = col_numeric("Blues", domain = range(shp.cnty@data$Unemp.Rate))(shp.cnty@data$Unemp.Rate),
  halo = TRUE,
  hc = "darkblue",
  hw = 0.08
)

text(x = -85.5, y = 48, "Michigan Unemployment 2015", cex = 6)

# Final border
rect(
  drawing.area[1],
  drawing.area[3],
  drawing.area[2],
  drawing.area[4],
  border = alpha("black",0.5),
  lwd = 3
)

dev.off()