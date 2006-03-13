ad_page_contract {

    @author Matthew Geddert (openacs@geddert.com)
    @creation-date 2006-03-12
    @cvs-id $Id$

} {
    {party_id:integer,multiple}
    {return_url}
    {process_id:integer ""}
} -validate {
    valid_process -requires {process_id} {
	if { $process_id ne "" } {
	    set package_id [ad_conn package_id]
	    if { ![db_0or1row process_exists {}] } {
		ad_complain [_ tasks.Process_id_not_valid]
	    }
	}
    }
}

set title [_ tasks.Add_Process]
set context [list $title]
set package_id [ad_conn package_id]

set assigneees [list]
foreach party $party_id {
    contact::require_visiblity -party_id $party
    if { $process_id ne "" } {
	lappend assignees [contact::name -party_id $party]
    } else {
	lappend assignees [contact::link -party_id $party]
    }
}
set assignees [join $assignees ", "]

if { $process_id ne "" } {
    set process [db_string get_process_title {}]
    ad_progress_bar_begin \
	-title [_ tasks.Assigning_-process-] \
	-message_1 [_ tasks.lt_Assigning_-process-_to_-assignees-] \

    foreach party $party_id {
	tasks::process::assign -object_id $party -process_id $process_id
    }
    ad_progress_bar_end -url ${return_url}
}



template::list::create \
    -name processes \
    -multirow processes \
    -elements {
	assign {
	    label ""
	    display_template {
		<a href="@processes.assign_url@" class="button">Assign</a>
	    }
	}
	title {
	    label "Title"
	}
	description {
	    label "Description"
	}
	creator_name {
	    label "Manager"
	    link_url_eval $creator_url
	}
    } -filters {}

db_multirow -extend { creator_url assign_url} -unclobber processes processes {} {
    set creator_url [tasks::object_url -object_id $creation_user]
    set assign_url [export_vars -base [ad_conn url] -url {party_id:multiple process_id return_url}]
}

ad_return_template
