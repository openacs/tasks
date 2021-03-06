-----------------------------------------------------
-- 
-- Create the data model for the timecard application
-- Author: Matthew Geddert geddert@yahoo.com
-- Creation Date: 2004-02-16
--
-----------------------------------------------------

create table t_processes (
        process_id                      integer
                                        constraint t_process_id_pk
                                        primary key
                                        constraint t_process_id_fk
                                        references acs_objects,
        title                           varchar(1000),
        description                     text,
        mime_type                       varchar(200) default 'text/plain',
        workflow_id                     integer
                                        constraint t_process_workflow_fk
                                        references workflows,
        -- the user assigned to this process
	assignee_id                     integer
);

create table t_process_instances (
        process_instance_id             integer
                                        constraint t_process_instances_id_pk
                                        primary key
                                        constraint t_process_instances_id_fk
                                        references acs_objects,
        process_id                      integer
                                        constraint t_process_instances_process_fk
                                        references t_processes,
        case_id                         integer,
        object_id                       integer
                                        constraint t_process_instances_tasks_object_fk
                                        references acs_objects
);


create sequence t_task_status_seq start 3;

create table t_task_status (
        status_id               integer
                                constraint t_task_status_pk
                                primary key,
        short_name              varchar(100),
        title                   varchar(100),
        -- closed or open
        status_type             char(1) default 'c'
                                constraint t_task_status_type_ck
                                check (status_type in ('c', 'o'))
);

insert into t_task_status (status_id, short_name, title, status_type) values
(1, 'open', '#acs-kernel.common_Open#', 'o');
insert into t_task_status (status_id, short_name, title, status_type) values
(2, 'closed', '#acs-kernel.common_Closed#', 'c');


create table t_process_tasks (
        task_id                 integer
                                constraint t_process_tasks_task_pk
                                primary key
                                constraint t_process_tasks_task_fk
                                references acs_objects,
        process_id              integer
                                constraint t_process_tasks_process_fk
                                references t_processes,
        -- action creating this task
        open_action_id          integer
                                constraint t_process_tasks_open_action_fk
                                references workflow_actions,
        -- action when closing task
        closing_action_id       integer
                                constraint t_process_tasks_close_action_fk
                                references workflow_actions,
        object_id               integer
                                constraint t_process_tasks_object_fk
                                references acs_objects,
        title                   varchar(1000),
        description             text,
        mime_type               varchar(200) default 'text/plain',
        comment                 text,
        status_id               integer
                                constraint t_process_tasks_status_fk
                                references t_task_status,
        priority                integer,
        -- start date relative to current date
        start                   numeric,
        -- due date relative to current date
        due                     numeric,
	assignee_id             integer
);


create table t_tasks (
        task_id                 integer
                                constraint t_tasks_task_pk
                                primary key
                                constraint t_tasks_task_fk
                                references acs_objects,
        process_instance_id     integer
                                constraint t_tasks_instance_fk
                                references t_process_instances,
        process_task_id         integer
                                constraint t_tasks_process_task_fk
                                references t_process_tasks,
        -- the object_id this tasks is applied to (such as a person, organization, page, etc.)
        object_id               integer
                                constraint t_tasks_object_fk
                                references acs_objects,
	-- I wish this were content_items...
        title                   varchar(1000),
        description             text,
        mime_type               varchar(200) default 'text/plain',
        comment                 text,
        status_id               integer
                                constraint t_tasks_status_fk
                                references t_task_status,
        priority                integer,
        start_date              timestamptz,
        due_date                timestamptz,
        completed_date          timestamptz,
        -- the user assigned to this task
	assignee_id             integer
);

 create index t_tasks_assignee_status_idx on t_tasks(assignee_id,status_id);
 create index t_tasks_object_idx on t_tasks(object_id);




CREATE FUNCTION inline_0()
RETURNS integer
AS 'declare
    begin
       PERFORM
	    acs_object_type__create_type(
		''tasks_task'',	-- object_type
		''#tasks.Task#'',	-- pretty_name
		''#tasks.Tasks#'',	-- pretty_plural
		''acs_object'',	-- supertype
		''t_tasks'',	-- table_name
		''task_id'',	-- id_column
		''tasks_task'',	-- package_name
		''f'',		-- abstract_p
		null,		-- type_extension_table
		null		-- name_method
	    );
		
       PERFORM
	    acs_object_type__create_type(
		''tasks_process'',	-- object_type
		''#tasks.Task_Process#'',	-- pretty_name
		''#tasks.Task_Processes#'',	-- pretty_plural
		''acs_object'',		-- supertype
		''t_processes'',	-- table_name
		''process_id'',		-- id_column
		''tasks_process'',	-- package_name
		''f'',			-- abstract_p
		null,			-- type_extension_table
		null			-- name_method
	    );
		
       PERFORM
	    acs_object_type__create_type(
		''tasks_process_instance'',	-- object_type
		''#tasks.Task_Process_Instance#'',	-- pretty_name
		''#tasks.Task_Process_Instances#'',	-- pretty_plural
		''acs_object'',			-- supertype
		''t_process_instances'',	-- table_name
		''process_instance_id'',	-- id_column
		''tasks_process_instance'',	-- package_name
		''f'',				-- abstract_p
		null,				-- type_extension_table
		null				-- name_method
	    );
		
       PERFORM
	    acs_object_type__create_type(
		''tasks_process_task'',	-- object_type
		''#tasks.Process_Task#'',	-- pretty_name
		''#tasks.Process_Tasks#'',	-- pretty_plural
		''acs_object'',		-- supertype
		''t_process_tasks'',	-- table_name
		''task_id'',		-- id_column
		''tasks_process_task'',	-- package_name
		''f'',			-- abstract_p
		null,			-- type_extension_table
		null			-- name_method
	    );
		
	    return 0;

    end;' 
LANGUAGE 'plpgsql';

SELECT inline_0();

DROP function inline_0();



create or replace function tasks__relative_date (
        timestamptz             -- date_comparative
) returns varchar
as '
declare
        p_date                  alias for $1;
        v_date                  varchar;
begin
	v_date := CASE WHEN to_char(p_date,''YYYY'') = to_char(now(),''YYYY'') THEN 
                       CASE WHEN to_char(p_date,''YYYY-MM-DD'') = to_char(now(),''YYYY-MM-DD'') THEN ''Today''
                            WHEN to_char(p_date,''YYYY-MM-DD'') = to_char((now() - ''1 day''::interval),''YYYY-MM-DD'') THEN ''Yesterday'' 
                            WHEN to_char(p_date,''YYYY-MM-DD'') = to_char((now() - ''2 day''::interval),''YYYY-MM-DD'') THEN ''Two Days Ago'' 
                            WHEN to_char(p_date,''YYYY-MM-DD'') = to_char((now() + ''1 day''::interval),''YYYY-MM-DD'') THEN ''Tomorrow'' 
                            WHEN to_char(p_date,''YYYY-MM-DD'') = to_char((now() + ''2 day''::interval),''YYYY-MM-DD'') THEN CASE WHEN to_char(p_date,''FMDay'') not in ( ''Sunday'', ''Saturday'', ''Monday'', ''Tuesday'') THEN to_char(p_date,''Day'') ELSE to_char(p_date,''Mon DD (Dy)'') END 
                            WHEN to_char(p_date,''YYYY-MM-DD'') = to_char((now() + ''3 day''::interval),''YYYY-MM-DD'') THEN CASE WHEN to_char(p_date,''FMDay'') not in ( ''Sunday'', ''Saturday'', ''Monday'', ''Tuesday'') THEN to_char(p_date,''Day'') ELSE to_char(p_date,''Mon DD (Dy)'') END 
                            WHEN to_char(p_date,''YYYY-MM-DD'') = to_char((now() + ''4 day''::interval),''YYYY-MM-DD'') THEN CASE WHEN to_char(p_date,''FMDay'') not in ( ''Sunday'', ''Saturday'', ''Monday'', ''Tuesday'') THEN to_char(p_date,''Day'') ELSE to_char(p_date,''Mon DD (Dy)'') END 
                            ELSE to_char(p_date,''Mon DD (Dy)'') END
                       ELSE to_char(p_date,''Mon DD, YYYY'') END;

        return v_date;
end;' language 'plpgsql';

-----------------------------

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
