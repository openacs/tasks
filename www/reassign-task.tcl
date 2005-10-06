# packages/tasks/www/reassing-task.tcl

ad_page_contract {
    Reassigns checked tasks to another user
    @author Miguel Marin (miguelmarin@viaro.net)
    @author Viaro Networks www.viaro.net
    @creation-date 2005-10-06
} {
    {return_url ""}
    task_id:multiple
    reassign_party:optional
}

set user_id [ad_conn user_id]
set page_title "[_ tasks.Reassign_Tasks]"
set context [list $page_title]

if { ![exists_and_not_null $return_url] } {
    set return_url [get_referrer]
}

# To display the tasks in the ad_form 
set show_tasks [list]
if { [exists_and_not_null task_id] } {
    foreach task $task_id {
	lappend show_tasks "\#$task"
    }
    set show_tasks [join $show_tasks ", "]
}

# We get allt the posible users to reassign
# to use in the options of the select
set reassign_parties [db_list_of_lists get_all_users { }]

ad_form -name "reassign" -form {
    {task_id:text(hidden)
	{value $task_id}
    }
    {return_url:text(hidden)
	{value $return_url}
    }
    {show_tasks:text(text)
	{label "[_ tasks.Tasks]:"}
	{value  $show_tasks}
	{mode display}
    }
    {reassign_party:text(search)
	{label "[_ tasks.Reassign]:"}
	{options { $reassign_parties}}
	{help_text "[_ tasks.Select_the_user]"}
    }
} -on_submit {

    # We are going to reassign the all the checked tasks to the new party_id
    foreach task $task_id {
	# We need to change the party_id in t_tasks table to reassign the task
	db_dml update_t_tasks { }
    }

} -after_submit {
    ad_returnredirect $return_url
}