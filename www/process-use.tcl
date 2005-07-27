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

    project_item_id:integer,notnull

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

# --------------------------------------------------------------- #

set user_id    [ad_maybe_redirect_for_registration]
set package_id [ad_conn package_id]

# terminology
set project_term    [parameter::get -parameter "ProjectName" -default "Project"]
set task_term       [parameter::get -parameter "TaskName" -default "Task"]
set task_term_lower [parameter::get -parameter "taskname" -default "task"]
set use_uncertain_completion_times_p [parameter::get -parameter "UseUncertainCompletionTimesP" -default "1"]


set title "Use a process"
set context_bar [ad_context_bar [list "processes" "Processes"] "Use"]


# need to change this to show all the projects you're on by
# default, and then give you the option of selecting all projects
# as an option.

set select_widget_name process_id
set select_widget "<select name=\"$select_widget_name\">"


db_foreach select_a_process { } -column_array process {
    append select_widget "<option value=\"$process(process_id)\">$process(one_line)</option>"
}
append select_widget "</select>"

set form_definition_beg "<form action=\"task-add-edit\" method=\"post\">"

append form_definition_beg [export_vars -form {project_item_id}]
set form_definition_end "</form>"

