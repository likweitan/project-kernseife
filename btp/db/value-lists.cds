namespace kernseife.valueLists;

using kernseife.db as db from './schema';


entity AdoptionEffortValueList           as
    select from db.AdoptionEffort distinct {
        key code,
            title
    };

entity ObjectTypeValueList               as
        select from db.Classifications distinct {
            key objectType
        }
    union
        select from db.DevelopmentObjects distinct {
            key objectType
        };

entity ObjectSubTypeValueList            as
    select from db.Classifications distinct {
        key subType
    };

entity NamespaceValueList                as
    select from db.DevelopmentObjects distinct {
        key namespace
    };

entity SoftwareComponentValueList        as
    select from db.Classifications distinct {
        key softwareComponent
    };

entity ApplicationComponentValueList     as
    select from db.Classifications distinct {
        key applicationComponent
    };


entity DevClassValueList                 as
    select from db.DevelopmentObjects distinct {
        key devClass
    };


entity RatingsValueList                  as
    select from db.Ratings
    where
        usableInClassification == true
    order by
        score desc,
        code  asc;


entity NoteClassificationsValueList      as
    select from db.NoteClassifications
    order by
        code asc;


entity SuccessorClassificationsValueList as
    select from db.SuccessorClassifications
    order by
        title asc;
