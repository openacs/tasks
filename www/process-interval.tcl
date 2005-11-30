ad_page_contract {

    Simple add/edit form for projects

    @author jader@bread.com, ncarroll@ee.usyd.edu.au
    @creation-date 2003-05-15
    @cvs-id $Id$

    @return context_bar Context bar.
    @return title Page title.

} {
    {party_id:integer,notnull}
    process_instance:integer,optional
    status_id:integer,optional
    orderby:optional
    {return_url ""}
    action
    days:integer
} -properties {
}

if { $days != "7" } {
    set days 7
}


if { ![exists_and_not_null return_url] } {
    set return_url [export_vars -base "contact" -url {party_id orderby status_id}]
}
if { $action == "minus" } {
    set operand "-"
} else {
    set operand "+"
}

set package_id [ad_conn package_id]
set user_id    [ad_maybe_redirect_for_registration]
set peeraddr   [ad_conn peeraddr]
set project_id [tasks::project_id]

set title "Add/Edit"
set context [list $title]

set interval_number 1
db_foreach get_tasks {
    select pt.task_id
      from pm_tasks pt, cr_items ci, cr_revisions cr, pm_tasks_revisions ptr
     where pt.process_instance = :process_instance
       and pt.deleted_p != 't'
       and pt.status = '1'
       and pt.task_id = ci.item_id
       and ci.live_revision = cr.revision_id
       and cr.revision_id = ptr.task_revision_id
       and ptr.end_date is not null
     order by ptr.end_date
} {

    db_1row get_task_info "
    select ci.item_id as task_id,
           cr.title as task,
           to_char((ptr.end_date $operand '[expr $days * $interval_number] days'::interval),'YYYY-MM-DD') as end_date,
           ptr.percent_complete,
           ptr.priority,
           cr.description
      from pm_tasks_revisions ptr,
           cr_revisions cr,
           cr_items ci
     where ci.item_id = :task_id
       and ci.latest_revision = ptr.task_revision_id
       and ci.live_revision = ptr.task_revision_id
       and ptr.task_revision_id = cr.revision_id
    "
    if { $percent_complete >= "100" } {
	set completed_p "1"
    }
    if {$percent_complete >= 100} {
	set task_status_id [pm::task::default_status_closed]
    } elseif {$percent_complete < 100} {
	set task_status_id [pm::task::default_status_open]
    }
    set task_item_id $task_id
    set project_item_id $project_id
    set title $task
    set mime_type "text/plain"
    set estimated_hours_work ""
    set estimated_hours_work_min ""
    set estimated_hours_work_max ""
    set actual_hours_worked ""
    set update_user $user_id
    set update_ip $peeraddr
    
    db_exec_plsql new_task_revision "
    select pm_task__new_task_revision (
				       :task_item_id,
				       :project_item_id,
				       :title,
				       :description,
				       :mime_type,
				       [pm::util::datenvl -value $end_date -value_if_null "null" -value_if_not_null ":end_date"],
				       :percent_complete,
				       :estimated_hours_work,
				       :estimated_hours_work_min,
				       :estimated_hours_work_max,
				       :actual_hours_worked,
				       :task_status_id,
				       current_timestamp,
				       :update_user,
				       :update_ip, 
				       :package_id,
				       :priority)
    "
    
    incr interval_number


}

if { $action == "minus" } {
    util_user_message -html -message "The process interval was decreased by $days days"
} else {
    util_user_message -html -message "The process interval was increased by $days days"
}

ad_returnredirect $return_url
ad_script_abort
