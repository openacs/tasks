ad_page_contract {
    List and manage contacts.

    @author Matthew Geddert openacs@geddert.com
    @creation-date 2004-07-28
    @cvs-id $Id$
} {
    {orderby "end_date,asc"}
    {format "normal"}
    {search_id:integer ""}
    {query ""}
    {page:optional}
    {page_size:integer "25"}
    {tasks_interval:integer "7"}
    {page_flush_p "f"}
}


set title "Tasks"
set context {}
set project_id [tasks::project_id]
set user_id [ad_conn user_id]

set return_url [export_vars -base "/tasks/" -url {orderby format search_id query page page_size tasks_interval {page_flush_p t}}]


if { $orderby == "contact_name,asc" } {
    set name_order 0
} elseif { $orderby == "contact_name,desc" } {
    set name_order 1
} else {
    set name_order 0
}




set first_p 1
foreach page_s [list 25 50 100 500] {
    if { [string is false $first_p] } {
        append name_label " | "
    }
    if { $page_size == $page_s } {
        append name_label $page_s
    } else {
        append name_label "<a href=\"[export_vars -base . -url {rel_type format query_id query page orderby {page_size $page_s}}]\">$page_s</a>"
    }
    set first_p 0
}

set admin_p [permission::permission_p -object_id [ad_conn package_id] -privilege admin]
set task_term [ad_conn instance_name]
set context {}

template::list::create \
    -name tasks \
    -multirow tasks \
    -key task_id \
    -page_size "50" \
    -page_flush_p $page_flush_p \
    -page_query_name tasks_pagination \
    -elements {
        priority {
	    label "Priority"
	}
        contact_name {
	    label "Contact"
	    link_url_eval $contact_url
	} 
	title {
	    label "Task"
            display_template {
		<a href="/tasks/task?party_id=@tasks.party_id@&task_id=@tasks.task_id@&orderby=${orderby}" title="@tasks.title@">@tasks.title@</a>
	    }
	}
        process {
	    label "Process"
	}
        end_date {
	    label "Due"
            display_template {
		<if @tasks.overdue_p@>
		<span class="overdue">@tasks.end_date@</span>
		</if>
		<else>
		@tasks.end_date@
		</else>
	    }
	}
    } \
    -bulk_actions [list \
		       "Mark Completed" "mark-completed" "Mark Completed" \
		       "Delete" "delete" "Delete" \
		       "[_ contacts.Mail_Merge]" "mail-merge" "[_ contacts.lt_E-mail_or_Mail_the_se]" \
		      ]\
    -bulk_action_export_vars {
        {return_url}
    } \
    -sub_class {
        narrow
    } \
    -filters {
	search_id {}
	query {}
	page_size {}
	tasks_interval {}
	process_instance {}
    } \
    -orderby {
        default_value $orderby
        end_date {
            label "Due"
            orderby_desc "ptr.end_date desc, ptr.priority, upper(cr.title)"
            orderby_asc "ptr.end_date asc, ptr.priority, upper(cr.title)"
            default_direction asc
        }
        priority {
            label "Priority"
            orderby_desc "ptr.priority desc, ptr.end_date asc, upper(cr.title)"
            orderby_asc "ptr.priority asc, ptr.end_date asc, upper(cr.title)"
            default_direction desc
        }
        title {
            label "Task"
            orderby_desc "upper(cr.title) desc, ptr.priority desc, ptr.end_date asc"
            orderby_asc "upper(cr.title) asc, ptr.priority desc, ptr.end_date asc"
            default_direction asc
        }
	contact_name {
	    label "Contact"
	    orderby_asc "lower(contact__name(assigned_tasks.party_id,'1'::boolean)) asc"
	    orderby_desc "lower(contact__name(assigned_tasks.party_id,'0'::boolean)) asc"
	    default_direction asc
	}
        process {
	    label "Process"
            orderby_desc "upper(ppi.name) desc, ptr.priority desc, ptr.end_date asc"
            orderby_asc "upper(ppi.name) asc, ptr.priority desc, ptr.end_date asc"
	    default_direction asc
	}
    }

db_multirow -extend { contact_url } -unclobber tasks tasks_select {} {
    set contact_url "/contacts/${party_id}/"
}


set tasks_count [db_string tasks_count {} -default {0}]


set package_id "11426862"
if { [exists_and_not_null search_id] } {
    contact::search::log -search_id $search_id
}
set search_options [concat [list [list [_ contacts.All_Contacts] ""]] [db_list_of_lists dbqd.contacts.www.index.public_searches {}]]

set searchcount 1
db_foreach dbqd.contacts.www.index.my_recent_searches {} {
    lappend search_options [list "${searchcount}) ${recent_title}" ${recent_search_id}]
    incr searchcount
}

set form_elements {
    {search_id:integer(select),optional {label ""} {options $search_options} {html {onChange "javascript:acs_FormRefresh('search')"}}}
    {query:text(text),optional {label ""} {html {size 20 maxlength 255}}}
    {save:text(submit) {label {[_ contacts.Search]}} {value "go"}}
    {tasks_interval:integer(text),optional {label "&nbsp;&nbsp;<span style=\"font-size: smaller;\">View next</span>"} {after_html "<span style=\"font-size: smaller;\">days &nbsp;&nbsp;&nbsp;Results:</span>&nbsp;$tasks_count"} {html {size 2 maxlength 3 onChange "javascript:acs_FormRefresh('search')"}}}
}

if { [parameter::get -boolean -parameter "ForceSearchBeforeAdd" -default "0"] } {
    if { [exists_and_not_null query] && $search_id == "" } {
	append form_elements {
	    {add_person:text(submit) {label {[_ contacts.Add_Person]}} {value "1"}}
	    {add_organization:text(submit) {label {[_ contacts.Add_Organization]}} {value "1"}}
	}
    }
}

ad_form -name "search" -method "GET" -export {orderby page_size format} -form $form_elements \
    -on_request {
    } -edit_request {
    } -on_refresh {
    } -on_submit {
    } -after_submit {
    }

