set portlet_layout [parameter::get -parameter "DefaultPortletLayout"]

if { ![info exists start_date] } { set start_date {} }
if { ![info exists end_date] } { set end_date {} }
