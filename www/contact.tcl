ad_page_contract {

    Main view page for tasks.

    @author jader@bread.com
    @creation-date 2003-12-03
    @cvs-id $Id$

    @return title Page title.
    @return context Context bar.
    @return tasks Multirow data set of tasks
    @return task_term Terminology for tasks
    @return task_term_lower Terminology for tasks (lower case)
    @return project_term Terminology for projects
    @return project_term_lower Terminology for projects (lower case)

    @param mine_p is used to make the default be the user, but
    still allow people to view everyone.

} {
    {orderby ""}
    {party_id ""}
    {searchterm ""}
    {mine_p "t"}
    {status_id "1"}
    {process_instance:integer,optional}
} -properties {
    task_term:onevalue
    context:onevalue
    tasks:multirow
    hidden_vars:onevalue
}

set user_id [ad_conn user_id]
set package_id [ad_conn package_id]
set admin_p [permission::permission_p -object_id $package_id -privilege admin]
set context {}
