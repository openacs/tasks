<?xml version="1.0"?>
<queryset>

<fullquery name="tasks_pagination">
      <querytext>
    select pt.task_id
      from cr_items ci,
           pm_tasks_revisions ptr,
           pm_tasks pt left join pm_process_instance ppi on (pt.process_instance = ppi.instance_id ),
           cr_revisions cr,
           acs_objects ao,
           ( select task_id, party_id
               from pm_task_assignment
              where party_id in ( select parties.party_id
                                    from parties left join cr_items on (parties.party_id = cr_items.item_id) left join cr_revisions on (cr_items.latest_revision = cr_revisions.revision_id ) , group_distinct_member_map
                                   where parties.party_id = group_distinct_member_map.member_id
                                     and group_distinct_member_map.group_id = '11428599'
                                     [contact::search_clause -and -search_id $search_id -query $query -party_id "parties.party_id" -revision_id "revision_id"] )
                and role_id = '1' ) assigned_tasks
     where ci.parent_id = '$project_id'
       and ci.item_id = pt.task_id
       and ci.live_revision = ptr.task_revision_id
       and ci.live_revision = cr.revision_id
       and pt.status = 1
       and ptr.end_date is not null
       and pt.deleted_p = 'f'
       and pt.task_id = assigned_tasks.task_id 
       and pt.task_id = ao.object_id
       and CASE WHEN ao.creation_user = assigned_tasks.party_id THEN
                CASE WHEN assigned_tasks.party_id = '$user_id' THEN 'f'::boolean ELSE 't'::boolean END
                ELSE 't'::boolean END
       and ptr.end_date < ( now() + '$tasks_interval days'::interval )
    [template::list::orderby_clause -orderby -name tasks]
      </querytext>
</fullquery>

<fullquery name="tasks_count">
      <querytext>
    select count(*)
      from cr_items ci,
           pm_tasks_revisions ptr,
           pm_tasks pt left join pm_process_instance ppi on (pt.process_instance = ppi.instance_id ),
           cr_revisions cr,
           acs_objects ao,
           ( select task_id, party_id
               from pm_task_assignment
              where party_id in ( select parties.party_id
                                    from parties left join cr_items on (parties.party_id = cr_items.item_id) left join cr_revisions on (cr_items.latest_revision = cr_revisions.revision_id ) , group_distinct_member_map
                                   where parties.party_id = group_distinct_member_map.member_id
                                     and group_distinct_member_map.group_id = '11428599'
                                     [contact::search_clause -and -search_id $search_id -query $query -party_id "parties.party_id" -revision_id "revision_id"] )
                and role_id = '1' ) assigned_tasks
     where ci.parent_id = '$project_id'
       and ci.item_id = pt.task_id
       and ci.live_revision = ptr.task_revision_id
       and ci.live_revision = cr.revision_id
       and pt.status = 1
       and ptr.end_date is not null
       and pt.deleted_p = 'f'
       and pt.task_id = assigned_tasks.task_id 
       and pt.task_id = ao.object_id
       and CASE WHEN ao.creation_user = assigned_tasks.party_id THEN
                CASE WHEN assigned_tasks.party_id = '$user_id' THEN 'f'::boolean ELSE 't'::boolean END
                ELSE 't'::boolean END
       and ptr.end_date < ( now() + '$tasks_interval days'::interval )
      </querytext>
</fullquery>

<fullquery name="tasks_select">      
      <querytext>
    select pt.task_id,
           tasks__relative_date(ptr.end_date) as end_date,
           CASE WHEN ptr.end_date < now() THEN 't'::boolean ELSE 'f'::boolean END as overdue_p,
           cr.title,
           ptr.priority,
           contact__name(assigned_tasks.party_id,:name_order) as contact_name,
           assigned_tasks.party_id,
           ppi.name as process,
           ppi.process_id as process_id
      from cr_items ci,
           pm_tasks_revisions ptr,
           pm_tasks pt left join pm_process_instance ppi on (pt.process_instance = ppi.instance_id ),
           cr_revisions cr,
           acs_objects ao,
           pm_task_assignment as assigned_tasks
     where ci.parent_id = :project_id
       and ci.item_id = pt.task_id
       and ci.live_revision = ptr.task_revision_id
       and ci.live_revision = cr.revision_id
       and pt.status = 1
       and ptr.end_date is not null
       and pt.deleted_p = 'f'
       and pt.task_id = assigned_tasks.task_id 
       and pt.task_id = ao.object_id
       and CASE WHEN ao.creation_user = assigned_tasks.party_id THEN
                CASE WHEN assigned_tasks.party_id = :user_id THEN 'f'::boolean ELSE 't'::boolean END
                ELSE 't'::boolean END
       and ptr.end_date < ( now() + '$tasks_interval days'::interval )
    [template::list::page_where_clause -and -name tasks -key pt.task_id]
    [template::list::orderby_clause -orderby -name tasks]
      </querytext>
</fullquery>

 
</queryset>
