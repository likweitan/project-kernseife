using AdminService as service from '../../srv/admin-service';

annotate service.Jobs with @(
    UI.FieldGroup #GeneratedGroup         : {
        $Type: 'UI.FieldGroupType',
        Data : [
            {
                $Type: 'UI.DataField',
                Label: '{i18n>status}',
                Value: status,
            },
            {
                $Type: 'UI.DataField',
                Label: '{i18n>type}',
                Value: type,
            },
            {
                $Type : 'UI.DataFieldForAnnotation',
                Target: '@UI.DataPoint#progressCurrent',
                Label : '{i18n>progress}',
            }
        ],
    },
    UI.Facets                             : [
        {
            $Type : 'UI.ReferenceFacet',
            ID    : 'GeneratedFacet1',
            Label : 'General Information',
            Target: '@UI.FieldGroup#GeneratedGroup',
        },
        {
            $Type        : 'UI.ReferenceFacet',
            Label        : '{i18n>importList}',
            ID           : 'importList',
            Target       : 'importList/@UI.LineItem#importList',
            ![@UI.Hidden]: hideImports
        },
        {
            $Type        : 'UI.ReferenceFacet',
            Label        : '{i18n>exportList}',
            ID           : 'exportList',
            Target       : 'exportList/@UI.LineItem#exportList',
            ![@UI.Hidden]: hideExports
        },
    ],
    UI.LineItem                           : [
        {
            $Type            : 'UI.DataField',
            Label            : '{i18n>title}',
            Value            : title,
            ![@UI.Importance]: #High,
        },
        {
            $Type            : 'UI.DataField',
            Label            : '{i18n>status}',
            Value            : status,
            ![@UI.Importance]: #High,
        },
        {
            $Type            : 'UI.DataField',
            Label            : '{i18n>type}',
            Value            : type,
            ![@UI.Importance]: #Medium,
        },
        {
            $Type                : 'UI.DataFieldForAnnotation',
            Target               : '@UI.DataPoint#progressCurrent',
            Label                : '{i18n>progress}',
            ![@UI.Importance]    : #High,
            ![@HTML5.CssDefaults]: {width: '8rem'},
        },
        {
            $Type            : 'UI.DataField',
            Value            : createdAt,
            ![@UI.Importance]: #Low,
        },
        {
            $Type            : 'UI.DataField',
            Value            : createdBy,
            ![@UI.Importance]: #Low,
        }
    ],
    UI.DataPoint #progressCurrent         : {
        Value        : progressCurrent,
        Visualization: #Progress,
        TargetValue  : progressTotal,


    },
    UI.SelectionPresentationVariant #table: {
        $Type              : 'UI.SelectionPresentationVariantType',
        PresentationVariant: {
            $Type         : 'UI.PresentationVariantType',
            Visualizations: ['@UI.LineItem',
            ],
            SortOrder     : [{
                $Type     : 'Common.SortOrderType',
                Property  : modifiedAt,
                Descending: true,
            }, ],
            GroupBy       : [type, ],
        },
        SelectionVariant   : {
            $Type        : 'UI.SelectionVariantType',
            SelectOptions: [],
        },
    },
);

annotate service.Jobs with {
    type @Common.Label: '{i18n>type}';
};

annotate service.Imports with @(UI.LineItem #importList: [{
    $Type                : 'UI.DataField',
    Value                : file,
    Label                : '{i18n>file}',
    ![@UI.Importance]    : #High,
    ![@HTML5.CssDefaults]: {width: '50rem'},
}, ]);


annotate service.Exports with @(UI.LineItem #exportList: [{
    $Type                : 'UI.DataField',
    Value                : file,
    Label                : '{i18n>file}',
    ![@UI.Importance]    : #High,
    ![@HTML5.CssDefaults]: {width: '50rem'},
}, ]);
