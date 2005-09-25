<?xml version="1.0"?>
<queryset>

  <fullquery name="task_query">
    <querytext>
	    select tp.task_id as process_task_id, tp.title as task,
                   tp.description, tp.priority, tp.due, tp.start,
                   tp2.title as after_task, tp2.task_id as after_task_id
              from t_process_tasks tp
	      left outer join t_process_tasks tp2
                on (tp2.closing_action_id = tp.open_action_id)
             where tp.process_id = :process_id
               and tp.status_id is not null
        [template::list::orderby_clause -orderby -name tasks]
    </querytext>
  </fullquery>

</queryset>
