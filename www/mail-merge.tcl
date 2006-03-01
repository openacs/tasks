ad_page_contract {

    @author Matthew Geddert openacs@geddert.com
    @creation-date 2004-07-28
    @cvs-id $Id$

} {
    {task_id:integer,multiple}
    {return_url:notnull}
}

tasks::require_belong_to_package -objects $process_id 

set party_ids [db_list get_party_ids "
	    select distinct party_id
              from pm_task_assignment
             where task_id in ('[join $task_id {','}]')
"]

ad_returnredirect [export_vars -base "/contacts/message" -url {return_url party_ids}]
ad_script_abort




