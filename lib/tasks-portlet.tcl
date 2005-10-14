foreach optional_param {party_id query search_id tasks_interval} {
    if {![info exists $optional_param]} {
	set $optional_param {}
    }
}

set portlet_layout [parameter::get -parameter "DefaultPortletLayout"]