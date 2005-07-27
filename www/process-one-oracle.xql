<?xml version="1.0"?>
<queryset>

  <fullquery name="task_query">
    <querytext>
	SELECT t.process_task_id,
               t.one_line,
               t.description,
               t.estimated_hours_work,
               t.estimated_hours_work_min,
               t.estimated_hours_work_max,
               d.dependency_type,
               t.ordering
	FROM pm_process_task t ,
             pm_process_task_dependency d 
	WHERE t.process_task_id = d.process_task_id (+)  and
	      t.process_id = :process_id
        [template::list::orderby_clause -orderby -name tasks]
    </querytext>
  </fullquery>

</queryset>
