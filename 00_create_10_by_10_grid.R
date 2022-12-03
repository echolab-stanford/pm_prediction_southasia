####import library####
library(geojsonio)
library(sp)
library(sf)
library(rnaturalearth)
library(ggplot2)
library(SpatialPosition)
library(rgeos)
library(rgdal)
library(raster)
library(dplyr)
library(leaflet)
library(mapview)
setwd("C:/Users/ayako/Documents/StanfordPhD/Myprojects/01_PM_prediction")

####convert geojson to spatialpolygon####
#geojson file was created using here https://geojson.io/#map=2/0/20
#it covers Pakistan, India, Nepal, and Bangladesh
#this geojson file was used when Sentinel-5P and ERA5 were collected
zone <- geojson_sp("s5p-tools/map.geojson")
zone <- st_as_sf(zone)

####quick visualization####
#convert to sf for visualization
BD_border <- ne_countries(country = "Bangladesh") %>% st_as_sf(BD_border)
PK_border <- ne_countries(country = "Pakistan") %>% st_as_sf(PK_border)
NP_border <- ne_countries(country = "Nepal") %>% st_as_sf(NP_border)
IN_border <- ne_countries(country = "India") %>% st_as_sf(IN_border)

#just to check if the polygon covers the right geographic areas
(
  BD <- ggplot() +
    geom_sf(data = BD_border, fill = "blue") +
    geom_sf(data = PK_border, fill = "yellow") +
    geom_sf(data = NP_border, fill = "pink") +
    geom_sf(data = IN_border, fill = "antiquewhite1") +
    geom_sf(data = zone) +
    theme_bw() +
    theme(panel.background = element_rect(fill = "aliceblue"),
          panel.grid = element_line(color = "white", size = 0.8)
    )
)

####create 10km-by-10km grid based on the spatialpolygon####
res = 10000
proj = "+proj=utm +zone=42 +datum=WGS84 +units=m +no_defs +type=crs"

zone <- st_transform(zone, crs = proj)
grid <- raster(extent(zone), resolution = c(10000,10000), crs = proj)
grid_10km <- rasterToPolygons(grid)
grid_10km_buffer <- gBuffer(grid_10km, byid=T, width=res/2, capStyle="SQUARE")
grid_10km_fin <- st_as_sf(grid_10km_buffer) %>% st_transform(st_crs(4326))
grid_10km_fin <- grid_10km_fin %>% mutate(grid_id = row_number()) %>% 
  select(grid_id, geometry)

st_write(obj=grid_10km_fin, 
                  dsn="data/intermediate/grid_10km",
                  driver="ESRI Shapefile")
