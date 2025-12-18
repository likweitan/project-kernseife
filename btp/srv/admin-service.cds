using kernseife.db as db from '../db/schema';
using kernseife.valueLists as valueLists from '../db/value-lists';
using {kernseife_btp as btp} from './external/kernseife_btp';

service AdminService @(requires: 'admin') {
    
    // Actions
    @Common.IsActionCritical: true
    action syncClassificationsToAllSystems();

    action triggerExport(exportType: String, legacy: Boolean, dateFrom: Timestamp); // as "export" is not allowed due to TS type generation
    action triggerImport(importType: String, systemId: String);

    entity ReleaseStates                     as projection on db.ReleaseStates;
    entity ReleaseStateSuccessors            as projection on db.ReleaseStateSuccessors;

    entity Imports                           as projection on db.Imports;
    entity Exports                           as projection on db.Exports;

    entity ImportTypes                       as projection on db.ImportTypes
                                                where
                                                    hidden == false;

    entity ExportTypes                       as projection on db.ExportTypes
                                                where
                                                    hidden == false;


    event Imported : { // Async API
        ID   : Imports:ID;
        type : Imports:type;
    }

    entity FileUpload                        as projection on db.FileUpload;

    entity Destinations                      as projection on db.Destinations;

    entity JobStatus                         as projection on db.JobStatus;
    entity JobTypes                          as projection on db.JobTypes;

    entity SimplificationItems               as projection on db.SimplificationItems;

    entity Ratings                           as projection on db.Ratings;
    entity Frameworks                        as projection on db.Frameworks;
    entity FrameworkTypes                    as projection on db.FrameworkTypes;
    entity SuccessorClassifications          as projection on db.SuccessorClassifications;
    entity ReleaseInfo                       as projection on db.ReleaseInfo;
    entity ClassicInfo                       as projection on db.ClassicInfo;
    entity ReleaseLabel                      as projection on db.ReleaseLabel;
    entity ReleaseLevel                      as projection on db.ReleaseLevel;
    entity LanguageVersions                  as projection on db.LanguageVersions;
    entity Notes                             as projection on db.Notes;
    entity NoteClassifications               as projection on db.NoteClassifications;
    entity SuccessorTypes                    as projection on db.SuccessorTypes;

    entity Customers                         as projection on db.Customers;

    entity Projects                          as
        projection on btp.ZKNSF_I_PROJECTS {
            *
        };

    entity Systems                           as
        projection on db.Systems {
            *,
            virtual setupDone    : Boolean,
            virtual setupNotDone : Boolean,
            project              : Association to Projects
                                       on project.systemId = $self.sid //Not exactly correct, but we need an ON condition here
        }
        actions {
            action syncClassifications();
            action setupSystem();
            action triggerATCRun();
        };


    type inInitialData                : {
        configUrl : String;
    }

            @odata.draft.enabled
    entity Settings                          as projection on db.Settings
        actions {
            @Common.IsActionCritical: true
            @(Common.SideEffects: {TargetEntities: [
                'in/customerList',
                'in/systemList',
                'in/ratingList',
            ], })
            action createInitialData(configUrl: inInitialData:configUrl @UI.ParameterDefaultValue: 'https://raw.githubusercontent.com/SAP/project-kernseife/refs/heads/main/defaultSetup.json'

            );
        };

    entity Jobs                              as
        projection on db.Jobs {
            *,
            virtual hideImports : Boolean,
            virtual hideExports : Boolean,
        };

    type inExportSystemClassification : {
        legacy : Boolean;
    }


    @cds.redirection.target: false
    entity ObjectTypeValueList               as projection on valueLists.ObjectTypeValueList;

    @cds.redirection.target: false
    entity AdoptionEffortValueList           as projection on valueLists.AdoptionEffortValueList;

    @cds.redirection.target: false
    entity ObjectSubTypeValueList            as projection on valueLists.ObjectSubTypeValueList;

    @cds.redirection.target: false
    entity NamespaceValueList                as projection on valueLists.NamespaceValueList;

    @cds.redirection.target: false
    entity ApplicationComponentValueList     as projection on valueLists.ApplicationComponentValueList;

    @cds.redirection.target: false
    entity SoftwareComponentValueList        as projection on valueLists.SoftwareComponentValueList;

    @cds.redirection.target: false
    entity DevClassValueList                 as projection on valueLists.DevClassValueList;

    @cds.redirection.target: false
    entity RatingsValueList                  as projection on valueLists.RatingsValueList;

    @cds.redirection.target: false
    entity NoteClassificationsValueList      as projection on valueLists.NoteClassificationsValueList;

    @cds.redirection.target: false
    entity SuccessorClassificationsValueList as projection on valueLists.SuccessorClassificationsValueList;

    entity ObjectTypes                       as projection on db.ObjectTypes;
    entity Criticality                       as projection on db.Criticality;
}
