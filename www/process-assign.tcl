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
    {object_id:integer,optional ""}
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


db_1row get_process {
    select title as process, workflow_id
    from t_processes
    where process_id = :process_id
}

db_transaction {

    set case_id [db_nextval acs_object_id_seq]

    set instance_id [tasks::process::instance::new \
			 -process_id $process_id \
			 -case_id $case_id \
			 -party_id $assignee_id \
			 -object_id $object_id]

    workflow::case::new -no_notification \
	-case_id $case_id \
	-workflow_id $workflow_id \
	-object_id $instance_id
}

ad_returnredirect [export_vars -base "contact" -url {{party_id $assignee_id}}]
