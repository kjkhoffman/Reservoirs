### Function to create a QAQC plot and
## clean up files produced by LiCor Eddy Pro

## Originally from Alex Hounshell's EddyPro_CleanUp script from 8 October 2021, A. Hounshell

# Edits: 
## A. Breef-Pilz updated on 26 Oct. 2022 to included a for loop to
## read in the EddyPro output, create QAQC plots and bind all the files together into on large data frame.
## A. Breef-Pilz modified the script to create a function that reads in the current EddyFlux files
## Makes QAQC plots if they haven't been created,
## then binds current files from the year,
## does a quick QAQC check and then creates an L1 file with all of the current fluxes
## A.Breef-Pilz edited to just make it the function 26 Jan 2024
## A.Breef-Pilz edits to filter by EDi package and make time conversion section work. 05 Feb 2024
## A.Breef-Pilz edits to add in streaming summary files 
## B.Kandel edits to add in qc for H and LE for extreme values adapted from eddy-flux_post_processing script
## A.Breef-Pilz made a function to read in processed files from EddyPro because the headings had changed
## A.Breef-Pilz added an if statement when no new observations for the year. 18 Feb 2025
## A.Breef-Pilz added an if statement to just download files or process files. 02 Apr 2025

### This function:
# 1. Reads in the Summary files from the EddyFlux system that is streaming at FCR or from proceesed EddyPro files
# 2. Compiles into one data frame
# 3. Renames the columns
# 4. Very light qaqc for extreme outliers

# Additional notes: This script is included with this EDI package to show which QAQC has already been 
# applied to generate these data <and includes additional R scripts available with this package>. 
# This script is only for internal use by the data creator team and is provided as a reference; 
# it will not run as-is. 

#####################################################


# Download/load libraries
#pacman::p_load(lubridate,tidyverse,hms,gridExtra,openair, googledrive)


eddypro_cleaning_function<-function(directory, # Name of the directory where the data folder and the QAQC plot folder lives
                                    text_file=F, # Are you using the text file which is generated from the streaming summary files? If it is an EddyPro file then it is FALSE
                                    gdrive, # Are the files on Google Drive. True or False
                                    gshared_drive, # Name of the shared drive where the files are held or use as_id()and the ID of the folder
                                    process_files = T, 
                                    #current_year, # Current Year. Must be numeric
                                    output_file,
                                    start_date, # date the EDI file ends
                                    end_date)  # sys.Date plus 1
{
  
  # Name the directory where the full output files are found. Ours are on GitHub 
  mydir <-directory

  print(mydir)
  
  # list of EddyPro full output files on Github
  rfiles <- list.files(path=mydir,pattern="", full.names=TRUE)
  
  print(rfiles)
  # Are the files on Google Drive? If so then download missing EddyPro Full Output files
  
  if(gdrive==T){
    # authenticate Google Drive to download the files from the EC folder.
    googledrive::drive_auth(path = Sys.getenv('GDRIVE_PAT'))
    
    # Get the file info of the EddyPro Full output files
    gdrive_files<-googledrive::drive_find(pattern = "_full_output_", 
                                          type="csv",
                                          n_max = Inf, 
                                          shared_drive = gshared_drive)
    
    
    # download output files and put them on GitHub
    
    for(i in 1:nrow(gdrive_files)){
      
      #extract the beginning of the file name to see if a qaqc plot has been made
      dfile<-sub("\\_full.*", "",sub(pattern = "(.*)\\..*$", replacement = "\\1", basename(gdrive_files$name[i])))
      
      
      if(any(grepl(dfile,rfiles))==F){
        # download and put on GitHub
        
        name<-gdrive_files$name[i]
        
        googledrive::drive_download(gdrive_files$id[i], path = paste0(mydir,name))
        
      }else{
        
      }
    }
    
  }
  
  if (process_files == T) {
  
  ## Now bind files together
  
  if (text_file==T){
    # This is for processing the streaming Summary files which are .txt and have to be read in differently then 
    # the .csv that are processed in EddyPro
    
    myfiles <- list.files(path=mydir, pattern= "EP-Summary", recursive = TRUE, full.names=TRUE)
    
    print(myfiles)
    # Let's use map to combine the files together
    b <- myfiles%>%
      purrr::map_df(~ read.delim(.x, header = TRUE, sep = "\t"))
    
  } else{

    # They are .csv and were processed in EddyPro
    
    # Make a function that reads in EddyFlux files and selects only the columns we want
    
    read_flux_files<-function(FILES){
      
      df <- read_csv(FILES, skip=1, col_names=T)|>
        select(filename, date,time,DOY,Tau,qc_Tau,H,qc_H,LE,qc_LE,co2_flux,qc_co2_flux,h2o_flux,
               qc_h2o_flux,`co2_v-adv`,`h2o_v-adv`,
               co2_molar_density,co2_mole_fraction,co2_mixing_ratio,co2_time_lag,
               co2_def_timelag,h2o_molar_density,h2o_mole_fraction,h2o_mixing_ratio,
               h2o_time_lag,h2o_def_timelag,sonic_temperature,
               air_temperature,air_pressure,air_density,air_heat_capacity,
               air_molar_volume,ET,water_vapor_density,e,es,specific_humidity,RH,VPD,
               Tdew,wind_speed,max_wind_speed,wind_dir,`u*`,TKE,L,`(z-d)/L`,bowen_ratio,
               `T*`,x_peak,x_offset,`x_10%`,`x_30%`,`x_50%`,`x_70%`,`x_90%`,un_Tau,
               Tau_scf,un_H,H_scf,un_LE,LE_scf,un_co2_flux,co2_scf,un_h2o_flux,
               h2o_scf,u_var,v_var,w_var,one_of("ch4_flux","qc_ch4_flux",
                                                  "ch4_molar_density","ch4_mole_fraction",
                                                  "ch4_v-adv","ch4_mixing_ratio","ch4_time_lag",
                                                  "ch4_def_timelag",
                                                  "un_ch4_flux","ch4_scf",
                                                  "rssi_77_mean","flowrate_mean"))
      
      # take out the unit row
      df <-df|>
        dplyr::filter(filename!="")|>
        select(-filename)
      
      # print the file that was read in 
      print(paste0("Read in ", FILES))
      
      
      return(df)
    }     
    
    # use the function above to read in the files and bind them together
    b2 <- list.files(path=mydir,pattern= "full_output", recursive = TRUE,full.names=TRUE)%>%
      purrr::map_df(~read_flux_files(.x))
    
    b3 <- b2|>
      # rename some of the file headers because they are different in the streaming .txt file and in the historical file
      dplyr::rename(
        "u."=`u*`,
        "T."=`T*`,
        "co2_v.adv" = `co2_v-adv`,
        "h2o_v.adv" = `h2o_v-adv`,
        "ch4_v.adv" = `ch4_v-adv`,
        "X.z.d..L" = `(z-d)/L`,
        "x_10." =`x_10%`, 
        "x_30." =`x_30%`,
        "x_50." =`x_50%`,
        "x_70."=`x_70%`,
        "x_90."=`x_90%`)
    
    # read in the compiled old file
    
    oldfiles <- list.files(path=mydir, pattern="FCR_Eddy_up_to", recursive = T, full.names = T)
    
    if(identical(oldfiles, character(0))==T){
      
      c <-NULL
    }else{
      
      print("read old file")
      # read in the old file 
      c <- readr::read_csv(oldfiles)|>
        dplyr::rename("flowrate_mean"=flowrate_mean_m3s)
      
      # rename headers so they match
      
      
      
      # change columns to character instead of numeric
      c[, c(1:166)] <- sapply(c[, c(1:166)], as.character)
      
    }
    
    # combine the old file with the new one
    
    b <- dplyr::bind_rows(c, b3)
  }
  
  
  
  # Clean up and make it useable for plotting
  b[b ==-9999] <- NA # Remove -9999 and replace with NAs
  
  # If there was no flow rate than add that column. It means the 7200-101 flow module wasn't working. 
  if(!("flowrate_mean" %in% names(b))) {
    b$flowrate_mean<-NA
    
  }
  
  # select the columns we want 
  
  data3<-b%>%
    dplyr::select(date,time,DOY,Tau,qc_Tau,H,qc_H,LE,qc_LE,co2_flux,qc_co2_flux,h2o_flux,
                        qc_h2o_flux,ch4_flux,qc_ch4_flux,`co2_v.adv`,`h2o_v.adv`,`ch4_v.adv`,
                        co2_molar_density,co2_mole_fraction,co2_mixing_ratio,co2_time_lag,
                        co2_def_timelag,h2o_molar_density,h2o_mole_fraction,h2o_mixing_ratio,
                        h2o_time_lag,h2o_def_timelag,ch4_molar_density,ch4_mole_fraction,
                        ch4_mixing_ratio,ch4_time_lag,ch4_def_timelag,sonic_temperature,
                        air_temperature,air_pressure,air_density,air_heat_capacity,
                        air_molar_volume,ET,water_vapor_density,e,es,specific_humidity,RH,VPD,
                        Tdew,wind_speed,max_wind_speed,wind_dir,`u.`,TKE,L,`X.z.d..L`,bowen_ratio,
                        `T.`,x_peak,x_offset,`x_10.`,`x_30.`,`x_50.`,`x_70.`,`x_90.`,un_Tau,
                        Tau_scf,un_H,H_scf,un_LE,LE_scf,un_co2_flux,co2_scf,un_h2o_flux,
                        h2o_scf,un_ch4_flux,ch4_scf,u_var,v_var,w_var,rssi_77_mean, flowrate_mean)
  
  
  # change columns to numeric instead of character
  data3[, c(3:80)] <- sapply(data3[, c(3:80)], as.numeric)
  
  
  current.ec<-data3%>%
    dplyr::mutate(
      date=lubridate::parse_date_time(date, orders = c('ymd','mdy')),#converts date to correct format
      time=strptime(time, format = "%H:%M"), #converts time to postix
      time=as_hms(time), #takes out the date and just leaves the time
      #Year = year(date),
      flowrate_mean = flowrate_mean *60000)%>% # convert the flowrate to L min-1
    dplyr::rename(Tau_kgms2 = Tau,
                  H_wm2 = H,
                  LE_wm2 = LE,
                  co2_flux_umolm2s = co2_flux,
                  h2o_flux_umolm2s = h2o_flux,
                  ch4_flux_umolm2s = ch4_flux,
                  co2_v_adv_umolm2s = `co2_v.adv`,
                  h2o_v_adv_umolm2s = `h2o_v.adv`,
                  ch4_v_adv_umolm2s = `ch4_v.adv`,
                  co2_molar_density_mmolm3 = co2_molar_density,
                  co2_mole_fraction_umolmol = co2_mole_fraction,
                  co2_mixing_ratio_umolmol = co2_mixing_ratio,
                  co2_time_lag_s = co2_time_lag,
                  h2o_molar_density_mmolm3 = h2o_molar_density,
                  h2o_mole_fraction_umolmol = h2o_mole_fraction,
                  h2o_mixing_ratio_umolmol = h2o_mixing_ratio,
                  h2o_time_lag_s = h2o_time_lag,
                  ch4_molar_density_mmolm3 = ch4_molar_density,
                  ch4_mole_fraction_umolmol = ch4_mole_fraction,
                  ch4_mixing_ratio_umolmol = ch4_mixing_ratio,
                  ch4_time_lag_s = ch4_time_lag,
                  sonic_temperature_k = sonic_temperature,
                  air_temperature_k = air_temperature,
                  air_pressure_pa = air_pressure,
                  air_density_kgm3 = air_density,
                  air_heat_capacity_jkkg = air_heat_capacity,
                  air_molar_volume_m3mol = air_molar_volume,
                  ET_mmhr = ET,
                  water_vapor_density_kgm3 = water_vapor_density,
                  e_pa = e,
                  es_pa = es,
                  specific_humidity_kgkg = specific_humidity,
                  VPD_pa = VPD,
                  Tdew_k = Tdew,
                  wind_speed_ms = wind_speed,
                  max_wind_speed_ms = max_wind_speed,
                  u_star_ms = `u.`,
                  TKE_m2s2 = TKE,
                  L_m = L,
                  MO_stability = `X.z.d..L`,
                  scale_T_k = `T.`,
                  x_peak_m = x_peak,
                  x_offset_m = x_offset,
                  x_10_m = `x_10.`,
                  x_30_m = `x_30.`,
                  x_50_m = `x_50.`,
                  x_70_m = `x_70.`,
                  x_90_m = `x_90.`,
                  un_Tau_kgms2 = un_Tau,
                  un_H_wm2 = un_H,
                  un_LE_wm2 = un_LE,
                  un_co2_flux_umolm2s = un_co2_flux,
                  un_h2o_flux_umolm2s = un_h2o_flux,
                  un_ch4_flux_umolm2s = un_ch4_flux,
                  u_var_ms = u_var,
                  v_var_ms = v_var,
                  w_var_ms = w_var)
  
  # round columns
  # Columns to round
  columns_dont_round <- c("date","time","DOY","qc_Tau","qc_H","qc_LE","qc_co2_flux","qc_h2o_flux",
                          "co2_def_timelag", "ch4_def_timelag")
  
  # Round everything but certain columns
  current.ec <- current.ec %>%
    mutate_at(vars(-one_of(columns_dont_round)), ~ round(., digits = 4))
  
  
  # Make a datetime column
  #current.ec$datetime <- as.POSIXct(paste(current.ec$date , paste(current.ec$time), sep=" "))
  
  # Fix DateTime issues. From 2020-04-04 to 2020-09-02 17:30 the system was in Est/GMT +5. 
  # System is in US/Eastern with daylight savings observed from 2020-09-02 12:00 to current.
  
  # We want to convert the time in Est/GMT +5 to GMT+4  so we need to add an hour. 
  #Change DateTime when it was changed from EDT to EST
  # Set everything to Etc/GMT+4
  # Make a datetime column
  
  current.ec$datetime <- lubridate::ymd_hms(paste0(as.character(current.ec$date), " " , as.character(current.ec$time)), tz="Etc/GMT+4")
  
  sed <- current.ec%>%
    dplyr::select(date,time,datetime)
  
  # order the datetime column
  # reorder 
  current.ec <-  current.ec[order(current.ec$datetime),]
  
  if("2020-09-02 17:30:00" %in% current.ec$datetime){
    # shows time point when met station was switched from GMT -4(EST) to GMT -5(EDT) then -2 to get the row number right
    flux_timechange=max(which(current.ec$datetime=="2020-09-02 17:30:00")-2) 
    #Met$DateTime<-as.POSIXct(strptime(Met$DateTime, "%Y-%m-%d %H:%M"), tz = "Etc/GMT+5") #get dates aligned
    current.ec$datetime[c(0:flux_timechange+1)]<-lubridate::with_tz(force_tz(current.ec$datetime[c(0:flux_timechange+1)],"Etc/GMT+5"), "Etc/GMT+4") #pre time change data gets assigned proper timezone then corrected to GMT -5 to match the rest of the data set
  }
  # else if (min(current.ec$datetime, na.rm = TRUE)<"2020-09-02 17:30:00"){
  #   #pre time change data gets assigned proper timezone then corrected to GMT -5 to match the rest of the data set
  #   current.ec$datetime<-with_tz(force_tz(current.ec$datetime,"Etc/GMT+5"), "Etc/GMT+4")
  # }else if(min(current.ec$datetime, na.rm = TRUE)>"2020-09-02 17:30:00"){
  #   # Do nothing because already in EST
  # }
  
  # Set timezone as America/New_York because 
  #current.ec$datetime <- force_tz(current.ec$datetime, tzone = "America/New_York")
  
  # Because we changed times in the datetime column, we need to make sure we get the new time
  # convert to character 
  current.ec$datetime2 <-as.character(format(current.ec$datetime))
  # split into 2 columns   
  current.ec <- current.ec %>% separate(datetime2, c('date', 'time'), sep = " ")  
  
  
  # Filter for just the unprocessed files
  ### identify the date subsetting for the data
  if (!is.null(start_date)){
    current.ec <- current.ec %>% 
      dplyr::filter(datetime >= start_date)
  }
  
  if(!is.null(end_date)){
    current.ec <- current.ec %>% 
      dplyr::filter(datetime <= end_date)
  }
  
  
  # Check if there are any files for the L1. If not then end the script
  
  if(nrow(current.ec)==0){
    
    print("No new files for the current year")
    
  }else{
  
  ## Add flag for missing data: 3 = missing data, 4= instrument malfunction 
  # For: qc_tau, qc_H, qc_LE, qc_co2_flux, qc_h2o_flux, qc_ch4_flux
  ec_all <- current.ec %>% 
    dplyr::mutate(qc_Tau = ifelse(is.na(Tau_kgms2), 3, qc_Tau),
           qc_H = ifelse(is.na(H_wm2), 3, qc_H),
           qc_LE = ifelse(is.na(LE_wm2), 3, qc_LE),
           qc_H = ifelse(H_wm2 >= 200 | H_wm2 <= -200, 4, qc_H), 
           H_wm2 = ifelse(H_wm2 >= 200 | H_wm2 <= -200, NA, H_wm2),
           qc_LE = ifelse(LE_wm2 >= 500 | LE_wm2 <= -500, 4, qc_LE),
           LE_wm2 = ifelse(LE_wm2 >= 500 | LE_wm2 <= -500, NA, LE_wm2),
           qc_co2_flux = ifelse(is.na(co2_flux_umolm2s), 3, qc_co2_flux),
           qc_h2o_flux = ifelse(is.na(h2o_flux_umolm2s), 3, qc_h2o_flux),
           qc_ch4_flux = ifelse(is.na(ch4_flux_umolm2s), 3, qc_ch4_flux),
           qc_co2_flux = ifelse(flowrate_mean<10 & !is.na(flowrate_mean) | flowrate_mean>20 & !is.na(flowrate_mean), 4, qc_co2_flux), # take out fluxes when the blower motor malfunction
           co2_flux_umolm2s = ifelse(flowrate_mean<10 & !is.na(flowrate_mean) | flowrate_mean>20 & !is.na(flowrate_mean),NA, co2_flux_umolm2s),  # take out fluxes when the blower motor malfunction
           qc_h2o_flux = ifelse(flowrate_mean<10 & !is.na(flowrate_mean) | flowrate_mean>20 & !is.na(flowrate_mean), 4, qc_h2o_flux),  # take out fluxes when the blower motor malfunction
           h2o_flux_umolm2s = ifelse(flowrate_mean<10 & !is.na(flowrate_mean) | flowrate_mean>20 & !is.na(flowrate_mean),NA, h2o_flux_umolm2s),  # take out fluxes when the blower motor malfunction
           qc_ch4_flux = ifelse(ch4_flux_umolm2s> 1 & !is.na(ch4_flux_umolm2s) | ch4_flux_umolm2s< -0.25 & !is.na(ch4_flux_umolm2s), 4, qc_ch4_flux),
           ch4_flux_umolm2s = ifelse(ch4_flux_umolm2s> 1 & !is.na(ch4_flux_umolm2s)| ch4_flux_umolm2s< -0.25 & !is.na(ch4_flux_umolm2s), NA, ch4_flux_umolm2s), # take out very high and low fluxes
           qc_co2_flux = ifelse(co2_flux_umolm2s > 300 & !is.na(co2_flux_umolm2s) | co2_flux_umolm2s < -300 & !is.na(co2_flux_umolm2s), 4, qc_co2_flux),
           co2_flux_umolm2s = ifelse(co2_flux_umolm2s > 300 & !is.na(co2_flux_umolm2s) | co2_flux_umolm2s < -300 & !is.na(co2_flux_umolm2s), NA, co2_flux_umolm2s), # take out very high and low fluxes
           qc_h2o_flux = ifelse(h2o_flux_umolm2s > 40 & !is.na(h2o_flux_umolm2s) | h2o_flux_umolm2s < -40 & !is.na(h2o_flux_umolm2s), 4, qc_h2o_flux),
           h2o_flux_umolm2s = ifelse(h2o_flux_umolm2s > 40 & !is.na(h2o_flux_umolm2s) | h2o_flux_umolm2s < -40 & !is.na(h2o_flux_umolm2s), NA, h2o_flux_umolm2s))%>% # take out very high and low fluxes
    dplyr::distinct()%>% # take out duplicates
    dplyr::select(-flowrate_mean)%>% # take out the columns not in EDI
    dplyr::select(date, time, everything())
  
  
  
  # Double check that -9999 got changed to NA
  # Clean up and make it useable for plotting
  ec_all[ec_all ==-9999] <- NA # Remove -9999 and replace with NAs
  
  # order the observations
  ec_all<-ec_all[order(ec_all$date),]
  
  # Clean up when a date and time was processed on 2 occasions
  # found observations where there was no info and other observations for the same time that
  # had some columns filled. This was 2022-08-18 15:00 - 2022-08-19 23:00. I decided to take the
  # observation that had values. 
  
  # this code groups by datetime where there should be one value. If there is more than one value then 
  # take the value with the highest Tau_kg2 because the other one is an NA.  
  
  ec_all <- ec_all %>% 
    dplyr::group_by(datetime) %>% 
    dplyr::slice_max(Tau_kgms2, n = 1) %>%
    dplyr::ungroup()%>%
    dplyr::select(-datetime)
  
  # convert datetimes to characters so that they are properly formatted in the output file
  ec_all$date <- as.character(format(ec_all$date))
  ec_all$time <- as.character(format(ec_all$time))
  
  # Output data
  #write_csv(ec_all, paste0(mydir,output_file), row.names = FALSE)
  # save data if there is an output)file path. If not then the file is returned. 
  if (is.null(output_file)){
    return(ec_all)
  }else{
    readr::write_csv(ec_all, output_file)
  }
  
  } # ends the if statement when no new observations for the year
  } else {
    print ("Did not process files and create an L1 file. If you want to create a processed L1 file change process_files = T")
  }
} # ends the function



