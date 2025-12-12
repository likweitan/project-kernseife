namespace kernseife.db;

using {
    cuid,
    managed
} from '@sap/cds/common';


aspect DevelopmentObjectAspect {
        @Common.ValueListWithFixedValues: true
        @(Common                        : {
            Label    : '{i18n>objectType}',
            ValueList: {
                CollectionPath: 'ObjectTypeValueList',
                Parameters    : [{
                    $Type            : 'Common.ValueListParameterInOut',
                    LocalDataProperty: objectType,
                    ValueListProperty: 'objectType'
                }]
            }
        })
    key objectType              : String;
    key objectName              : String;

        @readonly
        @(Common                        : {
            Label    : '{i18n>devClass}',
            ValueList: {
                CollectionPath: 'DevClassValueList',
                Parameters    : [{
                    $Type            : 'Common.ValueListParameterInOut',
                    LocalDataProperty: devClass,
                    ValueListProperty: 'devClass'
                }]
            }
        })
    key devClass                : String;

        @Common.ValueListWithFixedValues: true
        @(Common                        : {
            Label    : '{i18n>systemId}',
            ValueList: {
                CollectionPath: 'Systems',
                Parameters    : [
                    {
                        $Type            : 'Common.ValueListParameterInOut',
                        LocalDataProperty: systemId,
                        ValueListProperty: 'sid'
                    },
                    {
                        $Type            : 'Common.ValueListParameterDisplayOnly',
                        ValueListProperty: 'title'
                    }
                ]
            }
        })
    key systemId                : String;
        system                  : Association to Systems
                                      on system.sid = $self.systemId;

        @readonly
        extension_ID            : UUID;

        @readonly
        extension               : Association to Extensions
                                      on extension.ID = $self.extension_ID;

        @Common.ValueListWithFixedValues: true
        @(Common                        : {
            Label    : '{i18n>namespace}',
            ValueList: {
                CollectionPath: 'NamespaceValueList',
                Parameters    : [{
                    $Type            : 'Common.ValueListParameterInOut',
                    LocalDataProperty: namespace,
                    ValueListProperty: 'namespace'
                }]
            }
        })
        namespace               : String;
        softwareComponent       : String;

        @Common.ValueListWithFixedValues: true
        @(Common                        : {
            Label    : '{i18n>languageVersion}',
            ValueList: {
                CollectionPath: 'LanguageVersions',
                Parameters    : [
                    {
                        $Type            : 'Common.ValueListParameterInOut',
                        LocalDataProperty: languageVersion_code,
                        ValueListProperty: 'code'
                    },
                    {
                        $Type            : 'Common.ValueListParameterDisplayOnly',
                        ValueListProperty: 'title'
                    }
                ]
            }
        })
        languageVersion_code    : String;
        version_ID              : UUID;


        score                   : Integer;
        potentialScore          : Integer;
        level                   : CleanCoreLevel;
        potentialLevel          : CleanCoreLevel;
        cleanupPotential        : Integer       = score - potentialScore stored;

        @Common.Label                   : '{i18n>cleanupPotentialPercent}'
        @Measures.Unit                  : '%'
        cleanupPotentialPercent : Decimal(8, 2) = (
            score > 0
        ) ? (
            100.0 - (
                (
                    100.0 / score
                ) * potentialScore
            )
        ) : 0 stored;

        difficulty              : Integer default 0;
        numberOfChanges         : Integer default 0;

        // Associations
        languageVersion         : Association to LanguageVersions
                                      on languageVersion.code = $self.languageVersion_code;
        version                 : Association to DevelopmentObjectVersions
                                      on version.ID = $self.version_ID;


        findingList             : Association to many DevelopmentObjectFindings
                                      on  findingList.objectType = $self.objectType
                                      and findingList.objectName = $self.objectName
                                      and findingList.devClass   = $self.devClass
                                      and findingList.systemId   = $self.systemId
                                      and findingList.version_ID = $self.version_ID;

        usageList               : Association to many DevelopmentObjectUsages
                                      on  usageList.objectType = $self.objectType
                                      and usageList.objectName = $self.objectName;

}

@cds.persistence.journal
entity DevelopmentObjects : managed, DevelopmentObjectAspect {}

@cds.persistence.journal
entity HistoricDevelopmentObjects : managed, DevelopmentObjectAspect {}

@cds.persistence.journal
entity DevelopmentObjectVersions : managed, cuid {
    systemId : String;

    // Use the same UUID as for the Import to make relations easier
    import   : Association to Imports
                   on import.ID = $self.ID;
}

@cds.persistence.journal
entity DevelopmentObjectFindings {
    key version_ID        : UUID;

    key objectType        : String;
    key objectName        : String;
    key refObjectType     : String;
    key refObjectName     : String;
    key devClass          : String;
    key code              : String;
        softwareComponent : String;
        systemId          : String;

        potentialCode     : String;

        // Pre-Calculated for performance
        total             : Integer;
        count             : Integer;
        totalPercentage   : Decimal(5, 2);

        version           : Association to DevelopmentObjectVersions
                                on version.ID = $self.version_ID;

        rating            : Association to Ratings
                                on rating.code = $self.code;
        potentialRating   : Association to Ratings
                                on potentialRating.code = $self.potentialCode;
        releaseState      : Association to ReleaseStates
                                on  releaseState.objectType = $self.refObjectType
                                and releaseState.objectName = $self.refObjectName;
        developmentObject : Association to DevelopmentObjects
                                on  developmentObject.objectType = $self.objectType
                                and developmentObject.objectName = $self.objectName
                                and developmentObject.devClass   = $self.devClass;
        classification    : Association to Classifications
                                on  classification.objectType = $self.refObjectType
                                and classification.objectName = $self.refObjectName;

}

@cds.persistence.journal
entity ReleaseStates : cuid {
    tadirObjectType         : String;
    tadirObjectName         : String;
    objectType              : String;
    objectName              : String;
    softwareComponent       : String;
    applicationComponent    : String;
    releaseInfo             : Association to ReleaseInfo;
    classicInfo             : Association to ClassicInfo;
    releaseLevel            : Association to ReleaseLevel;
    successorClassification : Association to SuccessorClassifications;
    successorConceptName    : String;
    successorList           : Composition of many ReleaseStateSuccessors
                                  on successorList.releaseState = $self;
    labelList               : many String;
}

@cds.persistence.journal
entity ReleaseStateSuccessors : cuid {
    releaseState    : Association to ReleaseStates;
    tadirObjectType : String;
    tadirObjectName : String;
    objectType      : String;
    objectName      : String;
}


@cds.persistence.journal
entity Classifications : managed {
    key tadirObjectType             : String;
    key tadirObjectName             : String;

        @Common.ValueListWithFixedValues: true
        @(Common                        : {
            Label    : '{i18n>objectType}',
            ValueList: {
                CollectionPath: 'ObjectTypeValueList',
                Parameters    : [{
                    $Type            : 'Common.ValueListParameterInOut',
                    LocalDataProperty: objectType,
                    ValueListProperty: 'objectType'
                }]
            }
        })
    key objectType                  : String;
    key objectName                  : String;

        @(Common: {
            Label    : '{i18n>applicationComponent}',
            ValueList: {
                CollectionPath: 'ApplicationComponentValueList',
                Parameters    : [{
                    $Type            : 'Common.ValueListParameterInOut',
                    LocalDataProperty: applicationComponent,
                    ValueListProperty: 'applicationComponent'
                }]
            }
        })
        applicationComponent        : String;


        @Common.ValueListWithFixedValues: true
        @(Common                        : {
            Label    : '{i18n>objectType}',
            ValueList: {
                CollectionPath: 'ObjectSubTypeValueList',
                Parameters    : [{
                    $Type            : 'Common.ValueListParameterInOut',
                    LocalDataProperty: subType,
                    ValueListProperty: 'subType'
                }]
            }
        })
        subType                     : String;

        @readonly
        @Common.ValueListWithFixedValues: true
        @(Common                        : {
            Label    : '{i18n>softwareComponent}',
            ValueList: {
                CollectionPath: 'SoftwareComponentValueList',
                Parameters    : [{
                    $Type            : 'Common.ValueListParameterInOut',
                    LocalDataProperty: softwareComponent,
                    ValueListProperty: 'softwareComponent'
                }]
            }
        })
        softwareComponent           : String;

        frameworkUsageList          : Composition of many FrameworkUsages
                                          on frameworkUsageList.classification = $self;

        adoptionEffort              : Association to AdoptionEffort
                                          on adoptionEffort.code = $self.adoptionEffort_code;

        @Common.ValueListWithFixedValues: true
        @(Common                        : {
            Label    : '{i18n>adoptionEffort}',
            ValueList: {
                CollectionPath: 'AdoptionEffortValueList',
                Parameters    : [
                    {
                        $Type            : 'Common.ValueListParameterInOut',
                        LocalDataProperty: adoptionEffort_code,
                        ValueListProperty: 'code'
                    },
                    {
                        $Type            : 'Common.ValueListParameterDisplayOnly',
                        ValueListProperty: 'title'
                    }
                ]
            }
        })
        adoptionEffort_code         : type of AdoptionEffort : code;
        comment                     : String;

        @readonly
        referenceCount              : Integer;


        @Common.ValueListWithFixedValues: true
        @(Common                        : {Label: '{i18n>releaseLevel}'})
        @readonly
        releaseLevel                : Association to ReleaseLevel;

        @readonly
        releaseState                : Association to ReleaseStates
                                          on  releaseState.tadirObjectType      = $self.tadirObjectType
                                          and releaseState.tadirObjectName      = $self.tadirObjectName
                                          and releaseState.objectType           = $self.objectType
                                          and releaseState.objectName           = $self.objectName
                                          and releaseState.applicationComponent = $self.applicationComponent;

        @(Common: {Label: '{i18n>numberOfSimplificationNotes}'})
        numberOfSimplificationNotes : Integer default 0;

        @Common.ValueListWithFixedValues: true
        @(Common                        : {
            Label    : '{i18n>successorClassificationValueList}',
            ValueList: {
                CollectionPath: 'SuccessorClassificationsValueList',

                Parameters    : [
                    {
                        $Type            : 'Common.ValueListParameterInOut',
                        LocalDataProperty: successorClassification_code,
                        ValueListProperty: 'code'
                    },
                    {
                        $Type            : 'Common.ValueListParameterDisplayOnly',
                        ValueListProperty: 'title'
                    },
                    {
                        $Type            : 'Common.ValueListParameterDisplayOnly',
                        ValueListProperty: 'obsolete'
                    }
                ]
            }
        })
        successorClassification     : Association to SuccessorClassifications;

        successorList               : Composition of many ClassificationSuccessors
                                          on successorList.classification = $self;

        noteList                    : Composition of many Notes
                                          on noteList.classification = $self;


        rating                      : Association to Ratings
                                          on rating.code = $self.rating_code;

        @Common.ValueListWithFixedValues: true
        @(Common                        : {
            Label    : '{i18n>rating}',
            ValueList: {
                CollectionPath: 'RatingsValueList',

                Parameters    : [
                    {
                        $Type            : 'Common.ValueListParameterInOut',
                        LocalDataProperty: rating_code,
                        ValueListProperty: 'code'
                    },
                    {
                        $Type            : 'Common.ValueListParameterDisplayOnly',
                        ValueListProperty: 'title'
                    },
                    {
                        $Type            : 'Common.ValueListParameterDisplayOnly',
                        ValueListProperty: 'score'
                    }
                ]
            }
        })
        rating_code                 : type of Ratings : code;

        codeSnippets                : Composition of many CodeSnippets
                                          on codeSnippets.classification = $self;

        @(Common                        : {Label: '{i18n>totalScore}'})
        @readonly
        totalScore                  : Integer;
        findingList                 : Association to many DevelopmentObjectFindings
                                          on  findingList.refObjectType = $self.objectType
                                          and findingList.refObjectName = $self.objectName;

}

@cds.persistence.journal
entity CodeSnippets : cuid {
    classification : Association to Classifications;

    @mandatory
    title          : String;
    comment        : String;
    coding         : String;
}

@cds.persistence.journal
entity Notes : cuid {
    classification          : Association to Classifications;

    @mandatory
    note                    : String;
    title                   : String;


    noteClassification      : Association to NoteClassifications
                                  on noteClassification.code = $self.noteClassification_code;

    @Common.ValueListWithFixedValues: true
    @(Common                        : {
        Label    : '{i18n>noteClassification}',
        ValueList: {
            CollectionPath: 'NoteClassificationsValueList',
            Parameters    : [
                {
                    $Type            : 'Common.ValueListParameterInOut',
                    LocalDataProperty: noteClassification_code,
                    ValueListProperty: 'code'
                },
                {
                    $Type            : 'Common.ValueListParameterDisplayOnly',
                    ValueListProperty: 'title'
                }
            ]
        }
    })
    noteClassification_code : type of NoteClassifications : code;
}

@cds.persistence.journal
entity ClassificationSuccessors : cuid {
    classification     : Association to Classifications;
    tadirObjectType    : String;
    tadirObjectName    : String;
    objectType         : String;
    objectName         : String;

    successorType      : Association to SuccessorTypes
                             on successorType.code = $self.successorType_code;

    @Common.ValueListWithFixedValues: true
    @(Common                        : {
        Label    : '{i18n>successorType}',
        ValueList: {
            CollectionPath: 'SuccessorTypes',
            Parameters    : [
                {
                    $Type            : 'Common.ValueListParameterInOut',
                    LocalDataProperty: successorType_code,
                    ValueListProperty: 'code'
                },
                {
                    $Type            : 'Common.ValueListParameterDisplayOnly',
                    ValueListProperty: 'title'
                }
            ]
        }
    })
    successorType_code : type of SuccessorTypes : code;
}

@cds.persistence.journal
entity Imports : cuid, managed {
    type          : String;
    title         : String;
    systemId      : String;
    comment       : String;
    overwrite     : Boolean default false;
    defaultRating : String(3);
    system        : Association to Systems
                        on system.sid = $self.systemId;

    @Core.MediaType                  : fileType
    @Core.ContentDisposition.Filename: fileName
    file          : LargeBinary;

    @Core.IsMediaType
    fileType      : String;
    fileName      : String;

    job_ID        : UUID;
    job           : Association to Jobs
                        on job.ID = $self.job_ID;
}

@cds.persistence.journal
entity Exports : cuid, managed {
    type     : String;

    @Core.MediaType                  : fileType
    @Core.ContentDisposition.Filename: fileName
    file     : LargeBinary;

    @Core.IsMediaType
    fileType : String;
    fileName : String;

    job_ID   : UUID;
    job      : Association to Jobs
                   on job.ID = $self.job_ID;
}

@cds.persistence.journal
entity FindingRecords {
    key import_ID          : UUID;
    key itemId             : String;
        objectType         : String;
        objectName         : String;
        refObjectType      : String;
        refObjectName      : String;
        devClass           : String;
        softwareComponent  : String;
        systemId           : String;
        messageId          : String;
        potentialMessageId : String;
        import             : Association to Imports
                                 on import.ID = $self.import_ID;
        rating             : Association to Ratings
                                 on rating.code = $self.messageId;
        potentialRating    : Association to Ratings
                                 on potentialRating.code = $self.potentialMessageId;
        releaseState       : Association to ReleaseStates
                                 on  releaseState.objectType = $self.refObjectType
                                 and releaseState.objectName = $self.refObjectName;
        developmentObject  : Association to DevelopmentObjects
                                 on  developmentObject.objectType = $self.objectType
                                 and developmentObject.objectName = $self.objectName
                                 and developmentObject.devClass   = $self.devClass;
        classification     : Association to Classifications
                                 on  classification.objectType = $self.refObjectType
                                 and classification.objectName = $self.refObjectName;


}

@cds.redirection.target: false
entity SuccessorRatings   as
    projection on db.ClassificationSuccessors {
        key classification.tadirObjectType as tadirObjectType,
        key classification.tadirObjectName as tadirObjectName,
        key classification.objectType      as objectType,
        key classification.objectName      as objectName,
            tadirObjectType                as tadirObjectTypeSuccessor,
            tadirObjectName                as tadirObjectNameSuccessor,
            objectType                     as objectTypeSuccessor,
            objectName                     as objectNameSuccessor,
            successorClassification : Association to Classifications
                                          on  successorClassification.tadirObjectType = $self.tadirObjectTypeSuccessor
                                          and successorClassification.tadirObjectName = $self.tadirObjectNameSuccessor
                                          and successorClassification.objectType      = $self.objectTypeSuccessor
                                          and successorClassification.objectName      = $self.objectNameSuccessor
    }

@cds.persistence.journal
entity SimplificationItems {
    key objectType        : String;
    key objectName        : String;
    key softwareComponent : String;
    key note              : String;
        title             : String;
        itemCount         : Integer;
}

@cds.persistence.journal
entity ObjectTypes {
    key objectType : String;
        title      : String;
        category   : String;
//TODO Language Version enabled? BTP enabled?
}

define view ObjectTypeValueList as
        select from Classifications distinct {
            key objectType
        }
    union
        select from DevelopmentObjects distinct {
            key objectType
        };

define view ObjectSubTypeValueList as
    select from Classifications distinct {
        key subType
    };

define view NamespaceValueList as
    select from DevelopmentObjects distinct {
        key namespace
    };

define view SoftwareComponentValueList as
    select from Classifications distinct {
        key softwareComponent
    };

define view ApplicationComponentValueList as
    select from Classifications distinct {
        key applicationComponent
    };


define view DevClassValueList as
    select from DevelopmentObjects distinct {
        key devClass
    };

define view AdoptionEffortValueList as
    select from AdoptionEffort distinct {
        key code,
            title
    };

@cds.persistence.journal
entity Ratings : cuid, managed {
    setting                : Association to Settings;
    @mandatory code        : String(20);
    @mandatory title       : String;
    @mandatory score       : Integer;
    @mandatory level       : CleanCoreLevel;
    usableInClassification : Boolean;

    @Common.ValueListWithFixedValues: true
    @mandatory criticality : Association to Criticality;
}


@cds.persistence.journal
entity Frameworks : cuid, managed {
    setting            : Association to Settings;
    @mandatory code    : String;
    @mandatory title   : String;
    criticality        : Association to Criticality;

    @Common.ValueListWithFixedValues: true
    @(Common                        : {
        Label    : '{i18n>frameworkType}',
        ValueList: {
            CollectionPath: 'FrameworkTypes',
            Parameters    : [
                {
                    $Type            : 'Common.ValueListParameterInOut',
                    LocalDataProperty: frameworkType_code,
                    ValueListProperty: 'code'
                },
                {
                    $Type            : 'Common.ValueListParameterDisplayOnly',
                    ValueListProperty: 'title'
                },
            ]
        }
    })
    @mandatory
    frameworkType_code : String;

    frameworkType      : Association to FrameworkTypes
                             on frameworkType.code = $self.frameworkType_code;
}


@cds.odata.valuelist
entity FrameworkTypes {
    key code  : String;
        title : String;
}

@cds.persistence.journal
entity FrameworkUsages : cuid {
    classification : Association to Classifications;

    @Common.ValueListWithFixedValues: true
    @(Common                        : {
        Label    : '{i18n>framwwork}',
        ValueList: {
            CollectionPath: 'Frameworks',
            Parameters    : [
                {
                    $Type            : 'Common.ValueListParameterInOut',
                    LocalDataProperty: framework_code,
                    ValueListProperty: 'code'
                },
                {
                    $Type            : 'Common.ValueListParameterDisplayOnly',
                    ValueListProperty: 'title'
                },
            ]
        }
    })
    @mandatory
    framework_code : String;


    framework      : Association to Frameworks
                         on framework.code = $self.framework_code;
}

@cds.odata.valuelist
@cds.persistence.journal
entity SuccessorClassifications {
    key code        : String;

        @Common.Label: '{i18n>title}'
        title       : String;
        criticality : Association to Criticality;

        @Common.Label: '{i18n>obsolete}'
        obsolete    : Boolean default false;

        custom      : Boolean default true;
}

@cds.odata.valuelist
@cds.persistence.journal
entity NoteClassifications {
    key code        : String;
        title       : String;
        criticality : Association to Criticality;
}

@cds.odata.valuelist
entity SuccessorTypes {
    key code        : String;
        title       : String;
        criticality : Association to Criticality;
}

@cds.odata.valuelist
entity ClassicInfo {
    key code        : String;
        title       : String;
        criticality : Association to Criticality;
}


@cds.odata.valuelist
entity ReleaseInfo {
    key code        : String;
        title       : String;
        criticality : Association to Criticality;
}

@cds.odata.valuelist
entity ReleaseLevel {
    key code        : String;
        title       : String;
        criticality : Association to Criticality;
        score       : Integer;
}

@cds.odata.valuelist
entity ReleaseLabel {
    key code        : String;
        title       : String;
        criticality : Association to Criticality;
}


@cds.odata.valuelist
entity LanguageVersions {
    key code        : String;
        title       : String;
        criticality : Association to Criticality;
}


@cds.persistence.journal
entity AdoptionEffort {
    key code        : String;
        title       : String;
        criticality : Association to Criticality;
}

@cds.persistence.journal
entity Systems : cuid, managed {
    setting     : Association to Settings;

    @mandatory
    sid         : String;

    @mandatory
    title       : String;
    comment     : String;

    @Common.ValueListWithFixedValues: true
    @(Common                        : {
        Label    : '{i18n>destination}',
        ValueList: {
            CollectionPath: 'Destinations',
            Parameters    : [
                {
                    $Type            : 'Common.ValueListParameterInOut',
                    ValueListProperty: 'name',
                    LocalDataProperty: destination,
                },
                {
                    $Type            : 'Common.ValueListParameterDisplayOnly',
                    ValueListProperty: 'proxyType'
                },
                {
                    $Type            : 'Common.ValueListParameterDisplayOnly',
                    ValueListProperty: 'type'
                },
                {
                    $Type            : 'Common.ValueListParameterDisplayOnly',
                    ValueListProperty: 'authentication'
                },
            ]
        }
    })
    destination : String;

    customer    : Association to Customers
                      on customer.ID = $self.customer_ID;


    @Common.ValueListWithFixedValues: true
    @(Common                        : {
        Label    : '{i18n>customer}',
        ValueList: {
            CollectionPath: 'Customers',
            Parameters    : [
                {
                    $Type            : 'Common.ValueListParameterDisplayOnly',
                    ValueListProperty: 'title'
                },
                {
                    $Type            : 'Common.ValueListParameterDisplayOnly',
                    ValueListProperty: 'comment'
                },
                {
                    $Type            : 'Common.ValueListParameterInOut',
                    LocalDataProperty: customer_ID,
                    ValueListProperty: 'ID'
                },
            ]
        }
    })
    customer_ID : type of Customers : ID;
}

@cds.persistence.journal
entity Customers : cuid, managed {
    setting    : Association to Settings;

    @mandatory
    title      : String;
    contact    : String;

    @mandatory
    prefix     : String;

    systemList : Association to many Systems
                     on systemList.customer = $self;
}


@cds.persistence.journal
entity Extensions : cuid, managed {
    @mandatory
    title                : String;

    @mandatory
    system               : Association to Systems;

    developemtObjectList : Association to many DevelopmentObjects
                               on developemtObjectList.extension_ID = $self.ID;

}

@cds.persistence.journal
entity Settings : managed {
    key ID            : String(36);
        customerList  : Composition of many Customers
                            on customerList.setting = $self;

        systemList    : Composition of many Systems
                            on systemList.setting = $self;

        ratingList    : Composition of many Ratings
                            on ratingList.setting = $self;

        frameworkList : Composition of many Frameworks
                            on frameworkList.setting = $self;
}

@cds.persistence.journal
entity Jobs : cuid, managed {
    title           : String;

    @Common.ValueListWithFixedValues: true
    @(Common                        : {
        Label    : '{i18n>jobStatus}',
        ValueList: {
            CollectionPath: 'JobStatus',
            Parameters    : [
                {
                    $Type            : 'Common.ValueListParameterInOut',
                    LocalDataProperty: status,
                    ValueListProperty: 'code',
                },
                {
                    $Type            : 'Common.ValueListParameterDisplayOnly',
                    ValueListProperty: 'title'
                }
            ]
        }
    })
    status          : JobStatus:code;
    statusDetail    : Association to JobStatus
                          on statusDetail.code = $self.status;

    @Common.ValueListWithFixedValues: true
    @(Common                        : {
        Label    : '{i18n>jobType}',
        ValueList: {
            CollectionPath: 'JobTypes',
            Parameters    : [
                {
                    $Type            : 'Common.ValueListParameterInOut',
                    LocalDataProperty: type,
                    ValueListProperty: 'code',
                },
                {
                    $Type            : 'Common.ValueListParameterDisplayOnly',
                    ValueListProperty: 'title'
                }
            ]
        }
    })
    type            : String;
    typeDetail      : Association to JobTypes
                          on typeDetail.code = $self.type;
    progressCurrent : Integer;
    progressTotal   : Integer;
    message         : String;

    importList      : Association to many Imports
                          on $self.ID = importList.job_ID;
    exportList      : Association to many Exports
                          on $self.ID = exportList.job_ID;
}


type CleanCoreLevel : String enum {
    A;
    B;
    C;
    D;
}

@cds.odata.valuelist
entity Criticality {
    key code        : String;
        criticality : Integer;
        title       : String;
}

@cds.persistence.skip
@odata.singleton
entity FileUpload {
    @Core.MediaType: '*'
    file : LargeBinary;
};

@cds.persistence.journal
entity Modifications : cuid, managed {
    objectType   : String;
    objectName   : String;
    devClass     : String;
    systemId     : String;
    type         : Association to ModificationTypes
                       on type.code = $self.type_code;

    @Common.ValueListWithFixedValues: true
    @(Common                        : {
        Label    : '{i18n>modificationType}',
        ValueList: {
            CollectionPath: 'ModificationTypes',

            Parameters    : [
                {
                    $Type            : 'Common.ValueListParameterInOut',
                    LocalDataProperty: type_code,
                    ValueListProperty: 'code'
                },
                {
                    $Type            : 'Common.ValueListParameterDisplayOnly',
                    ValueListProperty: 'title'
                }
            ]
        }
    })
    type_code    : type of ModificationTypes : code;


    @readonly
    extension_ID : UUID;

    @readonly
    extension    : Association to Extensions
                       on extension.ID = $self.extension_ID;
}

@cds.odata.valuelist
entity ModificationTypes {
    key code        : String;
        criticality : Association to Criticality;
        title       : String;
}

@cds.persistence.journal
entity Enhancements : cuid, managed {
    objectType   : String;
    objectName   : String;
    devClass     : String;
    systemId     : String;

    @readonly
    extension_ID : UUID;

    @readonly
    extension    : Association to Extensions
                       on extension.ID = $self.extension_ID;
}


entity ImportTypes {
    key code          : String;
        order         : Integer;
        title         : String;
        reqSystemId   : Boolean;
        defaultRating : Boolean;
        comment       : Boolean;
        overwrite     : Boolean;
        fileEndings   : String;
        hidden        : Boolean;
        description   : String;
}

entity ExportTypes {
    key code        : String;
        order       : Integer;
        title       : String;
        legacy      : Boolean;
        hidden      : Boolean;
        dateFrom    : Boolean;
        description : String;
}

entity Destinations {
    key name           : String;
        type           : String;
        proxyType      : String;
        authentication : String;
}

@cds.odata.valuelist
entity JobStatus {
    key code        : String;
        criticality : Association to Criticality;
        title       : String;
}


entity JobTypes           as
        select from db.ImportTypes {
            key concat(
                    'IMPORT_', code
                ) as code : String,
                title
        }
    union
        select from db.ExportTypes {
            key concat(
                    'EXPORT_', code
                ) as code : String,
                title
        }

@cds.persistence.journal
entity DevelopmentObjectUsages {
    key entryPointObjectType : String;
    key entryPointObjectName : String;
    key objectType           : String;
    key objectName           : String;
        counter              : Integer;
        lastUsed             : DateTime;
}


entity FindingsAggregated as
    select from db.FindingRecords as f
    inner join Ratings as r
        on f.messageId = r.code
    {
        key f.import.ID          as importId,
        key f.objectType,
        key f.objectName,
        key f.devClass,
        key f.systemId,
        key f.refObjectName,
        key f.refObjectType,
        key f.messageId          as code,
            f.potentialMessageId as potentialCode,
            f.softwareComponent,
            count( * )           as count : Integer,
            count( * ) * r.score as total : Integer
    }

    where
        f.messageId not in (
            'X', '2', '5'
        )
    group by
        f.import.ID,
        f.objectType,
        f.objectName,
        f.devClass,
        f.systemId,
        f.refObjectName,
        f.refObjectType,
        f.messageId,
        f.potentialMessageId,
        f.softwareComponent,
        r.score;
