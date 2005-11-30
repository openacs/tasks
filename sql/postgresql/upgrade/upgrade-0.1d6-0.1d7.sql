-- We are going to update the assignee_id with the creation_user
-- if the assingee_id is null for t_tasks and t_process_tasks

create or replace function inline_0() returns integer as '
declare
    tasks     record;
begin
    for tasks in select 
                        t.task_id, 
		 	t.assignee_id,
			ao.creation_user
	         from 
			t_tasks t,
			acs_objects ao
		 where
			ao.object_id = t.task_id
    loop
	if tasks.assignee_id is null then

		update t_tasks
		set assignee_id = tasks.creation_user
		where task_id = tasks.task_id;

	end if;

    end loop;

    return 1;
end;' language 'plpgsql';

begin;
  select inline_0();
  drop function inline_0();
end;

create or replace function inline_0() returns integer as '
declare
    tasks     record;
begin
    for tasks in select 
                        t.task_id, 
		 	t.assignee_id,
			ao.creation_user
	         from 
			t_process_tasks t,
			acs_objects ao
		 where
			ao.object_id = t.task_id
    loop
	if tasks.assignee_id is null then

		update t_process_tasks
		set assignee_id = tasks.creation_user
		where task_id = tasks.task_id;

	end if;

    end loop;

    return 1;
end;' language 'plpgsql';

begin;
  select inline_0();
  drop function inline_0();
end;