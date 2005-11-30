<?xml version="1.0"?>
<!--  -->
<!-- @author  (jader-ibr@bread.com) -->
<!-- @creation-date 2004-11-05 -->
<!-- @arch-tag: 83fea880-0438-4082-8b1a-45ce0ad7fa67 -->
<!-- @cvs-id $Id$ -->

<queryset>

  <fullquery name="instances_query">
    <querytext>
      SELECT
      i.name,
      i.instance_id,
      i.project_item_id,
      projectr.title as project_name,
      (select count(*)
       from 
       pm_tasks_active t, 
       pm_task_status s 
       where 
       t.status = s.status_id and 
       s.status_type = 'o' and 
       t.process_instance = i.instance_id) as active_tasks
      FROM 
      pm_process_instance i,
      cr_items projecti,
      cr_revisions projectr
      WHERE
      i.process_id           = :process_id and
      i.project_item_id      = projecti.item_id and
      projecti.live_revision = projectr.revision_id
      ORDER BY
      i.instance_id desc
    </querytext>
</fullquery>
  
</queryset>
