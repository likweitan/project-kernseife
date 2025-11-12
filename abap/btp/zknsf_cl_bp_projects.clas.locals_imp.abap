CLASS lhc_project DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PUBLIC SECTION.
    METHODS finish_setup IMPORTING p_task TYPE c.
  PRIVATE SECTION.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR project RESULT result.

    METHODS setup FOR MODIFY
      IMPORTING keys FOR ACTION project~setup.


    METHODS uploadfile FOR MODIFY
      IMPORTING keys FOR ACTION project~uploadfile.



    DATA: create_project_message TYPE string.
    DATA: project_creation_finished TYPE abap_boolean.
ENDCLASS.

CLASS lhc_project IMPLEMENTATION.

  METHOD get_instance_authorizations.
  ENDMETHOD.

  METHOD setup.
    " Check if there is already a Custom Code Migration Project
    SELECT SINGLE  description FROM zknsf_i_projects INTO @DATA(description).
    IF sy-subrc EQ 0 AND description IS NOT INITIAL.
      " Error => already exists
      reported-%other = VALUE #( ( new_message_with_text( severity = if_abap_behv_message=>severity-warning text = |Kernseife Project already exists: {  description }| ) ) ).
      RETURN.
    ENDIF.

    project_creation_finished = abap_false.
    CALL FUNCTION 'ZKNSF_CREATE_PROJECT' STARTING NEW TASK 'KNSF_CREATE'
      DESTINATION 'NONE'
      CALLING finish_setup ON END OF TASK.

    WAIT FOR ASYNCHRONOUS TASKS UNTIL project_creation_finished EQ abap_true.

    IF create_project_message IS NOT INITIAL.
      reported-%other = VALUE #( ( new_message_with_text( severity = if_abap_behv_message=>severity-error text = |Failed: {  create_project_message }| ) ) ).
      RETURN.
    ENDIF.

    reported-%other = VALUE #( ( new_message_with_text( severity = if_abap_behv_message=>severity-success text = |Project created| ) ) ).
  ENDMETHOD.

  METHOD finish_setup.

    RECEIVE RESULTS FROM FUNCTION 'ZKNSF_CREATE_PROJECT'
       IMPORTING
         e_message = create_project_message.
    project_creation_finished = abap_true.
  ENDMETHOD.


  METHOD uploadfile.
    DATA message TYPE string.
    DATA(classification_manager) = NEW zknsf_cl_classification_mangr( ).

    " Upload File
    DATA(file_content) = VALUE #( keys[ 1 ]-%param-_streamproperties-streamproperty OPTIONAL ).
    DATA(file_name) = VALUE #( keys[ 1 ]-%param-_streamproperties-filename OPTIONAL ).
    DATA(file_type) = zknsf_cl_classification_mangr=>ty_custom_file_type-kernseife_custom.

    DATA(zip) = NEW cl_abap_zip( ).

    zip->load( file_content ).

    IF lines( zip->files ) <> 1.
      MESSAGE ID 'ZKNSF' TYPE 'E' NUMBER 001 INTO message.
      RETURN.
    ENDIF.
    IF NOT zip->files[ 1 ]-name CP '*.json'.
      MESSAGE ID 'ZKNSF' TYPE 'E' NUMBER 001 INTO message.
    ENDIF.

    zip->get( EXPORTING name    = zip->files[ 1 ]-name
              IMPORTING content = file_content ).


    TRY.
        " Now delete existing files
        DATA(api_files) = classification_manager->get_api_files( ).
        LOOP AT api_files ASSIGNING FIELD-SYMBOL(<api_file>).
          classification_manager->delete_file( url = CONV string( <api_file>-url ) ).
        ENDLOOP.

        " Then add the new ones
        classification_manager->upload_custom_file( file_content = file_content
                                                    file_name    = CONV string( file_name )
                                                    file_type    = file_type
                                                    uploader     = sy-uname ).
      CATCH cx_root.
        ASSERT 1 = 2.
    ENDTRY.
  ENDMETHOD.
ENDCLASS.
