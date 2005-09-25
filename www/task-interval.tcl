ad_page_contract {

    Simple add/edit form for projects

    @author jader@bread.com, ncarroll@ee.usyd.edu.au
    @creation-date 2003-05-15
    @cvs-id $Id$

    @return context_bar Context bar.
    @return title Page title.

} {
    {party_id:integer,notnull}
    task_id:integer
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
set title "Add/Edit"
set context [list $title]

db_1row get_task_info "
    select t.title as task, t.description, t.mime_type, t.priority,
           to_char((t.due_date $operand '$days days'::interval),'YYYY-MM-DD') as due_date,
           t.status_id as status, t.comment
      from t_tasks t
     where t.task_id = :task_id
    "

set task_id [tasks::task::edit \
		 -task_id ${task_id} \
		 -title ${task} \
		 -description ${description} \
		 -mime_type $mime_type \
		 -comment ${comment} \
		 -due_date ${due_date} \
		 -status_id ${status} \
		 -priority ${priority}]

set task_url [export_vars -base "/tasks/task" -url {task_id status_id orderby}]

if { $action == "minus" } {
    util_user_message -html -message "[_ tasks.task_moved_up]"
} else {
    util_user_message -html -message "[_ tasks.task_delayed]"
}


ad_returnredirect $return_url
ad_script_abort
