using kernseife.db as db from '../db/schema';
using kernseife.types as types from '../db/types';

service ClassificationService @(requires: ['classification-viewer']) {


    action loadReleaseState @(requires: 'classification-manager')();

    type inFramework : {
        code : String;
    }

    type inSuccessor : {
        tadirObjectType : String;
        tadirObjectName : String;
        objectType      : String;
        objectName      : String;
        successorType   : String;
    }

            @odata.draft.enabled
            @odata.draft.bypass
    entity Classifications         @(restrict: [
        {grant: 'READ'},
        {
            grant: 'WRITE',
            to   : 'classification-manager'
        }
    ])                                       as projection on db.Classifications
        actions {
            @(Common.SideEffects: {TargetEntities: ['in/frameworkUsageList'], })
            action assignFramework @(requires: 'classification-manager')( @mandatory frameworkCode: inFramework:code)          returns Classifications;
            @(Common.SideEffects: {TargetEntities: ['in/frameworkUsageList'], })
            action assignSuccessor @(requires: 'classification-manager')( @mandatory tadirObjectType: inSuccessor:tadirObjectType,
                                                                          @mandatory tadirObjectName: inSuccessor:tadirObjectName,
                                                                          @mandatory objectType: inSuccessor:objectType,
                                                                          @mandatory objectName: inSuccessor:objectName,
                                                                          @mandatory successorType: inSuccessor:successorType) returns Classifications;
        };

    entity FrameworkUsages                   as projection on db.FrameworkUsages;


    entity ClassificationSuccessors @(restrict: [
        {grant: 'READ'},
        {
            grant: 'WRITE',
            to   : 'classification-manager'
        }
    ])                                       as projection on db.ClassificationSuccessors;

    entity SuccessorClassifications          as projection on db.SuccessorClassifications;

    entity Ratings                           as projection on db.Ratings;

    entity Frameworks                        as projection on db.Frameworks;
    entity FrameworkTypes                    as projection on db.FrameworkTypes;


    entity ReleaseInfo                       as projection on db.ReleaseInfo;
    entity ClassicInfo                       as projection on db.ClassicInfo;
    entity ReleaseLabel                      as projection on db.ReleaseLabel;
    entity ReleaseLevel                      as projection on db.ReleaseLevel;
    entity LanguageVersions                  as projection on db.LanguageVersions;
    entity Notes                             as projection on db.Notes;
    entity NoteClassifications               as projection on db.NoteClassifications;
    entity SuccessorTypes                    as projection on db.SuccessorTypes;

    @odata.draft.bypass
    entity CodeSnippets @(restrict: [
        {grant: 'READ'},
        {
            grant: 'WRITE',
            to   : 'classification-manager'
        }
    ])                                       as projection on db.CodeSnippets;


    entity ReleaseStates @(restrict: [
        {grant: 'READ'},
        {
            grant: 'WRITE',
            to   : 'classification-manager'
        }
    ])                                       as projection on db.ReleaseStates;

    entity ReleaseStateSuccessors            as projection on db.ReleaseStateSuccessors;

    entity SimplificationItems               as projection on db.SimplificationItems;

    @cds.redirection.target: false
    entity ObjectTypeValueList               as projection on db.ObjectTypeValueList;

    @cds.redirection.target: false
    entity AdoptionEffortValueList           as projection on db.AdoptionEffortValueList;

    @cds.redirection.target: false
    entity ObjectSubTypeValueList            as projection on db.ObjectSubTypeValueList;

    @cds.redirection.target: false
    entity NamespaceValueList                as projection on db.NamespaceValueList;

    @cds.redirection.target: false
    entity ApplicationComponentValueList     as projection on db.ApplicationComponentValueList;

    @cds.redirection.target: false
    entity SoftwareComponentValueList        as projection on db.SoftwareComponentValueList;

    @cds.redirection.target: false
    entity RatingsValueList                  as projection on db.RatingsValueList;

    @cds.redirection.target: false
    entity NoteClassificationsValueList      as projection on db.NoteClassificationsValueList;

    @cds.redirection.target: false
    entity SuccessorClassificationsValueList as projection on db.SuccessorClassificationsValueList;

    entity AdoptionEffort                    as projection on db.AdoptionEffort;
    entity ObjectTypes                       as projection on db.ObjectTypes;
    entity Criticality                       as projection on db.Criticality;

    @odata.singleton
    entity FeatureControl {
        isManager    : Boolean;
        isNotManager : Boolean;
    }

    function getTileInfo(appName : String) returns types.DynamicAppLauncher;
}
