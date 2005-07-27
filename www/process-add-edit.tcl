ad_page_contract {

    Simple add/edit form for processs

    @author jader@bread.com
    @creation-date 2003-09-15
    @cvs-id $Id$

    @return context_bar Context bar.
    @return title Page title.

} {

    process_id:integer,optional
    {one_line ""}
    {description ""}
    {number_of_tasks:integer ""}

} -properties {

    context_bar:onevalue
    title:onevalue

}


# --------------------------------------------------------------- #
# the unique identifier for this package
set package_id [ad_conn package_id]
set user_id    [ad_maybe_redirect_for_registration]

# terminology and parameters
set project_term    [parameter::get -parameter "ProjectName" -default "Project"]
set project_term_lower  [parameter::get -parameter "projectname" -default "project"]

if { ![ad_form_new_p -key process_id] } {
    set process [db_string process_get { select one_line from pm_process where process_id = :process_id}]
    set title "Edit: $process"
    set context [list [list "processes" Processes] [list [export_vars -base "process" -url {process_id}] $process] "Edit"]
    # permissions
    permission::require_permission -party_id $user_id -object_id $package_id -privilege write
} else {
    set title "Add a Process"
    set context [list [list "processes" Processes] $title]
    # permissions
    permission::require_permission -party_id $user_id -object_id $package_id -privilege create
}


ad_form -name add_edit -form {
    process_id:key

    {one_line:text
        {label "Process"}
	{value $one_line}
        {html {size 40}}
    }

    {description:text(textarea),optional
	{label "Description"}
	{value $description}
	{html { rows 5 cols 40 wrap soft}}}

} -select_query_name process_query -on_submit {

    set party_id      [ad_conn user_id]
    set creation_date [db_string get_today { }]

} -new_data {
    set process_id [db_nextval pm_process_seq]

    db_dml new_process { *SQL* }

    ad_returnredirect -message "Process added. Now add a process task." [export_vars -base process-task -url { process_id}]
    ad_script_abort

} -edit_data {

    db_dml edit_process { *SQL* }

} -after_submit {

    ad_returnredirect -message "Process changes saved." [export_vars -base process -url {process_id}]
    ad_script_abort
}


