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
  <if @show_filters_p@>
    <listfilters name="tasks" style="select-menu"></listfilters>
    <br />
  </if>

</else>
<listtemplate name="tasks"></listtemplate>

