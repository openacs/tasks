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
    set return_url [export_vars -base "contact" -url {party_id status_id orderby}]
}

set package_id [ad_conn package_id]
set user_id    [ad_maybe_redirect_for_registration]

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
    ad_returnredirect [export_vars -base "delete" -url {task_id orderby status_id return_url}]
    ad_script_abort
}

set contact_options [db_list_of_lists contact_options {
    select CASE WHEN o.name is null THEN p.first_names || ' ' || p.last_name ELSE o.name END as name, y.party_id
    from parties y
    left join persons p on (y.party_id = p.person_id)
    left join organizations o on (y.party_id = o.organization_id)
    where (p.person_id is not null or o.organization_id is not null)
    and y.party_id > 0
    order by 1
}]
set contact_options [concat [list [list "" ""]] $contact_options]

set status_options [db_list_of_lists status_options {
    select title, status_id
    from t_task_status
    order by status_id
}]
set status_options [lang::util::localize $status_options]

ad_form -name add_edit \
    -cancel_url $return_url \
    -cancel_label "[_ tasks.Cancel]" \
    -edit_buttons $edit_buttons \
    -form {
        task_id:key
        return_url:text(hidden),optional
        orderby:text(hidden),optional
        status_id:integer(hidden),optional
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
            {html { maxlength 1000 size 80 }}
            {help_text {You can either use a standard task or a custom task, but not both}}
	}

        {object_id:text(select),optional
            {label "[_ tasks.Contact]"}
            {options $contact_options}
        }

	{due_date:text
	    {label "[_ tasks.Due]"}
	    {html {id date1 size 10 maxlength 10}}
	    {help_text {if blank there is no due date}}
	    {after_html {<input type='reset' value=' ... ' onclick=\"return showCalendar('date1', 'y-m-d');\"> \[<b>y-m-d </b>\]}}
	}

        {status:text(select)
            {label "[_ tasks.Status]"}
            {options $status_options}
        }

        {priority:integer(select),optional
            {label "[_ tasks.Priority]"}
            {options {{{3 - Very Important} 3} {{2 - Important} 2} {{1 - Normal} 1} {{0 - Not Important} 0}}}
        }

        {description:text(textarea),optional,nospell
            {label "[_ tasks.Notes]"}
            {html { rows 6 cols 60 wrap soft}}}

        {comment:text(textarea),optional,nospell
            {label "[_ tasks.Comment]"}
            {html { rows 6 cols 60 wrap soft}}}

    } -new_request {

        set title "[_ tasks.Add_Task]"
	set context [list $title]
	set status "1"
        set priority "1"

    } -edit_request {

	db_1row get_task_info {
	    select t.title as task, t.description, t.comment,
                   to_char(t.due_date,'YYYY-MM-DD') as due_date,
                   t.priority, t.status_id as status, t.object_id
              from t_tasks t
             where t.task_id = :task_id
	}
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

    } -new_data {

	foreach party $all_parties {

	    set task_id [tasks::task::new \
			     -title ${task} \
			     -description ${description} \
			     -mime_type "text/plain" \
			     -comment ${comment} \
			     -party_id ${party} \
			     -object_id $object_id \
			     -due_date ${due_date} \
			     -status_id ${status} \
			     -package_id ${package_id} \
			     -priority ${priority}]
	}

	if { [llength $all_parties] == 1 } {
	    set task_url [export_vars -base task -url {task_id status_id orderby party_id}]
	    util_user_message -html -message "[_ tasks.lt_The_task_a_hreftaskst]"
	} else {
	    util_user_message -html -message "[_ tasks.lt_The_task_task_was_add]"	    
	}

    } -edit_data {

	set task_id [tasks::task::edit \
			 -task_id ${task_id} \
			 -title ${task} \
			 -description ${description} \
			 -mime_type "text/plain" \
			 -comment ${comment} \
			 -object_id $object_id \
			 -due_date ${due_date} \
			 -status_id ${status} \
			 -priority ${priority}]

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
    set creator_url [contact::url -party_id $creation_id]
    set creator_name [contact::name -party_id $creation_id]
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
