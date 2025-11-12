/* checksum : 5f5a8836d0565fb2c6518434243204e7 */
@cds.external : true
@Aggregation.ApplySupported.Transformations : [ 'aggregate', 'groupby', 'filter' ]
@Aggregation.ApplySupported.Rollup : #None
@Common.ApplyMultiUnitBehaviorForSortingAndFiltering : true
@Capabilities.FilterFunctions : [
  'eq',
  'ne',
  'gt',
  'ge',
  'lt',
  'le',
  'and',
  'or',
  'contains',
  'startswith',
  'endswith',
  'any',
  'all'
]
@Capabilities.SupportedFormats : [ 'application/json', 'application/pdf' ]
@PDF.Features.DocumentDescriptionReference : '../../../../default/iwbep/common/0001/$metadata'
@PDF.Features.DocumentDescriptionCollection : 'MyDocumentDescriptions'
@PDF.Features.ArchiveFormat : true
@PDF.Features.Border : true
@PDF.Features.CoverPage : true
@PDF.Features.FitToPage : true
@PDF.Features.FontName : true
@PDF.Features.FontSize : true
@PDF.Features.Margin : true
@PDF.Features.Padding : true
@PDF.Features.Signature : true
@PDF.Features.HeaderFooter : true
@PDF.Features.ResultSizeDefault : 20000
@PDF.Features.ResultSizeMaximum : 20000
@Capabilities.KeyAsSegmentSupported : true
@Capabilities.AsynchronousRequestsSupported : true
service kernseife_btp {
  @cds.external : true
  type ZKNSF_I_FILE_STREAM {
    @Core.MediaType : 'application/octet-stream'
    @odata.Type : 'Edm.Stream'
    @Common.Label : 'Select file'
    streamProperty : LargeBinary not null;
    mimeType : String(128) not null;
    fileName : String(128) not null;
  };

  @cds.external : true
  type SAP__Message {
    code : String not null;
    message : String not null;
    target : String;
    additionalTargets : many String not null;
    transition : Boolean not null;
    @odata.Type : 'Edm.Byte'
    numericSeverity : Integer not null;
    longtextUrl : String;
  };

  @cds.external : true
  @cds.persistence.skip : true
  @Common.Label : 'Kernseife: Development Objects'
  @Capabilities.NavigationRestrictions.RestrictedProperties : [
    {
      NavigationProperty: _findings,
      InsertRestrictions: { Insertable: false }
    },
    {
      NavigationProperty: _metrics,
      InsertRestrictions: { Insertable: false }
    }
  ]
  @Capabilities.SearchRestrictions.Searchable : false
  @Capabilities.FilterRestrictions.Filterable : true
  @Capabilities.FilterRestrictions.FilterExpressionRestrictions : [
    { Property: devClass, AllowedExpressions: 'SearchExpression' },
    { Property: softwareComponent, AllowedExpressions: 'SearchExpression' }
  ]
  @Capabilities.SortRestrictions.NonSortableProperties : [ 'devClass', 'softwareComponent' ]
  @Capabilities.InsertRestrictions.Insertable : false
  @Capabilities.DeleteRestrictions.Deletable : false
  @Capabilities.UpdateRestrictions.Updatable : false
  @Capabilities.UpdateRestrictions.QueryOptions.SelectSupported : true
  entity ZKNSF_I_DEVELOPMENT_OBJECTS {
    @Common.Label : 'Project ID'
    @Common.Heading : 'Conversion Project Identification'
    key projectId : UUID not null;
    @Common.Label : 'Display ID'
    @Common.QuickInfo : 'ID for ''Display Load'' - overall result of ''ABAP Check Layer'''
    key runId : UUID not null;
    @Common.IsUpperCase : true
    @Common.Label : 'Object Type'
    @Common.Heading : 'Obj.'
    @Common.QuickInfo : 'Object Type in Object Directory'
    key objectType : String(4) not null;
    @Common.IsUpperCase : true
    @Common.Label : 'Object Name'
    @Common.QuickInfo : 'Object Name in Object Directory'
    key objectName : String(40) not null;
    @Common.IsUpperCase : true
    @Common.Label : 'Table Category'
    @Common.Heading : 'Tab.cat.'
    subType : String(8) not null;
    @Common.Label : 'Package'
    @Common.QuickInfo : 'Development package - as string'
    devClass : String(30) not null;
    @Common.Label : 'Software Component'
    @Common.QuickInfo : 'Software component - see "DLVUNIT" - as string'
    softwareComponent : String(30) not null;
    @Common.Label : 'Message Code'
    @Common.QuickInfo : 'Check message code'
    languageVersion : String(25) not null;
    @Common.IsUpperCase : true
    @Common.Label : 'Contact Person'
    @Common.QuickInfo : 'Contact person'
    contactPerson : String(12) not null;
    _findings : Association to many ZKNSF_I_FINDINGS {  };
    _metrics : Association to one ZKNSF_I_METRICS {  };
  };

  @cds.external : true
  @cds.persistence.skip : true
  @Common.Label : 'Kernseife: Findings for BTP Extraction'
  @Capabilities.SearchRestrictions.Searchable : false
  @Capabilities.FilterRestrictions.Filterable : true
  @Capabilities.FilterRestrictions.FilterExpressionRestrictions : [
    {
      Property: refApplicationComponent,
      AllowedExpressions: 'SearchExpression'
    },
    {
      Property: refSoftwareComponent,
      AllowedExpressions: 'SearchExpression'
    },
    { Property: refDevClass, AllowedExpressions: 'SearchExpression' }
  ]
  @Capabilities.SortRestrictions.NonSortableProperties : [ 'refApplicationComponent', 'refSoftwareComponent', 'refDevClass' ]
  @Capabilities.InsertRestrictions.Insertable : false
  @Capabilities.DeleteRestrictions.Deletable : false
  @Capabilities.UpdateRestrictions.Updatable : false
  @Capabilities.UpdateRestrictions.QueryOptions.SelectSupported : true
  entity ZKNSF_I_FINDINGS {
    @Common.Label : 'Project ID'
    @Common.Heading : 'Conversion Project Identification'
    key projectId : UUID not null;
    @Common.Label : 'runId'
    @Common.QuickInfo : 'Kernseife: Run ID'
    key runId : UUID not null;
    @Common.Label : 'itemId'
    @Common.QuickInfo : 'Kernseife: Item ID'
    key itemId : UUID not null;
    @Common.Label : 'objectType'
    @Common.QuickInfo : 'Kernseife: Object Type'
    objectType : String(16) not null;
    @Common.Label : 'objectName'
    @Common.QuickInfo : 'Kernseife: Object Name'
    objectName : String(40) not null;
    @Common.Label : 'messageId'
    @Common.QuickInfo : 'Kernseife: Message ID'
    messageId : String(25) not null;
    @Common.Label : 'refObjectType'
    @Common.QuickInfo : 'Kernseife: Object Type'
    refObjectType : String(16) not null;
    @Common.Label : 'refObjectName'
    @Common.QuickInfo : 'Kernseife: Object Name'
    refObjectName : String(40) not null;
    refApplicationComponent : String(80) not null;
    refSoftwareComponent : String(80) not null;
    refDevClass : String(80) not null;
  };

  @cds.external : true
  @cds.persistence.skip : true
  @Common.Label : 'Kernseife: Development Objects'
  @Capabilities.SearchRestrictions.Searchable : false
  @Capabilities.InsertRestrictions.Insertable : false
  @Capabilities.DeleteRestrictions.Deletable : false
  @Capabilities.UpdateRestrictions.Updatable : false
  @Capabilities.UpdateRestrictions.QueryOptions.SelectSupported : true
  entity ZKNSF_I_METRICS {
    @Common.Label : 'Project ID'
    @Common.Heading : 'Conversion Project Identification'
    key projectId : UUID not null;
    @Common.IsUpperCase : true
    @Common.Label : 'Object Type'
    @Common.Heading : 'Obj.'
    @Common.QuickInfo : 'Object Type in Object Directory'
    key objectType : String(4) not null;
    @Common.IsUpperCase : true
    @Common.Label : 'Object Name'
    @Common.QuickInfo : 'Object Name in Object Directory'
    key objectName : String(40) not null;
    difficulty : Integer64 not null;
    numberOfChanges : Integer64 not null;
  };

  @cds.external : true
  @cds.persistence.skip : true
  @Common.Label : 'Kernseife: Project'
  @Common.Messages : SAP__Messages
  @Capabilities.NavigationRestrictions.RestrictedProperties : [
    {
      NavigationProperty: _developmentObjects,
      InsertRestrictions: { Insertable: false }
    }
  ]
  @Capabilities.SearchRestrictions.Searchable : false
  @Capabilities.FilterRestrictions.Filterable : true
  @Capabilities.FilterRestrictions.FilterExpressionRestrictions : [ { Property: description, AllowedExpressions: 'SearchExpression' } ]
  @Capabilities.SortRestrictions.NonSortableProperties : [ 'description' ]
  @Capabilities.InsertRestrictions.Insertable : false
  @Capabilities.DeleteRestrictions.Deletable : false
  @Capabilities.UpdateRestrictions.Updatable : false
  @Capabilities.UpdateRestrictions.QueryOptions.SelectSupported : true
  entity ZKNSF_I_PROJECTS {
    @Common.Label : 'Project ID'
    @Common.Heading : 'Conversion Project Identification'
    key projectId : UUID not null;
    @Common.Label : 'Project Description'
    description : String(255) not null;
    @Common.Label : 'Display ID'
    @Common.QuickInfo : 'ID for ''Display Load'' - overall result of ''ABAP Check Layer'''
    displayId : UUID;
    @Common.IsUpperCase : true
    @Common.Label : 'Project State'
    status : String(10) not null;
    statusDescription : String(60) not null;
    @odata.Type : 'Edm.Byte'
    statusCriticality : Integer not null;
    @Common.Label : 'Series Name'
    @Common.QuickInfo : 'Name of configuration for run series'
    runId : String(16) not null;
    @Common.Label : 'Series Name'
    @Common.QuickInfo : 'Name of configuration for run series'
    runIdReferences : String(16) not null;
    totalObjectCount : Integer not null;
    findingCount : Integer not null;
    SAP__Messages : many SAP__Message not null;
    _developmentObjects : Association to many ZKNSF_I_DEVELOPMENT_OBJECTS {  };
  } actions {
    action UploadFile(
      _it : many $self not null,
      @UI.Hidden : true
      @Common.Label : 'Truth Value'
      @Common.QuickInfo : 'Truth Value: True/False'
      dummy : Boolean not null,
      _StreamProperties : ZKNSF_I_FILE_STREAM not null
    );
    action Setup(
      _it : many $self not null
    );
  };
};

