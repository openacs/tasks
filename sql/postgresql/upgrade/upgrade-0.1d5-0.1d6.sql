-- We add the extra fields
alter table t_tasks add column assignee_id integer;
alter table t_process_tasks add column assignee_id integer;

-- We create the functions

select define_function_args('tasks_task__new','task_id,process_instance_id,process_task_id,party_id,object_id,title,description,mime_type,comment,status_id,priority,start_date,due_date,package_id,creation_user,creation_ip,context_id,assignee_id');

create or replace function tasks_task__new (integer,integer,integer,integer,integer,varchar,text,varchar,text,integer,integer,timestamptz,timestamptz,integer,integer,varchar,integer,integer)
returns integer as '
declare
    p_task_id                 alias for $1;
    p_process_instance_id     alias for $2;
    p_process_task_id         alias for $3;
    p_party_id                alias for $4;
    p_object_id               alias for $5;
    p_title                   alias for $6;
    p_description             alias for $7;
    p_mime_type               alias for $8;
    p_comment                 alias for $9;
    p_status_id               alias for $10;
    p_priority                alias for $11;
    p_start_date              alias for $12;
    p_due_date                alias for $13;
    p_package_id              alias for $14;
    p_creation_user           alias for $15;
    p_creation_ip             alias for $16;
    p_context_id              alias for $17;
    p_assignee_id             alias for $18;
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
    (task_id, process_instance_id, process_task_id, party_id, object_id,
     title, description, mime_type, comment, status_id, priority,
     start_date, due_date, assignee_id)
    values
    (v_task_id, p_process_instance_id, p_process_task_id, p_party_id,
     p_object_id, p_title, p_description, p_mime_type, p_comment,
     p_status_id, p_priority, v_start_date, p_due_date, p_assignee_id);

    return v_task_id;
end;
' language 'plpgsql';


select define_function_args('tasks_process_task__new','task_id,process_id,open_action_id,closing_action_id,party_id,object_id,title,description,mime_type,comment,status_id,priority,start,due,package_id,creation_user,creation_ip,context_id,assignee_id');

create or replace function tasks_process_task__new (integer,integer,integer,integer,integer,integer,varchar,text,varchar,text,integer,integer,numeric,numeric,integer,integer,varchar,integer,integer)
returns integer as '
declare
    p_task_id                 alias for $1;
    p_process_id              alias for $2;
    p_open_action_id          alias for $3;
    p_closing_action_id       alias for $4;
    p_party_id                alias for $5;
    p_object_id               alias for $6;
    p_title                   alias for $7;
    p_description             alias for $8;
    p_mime_type               alias for $9;
    p_comment                 alias for $10;
    p_status_id               alias for $11;
    p_priority                alias for $12;
    p_start                   alias for $13;
    p_due                     alias for $14;
    p_package_id              alias for $15;
    p_creation_user           alias for $16;
    p_creation_ip             alias for $17;
    p_context_id              alias for $18;
    p_assignee_id             alias for $19;
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
    (task_id, process_id, open_action_id, closing_action_id, party_id,
     object_id, title, description, mime_type, comment, status_id,
     priority, start, due, assignee_id)
    values
    (v_task_id, p_process_id, p_open_action_id, p_closing_action_id,
     p_party_id, p_object_id, p_title, p_description, p_mime_type,
     p_comment, p_status_id, p_priority, p_start, p_due, p_assignee_id);

    return v_task_id;
end;
' language 'plpgsql';