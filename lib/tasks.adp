<if @tasks:rowcount@ gt 0>
<div class="tasks">
<h3>#tasks.Tasks#</h3>
<dl>
<multiple name="tasks">
  <dt<if @tasks.rownum@ eq 1> class="first"</if>><if @tasks.overdue_p@><span style="color: red; font-weight: bolder;"></if>@tasks.end_date@<if @tasks.overdue_p@></span></if></dt>
    <dd>
    <ul>
  <group column="end_date">
      <li><a href="@tasks.task_url@"><if @tasks.overdue_p@><span style="color: red; font-weight: bolder;"></if>@tasks.title@<if @tasks.overdue_p@></span></if></a></li>
  </group>
    </ul>
    </dd>
</multiple>
</dl>
</div>
</if>

