# Usage:
# <include
#        src="/packages/tasks/lib/tasks"
#        party_id="@party_id@"
#        elements="deleted_p priority title process_title contact_name date assignee contact_name"
#        hide_form_p="t"
#        page="@page@"
#        tasks_orderby="@tasks_orderby@"
#        page_flush_p="0"
#        page_size="15"
#        format="@format@"
#        show_filters_p="0" />
#
# elements       The name of the elements to display in the list.
# page           For pagination
# page_flush     For pagination
# page_size      How many rows are we going to show
# order_by       For the order_by clause
# format         The display format of the list. Normal
# emp_f          Filter to specify if you are going to show the tasks of the organizations only (1) or
#                or also the employess tasks (2), default to 2.
# show_filters_p Boolean to specify if you want to show the filters menu or not. Default to 0

foreach optional_param {party_id query search_id tasks_interval page page_size page_flush_p elements} {
    if {![info exists $optional_param]} {
	set $optional_param {}
    }
}

set tasks_url "/tasks/"

set row_list [list]
foreach element $elements {
    lappend row_list $element
    lappend row_list {}
}

if { ![exists_and_not_null format] } {
    set format "normal"
}

if { ![exists_and_not_null show_filters_p] } {
    # Boolean to especify to show the filters or not
    set show_filters_p 0
}

if { ![exists_and_not_null emp_f] } {
    # Show tasks of the employees
    set emp_f 2
}

# If we are not viewing the tasks of a party, view the tasks of the user
if {![exists_and_not_null party_id]} {

    # the user_id is used for the filter. user_id2 for comparison
    if {![exists_and_not_null user_id]} {
	set user_id [ad_conn user_id]
    }
    set contact_id $user_id
    set user_id2 $user_id
    if {$user_id == [ad_conn user_id]} {
	set user_id2 ""
    }
    set party_id ""
    unset party_id
    set page_query_name own_tasks_pagination
    set query_name own_tasks
} else {
    set contact_id $party_id 
    set user_id2 ""
    set page_query_name contact_tasks_pagination
    set query_name contact_tasks
}

set package_id [apm_package_id_from_key tasks]

if { ![exists_and_not_null tasks_interval] } {
    set tasks_interval 7
}
if { ![exists_and_not_null orderby] } {
    set orderby "priority,desc"
}
if { ![exists_and_not_null status_id] } {
    set status_id "1"
}
if { ![exists_and_not_null package_id] } {
    set package_id [ad_conn package_id]
}

if {[exists_and_not_null search_id]} {
    set group_where_clause ""
} else {
    set group_where_clause "and group_distinct_member_map.group_id = [contacts::default_group]"
}

set filters_list [list user_id [list where_clause "t.assignee_id = :user_id"] \
		      search_id {} \
		      query {} \
		      page_size {} \
		      tasks_interval {} \
		      party_id {} \
		      process_instance {}]

# We are going to verify if the party_id is an organization
# if it is, then we would retrieve the tasks also of the 
# employees of the organization.

set employee_where_clause "and t.party_id = :party_id"
if { [apm_package_installed_p organizations] && [exists_and_not_null contact_id]} {
    set org_p [organization::organization_p -party_id $contact_id]
    if { $org_p } {
        lappend filters_list emp_f {
            label "[_ tasks.Tasks_Assigned_to]"
            values { {"[_ tasks.Organization]" 1} { "[_ tasks.Employees]" 2 }}
        }
    }

    if { $org_p && [string equal $emp_f 2] } {
        set emp_list [contact::util::get_employees -organization_id $contact_id]
        lappend emp_list $contact_id
        set employee_where_clause " and t.party_id in ([template::util::tcl_to_sql_list $emp_list])"
    }
}

set done_url [export_vars -url -base "${tasks_url}contact" {orderby {status_id 2} {party_id $contact_id}}]
set not_done_url [export_vars -url -base "${tasks_url}contact" {orderby {status_id 1} {party_id $contact_id}}]
set return_url "[ad_conn url]?[ad_conn query]"
set add_url [export_vars -base "${tasks_url}task" {return_url orderby status_id {party_id $contact_id}}]
# set bulk_actions [list "[_ tasks.Reassign]" "${tasks_url}reassign-task" "[_ tasks.Reassign_selected]"\
		      "[_ tasks.Change_Assignee]" "${tasks_url}change-assignee" "[_ tasks.Change_Assignee]"]
set bulk_actions [list "[_ tasks.Change_Assignee]" "${tasks_url}change-assignee" "[_ tasks.Change_Assignee]"]

template::list::create \
    -name tasks \
    -multirow tasks \
    -bulk_actions $bulk_actions \
    -bulk_action_method post \
    -bulk_action_export_vars { } \
    -selected_format $format \
    -key task_id \
    -orderby_name tasks_orderby \
    -page_size $page_size \
    -page_flush_p 0 \
    -page_query_name $page_query_name \
    -elements {
        deleted_p {
	    label {<img src="/resources/acs-subsite/checkboxchecked.gif" alt="[_ tasks.Not_Done]" border="0" height="13" width="13">}
	    display_template {
		<if @tasks.done_p@><img src="/resources/acs-subsite/checkboxchecked.gif" alt="[_ tasks.Done]" border="0" height="13" width="13"></img></if>
                <else><a href="@tasks.complete_url@"><img src="/resources/acs-subsite/checkbox.gif" alt="[_ tasks.Not_Done]" border="0" height="13" width="13"></img></a></else>
	    }
	}
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
        contact_name {
	    label "[_ tasks.Contact]"
	    link_url_eval $contact_url
	} 
        date {
	    label "[_ tasks.Date]"
	    display_template {
		<if @tasks.done_p@><span class="done">@tasks.completed_date;noquote@</span></if>
                <else>
		  <if @tasks.due_date@>
		<a href="@tasks.task_minus_url@" style="text-decoration: none; font-weight: bold;">&laquo;</a>&nbsp;<if @tasks.due_date_passed_p@><span style="color: red;"></if>@tasks.due_date;noquote@<if @tasks.due_date_passed_p@></span></if>&nbsp;<a href="@tasks.task_plus_url@" style="text-decoration: none; font-weight: bold;">&raquo;</a>
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
            orderby_asc "lower(contact__name(.assignee_id)) asc, t.due_date asc, t.priority, lower(t.title)"
	    default_direction asc
	}
    } -formats {
	normal {
	    label "Table"
	    layout table
	    row $row_list
	}
    }

db_multirow -extend {assignee_url contact_url complete_url done_p task_plus_url task_minus_url description_html task_url} -unclobber tasks $query_name {} {
    set contact_url [contact::url -party_id $party_id]
    set assignee_url [contact::url -party_id $assignee_id]
    regsub -all "/tasks/" $assignee_url "/contacts/" assignee_url
    set complete_url [export_vars -base "${tasks_url}mark-completed" -url {task_id orderby {party_id $contact_id} return_url}]
    if { $status_id == "2" } {
	set done_p 1
    } else {
	set done_p 0
    }
    set task_url [export_vars -base "${tasks_url}task" -url {{party_id $contact_id} orderby status_id task_id}]
    set task_plus_url  [export_vars -base "${tasks_url}task-interval" -url {{action plus}  {days 7} {party_id $contact_id} task_id status_id orderby return_url}]
    set task_minus_url [export_vars -base "${tasks_url}task-interval" -url {{action minus} {days 7} {party_id $contact_id} task_id status_id orderby return_url}]

    regsub -all "\r|\n" $description {LiNeBrEaK} description

    set description_html [ad_html_text_convert \
			      -from $mime_type \
			      -to "text/html" \
			      -truncate_len "400" \
			      -more "<a href=\"${task_url}\">[_ tasks.more]</a>" \
			      -- $description]
    regsub -all {LiNeBrEaKLiNeBrEaK} $description_html {LiNeBrEaK} description_html
    regsub -all {LiNeBrEaK} $description_html {\&nbsp;\&nbsp;\&#182;\&nbsp;} description_html
	regsub -all " " $due_date {\&nbsp;} due_date
	regsub -all " " $completed_date {\&nbsp;} completed_date
}
