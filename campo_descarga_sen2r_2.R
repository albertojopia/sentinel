
library(sf)
library(tidyverse)
library(raster)
library(leaflet)
library(stars)
library(sen2r)
library(lubridate)

in.vector<-'../vectores'
#out.safe<-'D:/Alberto/HEMERA/Proyectos/SENTINEL/safe'
#out_1<-'D:/Alberto/HEMERA/Proyectos/SENTINEL/out_1'

# definir area
zona<-c("campo1")

ee_roi <- st_read(paste0(in.vector,'/los_tilos_cuarteles.shp')) %>%
  st_geometry() %>%
  st_transform(crs = "+proj=utm +zone=19 +south +datum=WGS84 +units=m +no_defs")

ee_roi1<-st_as_sfc(st_bbox(ee_roi)+c(-100,-100,100,100)) %>% # se aumentar 100 metros a cada lado del area de estudio
  st_transform(crs="+proj=longlat +datum=WGS84 +no_defs")

st_write(ee_roi1, paste0(in.vector,"/", "ee_roi1.shp"))

# extraer fechas de imagenes ya descargadas
dir <- list.files(out.safe)
dates.donwload <- regmatches(dir,regexpr("[0-9]{8}",dir))
dates.donwload0 <- sort(ymd(dates.donwload ))

# defining time interval for which the images will be downloaded 
# (ajsutar de acuerdo a la cantiadad de imagenes disponibles para ordenar, no mayor a 30)
range.date<-c(as.Date("2016-01-01"), as.Date("2016-12-31"))

write_scihub_login("usuario", "clave") #definir usuario y clave de cuenta de copernicus

#imagenes disponibles
list <- s2_list(
  spatial_extent=ee_roi,
  time_interval=range.date,
  level = "L1C")
length(list)

#imagenes que faltan por descargar
dates.online<-regmatches(names(list),regexpr("[0-9]{8}",names(list)))
dates.online<-data.frame(dates=dates.online,id=seq_along(dates.online) )
dates.pending<-dates.online %>% filter(!dates %in% dates.donwload)

ordenes<-list() #lista para guardar orden de procesamiento cuando la imagen no esta disponible
date<-as.Date(ymd(dates.pending$dates))

for (i in 1:length(date)){
  start <- date[i]
  finish <- date[i]+1

  out_paths_1 <- sen2r(
    gui = FALSE,
    step_atmcorr = "auto",
    extent = paste0(in.vector,"/", "ee_roi1.shp"),
    extent_name = zona,
    timewindow = c(as.Date(start), as.Date(finish)),
    list_prods = c("BOA","SCL"),
    list_indices = c('NDVI','EVI','Rededge1', "Rededge2","RRI1","NDVIre"),
    list_rgb = c("RGB432B"),
    #mask_type = "cloud_and_shadow",
    #max_mask = 10, 
    path_l1c = out.safe,
    path_l2a = out.safe,
    path_out = out_1
  )
  ordenes[[i]]<-attr(out_paths_1,"ltapath" )
  Sys.sleep(60)   
}
