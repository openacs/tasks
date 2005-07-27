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
    task_term:onevalue
    task_term_lower:onevalue
    project_term:onevalue
    project_term_lower:onevalue
}

if { [exists_and_not_null assignee_id] } {
    set cancel_url [export_vars -base "/tasks/contact" -url {{party_id $assignee_id}}]
}
# --------------------------------------------------------------- #

# terminology
set task_term       [parameter::get -parameter "TaskName" -default "Task"]
set task_term_lower [parameter::get -parameter "taskname" -default "task"]
set project_term    [parameter::get -parameter "ProjectName" -default "Project"]
set project_term_lower [parameter::get -parameter "projectname" -default "project"]

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

# root CR folder
# set root_folder [db_string get_root "select pm_project__get_root_folder (:package_id, 'f')"]

# Processes, using list-builder ---------------------------------
if { [exists_and_not_null assignee_id] } {
    set mode "assign"
    set title "Assing Process"
    set content [list $title]
#    set actions [list "Manage Processes" "processes" "Manage Processes"]
    set actions ""
} else {
    set mode "manage"
    set title "Manage Processes"
    set context [list $title]
    set actions [list "Add Process" "process-add-edit" "Add a Process"]
}

set elements ""

    

template::list::create \
    -name processes \
    -multirow processes \
    -key item_id \
    -selected_format $mode \
    -elements {
	assign {
	    label ""
	    display_template {
                <a href="@processes.assign_url@" class="button">Assign</a>
	    }
	}
	one_line {
	    label "Subject"
	    display_template {
		<if @processes.mode@ eq manage><a href="@processes.process_url@"></if>
		@processes.one_line@
		<if @processes.mode@ eq manage></a></if>
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
	owner_name {
	    label "Manager"
	    link_url_eval $owner_url
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
        one_line {orderby one_line}
        default_value one_line,desc
    } \
    -orderby_name orderby_project \
    -sub_class {
        narrow
    } \
    -html {
        width 100%
    } -formats {
	assign {
	    label "Assign Layout"
	    layout table 
	    row {
                assign {}
		one_line {}
		description {}
		owner_name {}
	    }
	}
	manage {
	    label "Assign Layout"
	    layout table 
	    row {
		edit {}
		one_line {}
		description {}
		owner_name {}
		instances {}
		delete {}
	    }
	}
    }

set mode_carryover $mode
db_multirow -extend { delete_url creation_date owner_url process_url assign_url mode } processes process_query {
} {
    set mode $mode_carryover
    set delete_url [export_vars -base "process-delete" {process_id}]
    set creation_date [lc_time_fmt $creation_date_ansi "%x"]
    set owner_url [acs_community_member_url -user_id $party_id]
    set process_url [export_vars -base process -url {process_id}]
    if { [exists_and_not_null assignee_id] } {
	set assign_url [export_vars -base process-assign -url {assignee_id process_id}]
    } else {
	set assign_url $process_url
    }
}


# ------------------------- END OF FILE ------------------------- #
