# Usage:
# <include
#        src="/packages/tasks/lib/tasks"
#        party_id="@party_id@"
#        elements="deleted_p priority title process_title contact_name date assignee contact_name"
#        hide_form_p="t"
#        page="@page@"
#        tasks_orderby="@tasks_orderby@"
#        tasks_previous="@tasks_previous@"
#        tasks_future="@tasks_future@"
#        page_flush_p="0"
#        page_size="15"
#        format="@format@"
#        show_filters_p="0" />
#
# elements       The name of the elements to display in the list.
# page           For pagination
# page_flush     For pagination
# page_size      How many rows are we going to show
# tasks_previous Filter for tasks in the past in days
# tasks_future   Filter for tasks in the future in days
# status_id ...

# hide_elements  List the template::list elements you don't want displated. if checkbox is listed bulk actions will be disabled for this include

set url [ad_conn url]
if { ![exists_and_not_null package_id] } { 
    set package_id [ad_conn package_id]
}
set package_url [apm_package_url_from_id $package_id]
set optional_params {start_date end_date page_size hide_elements default_assignee_id}
set required_params {object_query object_ids object_id assignee_query assignee_ids assignee_id}
set special_params {task_action_id task_action party_id process_id}
set ad_form_params {__confirmed_p __refreshing_p __key_signature __new_p}
set task_form_vars [concat [ns_queryget task_form_vars] task_form_vars]

set filters_list [list]
set page_elements [list]
set submitted_vars [tasks::get_submitted_as_list]
foreach {key value} $submitted_vars {
    # we only pass on vars that cannot be submitted by the include
    # this way somebody cannot pass a variable via the http request
    # what is hard coded by the include by the programmer
    if { [lsearch [concat $required_params $special_params $ad_form_params $task_form_vars] $key] < 0 && [string is false [regexp {^formbutton:} $key match]] } {
	# the variable is not expected to be submitted via
        # the include statement, so we can set this variable
	
	# we have one special variable, namely task_id
        # because it is able to used with bulk actions
        # if the key is task_id, we check it the variable
        # already exists and it it does we add it as a list
        # otherwise we just overrite the previous key with
        # the new one

	if { $key == "task_id" && [exists_and_not_null task_id] } {
	    lappend task_id $value
	} else {
	    set $key $value
	}
	if { $key ne "return_url" } {
	    lappend page_elements $key
	}
	if { [lsearch [list groupby orderby format page status_id] $key] < 0 } {
	    # the variable is not a reserved filter name
	    lappend filters_list $key {}
	}
    }
}

if { ![exists_and_not_null return_url] } {
    set return_url [export_vars -base $url -url $page_elements]
}
set add_url [export_vars -base $url -url [concat $page_elements {{task_action add}}]]
set add_process_url [export_vars -base $url -url [concat $page_elements {{task_action add_process}}]]


foreach optional_param [concat $optional_params $special_params] {
    if {![info exists $optional_param]} {
	set $optional_param {}
    }
}

set export_vars_list [list]
foreach page_element [concat $page_elements $special_params] {
    lappend export_vars_list $page_element [set $page_element]
}


if { ![exists_and_not_null page_size] } {
    # The default page size for tasks
    set page_size "25"
}

if { ![exists_and_not_null show_filters_p] } {
    # Boolean to specify to show the filters or not
    set show_filters_p 0
}






set limitations_clause ""

# we require one of the following:
#
# 1. object_query - an sql query which returns all valid object_ids for which to display tasks
#   or
# 2. object_ids - a tcl list of object_ids for which to display tasks
#   or
# 3. object_id - an object_id for which to display tasks
#
# only one can be provided to be valid. If none are provided the only
# other valid option is to specify specific assignees
if { 
    ( [info exists object_query] && ![info exists object_ids] && ![info exists object_id] ) ||
    ( ![info exists object_query] && [info exists object_ids] && ![info exists object_id] ) ||
    ( ![info exists object_query] && [info exists object_ids] && ![info exists object_id] ) 
} {
    # we only have one provided object_id list, this is correct set up
} else {
#    error "packages/tasks/lib/tasks - invalid include you must specify one (and only one) of the following: object_query, object_ids, object_id :: $object_id"
}

set single_object_p 0
if { [info exists object_ids] } {
    set object_query [template::util::tcl_to_sql_list $object_ids]
} elseif { [info exists object_id] } {
    set single_object_p 1
    set object_query '$object_id'
}

append limitations_clause "\n and t.object_id in ( $object_query )"


append limitations_clause "\n and ao.package_id = $package_id"

if { $start_date ne "" } {
    append limitations_clause "\n and CASE WHEN t.status_id <> '2' THEN t.due_date::date ELSE t.completed_date::date END >= '$start_date'::date"
}

if { $end_date ne "" } {
    append limitations_clause "\n and CASE WHEN t.status_id <> '2' THEN t.due_date::date ELSE t.completed_date::date END <= '$end_date'::date"
}






# before doing anything we check for the special vars task_action and task_action_id
# these actions are performed here because it requires less code to maintain just this
# one page, instead of routing to specialized pages.
# 
# we are also able to verify that this user is in fact able to perform this action
# with this task here on this page much more simply that on a secondary trigger page

set task_action [ns_queryget task_action]
set task_action_id [ns_queryget task_action_id]
set show_form_p 0
if { $task_action ne "" && $task_action_id ne "" && [string is integer $task_action_id] } {
    # somebody is attempting to perform an action on the tasks.
    # we need to first validate that this task is in fact accessible
    # to this user through this page.
    if { [db_0or1row task_available_for_action {}] } {
	set task [tasks::task::title -task_id $task_action_id]
	set task_url [export_vars -base $url -url [concat $page_elements {{task_id $task_action_id} {task_action edit}}]]
	switch $task_action {
	    complete {
		tasks::task::complete -task_id $task_action_id
		set task_title $task
		util_user_message -html -message "[_ tasks.task_completed]"
	    }
	    interval_increase {
		tasks::task::modify_interval -task_id $task_action_id -method "increase"
		util_user_message -html -message  "[_ tasks.task_delayed]"
	    }
	    interval_decrease {
		tasks::task::modify_interval -task_id $task_action_id -method "decrease"
		util_user_message -html -message  "[_ tasks.task_moved_up]"
	    }
	    edit {
		set show_form_p 1
	    }
	}
	if { [exists_and_not_null edit_task_id] } {
	    # in order to prevent double-click errors we have to redirect back to this url
	    # above the return_url has already been cleaned for us.
	    ad_returnredirect $return_url
	    ad_script_abort
	}
    } else {
	# we can return a permissions error here if we want to
	# for now we will just display the page and silently
        # ignore this error
    }
} elseif { $task_action eq "add" } {
    set show_form_p 1
} elseif { $task_action eq "add_process" } {

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
	set assign_url [export_vars -base $url -url [concat $page_elements {process_id {task_action assign_process}}]]
    }

} elseif { $task_action eq "assign_process" && [ns_queryget process_id] ne "" } {
    set process_id [ns_queryget process_id]
    tasks::require_belong_to_package -objects $process_id 


    tasks::process::assign -object_id $object_id -process_id $process_id
    #		util_user_message -html -message "[_ tasks.process_assigned]"
    ad_returnredirect $return_url
    ad_script_abort
}


if { [string is true $show_form_p] } {
    set page_flush_p 1
} else {
    set page_flush_p 1
#    set page_flush_p 0
}




# [template::list::filter_where_clauses -and -name tasks]


# and t.due_date between ( now() - '$tasks_previous days'::interval ) and ( now() + '$tasks_future days'::interval )

#           and t.status_id <> 2






#if { ![exists_and_not_null tasks_previous] } {
#    set tasks_previous 0
#}
#if { ![exists_and_not_null tasks_future] } {
#    set tasks_future 7
#}
#if { ![exists_and_not_null orderby] } {
#    set orderby "priority,desc"
#}
#if { ![exists_and_not_null status_id] } {
#    set status_id "1"
#}



# you may specify a list of assignees as well if you like, they are similar to the object
# queries and ids this is not required. You may only specify one of the following, assignee_query, assignee_ids, assignee_id
if { [info exists assignee_query] || [info exists assignee_ids] || [info exists assignee_id] } {
    if {
	( [info exists assignee_query] && ![info exists assignee_ids] && ![info exists assignee_id] ) ||
	( ![info exists assignee_query] && [info exists assignee_ids] && ![info exists assignee_id] ) ||
	( ![info exists assignee_query] && ![info exists assignee_ids] && [info exists assignee_id] ) 
    } {
	# we only have one provided object_id list, this is correct set up
    } else {
	error "packages/tasks/lib/tasks - invalid include you must specify one (and only one) of the following: assignee_query, assignee_ids, assignee_id"
    }

    if { [info exists assignee_query] || [info exists assignee_ids] } {
	# the users should be able to select from a list of assignees
	if { ![info exists assignee_query] } {
	    set assignee_query [template::util::tcl_to_sql_list $assignee_ids]
	}
	set selected_assignee_id [ns_queryget selected_assignee_id]
	set assignees [db_list_of_lists get_them " select contact__name( party_id ),
                                                          party_id
                                                     from parties
                                                    where party_id in ( $assignee_query )
                                                      and party_id in (
            select t_tasks.assignee_id
              from t_tasks
             where t_tasks.object_id in ( $object_query ))"]
	set filters_list [concat $filters_list [list selected_assignee_id [list label [_ tasks.Assignee] values [concat [list [list "- - - -" ""]] $assignees]]]]
    } else {
        set selected_assignee_id $assignee_id
    }
    if { [exists_and_not_null selected_assignee_id] } {
	set assignee_query '${selected_assignee_id}'
    } else {
	if { [info exists assignee_ids] } {
	    set assignee_query [template::util::tcl_to_sql_list $assignee_ids]
	} elseif { [info exists assignee_id] } {
	    set assignee_query '$assignee_id'
	}
    }

    if { [exists_and_not_null assignee_query] } {
	append limitations_clause "\n and t.assignee_id in ( $assignee_query )"
    }
}





set row_list [list]
foreach element [list checkbox deleted_p priority title process_title object_name employer_name date assignee] {
    if { $single_object_p && $element == "object_name" } {	
    } elseif { [lsearch $hide_elements $element] < 0 } {
	lappend row_list $element {}
    }
}


set status_options [db_list_of_lists status_options {}]
set status_options [lang::util::localize $status_options]
# by default we only show pending tasks
lappend filters_list status_id [list label [_ tasks.Status] values $status_options where_clause { t.status_id = :status_id } default_value "1"]

#lappend filters_list 
if { [lsearch $hide_elements checkbox] >= 0 } {
    set bulk_actions [list]
} else {
    set bulk_actions [list "[_ tasks.Change_Assignee]" "${package_url}tasks-change-assignee" "[_ tasks.Change_Assignee]"]
    lappend bulk_actions "[_ tasks.Delete]" "${package_url}tasks-delete" "[_ tasks.Delete]"
}

template::list::create \
    -name tasks \
    -multirow tasks \
    -bulk_actions $bulk_actions \
    -bulk_action_export_vars {return_url} \
    -key task_id \
    -selected_format "normal" \
    -orderby_name tasks_orderby \
    -page_size $page_size \
    -page_flush_p $page_flush_p \
    -page_query_name tasks_pagination \
    -elements {
        deleted_p {
	    label {<img src="/resources/acs-subsite/checkboxchecked.gif" alt="[_ tasks.Not_Done]" border="0" height="13" width="13">}
	    display_template {
		<if @tasks.done_p@><img src="/resources/acs-subsite/checkboxchecked.gif" alt="[_ tasks.Done]" border="0" height="13" width="13"></img></if>
                <else><a href="@tasks.complete_url@"><img src="/resources/acs-subsite/checkbox.gif" alt="[_ tasks.Not_Done]" border="0" height="13" width="13"></img></a></else>
	    }
	}
	status_id {}
        priority {
	    label "[_ tasks.Priority]"
	    display_template {
		<if @tasks.done_p@><span class="done">@tasks.priority@</span></if><else>@tasks.priority@</else>
	    }
	}
	title {
	    label "[_ tasks.Task]"
            display_template {
		<a href="@tasks.task_url@" title="@tasks.title@"<if @tasks.done_p@> class="done"</if>>@tasks.title@</a>
		<if @tasks.description@ not nil>
		<if @tasks.done_p@><div class="done"></if>
                <p style="padding: 0; margin: 0; font-size: 0.85em; padding-left: 2em;">
		@tasks.description_html;noquote@
		</p>
		<if @tasks.done_p@></div></if>
		</if>
	    }
	}
        process_title {
	    label "[_ tasks.Process]"
	    display_template {
		<if @tasks.done_p@><span class="done">@tasks.process_title@</span></if>
                <else>
		  <if @tasks.process_title@ not nil>@tasks.process_title@</if>
		</else>
	    }
	}
        object_name {
	    label "[_ tasks.Contact]"
	    link_url_eval $object_url
	} 
        employer_name {
	    label "[_ contacts.Customer]"
	    link_url_eval $object_url
	} 
        date {
	    label "[_ tasks.Date]"
	    display_template {
		<if @tasks.done_p@><span class="done">@tasks.completed_date;noquote@</span></if>
                <else>
		  <if @tasks.due_date@>
		<a href="@tasks.interval_decrease_url@" style="text-decoration: none; font-weight: bold;">&laquo;</a>&nbsp;<if @tasks.due_date_passed_p@><span style="color: red;"></if>@tasks.due_date;noquote@<if @tasks.due_date_passed_p@></span></if>&nbsp;<a href="@tasks.interval_increase_url@" style="text-decoration: none; font-weight: bold;">&raquo;</a>
                  </if>
                </else>
	    }
	}
	assignee {
	    label "[_ tasks.Assignee]"
	    display_template {
		<a href="@tasks.assignee_url@"<if @tasks.done_p@> class="done"</if>>@tasks.assignee_name@</a>
	    }
	}      
    } \
    -sub_class {
        narrow
    } \
    -filters $filters_list \
    -orderby {
        default_value "priority,desc"
        date {
            label "[_ tasks.Due]"
            orderby_desc "CASE WHEN t.status_id <> 2 THEN t.due_date ELSE t.completed_date END desc, t.priority, lower(t.title)"
            orderby_asc "CASE WHEN t.status_id <> 2 THEN t.due_date ELSE t.completed_date END asc, t.priority, lower(t.title)"
            default_direction desc
        }
        priority {
            label "[_ tasks.Priority]"
            orderby_desc "t.status_id, t.priority desc, CASE WHEN t.status_id <> 2 THEN t.due_date ELSE t.completed_date END desc, lower(t.title)"
            orderby_asc "t.status_id, t.priority asc, CASE WHEN t.status_id <> 2 THEN t.due_date ELSE t.completed_date END asc, lower(t.title)"
            default_direction desc
        }
        title {
            label "[_ tasks.Task]"
            orderby_desc "lower(t.title) desc, t.priority desc, t.due_date asc"
            orderby_asc "lower(t.title) asc, t.priority desc, t.due_date asc"
            default_direction asc
        }
        process_title {
	    label "[_ tasks.Process]"
            orderby_desc "lower(p.title) desc, t.priority desc, t.due_date asc"
            orderby_asc "lower(p.title) asc, t.priority desc, t.due_date asc"
	    default_direction asc
	}
	contact_name {
	    label "[_ tasks.Created_By]"
            orderby_desc "lower(contact__name(t.party_id)) desc, t.due_date asc, t.priority, lower(t.title)"
            orderby_asc "lower(contact__name(t.party_id)) asc, t.due_date asc, t.priority, lower(t.title)"
	    default_direction asc
	}
	assignee {
	    label "[_ tasks.Assignee]"
            orderby_desc "lower(contact__name(t.assignee_id)) desc, t.due_date asc, t.priority, lower(t.title)"
            orderby_asc "lower(contact__name(t.assignee_id)) asc, t.due_date asc, t.priority, lower(t.title)"
	    default_direction asc
	}
    } -formats {
	normal {
	    label "Table"
	    layout table
	    row $row_list
	}
    }


db_multirow -extend {assignee_url assignee_name employer_name object_url complete_url done_p interval_increase_url interval_decrease_url description_html task_url} -unclobber tasks tasks {} {

    set due_date [tasks::relative_date -date $due_date]
    set completed_date [tasks::relative_date -date $completed_date]

    set assignee_name [contact::name -party_id $assignee_id]
    set employer_name [lindex [lindex [contact::util::get_employers -employee_id $object_id] 0] 1]
    
    set object_url             [tasks::object_url -object_id $object_id -package_id $package_id]
    set assignee_url           [tasks::object_url -object_id $assignee_id -package_id $package_id]
    if { [apm_package_key_from_id $package_id] == "contacts" } {
       	set task_url               [export_vars -base ${object_url}tasks -url [concat $page_elements {{task_action_id $task_id} {task_action edit} return_url}]]
    } else {
	set task_url               [export_vars -base $url -url [concat $page_elements {{task_action_id $task_id} {task_action edit} return_url}]]
    }

    set complete_url           [export_vars -base $url -url [concat $page_elements {{task_action_id $task_id} {task_action complete}}]]
    set interval_increase_url  [export_vars -base $url -url [concat $page_elements {{task_action_id $task_id} {task_action interval_increase}}]]
    set interval_decrease_url  [export_vars -base $url -url [concat $page_elements {{task_action_id $task_id} {task_action interval_decrease}}]]

    if { $status_id == "2" } {
	set done_p 1
    } else {
	set done_p 0
    }

    if { $done_p } {
	set due_date $completed_date
    }

    regsub -all "\r" $description "\n" description
    while { [regsub -all "\n\n" $description "\n" description] } {}
    regsub -all "\n" $description {LiNeBrEaK} description

    set description_html [ad_html_text_convert \
			      -from $mime_type \
			      -to "text/html" \
			      -truncate_len "400" \
			      -more "<a href=\"${task_url}\">[_ tasks.more]</a>" \
			      -- $description]

    regsub -all {LiNeBrEaK} $description_html "\\&nbsp;\\&nbsp;\\&#182;\\&nbsp;" description_html
    regsub -all " " $due_date {\&nbsp;} due_date
    regsub -all " " $completed_date {\&nbsp;} completed_date
}
#ad_return_error "AS" "<pre>$limitations_clause</pre>"

ad_return_template
