FUNCTION zknsf_create_project.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  EXPORTING
*"     VALUE(E_MESSAGE) TYPE  STRING
*"     VALUE(E_ERROR) TYPE  ABAP_BOOLEAN
*"----------------------------------------------------------------------
  CLEAR e_message.
  CLEAR e_error.


  " Try to Create Check Variant
  DATA(check_variant) = zknsf_cl_classification_mangr=>create_scoring_check_variant(  ).
  IF check_variant IS INITIAL.
    e_message =  'Error during Check Variant Creation'.
    e_error = abap_true.
    RETURN.
  ENDIF.


  " Create Project
  TRY.
      DATA(transaction_manager) =
    /bobf/cl_tra_trans_mgr_factory=>get_transaction_manager(  ).
      transaction_manager->set_transaction_context( iv_enqueue_scope = /bobf/if_conf_c=>sc_enqueue_scope_dialog ).


      DATA(service_manager) =
        /bobf/cl_tra_serv_mgr_factory=>get_service_manager(
        iv_bo_key = if_sycm_aps_i_project_c=>sc_bo_key ).



      DATA(object_configuration) =
        /bobf/cl_frw_factory=>get_configuration(
        if_sycm_aps_i_project_c=>sc_bo_key
        ).


      DATA project_node TYPE sycm_aps_i_project.

      project_node-project_id = /bobf/cl_frw_factory=>get_new_key( ).
      project_node-description = 'Kernseife'.
      project_node-check_variant = check_variant.
      project_node-atc_check_kind = if_ycm_aps_persistence=>co_atc_check_kind-local.
      project_node-project_type = if_ycm_aps_persistence=>co_project_type-checkv.
      project_node-transition_scenario = if_ycm_aps_persistence=>co_transition_scenario-new_implementation.

      DATA: mod_table TYPE /bobf/t_frw_modification.
      APPEND VALUE /bobf/s_frw_modification(
                    node           = if_sycm_aps_i_project_c=>sc_node-sycm_aps_i_project
                    change_mode    = /bobf/if_frw_c=>sc_modify_create
                    changed_fields = VALUE #( ( `PROJECT_TYPE` ) )
                    key            = project_node-project_id
                    data           = REF #( project_node ) ) TO mod_table.


      service_manager->modify(
        EXPORTING
          it_modification = mod_table
        IMPORTING
          eo_change       = DATA(change_object)
          eo_message      = DATA(messages) ).


      IF change_object->has_failed_changes( ) = abap_false.
        transaction_manager->save(
          IMPORTING
            ev_rejected = DATA(was_rejected)
            eo_message  = messages ).
      ENDIF.

      " Handle Errors in BOPF
      IF change_object->has_failed_changes( ) = abap_true OR was_rejected EQ abap_true.
        messages->get( IMPORTING et_message = DATA(message_table) ).
        DATA(text) = message_table[ 1 ]->get_text( ).
        e_message =  text.
        e_error = abap_true.
      ENDIF.

      " Now Update & Activate

      CLEAR mod_table.
      CLEAR was_rejected.
      CLEAR change_object.
      CLEAR messages.

      APPEND VALUE /bobf/s_frw_modification(
        node           = if_sycm_aps_i_project_c=>sc_node-sycm_aps_i_project
        change_mode    = /bobf/if_frw_c=>sc_modify_update
        changed_fields = VALUE #( ( `CHECK_VARIANT` ) ( `ATC_CHECK_KIND` ) ( `DESCRIPTION` ) )
        key            = project_node-project_id
        data           = REF #( project_node ) ) TO mod_table.

      service_manager->modify(
        EXPORTING
          it_modification = mod_table
        IMPORTING
          eo_change       = change_object
          eo_message      = messages ).



      DATA key_table TYPE /bobf/t_frw_key.
      APPEND VALUE /bobf/s_frw_key( key = project_node-project_id ) TO key_table.
      service_manager->do_action( EXPORTING iv_act_key = if_sycm_aps_i_project_c=>sc_action-sycm_aps_i_project-activation
                                            it_key     = key_table
                                  IMPORTING eo_message = messages ).

      IF change_object->has_failed_changes( ) = abap_false.
        transaction_manager->save(
          IMPORTING
            ev_rejected = was_rejected
            eo_message  = messages ).
      ENDIF.

      " Handle Errors in BOPF
      IF change_object->has_failed_changes( ) = abap_true OR was_rejected EQ abap_true.
        messages->get( IMPORTING et_message = message_table ).
        text = message_table[ 1 ]->get_text( ).
        e_message =  text.
        e_error = abap_true.
      ENDIF.
    CATCH cx_root INTO DATA(exception_root).
      e_message =  |{ exception_root->get_text( ) }|.
      e_error = abap_true.
  ENDTRY.



ENDFUNCTION.
