<p>
<if @contact_id@ ne @user_id2@>
<a href="@add_url@" class="button">#tasks.Add_Task#</a>
<a href="/tasks/processes?assignee_id=@contact_id@" class="button">#tasks.Assign_Process#</a>
</p>
</if>
<if @show_filters_p@>
<listfilters name="tasks" style="select-menu"></listfilters>
</if>
<br>
<listtemplate name="tasks"></listtemplate>
