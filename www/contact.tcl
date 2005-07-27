ad_page_contract {

    Main view page for tasks.

    @author jader@bread.com
    @creation-date 2003-12-03
    @cvs-id $Id$

    @return title Page title.
    @return context Context bar.
    @return tasks Multirow data set of tasks
    @return task_term Terminology for tasks
    @return task_term_lower Terminology for tasks (lower case)
    @return project_term Terminology for projects
    @return project_term_lower Terminology for projects (lower case)

    @param mine_p is used to make the default be the user, but
    still allow people to view everyone.

} {
    {orderby ""}
    {party_id ""}
    {searchterm ""}
    {mine_p "t"}
    {status_id "1"}
    {role_id "2"}
    {process_instance:integer,optional}
} -properties {
    task_term:onevalue
    context:onevalue
    tasks:multirow
    hidden_vars:onevalue
}

set user_id [ad_conn user_id]

if { ![contact::exists_p -party_id $party_id] } {
    set party_id $user_id
}
if { ![exists_and_not_null orderby] } {
    set orderby "priority,desc"
}
if { ![exists_and_not_null status_id] } {
    set status_id "1"
}
set done_url [export_vars -url -base "./contact" {orderby {status_id 2} party_id}]
set not_done_url [export_vars -url -base "./contact" {orderby {status_id 1} party_id}]
set return_url [export_vars -base "/tasks/contact" -url {orderby status_id party_id}]
set add_url [export_vars -base task {return_url orderby status_id party_id}]
set add_event_url [export_vars -base "/calendar/cal-item-new" -url {return_url party_id}]

set admin_p [permission::permission_p -object_id [ad_conn package_id] -privilege admin]
set task_term [ad_conn instance_name]
set context {}

#    -bulk_actions {
#	"Mark Completed" "mark-completed" "Mark Completed"
#	"Delete" "delete" "Delete"
#    } \
#    -bulk_action_export_vars {
#        {return_url} {orderby} {party_id}
#    } \


template::list::create \
    -name tasks \
    -multirow tasks \
    -key task_id \
    -elements {
        deleted_p {
	    label {<img src="/resources/acs-subsite/checkboxchecked.gif" alt="[_ tasks.Not_Done]" border="0" height="13" width="13">}
	    display_template {
		<if @tasks.done_p@><img src="/resources/acs-subsite/checkboxchecked.gif" alt="[_ tasks.Done]" border="0" height="13" width="13"></img></if>
                <else><a href="@tasks.complete_url@"><img src="/resources/acs-subsite/checkbox.gif" alt="[_ tasks.Not_Done]" border="0" height="13" width="13"></img></a></else>
	    }
	}
        priority {
	    label "[_ tasks.Priority]"
	    display_template {
		<if @tasks.done_p@><span class="done">@tasks.priority@</span></if><else>@tasks.priority@</else>
	    }
	}
	title {
	    label "[_ tasks.Task]"
            display_template {
		<a href="@tasks.task_url@" title="@tasks.title@"<if @tasks.done_p@> class="done"</if>>@tasks.title@</a>
		<if @tasks.description@ not nil>
		<if @tasks.done_p@><div class="done"></if>
                <p style="padding: 0; margin: 0; font-size: 0.85em; padding-left: 2em;">
		@tasks.description_html;noquote@
		</p>
		<if @tasks.done_p@></div></if>
		</if>
	    }
	}
        process {
	    label "[_ tasks.Process]"
	    display_template {
		<if @tasks.done_p@><span class="done">@tasks.process@</span></if>
                <else>
		  <if @tasks.process@ not nil>
		<a href="@tasks.process_minus_url@" style="text-decoration: none; font-weight: bold;">&laquo;</a>&nbsp;@tasks.process@&nbsp;<a href="@tasks.process_plus_url@" style="text-decoration: none; font-weight: bold;">&raquo;</a>
                  </if>
		</else>
	    }
	}
        date {
	    label "[_ tasks.Date]"
	    display_template {
		<if @tasks.done_p@><span class="done">@tasks.completed_date;noquote@</span></if>
                <else>
		  <if @tasks.end_date@>
		<a href="@tasks.task_minus_url@" style="text-decoration: none; font-weight: bold;">&laquo;</a>&nbsp;<if @tasks.end_date_passed_p@><span style="color: red;"></if>@tasks.end_date;noquote@<if @tasks.end_date_passed_p@></span></if>&nbsp;<a href="@tasks.task_plus_url@" style="text-decoration: none; font-weight: bold;">&raquo;</a>
                  </if>
                </else>
	    }
	}
	creation_user {
	    label "[_ tasks.Created_By]"
	    display_template {
		<a href="@tasks.creation_user_url@"<if @tasks.done_p@> class="done"</if>>@tasks.creation_name@</a>
	    }
	}      
    } \
    -sub_class {
        narrow
    } \
    -filters {
	party_id {}
    } -orderby {
        default_value $orderby
        date {
            label "[_ tasks.Due]"
            orderby_desc "CASE WHEN pt.status = 1 THEN ptr.end_date ELSE tasks__completion_date(ci.item_id) END desc, ptr.priority, upper(cr.title)"
            orderby_asc "CASE WHEN pt.status = 1 THEN ptr.end_date ELSE tasks__completion_date(ci.item_id) END asc, ptr.priority, upper(cr.title)"
            default_direction desc
        }
        priority {
            label "[_ tasks.Priority]"
            orderby_desc "pt.status, ptr.priority desc, CASE WHEN pt.status = 1 THEN ptr.end_date ELSE tasks__completion_date(ci.item_id) END desc, upper(cr.title)"
            orderby_asc "pt.status, ptr.priority asc, CASE WHEN pt.status = 1 THEN ptr.end_date ELSE tasks__completion_date(ci.item_id) END asc, upper(cr.title)"
            default_direction desc
        }
        title {
            label "[_ tasks.Task]"
            orderby_desc "upper(cr.title) desc, ptr.priority desc, ptr.end_date asc"
            orderby_asc "upper(cr.title) asc, ptr.priority desc, ptr.end_date asc"
            default_direction asc
        }
        process {
	    label "[_ tasks.Process]"
            orderby_desc "upper(ppi.name) desc, ptr.priority desc, ptr.end_date asc"
            orderby_asc "upper(ppi.name) asc, ptr.priority desc, ptr.end_date asc"
	    default_direction asc
	}
	creation_user {
	    label "[_ tasks.Created_By]"
            orderby_desc "upper(contact__name(ao.creation_user)) desc, ptr.end_date asc, ptr.priority, upper(cr.title)"
            orderby_asc "upper(contact__name(ao.creation_user)) asc, ptr.end_date asc, ptr.priority, upper(cr.title)"
	    default_direction asc
	}
    }



set project_id [tasks::project_id]
db_multirow -extend {creation_user_url complete_url done_p process_plus_url process_minus_url task_plus_url task_minus_url description_html task_url} -unclobber tasks get_tasks "
    select pt.task_id,
           tasks__relative_date(ptr.end_date) as  end_date,
           tasks__relative_date(tasks__completion_date(ci.item_id)) as completed_date,
           cr.title,
           cr.description,
           ptr.priority,
           :party_id as party_id,
           ppi.name as process,
           ppi.process_id as process_id,
           ao.creation_user,
           contact__name(ao.creation_user) as creation_name,
           pt.status as status_id,
           pt.process_instance,
           CASE WHEN ptr.end_date < now() THEN 't' ELSE 'f' END as end_date_passed_p
      from cr_items ci,
           pm_tasks_revisions ptr,
           pm_tasks pt left join pm_process_instance ppi on (pt.process_instance = ppi.instance_id ),
           cr_revisions cr,
           acs_objects ao
     where ci.parent_id = :project_id
       and ci.item_id = pt.task_id
       and ci.latest_revision = ptr.task_revision_id
       and ci.live_revision = ptr.task_revision_id
       and ptr.task_revision_id = cr.revision_id
       and cr.revision_id = ao.object_id
       and pt.deleted_p = 'f'
       and task_id in ( select task_id from pm_task_assignment where party_id = :party_id and role_id = '1' )
     [template::list::orderby_clause -orderby -name tasks]
" {
    set creation_user_url [contact::url -party_id $creation_user]
    regsub -all "/tasks/" $creation_user_url "/contacts/" creation_user_url
    set complete_url [export_vars -base "mark-completed" -url {task_id orderby party_id return_url}]
    if { $status_id == "2" } {
	set done_p 1
    } else {
	set done_p 0
    }
    set task_url [export_vars -base task -url {party_id orderby status task_id}]
    set task_plus_url  [export_vars -base task-interval -url {{action plus}  {days 7} party_id task_id status_id orderby return_url}]
    set task_minus_url [export_vars -base task-interval -url {{action minus} {days 7} party_id task_id status_id orderby return_url}]
    set process_plus_url  [export_vars -base process-interval -url {{action plus}  {days 7} party_id process_instance status_id orderby return_url}]
    set process_minus_url [export_vars -base process-interval -url {{action minus} {days 7} party_id process_instance status_id orderby return_url}]

    regsub -all "\r|\n" $description {LiNeBrEaK} description

    set description_html [ad_html_text_convert \
			      -from "text/plain" \
			      -to "text/html" \
			      -truncate_len "400" \
			      -more "<a href=\"${task_url}\">[_ tasks.more]</a>" \
			      -- $description]
    regsub -all {LiNeBrEaKLiNeBrEaK} $description_html {LiNeBrEaK} description_html
#    regsub -all {LiNeBrEaKLiNeBrEaK} $description_html {LiNeBrEaK} description_html
#    regsub -all {LiNeBrEaKLiNeBrEaK} $description_html {LiNeBrEaK} description_html 
# 167 is the actual paragraph standard internationally but 182 is more common in the US
    regsub -all {LiNeBrEaK} $description_html {\&nbsp;\&nbsp;\&#182;\&nbsp;} description_html

    regsub -all " " $end_date {\&nbsp;} end_date
    regsub -all " " $completed_date {\&nbsp;} completed_date
}

#        [template::list::filter_where_clauses -and -name tasks]
#set fred [template::list::orderby_clause -orderby -name tasks]
