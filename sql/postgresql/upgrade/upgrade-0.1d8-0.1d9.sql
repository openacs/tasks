-- tasks/sql/postgresql/upgrade/upgrade-0.1d8-0.1d9.sql
--
-- @author Matthew Geddert (openacs@geddert.com)
-- @creation-date 2006-02-22
-- @cvs-id $Id$


-- We first validate that we can in fact delete 
create or replace function inline_0() returns integer as '
declare 
        v_valid_p   boolean;
	v_tpt_row   record;
	v_tt_row    record;
	v_tpi_row   record;

begin

     if ( select count(*) from t_process_instances where object_id is not null ) > 0 then
        raise EXCEPTION '' -20000: tasks/sql/postgresql/upgrade/upgrade-0.1d8-0.1d9.sql cannot upgrade because t_process_instances object_id column is not null.'';
     end if;

     if ( select count(*) from apm_packages where package_key = ''tasks'' ) > 1 then
        raise EXCEPTION '' -20000: tasks/sql/postgresql/upgrade/upgrade-0.1d8-0.1d9.sql cannot upgrade because there is more than one tasks instance.'';
     end if;

     if ( select count(*) from t_tasks where party_id not in ( select member_id from group_distinct_member_map where group_id = ''-2'' ))  > 0 then
        raise EXCEPTION '' -20000: tasks/sql/postgresql/upgrade/upgrade-0.1d8-0.1d9.sql cannot upgrade because assigned to parties that are not in -2.'';
     end if;


     -- t_processes changes
     alter table t_processes add column assignee_id integer;


     --
     -- t_procss_instances changes

     update t_process_instances set object_id = party_id ;
--     alter table t_process_instances drop constraint t_process_instances_party_fk;
     alter table t_process_instances drop column party_id;


     --
     -- t_process_tasks party_id, object_id

     for v_tpt_row in select * from t_process_tasks where object_id is not null
     loop

        -- create forward link
        insert into acs_data_links (rel_id, object_id_one, object_id_two)
	    values (nextval(''acs_data_links_seq''), v_tpt_row.task_id, v_tpt_row.object_id );

        -- create backward link
        insert into acs_data_links (rel_id, object_id_one, object_id_two)
	    values (nextval(''acs_data_links_seq''), v_tpt_row.object_id, v_tpt_row.task_id );

     end loop;
     return 0;

     update t_process_tasks set object_id = party_id;
     alter table t_process_tasks drop constraint t_process_tasks_party_fk;
     alter table t_process_tasks drop column party_id;

     --
     -- t_tasks party_id, object_id

     for v_tt_row in select * from t_tasks where object_id is not null
     loop

        -- create forward link
        insert into acs_data_links (rel_id, object_id_one, object_id_two)
	    values (nextval(''acs_data_links_seq''), v_tt_row.task_id, v_tt_row.object_id );

        -- create backward link
        insert into acs_data_links (rel_id, object_id_one, object_id_two)
	    values (nextval(''acs_data_links_seq''), v_tt_row.object_id, v_tt_row.task_id );

     end loop;
     return 0;

     update t_tasks set object_id = party_id;
     alter table t_tasks drop constraint t_tasks_party_fk;
     alter table t_tasks drop column party_id;



     return 0;

end;' language 'plpgsql';
--     alter table t_process_tasks add column tester boolean;
-- Calling and droping the function
select inline_0();
drop function inline_0();


drop function tasks_task__new (integer,integer,integer,integer,integer,varchar,text,varchar,text,integer,integer,timestamptz,timestamptz,integer,integer,varchar,integer,integer);

drop function tasks_process_task__new (integer,integer,integer,integer,integer,integer,varchar,text,varchar,text,integer,integer,numeric,numeric,integer,integer,varchar,integer,integer);

drop function tasks_process_instance__new (integer,integer,integer,integer,integer,integer,integer,varchar,integer);

drop function tasks_process__new (integer,varchar,text,varchar,integer,integer,integer,varchar,integer);


select define_function_args('tasks_task__new','task_id,process_instance_id,process_task_id,object_id,title,description,mime_type,comment,status_id,priority,start_date,due_date,package_id,creation_user,creation_ip,context_id,assignee_id');

create or replace function tasks_task__new (integer,integer,integer,integer,varchar,text,varchar,text,integer,integer,timestamptz,timestamptz,integer,integer,varchar,integer,integer)
returns integer as '
declare
    p_task_id                 alias for $1;
    p_process_instance_id     alias for $2;
    p_process_task_id         alias for $3;
    p_object_id               alias for $4;
    p_title                   alias for $5;
    p_description             alias for $6;
    p_mime_type               alias for $7;
    p_comment                 alias for $8;
    p_status_id               alias for $9;
    p_priority                alias for $10;
    p_start_date              alias for $11;
    p_due_date                alias for $12;
    p_package_id              alias for $13;
    p_creation_user           alias for $14;
    p_creation_ip             alias for $15;
    p_context_id              alias for $16;
    p_assignee_id             alias for $17;
    v_task_id                 integer;
    v_start_date              timestamptz;
begin
    v_task_id:= acs_object__new(
        p_task_id,
        ''tasks_task'',
        now(),
        p_creation_user,
        p_creation_ip,
        coalesce(p_context_id, p_package_id),
        ''t'',
        p_title,
        p_package_id
    );

    if p_start_date is null then
      v_start_date := now();
    else
      v_start_date := p_start_date;
    end if;

    insert into t_tasks
    (task_id, process_instance_id, process_task_id, object_id,
     title, description, mime_type, comment, status_id, priority,
     start_date, due_date, assignee_id)
    values
    (v_task_id, p_process_instance_id, p_process_task_id,
     p_object_id, p_title, p_description, p_mime_type, p_comment,
     p_status_id, p_priority, v_start_date, p_due_date, p_assignee_id);

    return v_task_id;
end;
' language 'plpgsql';


select define_function_args('tasks_process_task__new','task_id,process_id,open_action_id,closing_action_id,object_id,title,description,mime_type,comment,status_id,priority,start,due,package_id,creation_user,creation_ip,context_id,assignee_id');

create or replace function tasks_process_task__new (integer,integer,integer,integer,integer,varchar,text,varchar,text,integer,integer,numeric,numeric,integer,integer,varchar,integer,integer)
returns integer as '
declare
    p_task_id                 alias for $1;
    p_process_id              alias for $2;
    p_open_action_id          alias for $3;
    p_closing_action_id       alias for $4;
    p_object_id               alias for $5;
    p_title                   alias for $6;
    p_description             alias for $7;
    p_mime_type               alias for $8;
    p_comment                 alias for $9;
    p_status_id               alias for $10;
    p_priority                alias for $11;
    p_start                   alias for $12;
    p_due                     alias for $13;
    p_package_id              alias for $14;
    p_creation_user           alias for $15;
    p_creation_ip             alias for $16;
    p_context_id              alias for $17;
    p_assignee_id             alias for $18;
    v_task_id                 integer;
begin
    v_task_id:= acs_object__new(
        p_task_id,
        ''tasks_process_task'',
        now(),
        p_creation_user,
        p_creation_ip,
        coalesce(p_context_id, p_package_id),
        ''t'',
        p_title,
        p_package_id
    );

    insert into t_process_tasks
    (task_id, process_id, open_action_id, closing_action_id,
     object_id, title, description, mime_type, comment, status_id,
     priority, start, due, assignee_id)
    values
    (v_task_id, p_process_id, p_open_action_id, p_closing_action_id,
     p_object_id, p_title, p_description, p_mime_type,
     p_comment, p_status_id, p_priority, p_start, p_due, p_assignee_id);

    return v_task_id;
end;
' language 'plpgsql';


select define_function_args('tasks_process_instance__new','process_instance_id,process_id,case_id,object_id,package_id,creation_user,creation_ip,context_id');

create or replace function tasks_process_instance__new (integer,integer,integer,integer,integer,integer,varchar,integer)
returns integer as '
declare
    p_process_instance_id     alias for $1;
    p_process_id              alias for $2;
    p_case_id                 alias for $3;
    p_object_id               alias for $4;
    p_package_id              alias for $5;
    p_creation_user           alias for $6;
    p_creation_ip             alias for $7;
    p_context_id              alias for $8;
    v_process_instance_id     integer;
begin
    v_process_instance_id:= acs_object__new(
        p_process_instance_id,
        ''tasks_process_instance'',
        now(),
        p_creation_user,
        p_creation_ip,
        coalesce(p_context_id, p_package_id),
        ''t'',
        ''process instance of process '' || p_process_id || '' for object '' || p_object_id,
        p_package_id
    );

    insert into t_process_instances
    (process_instance_id, process_id, case_id, object_id)
    values
    (v_process_instance_id, p_process_id, p_case_id, p_object_id);

    return v_process_instance_id;
end;
' language 'plpgsql';

select define_function_args('tasks_process__new','process_id,title,description,mime_type,workflow_id,assignee_id,package_id,creation_user,creation_ip,context_id');

create or replace function tasks_process__new (integer,varchar,text,varchar,integer,integer,integer,integer,varchar,integer)
returns integer as '
declare
    p_process_id              alias for $1;
    p_title                   alias for $2;
    p_description             alias for $3;
    p_mime_type               alias for $4;
    p_workflow_id             alias for $5;
    p_assignee_id             alias for $6;
    p_package_id              alias for $7;
    p_creation_user           alias for $8;
    p_creation_ip             alias for $9;
    p_context_id              alias for $10;
    v_process_id              integer;
begin
    v_process_id:= acs_object__new(
        p_process_id,
        ''tasks_process'',
        now(),
        p_creation_user,
        p_creation_ip,
        coalesce(p_context_id, p_package_id),
        ''t'',
        p_title,
        p_package_id
    );

    insert into t_processes
    (process_id, title, description, mime_type, workflow_id, assignee_id)
    values
    (v_process_id, p_title, p_description, p_mime_type, p_workflow_id, p_assignee_id);

    return v_process_id;
end;
' language 'plpgsql';










-- drop function tasks__completion_date (integer);
-- drop function takss__completion_user (integer);


-- alter table t_process_tasks drop constraint t_process_tasks_object_id_fk;

-- alter table t_process_tasks drop column party_id


-- t_tasks, t_process_tasks, t_process_instances

-- create application_data links for object_id
-- delete object_id values
-- move party_id to object_id



-- alter table t_process_tasks drop column party_id;
-- alter table t_tasks drop column party_id;
