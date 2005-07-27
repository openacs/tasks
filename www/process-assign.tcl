ad_page_contract {

    Page to get the process if one is missing for task creation

    @author jader@bread.com
    @creation-date 2003-10-08
    @cvs-id $Id$

    @return context_bar Context bar.
    @return title Page title.
    @return projects A multirow containing the list of projects

    @param process_id The process we're using to create this task
} {
    {process_id:integer,notnull}
    {assignee_id:integer,notnull}
} -properties {

    context_bar:onevalue
    title:onevalue
    select_widget:onevalue
    select_widget_name:onevalue
    form_definition_beg:onevalue
    form_definition_end:onevalue

} -validate {
} -errors {
}


set process [db_string get_rpocess { select one_line from pm_process where process_id = :process_id }]
set project_id [tasks::project_id]
set instance_id [pm::process::instantiate -process_id $process_id -project_item_id $project_id -name $process]

db_transaction {

db_foreach task_in_process {
    select *,
           CASE WHEN due_date is null and due_interval is null THEN ''::varchar ELSE
                   CASE WHEN due_date is not null THEN to_char(due_date,'YYYY-MM-DD') ELSE
                     to_char((now()+due_interval),'YYYY-MM-DD')
                   END
           END as end_date
      from pm_process_task, tasks_pm_process_task
     where process_id = :process_id
       and pm_process_task.process_task_id = tasks_pm_process_task.process_task_id 
} {

            set task_id [pm::task::new -project_id ${project_id} \
                         -process_instance_id $instance_id \
			 -title ${one_line} \
			 -description ${description} \
                         -mime_type ${mime_type} \
			 -end_date ${end_date} \
			 -percent_complete "0" \
			 -creation_user [ad_conn user_id] \
			 -creation_ip [ad_conn peeraddr] \
			 -package_id [ad_conn package_id] \
			 -priority ${priority}]
	pm::task::assign -task_item_id $task_id -party_id $assignee_id

	    set task_url [export_vars -base task -url {task_id status_id orderby {party_id $assignee_id}}]
	util_user_message -html -message "The task <a href=\"/tasks/${task_url}\">$one_line</a> was added with a due date of $end_date"

}
}


ad_returnredirect [export_vars -base "contact" -url {{party_id $assignee_id}}]
