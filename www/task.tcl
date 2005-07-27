ad_page_contract {

    Simple add/edit form for projects

    @author jader@bread.com, ncarroll@ee.usyd.edu.au
    @creation-date 2003-05-15
    @cvs-id $Id$

    @return context_bar Context bar.
    @return title Page title.

} {
    {party_id:integer,notnull,multiple}
    {other_party_ids ""}
    task_id:integer,optional
    status_id:integer,optional
    orderby:optional
    {return_url ""}
} -properties {
}

set party_count [expr [llength $party_id] + [llength $other_party_ids]]
if { $party_count > 1 && ![ad_form_new_p -key "task_id"] } {
    ad_return_error "[_ tasks.Not_Allowed]" "[_ tasks.lt_You_are_not_allowed_t]"
}

if { [llength $party_id] > 1 } {
    set real_party_id [lindex $party_id 0]
    set other_party_ids [list]
    foreach party_id $party_id {
	if { $party_id != $real_party_id } {
	    lappend other_party_ids $party_id
	}
    }
    set party_id $real_party_id
}
set all_parties [concat $party_id $other_party_ids]
set names [list]
foreach party $all_parties {
    lappend names [contact::link -party_id $party]
}
set names [join $names ", "]

if { ![exists_and_not_null return_url] } {
    set return_url [export_vars -base "contact" -url {party_id orderby status_id}]
}

set package_id [ad_conn package_id]
set user_id    [ad_maybe_redirect_for_registration]
set project_id [tasks::project_id]

set title "[_ tasks.AddEdit]"
set context [list $title]

if { ![ad_form_new_p -key task_id] } {
    append edit_buttons [list \
			     [list "[_ tasks.Update]" save] \
			     [list "[_ tasks.lt_Update_and_Add_New_Ta]" save_add_another] \
			     [list "[_ tasks.Delete]" delete]
			 ]
} else {
    set edit_buttons [list \
			  [list "[_ tasks.Add_Task]" save] \
			  [list "[_ tasks.lt_Add_Task_and_Add_Anot]" save_add_another]
		      ]
}

if { [ns_queryget "formbutton:delete"] != "" } {
    ad_returnredirect [export_vars -base "delete" -url {task_id status_id orderby return_url}]
    ad_script_abort
}


ad_form -name add_edit \
    -cancel_url $return_url \
    -cancel_label "[_ tasks.Cancel]" \
    -edit_buttons $edit_buttons \
    -form {
        task_id:key
        return_url:text(hidden),optional
        status_id:integer(hidden),optional
        orderby:text(hidden),optional
        party_id:integer(hidden)
        other_party_ids:text(hidden),optional
        {names:text(hidden),optional {label {Add Task To}}}

        {task_prescribed:text(select),optional
            {label "[_ tasks.Standard_Task]"}
	    {options {
		{{}                                {}}             
		{{[_ tasks.lt_Delete_from_Recruitin]}   {[_ tasks.lt_Delete_from_Recruitin]}}	 
		{{[_ tasks.Follow_Up_Call]}		   {[_ tasks.Follow_Up_Call]}}		 	
		{{[_ tasks.Follow_Up_Email]}		   {[_ tasks.Follow_Up_Email]}}		 
		{{[_ tasks.Have_they_responded]}		   {[_ tasks.Have_they_responded]}}		 
		{{[_ tasks.lt_Provide_Promotional_I]} {[_ tasks.lt_Provide_Promotional_I]}}
		{{[_ tasks.Send_Letter]}			   {[_ tasks.Send_Letter]}}			 
		{{[_ tasks.Send_Birthday_Card]}		   {[_ tasks.Send_Birthday_Card]}}		 
		{{[_ tasks.Send_Class_Schedule]}		   {[_ tasks.Send_Class_Schedule]}}		 
		{{[_ tasks.lt_Send_Personal_NoteLet]}	   {[_ tasks.lt_Send_Personal_NoteLet]}}	 
		{{[_ tasks.Send_Web_Info_Card]}              {[_ tasks.Send_Web_Info_Card]}}             
	    }}
	}

        {task:text(text),optional
            {label "[_ tasks.Custom_Task]"}
            {html { maxlength 1000 size 35 }}
            {help_text {You can either use a standard task or a custom task, but not both}}
	}

	{end_date:text(text)
	    {label "[_ tasks.Due]"}
	    {html {id date1 size 10 maxlength 10}}
	    {help_text {if blank there is no due date}}
	    {after_html {
		<button type=\"reset\" id=\"f_date_b1\">YYYY-MM-DD</button>
<script type=\"text/javascript\">
    Calendar.setup({
        inputField     :    \"date1\",       // id of the input field, put readonly 1 in html to limit input 
        ifFormat       :    \"%Y-%m-%d\",   // Format the input field
        daFormat       :    \"%m %d %Y\",   // Format for the display area
        showsTime      :    false,          // will display a time selector
        button         :    \"f_date_b1\",   // trigger for the calendar (button ID)
        singleClick    :    true,           // double-click mode
        step           :    1,              // show all years in drop-down boxes (instead of every other year as default)
        weekNumbers    :    false,          // do not show the week numbers
        showOthers     :    false           // show days belonging to other months
    });
</script>
	    }}
	}

        {completed_p:text(checkbox),optional
            {label "[_ tasks.Status]"}
            {options {{Completed 1}}}
        }

        {priority:integer(select),optional
            {label "[_ tasks.Priority]"}
            {options {{{3 - Very Important} 3} {{2 - Important} 2} {{1 - Normal} 1} {{0 - Not Important} 0}}}
        }

        {description:text(textarea),optional,nospell
            {label "[_ tasks.Notes]"}
            {html { rows 6 cols 60 wrap soft}}}

    } -new_request {

        set title "[_ tasks.Add_Task]"
	set context [list $title]
	set status_id "1"
        set priority "1"

    } -edit_request {

	db_1row get_task_info {
	    select ci.item_id as task_id,
                   cr.title as task,
                   to_char(ptr.end_date,'YYYY-MM-DD') as end_date,
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
            
	}
	if { $percent_complete >= "100" } {
	    set completed_p "1"
	}
        set title ${task}
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
	    set task $task
	}
    } -validate {
#	{end_date {[calendar::date_valid_p -date $end_date]} {This is not a valid date. Either the date doesn't exist or it is not formatted correctly. Correct formatting is: YYYY-MM-DD or YYYYMMDD}}
    } -on_submit {
	set task_prescribed [string trim $task_prescribed]
	set task [string trim $task]
	if { [exists_and_not_null task_prescribed] && [exists_and_not_null task] } {
	    template::element set_error add_edit task_prescribed "[_ tasks.lt_Standard_tasks_are_ca]"
	    template::element set_error add_edit task "[_ tasks.lt_Standard_tasks_are_ca]"
	} elseif { ![exists_and_not_null task_prescribed] && ![exists_and_not_null task] } {
	    template::element set_error add_edit task_prescribed "[_ tasks.lt_Either_a_custom_task_]"
	    template::element set_error add_edit task "[_ tasks.lt_Either_a_custom_task_]"
	} elseif { [exists_and_not_null task_prescribed] } {
	    set task $task_prescribed
	}
	if { [string is false [::template::form::is_valid add_edit]] } {
	    break
	}

        set user_id [ad_conn user_id]
        set peeraddr [ad_conn peeraddr]
        if { $completed_p == "1" } {
	    set percent_complete "100"
	} else {
	    set percent_complete "0"
	}
    } -new_data {

	foreach party $all_parties {

	    set task_id [pm::task::new -project_id ${project_id} \
			     -title ${task} \
			     -description ${description} \
			     -mime_type "text/plain" \
			     -end_date ${end_date} \
			     -percent_complete ${percent_complete} \
			     -creation_user ${user_id} \
			     -creation_ip ${peeraddr} \
			     -package_id ${package_id} \
			     -priority ${priority}]

	    pm::task::assign -task_item_id $task_id -party_id $party

	}

	if { [llength $all_parties] == 1 } {
	    set task_url [export_vars -base task -url {task_id status_id orderby party_id}]
	    util_user_message -html -message "[_ tasks.lt_The_task_a_hreftaskst]"
	} else {
	    util_user_message -html -message "[_ tasks.lt_The_task_task_was_add]"	    
	}

    } -edit_data {

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

    	set task_url [export_vars -base task -url {task_id status_id orderby party_id}]
	util_user_message -html -message "[_ tasks.lt_The_task_a_hreftaskst_1]"


    } -after_submit {
	if { ![exists_and_not_null return_url] } {
	    set return_url [export_vars -url -base "contact" {party_id}]
	}
	if { [ns_queryget "formbutton:save_add_another"] != "" } {
	    set return_url [export_vars -url -base "task" {orderby status_id party_id return_url}]
	}
	ad_returnredirect $return_url
	ad_script_abort

    }

if { ![ad_form_new_p -key task_id] } {
    set creation_id [db_string get_it { select creation_user from acs_objects where object_id = :task_id }]
    template::element::create add_edit creator \
	-datatype "text" \
	-widget "inform" \
	-label "" \
	-value "[_ tasks.lt_Originally_created_by]" \
	-optional
} else {
    if { $party_count > 1 } {
	template::element::set_properties add_edit names widget inform
    }
}
