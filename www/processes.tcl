ad_page_contract {

    Main view page for projects.

    @author jader@bread.com, ncarroll@ee.usyd.edu.au
    @creation-date 2003-05-15
    @cvs-id $Id$

    @return title Page title.
    @return context Context bar.
    @return projects Multirow data set of projects.
    @return task_term Terminology for tasks
    @return task_term_lower Terminology for tasks (lower case)
    @return project_term Terminology for projects
    @return project_term_lower Terminology for projects (lower case)
} {
    {assignee_id:integer ""}
} -properties {
    context:onevalue
    processes:multirow
    write_p:onevalue
    create_p:onevalue
    admin_p:onevalue
}

if { [exists_and_not_null assignee_id] } {
    set cancel_url [export_vars -base "/tasks/contact" -url {{party_id $assignee_id}}]
}
# --------------------------------------------------------------- #

# set up context bar
set context_bar [list "Processes"]

# the unique identifier for this package
set package_id [ad_conn package_id]
set user_id    [ad_maybe_redirect_for_registration]

# permissions
permission::require_permission -party_id $user_id -object_id $package_id -privilege read

set write_p  [permission::permission_p -object_id $package_id -privilege write] 
set create_p [permission::permission_p -object_id $package_id -privilege create]
set admin_p [permission::permission_p -object_id $package_id -privilege admin]

set title "Manage Processes"
set context [list $title]
set actions [list "Add Process" [export_vars -base process-add-edit {assignee_id}] "Add a Process"]
if {[exists_and_not_null assignee_id]} {
    lappend actions "Cancel" "$cancel_url" "Cancel"
}


if {$admin_p} {
    set mode admin
} else {
    set mode normal
}

template::list::create \
    -name processes \
    -multirow processes \
    -key item_id \
    -pass_properties { admin_p } \
    -selected_format $mode \
    -elements {
	assign {
	    label ""
	    display_template {
                <a href="@processes.assign_url@" class="button">Assign</a>
	    }
	}
	title {
	    label "Title"
	    display_template {
		<if @admin_p@ eq 1><a href="@processes.process_url@"></if>
		@processes.title@
		<if @admin_p@ eq 1></a></if>
	    }
	}
	description {
	    label "Description"
	}
	instances {
	    label "Times used"
	    display_template {
		@processes.instances@
	    }
	}
	creator_name {
	    label "Manager"
	    link_url_eval $creator_url
	}
	edit {
	    display_template {
		<a href="@processes.process_url@"><img src="/resources/acs-subsite/Edit16.gif" width="16" height="16" border="0"></a>
	    }
	}
	delete {
	    display_template {
		<a href="@processes.delete_url@"><img src="/resources/acs-subsite/Delete16.gif" width="16" height="16" border="0"></a>
	    }
	}
    } -actions $actions \
    -filters {
        orderby_process {}
    } \
    -orderby {
        title {orderby title}
        default_value title,desc
    } \
    -orderby_name orderby_project \
    -sub_class {
        narrow
    } -formats {
	normal {
	    label "Assign Layout"
	    layout table 
	    row {
                assign {}
		title {}
		description {}
		creator_name {}
	    }
	}
	admin {
	    label "Admin Layout"
	    layout table 
	    row {
		assign {}
		title {}
		description {}
		creator_name {}
		instances {}
		edit {}
		delete {}
	    }
	}
    }

db_multirow -extend { delete_url creation_date creator_url process_url assign_url} processes process_query {
} {
    set delete_url [export_vars -base "process-delete" {process_id assignee_id}]
    set creation_date [lc_time_fmt $creation_date_ansi "%x"]
    set creator_url [acs_community_member_url -user_id $creation_user]
    set process_url [export_vars -base process -url {process_id assignee_id}]
    if { [exists_and_not_null assignee_id] } {
	set assign_url [export_vars -base process-assign -url {assignee_id process_id}]
    } else {
	set assign_url $process_url
    }
}
