<?xml version="1.0"?>
<queryset>

  <fullquery name="task_query">
    <querytext>
	    select pm.process_task_id,
                   pm.one_line as task,
                   pm.description,
                   tp.due_interval,
                   tp.due_date,
	           CASE WHEN to_char(tp.due_date,'YYYY') = to_char(now(),'YYYY') THEN to_char(tp.due_date,'Mon DD (Dy)') ELSE to_char(tp.due_date,'Mon DD, YYYY (Dy') END as pretty_due_date,
                   tp.priority
              from pm_process_task pm,
                   tasks_pm_process_task tp
             where pm.process_id = :process_id
               and pm.process_task_id = tp.process_task_id
        [template::list::orderby_clause -orderby -name tasks]
    </querytext>
  </fullquery>

</queryset>
