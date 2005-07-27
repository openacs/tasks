if { ![exists_and_not_null party_id] } {
     error "you must supply a party_id"
}
set mine_p "f"
set status_id "1"
set role_id "2"
set orderby "priority,desc"


# \
#    -orderby_name orderby
 
# \
#    -html {
#        width 100%
#    }

#set user_id [ad_conn user_id]

#set project_id [tasks::project_id]
set project_id "26798"




template::multirow create tasks task_url title end_date overdue_p

set new_num 1
db_foreach get_tasks "
    select pt.task_id,
           tasks__relative_date(ptr.end_date) as end_date,
           cr.title,
           ptr.priority,
           CASE WHEN ptr.end_date <  now() THEN '1' ELSE '0' END as overdue_p
      from cr_items ci,
           pm_tasks_revisions ptr,
           pm_tasks pt,
           cr_revisions cr
     where ci.parent_id = :project_id
       and ci.item_id = pt.task_id
       and ci.latest_revision = ptr.task_revision_id
       and ci.live_revision = ptr.task_revision_id
       and ptr.task_revision_id = cr.revision_id
       and pt.deleted_p = 'f'
       and task_id in ( select task_id from pm_task_assignment where party_id = :party_id and role_id = '1' )
       and ptr.end_date is not null
       and ptr.percent_complete < 100
     order by ptr.end_date asc, ptr.priority, upper(cr.title)
" {

    if { !$overdue_p } {
	if { $new_num > 3 } {
	    break
	}
	incr new_num
    }
    set task_url [export_vars -base "/tasks/task" -url { party_id task_id }]
    template::multirow append tasks $task_url $title $end_date $overdue_p
}
#        [template::list::filter_where_clauses -and -name tasks]
#set fred [template::list::orderby_clause -orderby -name tasks]
