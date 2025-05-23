### MakeEMLChaoborus
### Updated script to publish ES&T Chaoborus data 
### 11 January 2021, Ryan McClure & Mary Lofton

# (install and) Load EMLassemblyline #####
install.packages('devtools')

devtools::install_github("EDIorg/EMLassemblyline")
#note that EMLassemblyline has an absurd number of dependencies and you
#may exceed your API rate limit; if this happens, you will have to wait an
#hour and try again or get a personal authentification token (?? I think)
#for github which allows you to submit more than 60 API requests in an hour
library(EMLassemblyline)


#Step 1: Create a directory for your dataset
#in this case, our directory is Reservoirs/Data/DataAlreadyUploadedToEDI/EDIProductionFiles/MakeEML_GHG/Sep2020

#Step 2: Move your dataset to the directory

#Step 3: Identify an intellectual rights license
#ours is CCBY

#Step 4: Identify the types of data in your dataset
#right now the only supported option is "table"; happily, this is what 
#we have!

#Step 5: Import the core metadata templates

#for our application, we will need to generate all types of metadata
#files except for taxonomic coverage, as we have both continuous and
#categorical variables and want to report our geographic location

# View documentation for these functions
?template_core_metadata
?template_table_attributes
?template_categorical_variables #don't run this till later
?template_geographic_coverage

# Import templates for our dataset licensed under CCBY, with 1 table.
template_core_metadata(path = "C:/Users/Owner/Desktop/Reservoirs/Data/DataAlreadyUploadedToEDI/EDIProductionFiles/MakeEMLChaoborus",
                       license = "CCBY",
                       file.type = ".txt",
                       write.file = TRUE)

template_table_attributes(path = "C:/Users/Owner/Desktop/Reservoirs/Data/DataAlreadyUploadedToEDI/EDIProductionFiles/MakeEMLChaoborus",
                          data.path = "C:/Users/Owner/Desktop/Reservoirs/Data/DataAlreadyUploadedToEDI/EDIProductionFiles/MakeEMLChaoborus",
                          data.table = c("Vial_MethaneConc_Chaoborus.csv", "WaterColumn_MethaneConc_ChaoborusDensity.csv"),
                          write.file = TRUE)


#we want empty to be true for this because we don't include lat/long
#as columns within our dataset but would like to provide them
template_geographic_coverage(path = "C:/Users/Owner/Desktop/Reservoirs/Data/DataAlreadyUploadedToEDI/EDIProductionFiles/MakeEMLChaoborus",
                             data.path = "C:/Users/Owner/Desktop/Reservoirs/Data/DataAlreadyUploadedToEDI/EDIProductionFiles/MakeEMLChaoborus",
                             data.table = c("Vial_MethaneConc_Chaoborus.csv", "WaterColumn_MethaneConc_ChaoborusDensity.csv"),
                             empty = TRUE,
                             write.file = TRUE)

#Step 6: Script your workflow
#that's what this is, silly!

#Step 7: Abstract
#copy-paste the abstract from your Microsoft Word document into abstract.txt
#if you want to check your abstract for non-allowed characters, go to:
#https://pteo.paranoiaworks.mobi/diacriticsremover/
#paste text and click remove diacritics

#Step 8: Methods
#copy-paste the methods from your Microsoft Word document into methods.txt
#if you want to check your methods for non-allowed characters, go to:
#https://pteo.paranoiaworks.mobi/diacriticsremover/
#paste text and click remove diacritics

#Step 9: Additional information
# No additional information for inflow data

#Step 10: Keywords
#DO NOT EDIT KEYWORDS FILE USING A TEXT EDITOR!! USE EXCEL!!
#not sure if this is still true...let's find out! :-)
#see the LabKeywords.txt file for keywords that are mandatory for all Carey Lab data products

#Step 11: Personnel
#copy-paste this information in from your metadata document
#Cayelan needs to be listed several times; she has to be listed separately for her roles as
#PI, creator, and contact, and also separately for each separate funding source (!!)

#Step 12: Attributes
#grab attribute names and definitions from your metadata word document
#for units....
# View and search the standard units dictionary
view_unit_dictionary()
#put flag codes and site codes in the definitions cell
#force reservoir to categorical

#Step 14: Categorical variables
# Run this function for your dataset
#THIS WILL ONLY WORK once you have filled out the attributes_chemistry.txt and
#identified which variables are categorical
template_categorical_variables(path = "C:/Users/Owner/Desktop/Reservoirs/Data/DataAlreadyUploadedToEDI/EDIProductionFiles/MakeEMLChaoborus",
                               data.path = "C:/Users/Owner/Desktop/Reservoirs/Data/DataAlreadyUploadedToEDI/EDIProductionFiles/MakeEMLChaoborus",
                               write.file = TRUE)

#open the created value IN A SPREADSHEET EDITOR and add a definition for each category

#Step 15: Geographic coverage
#copy-paste the bounding_boxes.txt file (or geographic_coverage.txt file) that is Carey Lab specific into your working directory

#Step 16: Custom units
# Copy and pased custom units .txt file from prior year

## Step 17: Obtain a package.id FROM STAGING ENVIRONMENT. ####
# Go to the EDI staging environment (https://portal-s.edirepository.org/nis/home.jsp),
# then login using one of the Carey Lab usernames and passwords. 

# Select Tools --> Data Package Identifier Reservations and click 
# "Reserve Next Available Identifier"
# A new value will appear in the "Current data package identifier reservations" 
# table (e.g., edi.123)
# Make note of this value, as it will be your package.id below

## Step XXX: Make EML metadata file using the EMLassemblyline::make_eml() command ####
# For modules that contain only zip folders, modify and run the following 
# ** double-check that all files are closed before running this command! **

## Make EML for staging environment
## NOTE: Will need to check geographic coordinates!!!
make_eml(
  path = "C:/Users/Owner/Desktop/Reservoirs/Data/DataAlreadyUploadedToEDI/EDIProductionFiles/MakeEMLChaoborus",
  data.path = "C:/Users/Owner/Desktop/Reservoirs/Data/DataAlreadyUploadedToEDI/EDIProductionFiles/MakeEMLChaoborus",
  eml.path = "C:/Users/Owner/Desktop/Reservoirs/Data/DataAlreadyUploadedToEDI/EDIProductionFiles/MakeEMLChaoborus",
  dataset.title = "Depth profiles of water column dissolved methane, density and biomass of zooplankton (specifically, Chaoborus spp.), and measurements of methane extracted from the tracheal gas sacs of Chaoborus spp. during two sampling efforts in 2016",
  temporal.coverage = c("2016-08-03", "2016-09-17"),
  maintenance.description = 'completed',
  data.table = c("Vial_MethaneConc_Chaoborus.csv", "WaterColumn_MethaneConc_ChaoborusDensity.csv"),
  data.table.description = c("Measurements of methane extracted from the tracheal gas sacs of Chaoborus spp.",
                             "Depth profiles of water column dissolved methane, density and biomass of Chaoborus spp."),
  data.table.name = c("Methane Extracted from Chaooborus spp.",
                      "Ambient Water Column Methane Concentrations"),
  user.id = 'ccarey',
  user.domain = 'EDI',
  package.id = 'edi.151.1')

## Step 8: Check your data product! ####
# Return to the EDI staging environment (https://portal-s.edirepository.org/nis/home.jsp),
# then login using one of the Carey Lab usernames and passwords. 

# Select Tools --> Evaluate/Upload Data Packages, then under "EML Metadata File", 
# choose your metadata (.xml) file (e.g., edi.270.1.xml), check "I want to 
# manually upload the data by selecting files on my local system", then click Upload.

# Now, Choose File for each file within the data package (e.g., each zip folder), 
# then click Upload. Files will upload and your EML metadata will be checked 
# for errors. If there are no errors, your data product is now published! 
# If there were errors, click the link to see what they were, then fix errors 
# in the xml file. 
# Note that each revision results in the xml file increasing one value 
# (e.g., edi.270.1, edi.270.2, etc). Re-upload your fixed files to complete the 
# evaluation check again, until you receive a message with no errors.

## Step 17: Obtain a package.id. ####
# Need to obtain a package identifier: reserved #551
make_eml(
  path = "C:/Users/ahoun/OneDrive/Desktop/Reservoir/Reservoirs/Data/DataAlreadyUploadedToEDI/EDIProductionFiles/MakeEML_GHG/Sep2020",
  data.path = "C:/Users/ahoun/OneDrive/Desktop/Reservoir/Reservoirs/Data/DataAlreadyUploadedToEDI/EDIProductionFiles/MakeEML_GHG/Sep2020",
  eml.path = "C:/Users/ahoun/OneDrive/Desktop/Reservoir/Reservoirs/Data/DataAlreadyUploadedToEDI/EDIProductionFiles/MakeEML_GHG/Sep2020",
  dataset.title = "Time series of dissolved methane and carbon dioxide concentrations for Falling Creek Reservoir and Beaverdam Reservoir in southwestern Virginia, USA during 2015-2019",
  temporal.coverage = c("2015-03-31", "2019-11-20"),
  maintenance.description = 'ongoing',
  data.table = 'DATASET_for_EDI_LOL_MS_31Aug20.csv',
  data.table.description = "GHG Dataset",
  data.table.name = "GHG Dataset",
  user.id = 'ccarey',
  user.domain = 'EDI',
  package.id = 'edi.551.2')

## Step 18: Upload revision to EDI
# Go to EDI website: https://portal.edirepository.org/nis/home.jsp and login with Carey Lab ID
# Click: Tools then Evaluate/Upload Data Packages
# Under EML Metadata File, select 'Choose File'
# Select the .xml file of the last revision (i.e., edi.202.4)
# Under Data Upload Options, select 'I want to manually upload the data by selecting...'
# Click 'Upload'
# Select text files and R file associated with the upload
# Then click 'Upload': if everything works, there will be no errors and the dataset will be uploaded!
# Check to make sure everything looks okay on EDI Website
