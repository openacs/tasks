-----------------------------------------------------
-- 
-- Create the data model for the timecard application
-- Author: Matthew Geddert geddert@yahoo.com
-- Creation Date: 2004-02-16
--
-----------------------------------------------------

create table tasks_pm_process_task (
        process_task_id         integer
                                constraint tasks_pm_process_task_id_fk references pm_process_task(process_task_id)
                                constraint tasks_pm_process_task_id_pk primary key,
        due_interval            interval,
        due_date                timestamptz,
        priority                integer default 0
);

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
