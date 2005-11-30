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
	}
}
