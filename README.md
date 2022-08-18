# L4tides
L4 tidal model for predicting times of slack water at the buoy

The tidal model either uses pre-calculated (on a faster Linux box than ARM) tidal harmonics, generated from historical tidal data at Devonport, or calculates them as a call within the routine from those tidal data.

Based on the time of high water and the magnitude of that tide, the time of slack water is calculated from empirical relationships provided by Dr. Reg Uncles.  No correction is made for the effect of the wind: there is approximately slack water at L4 three hours before and three hours after.

The wrapper script run_L4buoy_tidal_model.sh then adds the offset to UTC in French time to make the output compatible with the profiling winch on the buoy.  This is also a function of the time of year (UTC vs. BST) which is accounted for in the code.

--

Tim Smyth - PML

18 August 2022 
