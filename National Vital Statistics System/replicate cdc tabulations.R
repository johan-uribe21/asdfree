# analyze survey data for free (http://asdfree.com) with the r language
# national vital statistics system
# natality, period-linked deaths, cohort-linked deaths, and fetal death files

# # # # # # # # # # # # # # # # #
# # block of code to run this # #
# # # # # # # # # # # # # # # # #
# library(downloader)
# setwd( "C:/My Directory/NVSS/" )
# source_url( "https://raw.githubusercontent.com/ajdamico/asdfree/master/National%20Vital%20Statistics%20System/replicate%20cdc%20tabulations.R" , prompt = FALSE , echo = TRUE )
# # # # # # # # # # # # # # #
# # end of auto-run block # #
# # # # # # # # # # # # # # #

# contact me directly for free help or for paid consulting work

# anthony joseph damico
# ajdamico@gmail.com


# this r script will replicate statistics found on four different
# centers for disease control and prevention (cdc) publications
# and match the output exactly


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#####################################################################################################################
# prior to running this analysis script, the national vital statistics system files must be imported into           #
# a monet database on the local machine. you must run this:                                                         #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# https://raw.githubusercontent.com/ajdamico/asdfree/master/National%20Vital%20Statistics%20System/download%20all%20microdata.R #
#################################################################################################################################
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #


library(MonetDB.R)		# load the MonetDB.R package (connects r to a monet database)
library(MonetDBLite)	# load MonetDBLite package (creates database files in R)


# setwd( "C:/My Directory/NVSS/" )
# uncomment the line above (remove the `#`) to set the working directory to C:\My Directory\NVSS


# after running the r script above, users should have handy a few lines
# to initiate and connect to the monet database containing the
# national vital statistics system files.  run them now.  mine look like this:

# name the database files in the "MonetDB" folder of the current working directory
dbfolder <- paste0( getwd() , "/MonetDB" )

# open the connection to the monetdblite database
db <- dbConnect( MonetDBLite() , dbfolder )



# # # # # # # # # # # # #
# replicated statistics #
# # # # # # # # # # # # #

# the centers for disease control and prevention (cdc) published control counts of the 2010 nationwide and territory tables
# on pdf page 11 - ftp://ftp.cdc.gov/pub/Health_Statistics/NCHS/Dataset_Documentation/DVS/natality/UserGuide2010.pdf#11

# reproduce the control counts of the nationwide file
dbGetQuery( db , 'select count(*) , ( restatus = 4 ) as foreign_resident from natality_us_2010 group by foreign_resident' )

# reproduce the control counts of the territory file
dbGetQuery( db , 'select count(*) , ( restatus = 4 ) as foreign_resident from natality_ps_2010 group by foreign_resident' )


# on pdf page two of this document, the cdc published birth (natality) counts by month
# http://www.cdc.gov/nchs/data/nvsr/nvsr62/nvsr62_01_tables.pdf#page=2

dbGetQuery( db , 'select count(*) , dob_mm from natality_us_2011 where not ( restatus = 4 ) group by dob_mm' )


# at the bottom of pdf page three of this document,
# the cdc published period-linked deaths by race/ethnicity
# http://www.cdc.gov/nchs/data/nvsr/nvsr61/nvsr61_08.pdf#page=3

# table A
# infant deaths column

# total infant deaths
dbGetQuery( db , 'select sum( recwt ) as wt , count(*) from periodlinked_us_num2009 where not ( restatus = 4 )' )

# non-hispanic white
# non-hispanic black
dbGetQuery( db , 'select mracehisp , sum( recwt ) as wt , count(*) from periodlinked_us_num2009 where not ( restatus = 4 ) AND mracehisp IN ( 6 , 7 ) group by mracehisp order by mracehisp' )

# american indian or alaska native
# asian or pacific islander
dbGetQuery( db , 'select mracerec , sum( recwt ) as wt , count(*) from periodlinked_us_num2009 where not ( restatus = 4 ) AND mracerec IN ( 3 , 4 ) group by mracerec order by mracerec' )

# hispanic
dbGetQuery( db , 'select sum( recwt ) as wt , count(*) from periodlinked_us_num2009 where not ( restatus = 4 ) AND umhisp IN ( 1 , 2 , 3 , 4 , 5 )' )

# mexican
# puerto rican
# cuban
# central and south american
dbGetQuery( db , 'select mracehisp , sum( recwt ) as wt , count(*) from periodlinked_us_num2009 where not ( restatus = 4 ) AND mracehisp IN ( 1 , 2 , 3 , 4 ) group by mracehisp order by mracehisp' )


# on pdf page 5, the cdc broke out fetal deaths by 20-27 weeks versus 28+ weeks
# http://www.cdc.gov/nchs/data/nvsr/nvsr60/nvsr60_08.pdf#page=5

# begin with an empty data.frame object
table.b <- data.frame( NULL )

# loop through years 2005, 2006, and 2007
for ( year in 2005:2007 ){

	# load the current nationwide fetal death file for this year
	load( paste0( "fetal death " , year , ".rda" ) )
	
	# throw out records that are not united states residents or under 20 months
	x <- subset( us , tabflg == 2 & restatus != 4 )
	
	# for 2005 and 2006, use the `gest12` variable instead of `gestrec12`
	gestvar <- ifelse( year %in% 2005:2006 , 'gest12' , 'gestrec12' )
	
	# create a zero/one (binary) variable that's only 1 when
	# the gestation weeks are a three or a four
	x$weeks.20.27 <- as.numeric( x[ , gestvar ] %in% 3:4 )
	# same for five through eleven
	x$weeks.28.plus <- as.numeric( x[ , gestvar ] %in% 5:11 )
	# note that these gestation recodes are based on pdf page 31 of the 2006 layout file.
	# have a look at the levels of `gestrec5` and `gestrec12`
	# ftp://ftp.cdc.gov/pub/Health_Statistics/NCHS/Dataset_Documentation/DVS/fetaldeath/2006FetalUserGuide.pdf#page=31
	
	
	# proportional distribution of the unknowns with tabflg == 2
	num.to.distribute <- sum( x[ , gestvar ] %in% 12 )
	
	# create a single-row data.frame, with..
	current.year <- 
		data.frame( 
			# the current year
			year = year ,
			# the current total number of fetal deaths
			total = nrow( x ) ,
			# the 20-27 week old fetuses plus the distributed unknowns
			twenty.to.twentyseven = sum( x$weeks.20.27 ) + ( num.to.distribute * ( sum( x$weeks.20.27 ) / ( nrow( x ) - num.to.distribute ) ) ) ,
			# the 28+ week old fetuses plus the distributed unknowns
			twentyeight.plus = sum( x$weeks.28.plus ) + ( num.to.distribute * ( sum( x$weeks.28.plus ) / ( nrow( x ) - num.to.distribute ) ) )
		)
	
	# stack this new table below what's already been run for table b
	table.b <- rbind( table.b , current.year )
}

# # # # # # # # # # # # # # # # #
# end of replicated statistics  #
# # # # # # # # # # # # # # # # #


# disconnect from the current monet database
dbDisconnect( db )

