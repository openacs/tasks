create table tasks (
        task_id                 integer
                                constraint tasks_pk
                                primary key
                                constraint tasks_task_fk
                                references acs_objects,
        party_id                integer
                                constraint tasks_party_fk
                                references parties,
        object_id               integer
                                constraint tasks_object_fk
                                references acs_objects,
        process_id              integer
                                constraint tasks_process_fk
                                references pm_process,
        title                   varchar(1000),
        description             text,
        mime_type               varchar(200) default 'text/plain'
                                constraint tasks_mime_type_fk
                                references cr_mime_types,
        comment                 text,
        due_date                timestamptz,
        priority                integer default 0,
        status                  char(1) default 'o'
                                constraint tasks_status_ck
                                check (status in ('o', 'c'))
);


create index tasks_party_idx on tasks(party_id);
create index tasks_object_idx on tasks(object_id);
create index tasks_due_date_idx on tasks(due_date);
create index tasks_status_idx on tasks(status);

create function inline_0 ()
returns integer as'
begin
    perform acs_object_type__create_type(
        ''tasks_task'',
        ''Tasks Task'',
        ''Tasks Tasks'',
        ''acs_object'',
        ''tasks'',
        ''task_id'',
        ''tasks'',
        ''f'',
        null,
        null
    );

    return null;
end;' language 'plpgsql';

select inline_0();
drop function inline_0();

select define_function_args('tasks__new','party_id,object_id,process_id,title,description,mime_type;text/plain,comment,due_date,priority;0,status;o,creation_date;now,creation_user,creation_ip,package_id');

create or replace function tasks__new (
  tasks.party_id%TYPE,
  tasks.object_id%TYPE,
  tasks.process_id%TYPE,
  tasks.title%TYPE,
  tasks.description%TYPE,
  tasks.mime_type%TYPE,
  tasks.comment%TYPE,
  tasks.due_date%TYPE,
  tasks.priority%TYPE,
  tasks.status%TYPE,
  acs_objects.creation_date%TYPE,
  acs_objects.creation_user%TYPE,
  acs_objects.creation_ip%TYPE,
  acs_objects.package_id%TYPE
) returns integer as '
declare
  new__party_id      alias for $1;
  new__object_id     alias for $2;
  new__process_id    alias for $3;
  new__title         alias for $4;
  new__description   alias for $5;
  new__mime_type     alias for $6;
  new__comment       alias for $7;
  new__due_date      alias for $8;
  new__priority      alias for $9;
  new__status        alias for $10;
  new__creation_date alias for $11;
  new__creation_user alias for $12;
  new__creation_ip   alias for $13;
  new__package_id    alias for $14;
  v_task_id        tasks.task_id%TYPE;
begin
  -- Create the object

  v_task_id := acs_object__new(
      null,
      'tasks_task', 
      new__creation_date, 
      new__creation_user, 
      new__creation_ip, 
      new__package_id,
      ''t'',
      new__title,
      new__package_id
  );

  insert into tasks (
    task_id, folder_id, party_id, object_id, process_id, title, description, mime_type,
    comment, due_date, priority, status
  ) values (
    v_task_id, new__folder_id, new__party_id, new__object_id, new__process_id, new__title,
    new__description, new__mime_type, new__comment, new__due_date, new__priority, new__status
  );

  return v_task_id;

end;' language 'plpgsql';

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
                                        references workflows
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
        party_id                        integer
                                        constraint t_process_instances_party_fk
                                        references parties,
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
        party_id                integer
                                constraint t_process_tasks_party_fk
                                references parties,
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
        due                     numeric
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
        party_id                integer
                                constraint t_tasks_party_fk
                                references parties,
        object_id               integer
                                constraint t_tasks_object_fk
                                references acs_objects,
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
        completed_date          timestamptz
);






CREATE FUNCTION inline_0()
RETURNS integer
AS 'declare
    begin
       PERFORM
	    acs_object_type__create_type(
		''tasks_task'',	-- object_type
		''Task'',	-- pretty_name
		''Tasks'',	-- pretty_plural
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
		''Task Process'',	-- pretty_name
		''Task Processes'',	-- pretty_plural
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
		''Task Process Instance'',	-- pretty_name
		''Task Process Instances'',	-- pretty_plural
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
		''Process Task'',	-- pretty_name
		''Process Tasks'',	-- pretty_plural
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

create or replace function tasks__completion_date (
	integer
) returns timestamptz
as '
declare
        p_task_id               alias for $1;
        v_complete_p            boolean;
        v_date                  varchar;
        v_previous_p            boolean;
        revision                record;
begin
        v_complete_p := ''1'' from pm_tasks where task_id = p_task_id and status = ''2'';
        v_date := NULL;

        IF v_complete_p THEN 
              v_previous_p := ''t'';
              FOR revision IN 
                  select ptr.percent_complete, ao.creation_date
                    from cr_revisions cr, pm_tasks_revisions ptr, acs_objects ao
                   where cr.item_id = p_task_id
                     and cr.revision_id = ao.object_id
                     and cr.revision_id = ptr.task_revision_id
                   order by ao.creation_date desc
              LOOP                 
                    IF revision.percent_complete = ''100'' AND v_previous_p THEN
	                  v_date := revision.creation_date;
                    ELSE
                          v_previous_p := ''f'';
                          EXIT;
                    END IF;
              END LOOP;

        END IF;

        return v_date;
end;' language 'plpgsql';


create or replace function tasks__completion_user (
	integer
) returns integer
as '
declare
        p_task_id               alias for $1;
        v_complete_p            boolean;
        v_user                  varchar;
        v_previous_p            boolean;
        revision                record;
begin
        v_complete_p := ''1'' from pm_tasks where task_id = p_task_id and status = ''2'';
        v_user := NULL;

        IF v_complete_p THEN 
              v_previous_p := ''t'';
              FOR revision IN 
                  select ptr.percent_complete, ao.creation_user
                    from cr_revisions cr, pm_tasks_revisions ptr, acs_objects ao
                   where cr.item_id = p_task_id
                     and cr.revision_id = ao.object_id
                     and cr.revision_id = ptr.task_revision_id
                   order by ao.creation_date desc
              LOOP                 
                    IF revision.percent_complete = ''100'' AND v_previous_p THEN
	                  v_user := revision.creation_user;
                    ELSE
                          v_previous_p := ''f'';
                          EXIT;
                    END IF;
              END LOOP;

        END IF;

        return v_user;
end;' language 'plpgsql';


-----------------------------

select define_function_args('tasks_task__new','task_id,process_instance_id,process_task_id,party_id,object_id,title,description,mime_type,comment,status_id,priority,start_date,due_date,package_id,creation_user,creation_ip,context_id');

create or replace function tasks_task__new (integer,integer,integer,integer,integer,varchar,text,varchar,text,integer,integer,timestamptz,timestamptz,integer,integer,varchar,integer)
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
     start_date, due_date)
    values
    (v_task_id, p_process_instance_id, p_process_task_id, p_party_id,
     p_object_id, p_title, p_description, p_mime_type, p_comment,
     p_status_id, p_priority, v_start_date, p_due_date);

    return v_task_id;
end;
' language 'plpgsql';


select define_function_args('tasks_process_task__new','task_id,process_id,open_action_id,closing_action_id,party_id,object_id,title,description,mime_type,comment,status_id,priority,start,due,package_id,creation_user,creation_ip,context_id');

create or replace function tasks_process_task__new (integer,integer,integer,integer,integer,integer,varchar,text,varchar,text,integer,integer,numeric,numeric,integer,integer,varchar,integer)
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
     priority, start, due)
    values
    (v_task_id, p_process_id, p_open_action_id, p_closing_action_id,
     p_party_id, p_object_id, p_title, p_description, p_mime_type,
     p_comment, p_status_id, p_priority, p_start, p_due);

    return v_task_id;
end;
' language 'plpgsql';


select define_function_args('tasks_process__new','process_id,title,description,mime_type,workflow_id,package_id,creation_user,creation_ip,context_id');

create or replace function tasks_process__new (integer,varchar,text,varchar,integer,integer,integer,varchar,integer)
returns integer as '
declare
    p_process_id              alias for $1;
    p_title                   alias for $2;
    p_description             alias for $3;
    p_mime_type               alias for $4;
    p_workflow_id             alias for $5;
    p_package_id              alias for $6;
    p_creation_user           alias for $7;
    p_creation_ip             alias for $8;
    p_context_id              alias for $9;
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
    (process_id, title, description, mime_type, workflow_id)
    values
    (v_process_id, p_title, p_description, p_mime_type, p_workflow_id);

    return v_process_id;
end;
' language 'plpgsql';


select define_function_args('tasks_process_instance__new','process_instance_id,process_id,case_id,party_id,object_id,package_id,creation_user,creation_ip,context_id');

create or replace function tasks_process_instance__new (integer,integer,integer,integer,integer,integer,integer,varchar,integer)
returns integer as '
declare
    p_process_instance_id     alias for $1;
    p_process_id              alias for $2;
    p_case_id                 alias for $3;
    p_party_id                alias for $4;
    p_object_id               alias for $5;
    p_package_id              alias for $6;
    p_creation_user           alias for $7;
    p_creation_ip             alias for $8;
    p_context_id              alias for $9;
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
    (process_instance_id, process_id, case_id, party_id, object_id)
    values
    (v_process_instance_id, p_process_id, p_case_id, p_party_id, p_object_id);

    return v_process_instance_id;
end;
' language 'plpgsql';
