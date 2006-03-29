# /packages/tasks/task-form
#
# @author Matthew Geddert

set required_params [list object_id return_url standard_tasks_list]
foreach required_param $required_params {
    if { [info exists $required_param] } {
	set $required_param [set $required_param]
    } else {
	set $required_param [ns_queryget $required_param]
    }
    if { $required_param eq "" } {
	ad_return_error "Required Parameter" "A required parameter '$required_params' was not supplied"
    }
}


# export_vars_list is a tcl list of key value that need
# to be submitted with the form so that the page that
# includes the tasks is displayed correctly when we
# submit infromation

if { ![info exists export_vars_list] } {
    set export_vars_list {}
}

set task_form_vars [list task_id names assignee_id task_prescribed task due_date status priority description comment creator]
set export_vars [list]
foreach {key value} $export_vars_list {
    if { [lsearch $task_form_vars $key] < 0 } {
	set $key $value
	lappend export_vars $key
    }
}

# this is being included for contacts
set party_id [ns_queryget party_id]
lappend export_vars party_id


# after being submitted via the form object_id is a single list item string,
# this removes that limitation, and simplifies passing object_id to the form
# by not requiring an ugly hack to maintain two lists
if { [llength $object_id] == 1 } {
    set object_id [lindex $object_id 0]
}

set object_id [lsort -unique $object_id]

set object_count [llength $object_id]



# ad_form_new_p is broken by this tasks include
# due to its use of all form vars, thus we need
# to find out if this is an edit request or not
# by checking if the task_id object exists

if { ![info exists task_id] } {
    set task_action "add"
} else {
    if { [db_0or1row get_it { select 1 from acs_objects where object_id = :task_id }] } {
	set task_action "edit"
	set task_action_id $task_id
    } else {
	set task_action "add"
    }
}

if { $task_action eq "add" } {
    set edit_buttons [list \
			  [list "[_ tasks.Add_Task]" save] \
			  [list "[_ tasks.lt_Add_Task_and_Add_Anot]" save_add_another] \
			 ]

} else {
    if { $object_count > 1 } {
	ad_return_error "[_ tasks.Not_Allowed]" "[_ tasks.lt_You_are_not_allowed_t]"
    }
    set edit_buttons [list \
			  [list "[_ tasks.Update]" save] \
			  [list "[_ tasks.Delete]" delete]
		     ]
#			  [list "[_ tasks.lt_Update_and_Add_New_Ta]" save_add_another] \

}


set user_id [ad_maybe_redirect_for_registration]


# We select the users to use in the assign_object_id element
# on the form to let the user choose who will be assigned to
# the task, plus one blank space that willl be the current object_id
set assign_parties_options [list [list "       " $object_id]]
append assign_parties_options " [db_list_of_lists get_all_users { }]"


set names [list]
foreach object $object_id {
    lappend names "<a href=\"[tasks::object_url -object_id $object]\">[db_string get_acs_object_name { select acs_object__name(:object) }]</a>"
}
set names [join $names ", "]

set package_id [ad_conn package_id]


if { [ns_queryget "formbutton:delete"] ne "" } {

    set task_title [tasks::task::title -task_id $task_id]
    tasks::task::delete -task_id $task_id
    ad_returnredirect -message "[_ tasks.lt_The_task_lindex_task_]" -html $return_url
    ad_script_abort
}

set status_options [db_list_of_lists status_options { }]
set status_options [lang::util::localize $status_options]


set form_elements {
	task_id:key
	{names:text(hidden),optional {label "[_ tasks.Add_task_to]"}}
	{assignee_id:text(select),optional 
	    {label "[_ tasks.Assign_to]"}
	    {options { $assign_parties_options}}
	    {help_text "[_ tasks.Select_the_user_to]"}
	}
    }



if { ![exists_and_not_null standard_tasks_list] } {
    set params [split [parameter::get -parameter DefaultTasks -default ""] ";"] 
    set standard_tasks_list [list [list "" ""]]
    foreach param $params {
	set param [string trim $param]
	set param_tran [_ $param]
	if { ![string match "MESSAGE KEY MISSING*" $param_tran] } {
	    set param $param_tran
	}
	lappend standard_tasks_list [list $param $param]
    }
}
if { [exists_and_not_null standard_tasks_list] } {

    # the calling package has provided a list of default tasks
    # to use for this package. Thus we set up a standard task list

    append form_elements {
        {task_prescribed:text(select),optional
            {label "[_ tasks.Standard_Task]"}
	    {options $standard_tasks_list}
	}
        {task:text(text),optional
            {label "[_ tasks.Custom_Task]"}
            {html { maxlength 1000 size 80 }}
            {help_text "[_ tasks.You_can_either_use]"}
	}
    }

} else {
    append form_elements {
	{task_prescribed:text(hidden),optional}
        {task:text(text)
            {label "[_ tasks.Task]"}
            {html { maxlength 1000 size 80 }}
	}
    }

}

append form_elements {
    {due_date:text
	{label "[_ tasks.Due]"}
	{html {id date1 size 10 maxlength 10}}
	{help_text "[_ tasks.if_blank_there_is_no]"}
	{after_html {<input type='reset' value=' ... ' onclick=\"return showCalendar('date1', 'y-m-d');\"> \[<b>y-m-d </b>\]}}
    }
    {status:text(select)
	{label "[_ tasks.Status]"}
	{options $status_options}
    }
    {priority:integer(select),optional
	{label "[_ tasks.Priority]"}
	{options {{{3 - [_ tasks.Very_Important]} 3} {{2 - [_ tasks.Important]} 2} {{1 - [_ tasks.Normal]} 1} {{0 - [_ tasks.Not_Important]} 0}}}
    }
    {description:text(textarea),optional,nospell
	{label "[_ tasks.Notes]"}
	{html { rows 6 cols 60 wrap soft}}
    }
    {comment:text(textarea),optional,nospell
	{label "[_ tasks.Comment]"}
	{html { rows 6 cols 60 wrap soft}}
    }
}

#ad_return_error "ASD" [lsort -unique [concat [list return_url object_id task_action task_action_id task_form_vars] $export_vars_list]]

ad_form \
    -name add_edit \
    -cancel_url $return_url \
    -cancel_label "[_ tasks.Cancel]" \
    -edit_buttons $edit_buttons \
    -export [lsort -unique [concat [list return_url object_id task_action task_action_id task_form_vars] $export_vars]] \
    -form $form_elements \
    -new_request {

        set title "[_ tasks.Add_Task]"
	set context [list $title]
	set status "1"
        set priority "1"

    } -edit_request {

	db_1row get_task_info {	}
	set title $task
	set context [list $title]
	set task_prescribed_p 0
	foreach task_prescribed_option [template::element::get_property add_edit task_prescribed options] {
	    if { [lindex $task_prescribed_option 0] == $task } {
		set task_prescribed_p 1
	    }
	}
	if { $task_prescribed_p } {
	    set task_prescribed $task
	    set task ""
	} else {
	    set task_prescribed ""
	}

    } -validate {
#	{end_date {[calendar::date_valid_p -date $end_date]} {This is not a valid date. Either the date doesn't exist or it is not formatted correctly. Correct formatting is: YYYY-MM-DD or YYYYMMDD}}
	{task { [string equal [string trim $task] {}] != [string equal [string trim $task_prescribed] {}] } {[_ tasks.lt_Either_a_custom_task_]}}
    } -on_submit {

	# we don't use new_data and edit_data blocks because otherwise the save_add_another
        # gets messed up if we are adding a second task

	if { ![db_0or1row get_it { select 1 from acs_objects where object_id = :task_id }] } {

	    foreach object $object_id {
		set task_id [tasks::task::new \
				 -title ${task} \
				 -description ${description} \
				 -mime_type "text/plain" \
				 -comment ${comment} \
				 -object_id ${object} \
				 -due_date ${due_date} \
				 -status_id ${status} \
				 -package_id ${package_id} \
				 -priority ${priority}]
	    }

	    if { [llength $object_id] == 1 } {
		set task_url [export_vars -base [ad_conn url] -url {task_id return_url}]
		util_user_message -html -message "[_ tasks.lt_The_task_a_hreftaskst]"
	    } else {
		util_user_message -html -message "[_ tasks.lt_The_task_task_was_add]"	    
	    }

	} else {

	    set task_id [tasks::task::edit \
			     -task_id ${task_id} \
			     -title ${task} \
			     -description ${description} \
			     -mime_type "text/plain" \
			     -comment ${comment} \
			     -due_date ${due_date} \
			     -status_id ${status} \
			     -priority ${priority} \
			     -assignee_id ${assignee_id}]

	    set task_url [export_vars -base task -url {task_id return_url}]
	    set title $task
	    util_user_message -html -message "[_ tasks.lt_The_task_a_hreftaskst_1]"

	}

    } -after_submit {
	if { [ns_queryget "formbutton:save_add_another"] != "" } {
	    template::element::set_value add_edit task_prescribed ""
	    template::element::set_value add_edit task ""
	    template::element::set_value add_edit comment ""
	    template::element::set_value add_edit due_date ""
	    template::element::set_value add_edit status "1"
	    template::element::set_value add_edit priority "1"
	    template::element::set_value add_edit description ""
	    template::element::set_value add_edit comment ""
	} else {
	    ad_returnredirect $return_url
	    ad_script_abort
	}
    }

if { $task_action eq "edit" } {
    set creation_id [db_string get_it { }]
    set creator_url [contact::url -party_id $creation_id]
    set creator_name [contact::name -party_id $creation_id]
    template::element::create add_edit creator \
	-datatype "text" \
	-widget "inform" \
	-label "" \
	-value "[_ tasks.lt_Originally_created_by]" \
	-optional
} else {
    if { $object_count > 1 } {
	template::element::set_properties add_edit names widget inform
    }
}

ad_return_template
