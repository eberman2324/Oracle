BEGIN { FS = " " }
{
the_day = $1
if (the_day == "Mon" || the_day == "Tue" || the_day == "Wed" || the_day == "Thu" || the_day == "Fri" || the_day == "Sat" || the_day == "Sun")
   {
   date_rec = $0
   }
else
   {
   log_entry = $0
   print date_rec " " log_entry
   }
}
