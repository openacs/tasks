ad_page_contract {
    Main view page for one process

    @author jader@bread.com
    @creation-date 2003-09-25
    @cvs-id $Id$

    @param process_id The process we're looking at.

    @return process_id the id for the process
    @return context_bar Context bar.
    @return use_link the link to use this process

} {

    process_id:integer,notnull
    orderby:optional
    {project_item_id ""}
    
} -properties {
    process_id:onevalue
    context_bar:onevalue
    use_link:onevalue
} -validate {
} -errors {
    process_id:notnull {You must specify a process to use. Please back up and select a process}
}

# --------------------------------------------------------------- 

# the unique identifier for this package
set package_id [ad_conn package_id]
set user_id    [ad_maybe_redirect_for_registration]

# permissions
permission::require_permission -party_id $user_id -object_id $package_id -privilege read

set write_p  [permission::permission_p -object_id $package_id -privilege write] 
set create_p [permission::permission_p -object_id $package_id -privilege create]

set use_uncertain_completion_times_p [parameter::get -parameter "UseUncertainCompletionTimesP" -default "1"]

# set up context bar, needs parent_id

db_1row get_process_info { select * from pm_process where process_id = :process_id }
set title $one_line
set context [list [list processes "Processes"] $title]

set use_link "<a href=\"[export_vars -base task-select-project {process_id project_item_id}]\"><img border=\"0\" src=\"/shared/images/go.gif\"></a>"


set elements \
    [list \
         priority {
	     label "Priority"
	 } \
         one_line {
             label "Subject"
             display_template {<a href="process-task?process_id=[set process_id]&process_task_id=@tasks.process_task_id@">@tasks.task@</a>
             }
         } \
         deadline {
	     label "Due"
	     display_template {
		 <if @tasks.due_interval@ not nil>@tasks.due_interval@ after assignment</if>
		 <if @tasks.due_date@ not nil>@tasks.pretty_due_date@</if>
	     }
	 } \
	]    


# Process tasks, using list-builder ---------------------------------
template::list::create \
    -name tasks \
    -multirow tasks \
    -key process_task_id \
    -elements $elements \
    -actions [list \
		  "Add Process Task" [export_vars -base process-task -url {process_id}] "Add Process Task" \
		  "Edit Process" [export_vars -base process-add-edit -url {process_id}] "Edit Process Title/Description" \
		  "Delete Process" [export_vars -base process-delete -url {process_id}] "Delete this Process" \
		  "Cancel" "processes" "Return to all processes" \
		 ] \
    -orderby {
        default_value ordering,desc
        ordering {
            label "Order"
            orderby_asc "tp.priority asc, tp.due_date, tp.due_interval, upper(pm.one_line)"
            orderby_desc "tp.priority desc, tp.due_date, tp.due_interval, upper(pm.one_line)"
            default_direction desc
        }
    } \
    -bulk_actions {
        "Delete" "process-task-delete" "Delete tasks"
    } \
    -bulk_action_export_vars {
        process_id
        project_item_id
    } \
    -sub_class {
        narrow
    } \
    -filters {
        process_id {}
    } \
    -html {
        width 100%
    }


db_multirow -extend { item_url } tasks task_query {
} {
}

