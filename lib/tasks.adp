<if @show_form_p@ true>
  <if @task_action@ eq edit>
    <include src="/packages/tasks/lib/task-form"
             object_id=@object_id;noquote@
             task_id=@task_action_id;noquote@
             return_url=@return_url;noquote@ 
             export_vars_list=@export_vars_list;noquote@ />
  </if>
  <else>
    <include src="/packages/tasks/lib/task-form"
             object_id=@object_id;noquote@
             return_url=@return_url;noquote@ 
             export_vars_list=@export_vars_list;noquote@ />
  </else>
  </div>
</if>
<elseif @task_action@ eq add_process>
<h3>#tasks.Assign_Process#</h3>
<listtemplate name="processes"></listtemplate>
<br />
<p><a href="@return_url@" class="button">#tasks.Cancel#</a><br />
</p>
</elseif>
<else>

 <if @single_object_p@ true>
    <p>
     <a href="@add_url@" class="button">#tasks.Add_Task#</a>
     <a href="@add_process_url@" class="button">#tasks.Assign_Process#</a>
    </p>
  </if>

</else>
	     <include
        	src="/packages/tasks/lib/tasks-list"
	        object_query=@object_query@
                package_id="@package_id@"
        	hide_form_p="t" 
		assignee_id="@assignee_id@"
		page_size="@page_size@" 
		show_filters_p="@show_filters_p@"
                hide_elements=@hide_elements@ />	


