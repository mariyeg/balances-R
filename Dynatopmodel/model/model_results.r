######################################
## output for the running model
######################################

# Plot discharge predictions, rainfall and potential (actual?) evapotranspiration,
# storage deficits and root and unsat zone storages.
# time buffer is in hours
disp.results <- function (it,  # current time step
													tm,  # current simulation time
													qr,  # calculated discharge at outlet
													rain,
													evap,  # actula evapotranspiration
													groups,
													flows,
													stores,
													qobs=NULL,
													wb=NULL,
													ichan=1,   # channel indicators
													text.out=stdout(),
													log.msg = "",
													start, end,
													disp.par,
													run.par, sf=2)
{
	fmt <-  disp.par$"time.text.fmt"
	# sim.delay expressed as hours, convert to seconds
	if(tm >= start & !is.null(text.out))
	{
		# send to console by default,  disp.par$output.text.flows
		#  txt.out <- paste(flows[,disp.par$output.text.flows], sep="\t", )
		cat(format(tm, fmt), "\t", signif(qr[it,ichan],sf), file=text.out)   #
		#         if(length(qobs)>0)
		#         {
		#           cat("\t\t", signif(qobs[it,], sf), file=text.out)
		#           cat("\t\t", signif((qr[it,ichan]-qobs[it,])/qobs[it,]*100, 2), "%")
		#         }
		if(any(flows$qof>0))
		{
			# overland flow distributed to channel over this time step
			cat("\t\t", signif(flows[ichan, "qof"]*1000*groups[ichan,]$area/sum(groups$area),2), file=text.out)   #
		}
		#cat("\t\tmm/hr\n")   #
		cat("\n")   #
	}
	else{
		# waiting...
		#    cat(".")
	}
	
	disp.par$disp.start <- start + run.par$"sim.delay"*3600
	
	if(!disp.par$"graphics.show" | tm < disp.par$disp.start){return()}
	
	title <- disp.par$"main"
	
	# render either graphical output at this time step?
	show.graphics <-  it%%disp.par$"graphics.interval"==0
	
	# time buffer, the length of time around the current observation that should be displayed
	buff <- disp.par$"graphics.window.length"
	
	# graphical output, if requested, after specified time interval
	if(show.graphics)
	{
		# dev.set(disp.par$winid)
	#	activate.device(disp.par$winid)
		# buffer output
		dev.hold()
		on.exit(dev.flush())
		
		qr <- GetTimeSeriesInputRange(qr, start, tm, verbose=FALSE)
		
		# determine y axis range from
		# (a) actual evapotranspiration
		# (b) any observed discharges
		# (c) max base flow routed through catchment outlet
		# (d) explicitly specified limits
		#    ymax <- max(max(evap, disp.par$max.q, na.rm=T), qobs[], na.rm=T)
		#    ymax <- max(c(disp.par$max.q, qobs[], 0.01), na.rm=T)
		par("mar"=c(5, 4.5, 5, 4.5))
		evap <- evap[,"ae"]
		
		# flows observed and simulated
		disp_output(main=title,
								qsim=qr,
								evap=evap,
								rain=rain,
								tm=tm,
								qobs=qobs,
								par=disp.par)
	}
}



# identify the first window of default type on list with hydrograph output
# call once to estalish titled output windows
setup.output <- function(disp.par,
												 run.par,
												 rain,
												 qobs=NULL,
												 sim.start=NULL, dt=1, pe=NULL)
	
{
	if(disp.par$"graphics.show"==T)
	{
		disp.par <- merge.lists(get.disp.par(), disp.par)
		# simStart <-  start + run.par$"sim.delay"*3600  # add simulation delay (expressed in hours)
		disp.par$disp.start <- sim.start + disp.par$"graphics.delay"*3600 # hours -> seconds
		
		if(!(disp.par$text.out == "N"))
		{
			disp.par$text.out <- stdout()
		}
		else
		{
			disp.par$text.out <- NULL
		}
		if(nchar(disp.par$text.out)>0)
		{
			#  file specified
			#   text.out <- file(disp.par$text.out)
		}
		
		if(disp.par$"graphics.save"==T & !file.exists(disp.par$"graphics.out"))
		{
			# mmmm
			dir.create(disp.par$"graphics.out", recursive=T)
		}
		# graphics interval is in hours but needs to be converted if time step is not
		disp.par$graphics.interval <- max(round(disp.par$graphics.interval/dt), 1)
		
		disp.par$time.tick.int <- "day"
		
		# set the tick interval according to the size of the window
		if(disp.par$graphics.window.length > 3*7*24)
		{
			disp.par$time.tick.int <- "week"
		}
		
		# ensure suffcient windows open to display results
		disp.par$winid <- open.devices(1, title=run.par$id,
																	 width=12, #disp.par$graphics.save.width,
																	 height=8) #disp.par$graphics.save.height)
		
		# for display should be in mm/hr
		#   disp.par$max.q <- convert.vals(disp.par$max.q)
		#    disp.par$max.rain <- convert.vals(disp.par$max.rain)
	}
	# return the updated display parameters
	return(disp.par)
}



SetFigWindow <- function(xmn=0, xmx=1, ymn=0, ymx=1)
{
	# set the fg parameter to place a window at the given position expressed in
	# proportion of the screen. Call with no parameters to reset to default window
	par(fig=c(xmn,xmx,ymn,ymx))
}

