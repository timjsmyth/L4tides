#!/usr/bin/bash
# Module: run_L4buoy_tidal_model.sh
# Author: Tim Smyth
# Date: 19 August 2022
# Description: 
# Wrapper script for the L4buoy_tides.py Python code
# Determines times of Hi / Lo water at Devonport for previous
# day and subsequent 7 days. Then works out times of slack water
# converting this into French time zone.
# 
# Directory this is operating in
execdir=/home/pi/profile_manager/utils/L4tides

## declare an array variable holding the locations
declare -a locations=("Plymouth_L4")
L4tidesfile_py=$execdir/Output/L4buoy_tides.txt
slackofile=/tmp/L4buoy_slack_today_FRENCH.txt

# Issues with the profiler only operating on the Devil's time
# The following assumes that the UK and France shift to Daylight Savings simultaneously
dst_start_end_file=$execdir/Required/daylight_saving_start_end.txt
YYYY=`date --utc +%Y`
JJJ=`date --utc +%j | sed 's/^0//'`
DST_start=`cat $dst_start_end_file | grep $YYYY | awk '{print $2}' | sed 's/^0//'`
DST_end=`cat $dst_start_end_file | grep $YYYY | awk '{print $3}' | sed 's/^0//'`

if [ "$JJJ" -ge "$DST_start" -a "$JJJ" -le "$DST_end" ]; then 
   ZONE="CEST"
else 
   ZONE="CET"
fi

TIME=$(date +%s --utc -d "12:00:00 $ZONE")
UTC_TIME=$(date +%s --utc -d "12:00:00")
((DIFF=UTC_TIME-TIME))
FROFF=`echo - | awk -v SECS=$DIFF '{printf "%d",SECS/(60*60)}'`

# Make sure that the current time has not been monkeyed with
echo "Current time"
date --utc

# Run model for a week starting one day before current
# Start date
START=`date --utc --date='-1 day' +%Y-%m-%d`
# End date
END=`date --utc --date='7 day' +%Y-%m-%d`

#START="2023-01-01"
#END="2023-06-30"

# Make sure that the python output text file is refreshed
/bin/rm -rf $L4tidesfile_py 
## loop through the locations array
for location in "${locations[@]}"
do
   echo "$location"
   ## Run the L4buoy_tides.py model
   /bin/python3 $execdir/L4buoy_tides.py -idir $execdir -o -start $START -end $END 
done

cat $L4tidesfile_py | sed -e 's/\"//g' > /tmp/L4buoy_tides.txt

# TODAY
echo "======================="
echo "Today's times of Hi/Lo water @Devonport (UTC)"
TODAY=`date --utc +%Y-%m-%d`
grep $TODAY /tmp/L4buoy_tides.txt | awk '{print $1,$2,$3,$4}'
grep $TODAY /tmp/L4buoy_tides.txt > /tmp/Devonport_tides_today.txt
echo "======================="

# Slack water
echo "Today's times of predicted slack water @L4 (UTC)"
#grep $TODAY /tmp/L4buoy_tides.txt | awk '{print $5,$6}'
#grep $TODAY /tmp/L4buoy_tides.txt | awk '{print $5,$6}' > /tmp/L4buoy_slack_today.txt
cat /tmp/L4buoy_tides.txt | awk '{if(NF==6){print $5,$6}}' | grep $TODAY
cat /tmp/L4buoy_tides.txt | awk '{if(NF==6){print $5,$6}}' | grep $TODAY > /tmp/L4buoy_slack_today.txt
echo "======================="

echo "Slack offset in French time from God's own time(UTC): $FROFF"
# Check to see that it is still TODAY in FRENCH time
FRTODAY=`date --utc -d "+${DIFF}Seconds" "+%Y-%m-%d"`

# Remove the slack tide file as will append it in a loop
/bin/rm -rf $slackofile
while read entry
do
   DATETIME=`echo "$entry" | awk '{if (NF==6){print $5,$6}}'`
   if [[ ! -z "$DATETIME" ]]; then
      FRENCHTIME=`date -d"$DATETIME $FROFF hour" +"%Y-%m-%d %H:%M:%S"`
      echo $FRENCHTIME >> $slackofile
   fi
done < /tmp/L4buoy_tides.txt
cat $slackofile | grep $FRTODAY | sort -u 
cat $slackofile | grep $FRTODAY | sort -u > /tmp/tmp_slack.txt
/bin/mv /tmp/tmp_slack.txt $slackofile 
echo "Written to $slackofile"
echo "======================="

exit 0

