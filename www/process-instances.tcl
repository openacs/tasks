# 

ad_page_contract {
    
    Lists all the process instances of a given process_id
    
    @author  (ibr@test)
    @creation-date 2004-11-05
    @arch-tag: 57bfd18d-a3e5-4047-8185-06707c42f058
    @cvs-id $Id$
} {
    process_id:integer,notnull
} -properties {
} -validate {
} -errors {
}


# set up context bar
set title   "Process Instances"
set context [list [list "Processes" processes] $title]
set header_stuff ""

# the unique identifier for this package
set package_id [ad_conn package_id]
set user_id    [ad_maybe_redirect_for_registration]

# permissions
permission::require_permission -party_id $user_id -object_id $package_id -privilege read

# Processes, using list-builder ---------------------------------

template::list::create \
    -name instances \
    -multirow instances \
    -key instance_id \
    -elements {
        edit {
            display_template {
                <a href="process-instance-edit?instance_id=@instances.instance_id@">
                <img border="0" src="/shared/images/Edit16.gif" alt="Edit" />
                </a>
            }
        }
        instance_id {
            label "ID"
        }
        name {
            label "Name"
        }
        project_item_id {
            label "Project"
            display_template {
                <a href="one?project_item_id=@instances.project_item_id@&instance_id=@instances.instance_id@">@instances.project_name@</a>
            }
        }
        active_tasks {
            label "Active tasks"
        }
    } \
    -main_class {
        narrow
    } \
    -html {
        width 100%
    }


db_multirow -extend { delete_url creation_date } instances instances_query {
} {
    set delete_url [export_vars -base "process-delete" {process_id}]
}

