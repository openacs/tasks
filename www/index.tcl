ad_page_contract {
    List and manage contacts.

    @author Matthew Geddert openacs@geddert.com
    @creation-date 2004-07-28
    @cvs-id $Id$
} {
    {orderby:optional ""}
    {format "normal"}
    {search_id:integer ""}
    {query ""}
    {page:optional "1"}
    {page_size:integer "25"}
    {tasks_interval:integer "7"}
}

set title "[_ tasks.Tasks]"
set context {}
set user_id [ad_conn user_id]
set package_id [ad_conn package_id]
set url [ad_conn url]

set return_url [export_vars -base $url -url {orderby format search_id query page page_size tasks_interval {page_flush_p t}}]


set package_id [site_node::get_element -url "/contacts" -element object_id]
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
    {tasks_interval:integer(text),optional {label "&nbsp;&nbsp;<span style=\"font-size: smaller;\">[_ tasks.View_next]</span>"} {after_html "<span style=\"font-size: smaller;\">days"} {html {size 2 maxlength 3 onChange "javascript:acs_FormRefresh('search')"}}}
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

set orderby ""
