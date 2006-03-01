drop table t_tasks;
drop table t_process_tasks;
drop table t_task_status;
drop table t_process_instances;
drop table t_processes;

select acs_object_type__drop_type('tasks_task','t');
select acs_object_type__drop_type('tasks_process','t');
select acs_object_type__drop_type('tasks_process_instance','t');
select acs_object_type__drop_type('tasks_process_task','t');

select drop_package('tasks');
select drop_package('tasks_task');
select drop_package('tasks_process');
select drop_package('tasks_process_instance');
select drop_package('tasks_process_task');

drop sequence t_task_status_seq;
