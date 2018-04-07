ad_library {

    @author Timo Hentschel (timo@timohentschel.de)
    @creation-date 2005-09-21
    @arch-tag: 81868d37-99f5-48b1-8336-88e22c0e9001
    @cvs-id $Id: 
}

namespace eval tasks::install {}

ad_proc -public tasks::install::package_install {
} {
    Procedure to install certain information right after startup

    @author Timo Hentschel (timo@timohentschel.de)
    @creation-date 2005-09-21

} {
    set spec {
        name "Tasks_Action_SideEffect"
        aliases {
            GetObjectType tasks::workflow::impl::action_side_effect::object_type
            GetPrettyName tasks::workflow::impl::action_side_effect::pretty_name
            DoSideEffect  tasks::workflow::impl::action_side_effect::do
        }  
    }

    lappend spec contract_name [workflow::service_contract::action_side_effect]
    lappend spec owner tasks

    acs_sc::impl::new_from_spec -spec $spec
}


ad_proc -public tasks::install::after_upgrade {
    {-from_version_name:required}
    {-to_version_name:required}
} {
    apm_upgrade_logic \
        -from_version_name $from_version_name \
        -to_version_name $to_version_name \
        -spec {
	    0.1d 0.1d1 {
		set spec {
		    name "Tasks_Action_SideEffect"
		    aliases {
			GetObjectType tasks::workflow::impl::action_side_effect::object_type
			GetPrettyName tasks::workflow::impl::action_side_effect::pretty_name
			DoSideEffect  tasks::workflow::impl::action_side_effect::do
		    }  
		}

		lappend spec contract_name [workflow::service_contract::action_side_effect]
		lappend spec owner tasks

		acs_sc::impl::new_from_spec -spec $spec
	    }
            0.1d8 0.1d9 {

                ns_log notice "Attempting to upgrade from 0.1d8 to 0.1d9 if this fails please look at the proc tasks::install::after_upgrade for details..."

                # Tasks is being converted from an application to a service with this release.
		# this means that it can only deal with being mounted once and currently its 
                # assumed that tasks is only used in conjunction with contacts. The service
                # tasks from this version forward allows inclusion of tasks in any other package
                # much like the way general-comments, ams or categories works.

		# this switch is being made because version 1.2b4 of contacts is no longer
                # singleton and this is the cleanest way of providing tasks to contacts 
                # instances site wide and tasks will be used in other packages for tasks
                # relations.

		# this will fail if more than one instance exists
		set tasks_package_id [apm_package_id_from_key "tasks"]


		# now we make sure that all the associated parties are
                # a part of the '-2' group. This was the default group
                # for contacts until version 1.2b4 which is when contacts
                # was no longer singleton and allowed users to use groups
                # other than '-2'. We are assuming that this upgrade
                # is taking place at the same time as the contacts upgrade
                # which was released a few days ago. I know its bad to assume
                # and sorry if this hurts you ... but this is necessary for
                # the move to make tasks a service package that cannot be
                # mounted numerous times.

		set count_of_non_parties [db_string get_it { 
                      select count(*)
                        from t_tasks
                       where object_id not in ( select member_id from group_distinct_member_map where group_id = '-2' )
                }]

		if { $count_of_non_parties > 0 } {
		    error "Cannot upgrade from 0.1d8 to 0.1d9 because tasks is becoming a service and the upgrade scripts do not know how to deal with your setup. look at the tasks::install::after_upgrade for details"
		    ad_script_abort
		}



		# if we only have one or zero we are happy.
		if { $tasks_package_id == "0" } {
		    ns_log notice "No upgrade of task objects necessary because none exist and any newly created ones will be properly taken care of"
		} else {
		    # there is one package_id we can likely do the upgrade. All parties related
                    # to tasks are in the '-2' group so we can assume that contacts was used
                    # in the 1.2b3 or before setup. Thus we get the package_id of the contacts
                    # instance.

#                    set contacts_package_id [site_node::get_from_object_id -object_id [site_node::get_from_url -url "/contacts/" -exact]]
                    set contacts_package_id [apm_package_id_from_key "contacts"]
		    if { ![exists_and_not_null contacts_package_id] } {
			error "Cannot upgrade from 0.1d9 because there are tasks assigned to this package, but there is no contacts instance mounted at /contacts/"
		    } else {
			db_dml update_objects {
			    update acs_objects
			       set package_id = :contacts_package_id
			     where object_type in ( 'tasks_task', 'tasks_process', 'tasks_process_instance', 'tasks_process_task' )
			}
			db_dml update_objects {
                            update acs_objects
                               set context_id = :contacts_package_id
                             where object_type in ( 'tasks_task', 'tasks_process', 'tasks_process_instance', 'tasks_process_task' )
			}
		    }

                    # now we unmount the tasks instance (since this is now a service that does not need to be mounted)
#                    site_node::unmount -node_id [site_node::get_from_object_id -object_id $tasks_package_id]
		    
		}

	    }
	}
}
