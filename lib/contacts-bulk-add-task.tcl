ad_page_contract {

    @author Matthew Geddert (openacs@geddert.com)
    @creation-date 2006-03-12
    @cvs-id $Id$

} {
    {party_id:integer,multiple ""}
    {assignee_id: ""}
    {return_url ""}
}

foreach assignee_id $assignee_id {
    lappend party_id $assignee_id
}

set title [_ tasks.Add_Task]
set context [list $title]
