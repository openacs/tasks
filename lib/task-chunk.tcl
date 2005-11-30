set title    [lindex $content 0]
set content  [lindex $content 1]
set task_url [export_vars -base "/tasks/task" -url {{task_id $object_id} party_id}]
