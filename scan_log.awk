BEGIN { FS = " " }
{
the_day = $1
if (the_day == "Mon" || the_day == "Tue" || the_day == "Wed" || the_day == "Thu" || the_day == "Fri" || the_day == "Sat" || the_day == "Sun")
   {
   date_rec = $0
   }
else
   if (the_day == "ORA-07445:")
      {
      log_entry = substr($0,1,43)
      print date_rec " " log_entry
      }
   else
   if (the_day == "ORA-00600:")
      {
      log_entry = substr($0,1,43)
      print date_rec " " log_entry
      }
   else
      {
      log_entry = $0
      print date_rec " " log_entry
      }
}
