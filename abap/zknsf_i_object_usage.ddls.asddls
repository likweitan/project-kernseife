@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'View of used objects'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
  serviceQuality: #X,
  sizeCategory: #S,
  dataClass: #MIXED
}
define view entity ZKNSF_I_OBJECT_USAGE
  with parameters usgid : susg_id
  as select from    tadir
    join            tdevc                on tadir.devclass = tdevc.devclass
    left outer join reposrc              on  tadir.object   = 'PROG'
                                         and tadir.obj_name = reposrc.progname
    left outer join SUSG_I_ODATA as susg on  tadir.object   = susg.obj_type
                                         and tadir.obj_name = susg.obj_name
                                         and susg.usgid = $parameters.usgid                                          
{
  tdevc.namespace,
  tadir.object,
  tadir.obj_name,
  sum( susg.counter )   as execution_count,
  max( susg.last_used ) as last_used
}

where
  (
          tadir.object    = 'TRAN'
    or    tadir.object    = 'CLAS'
    or    tadir.object    = 'FUGR'
    or    tadir.object    = 'FUGX'
    or    tadir.object    = 'FUGS'
    or(
          tadir.object    = 'PROG'
      and reposrc.subc      = '1'
    )
  )
  and     tdevc.namespace = '/0CUST/'
group by
  tdevc.namespace,
  tadir.object,
  tadir.obj_name
