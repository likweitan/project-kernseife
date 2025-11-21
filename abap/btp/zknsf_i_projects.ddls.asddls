@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Kernseife: Project'
@Metadata.ignorePropagatedAnnotations: true
define root view entity ZKNSF_I_PROJECTS
  as select from    sycm_aps_c_project           as projects
    left outer join sycm_aps_i_atc_result_latest as latest on latest.project_id = projects.project_id
    
    association [0..*] to ZKNSF_I_DEVELOPMENT_OBJECTS as _developmentObjects on _developmentObjects.projectId = $projection.projectId
{
  key projects.project_id                as projectId,
      projects.description,
      
      latest.display_id                  as displayId,

      projects.project_status            as status,
      projects._project_status_text.text as statusDescription,
      projects.project_status_crit       as statusCriticality,


      projects.atc_run_series            as runId,
      projects.atc_run_series_refs       as runIdReferences,
      projects.number_all_objects        as totalObjectCount,

      projects.number_findings           as findingCount,
      _developmentObjects

}
where
      projects.project_type  = 'CHECKV'
  and projects.check_variant = 'ZKNSF_SCORING';
