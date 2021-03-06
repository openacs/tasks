ad_page_contract {
    List and manage contacts.

    @author Matthew Geddert openacs@geddert.com
    @creation-date 2004-07-28
    @cvs-id $Id$
} {
    {search_id:integer ""}
    {status_id ""}
    {format ""}
    {tasks_orderby ""}
    {page ""}
    {query ""}
    {tasks_future:integer "7"}
    {tasks_previous:integer ""}
    {selected_assignee_id ""}
}



set title "[_ tasks.Tasks]"
set context {}
set user_id [ad_conn user_id]
set package_id [ad_conn package_id]
set url [ad_conn url]

set return_url [export_vars -base $url -url {orderby format search_id query page page_size tasks_future tasks_previous {page_flush_p t}}]

set package_id [site_node::get_element -url "/contacts" -element object_id]
if { [exists_and_not_null search_id] } {
    contact::search::log -search_id $search_id
}
set search_options [concat [list [list [_ contacts.All_Contacts] ""]] [db_list_of_lists dbqd.contacts.www.index.public_searches {}]]

set searchcount 1
db_foreach dbqd.contacts.www.index.my_searches {} {
    lappend search_options [list "${my_searches_title}" ${my_searches_search_id} [_ contacts.My_Searches]]
    incr searchcount
}
db_foreach dbqd.contacts.www.index.my_lists {} {
    lappend search_options [list "${my_lists_title}" ${my_lists_list_id} [_ contacts.Lists]]
    incr searchcount
}

if { [exists_and_not_null search_id] } {
    set search_in_list_p 0
    foreach search_option $search_options {
	if { [lindex $search_option 1] eq $search_id } {
	    set search_in_list_p 1
	}
    }
    if { [string is false $search_in_list_p] } {
	set search_options [concat [list [list "&lt;&lt; [_ contacts.Search] \#${search_id} &gt;&gt;" $search_id]] $search_options]
    }
}


lang::util::localize_list_of_lists -list $search_options


set form_elements {
    {search_id:integer(select),optional {label ""} {options $search_options} {html {onChange "javascript:acs_FormRefresh('search')"}}}
    {query:text(text),optional {label ""} {html {size 20 maxlength 255}}}
    {save:text(submit) {label {[_ contacts.Search]}} {value "go"}}
    {tasks_previous:integer(text),optional {label "&nbsp;&nbsp;<span style=\"font-size: smaller;\">[_ tasks.View_previous]</span>"} {after_html "<span style=\"font-size: smaller;\">days</span>"} {html {size 2 maxlength 3 onChange "javascript:acs_FormRefresh('search')"}}}
    {tasks_future:integer(text),optional {label "&nbsp;&nbsp;<span style=\"font-size: smaller;\">[_ tasks.View_next]</span>"} {after_html "<span style=\"font-size: smaller;\">days</span>"} {html {size 2 maxlength 3 onChange "javascript:acs_FormRefresh('search')"}}}
}

if { [parameter::get -boolean -parameter "ForceSearchBeforeAdd" -default "0"] } {
    if { [exists_and_not_null query] && $search_id == "" } {
	append form_elements {
	    {add_person:text(submit) {label {[_ contacts.Add_Person]}} {value "1"}}
	    {add_organization:text(submit) {label {[_ contacts.Add_Organization]}} {value "1"}}
	}
    }
}

ad_form -name "search" -method "GET" -export {selected_assignee_id status_id tasks_orderby page format} -form $form_elements \
    -on_request {
    } -edit_request {
    } -on_refresh {
    } -on_submit {
    } -after_submit {
    }


set object_query "
select parties.party_id
  from parties,
       cr_items,
       group_distinct_member_map
 where parties.party_id = group_distinct_member_map.member_id
   and parties.party_id = cr_items.item_id
   and group_distinct_member_map.group_id in ([template::util::tcl_to_sql_list [contacts::default_groups]])
[contact::search_clause -and -search_id $search_id -query $query -party_id "parties.party_id" -revision_id "cr_items.live_revision"]
"



set start_date ""
set end_date ""
if { $tasks_future ne "" } {
    set end_date [db_string get_new_start_date " select ( now() + '$tasks_future days'::interval ) " -default {}]
}
if { $tasks_previous ne "" } {
    set start_date [db_string get_new_end_date " select ( now() - '$tasks_previous days'::interval ) " -default {}]
}
