ad_page_contract {
    List and manage contacts.

    @author Matthew Geddert openacs@geddert.com
    @creation-date 2004-07-28
    @cvs-id $Id$
} {
    {orderby "due_date,asc"}
    {format "normal"}
    {search_id:integer ""}
    {query ""}
    {page:optional}
    {page_size:integer "25"}
    {tasks_interval:integer "7"}
    {page_flush_p "f"}
}


set title "[_ tasks.Tasks]"
set context {}
set user_id [ad_conn user_id]
set package_id [ad_conn package_id]
set url [ad_conn url]

set return_url [export_vars -base $url -url {orderby format search_id query page page_size tasks_interval {page_flush_p t}}]


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

set admin_p [permission::permission_p -object_id $package_id -privilege admin]
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
	    label "[_ tasks.Priority]"
	}
        contact_name {
	    label "[_ tasks.Contact]"
	    link_url_eval $contact_url
	} 
	title {
	    label "[_ tasks.Task]"
            display_template {
		<a href="@tasks.task_url@" title="@tasks.title@">@tasks.title@</a>
		<if @tasks.description@ not nil>
                <p style="padding: 0; margin: 0; font-size: 0.85em; padding-left: 2em;">
		@tasks.description_html;noquote@
		</p>
		</if>
	    }
	}
        process_title {
	    label "[_ tasks.Process]"
	}
        due_date {
	    label "[_ tasks.Due]"
            display_template {
		<if @tasks.overdue_p@><span class="overdue"></if>
		<a href="@tasks.task_minus_url@" style="text-decoration: none; font-weight: bold;">&laquo;</a>&nbsp;@tasks.due_date;noquote@&nbsp;<a href="@tasks.task_plus_url@" style="text-decoration: none; font-weight: bold;">&raquo;</a>
		<if @tasks.overdue_p@></span></if>
	    }
	}
    } \
    -bulk_actions [list \
		       "[_ tasks.Mark_Completed]" "mark-completed" "[_ tasks.Mark_Completed]" \
		       "[_ tasks.Delete]" "delete" "[_ tasks.Delete]" \
		       "[_ contacts.Mail_Merge]" "mail-merge" "[_ contacts.lt_E-mail_or_Mail_the_se]" \
		      ]\
    -bulk_action_export_vars {
        {return_url}
    } -pass_properties { } \
    -sub_class {
        narrow
    } \
    -filters {
	search_id {}
	query {}
	page_size {}
	tasks_interval {}
    } \
    -orderby {
        default_value $orderby
        due_date {
            label "Due"
            orderby_desc "t.due_date desc, t.priority, lower(t.title)"
            orderby_asc "t.due_date asc, t.priority, lower(t.title)"
            default_direction asc
        }
        priority {
            label "Priority"
            orderby_desc "t.priority desc, t.due_date asc, lower(t.title)"
            orderby_asc "t.priority asc, t.due_date asc, lower(t.title)"
            default_direction desc
        }
        title {
            label "Task"
            orderby_desc "lower(t.title) desc, t.priority desc, t.due_date asc"
            orderby_asc "lower(t.title) asc, t.priority desc, t.due_date asc"
            default_direction asc
        }
	contact_name {
	    label "Contact"
	    orderby_asc "lower(contact__name(t.party_id,'1'::boolean)) asc"
	    orderby_desc "lower(contact__name(t.party_id,'0'::boolean)) asc"
	    default_direction asc
	}
        process_title {
	    label "Process"
            orderby_desc "lower(p.title) desc, t.priority desc, t.due_date asc"
            orderby_asc "lower(p.title) asc, t.priority desc, t.due_date asc"
	    default_direction asc
	}
    }

db_multirow -extend { contact_url description_html task_url task_plus_url task_minus_url } -unclobber tasks tasks_select {} {
    set contact_url "/contacts/${party_id}/"
    set task_url [export_vars -base "task" -url {orderby status_id task_id}]
    set task_plus_url  [export_vars -base "task-interval" -url {{action plus}  {days 7} task_id status_id orderby return_url}]
    set task_minus_url [export_vars -base "task-interval" -url {{action minus} {days 7} task_id status_id orderby return_url}]

    regsub -all "\r|\n" $description {LiNeBrEaK} description
    set description_html [ad_html_text_convert \
			      -from $mime_type \
			      -to "text/html" \
			      -truncate_len "400" \
			      -more "<a href=\"${task_url}\">[_ tasks.more]</a>" \
			      -- $description]
    regsub -all {LiNeBrEaKLiNeBrEaK} $description_html {LiNeBrEaK} description_html
    regsub -all {LiNeBrEaK} $description_html {\&nbsp;\&nbsp;\&#182;\&nbsp;} description_html
    regsub -all " " $due_date {\&nbsp;} due_date
}

set tasks_count [db_string tasks_count {} -default {0}]


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
    {tasks_interval:integer(text),optional {label "&nbsp;&nbsp;<span style=\"font-size: smaller;\">[_ tasks.View_next]</span>"} {after_html "<span style=\"font-size: smaller;\">days &nbsp;&nbsp;&nbsp;Results:</span>&nbsp;$tasks_count"} {html {size 2 maxlength 3 onChange "javascript:acs_FormRefresh('search')"}}}
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

