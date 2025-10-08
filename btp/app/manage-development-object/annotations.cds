using AdminService as service from '../../srv/admin-service';

annotate service.DevelopmentObjects with @(
    Capabilities     : {FilterFunctions: ['tolower',
    ]},
    UI.Identification: [
                        // {
                        //     $Type : 'UI.DataFieldForAction',
                        //     Action : 'AdminService.calculateScore',
                        //     Label : 'calculateScore',
                        // },
                       ],
);

annotate service.DevelopmentObjects with @(
    UI.LineItem                          : [
        {
            $Type            : 'UI.DataField',
            Value            : system.sid,
            Label            : '{i18n>systemId}',
            ![@UI.Importance]: #Low,
        },
        {
            $Type            : 'UI.DataField',
            Label            : '{i18n>devClass}',
            Value            : devClass,
            ![@UI.Importance]: #Medium,
        },
        {
            $Type            : 'UI.DataField',
            Label            : '{i18n>namespace}',
            Value            : namespace,
            ![@UI.Importance]: #Low,
        },
        {
            $Type            : 'UI.DataField',
            Label            : '{i18n>objectType}',
            Value            : objectType,
            ![@UI.Importance]: #High,
        },
        {
            $Type            : 'UI.DataField',
            Label            : '{i18n>objectName}',
            Value            : objectName,
            ![@UI.Importance]: #High,
        },
        {
            $Type                    : 'UI.DataField',
            Label                    : '{i18n>languageVersion}',
            Value                    : languageVersion_code,
            Criticality              : languageVersion.criticality.criticality,
            CriticalityRepresentation: #WithoutIcon,
            ![@UI.Importance]        : #Medium,
        },
        {
            $Type            : 'UI.DataField',
            Label            : '{i18n>scoreObject}',
            Value            : score,
            ![@UI.Importance]: #High,
        },
        {
            $Type                    : 'UI.DataField',
            Label                    : '{i18n>level}',
            Value                    : level,
            CriticalityRepresentation: #WithoutIcon,
            Criticality              : {$edmJson: {$If: [
                {$Eq: [
                    {$Path: 'level'},
                    'D'
                ]},
                1,
                {$If: [
                    {$Eq: [
                        {$Path: 'level'},
                        'C'
                    ]},
                    2,
                    {$If: [
                        {$Eq: [
                            {$Path: 'level'},
                            'B'
                        ]},
                        0,
                        3
                    ]}
                ]}
            ]}},
            ![@HTML5.CssDefaults]    : {width: '6rem'},
        },
        {
            $Type                    : 'UI.DataField',
            Label                    : '{i18n>potentialLevel}',
            ![@UI.Importance]        : #Medium,
            Value                    : potentialLevel,
            CriticalityRepresentation: #WithoutIcon,
            Criticality              : {$edmJson: {$If: [
                {$Ne: [
                    {$Path: 'level'},
                    {$Path: 'potentialLevel'}
                ]},
                3,
                0
            ]}},
            ![@HTML5.CssDefaults]    : {width: '6rem'},
        },
        {
            $Type            : 'UI.DataField',
            Label            : '{i18n>potentialScore}',
            Value            : potentialScore,
            ![@UI.Importance]: #Medium,
        },
        {
            $Type                : 'UI.DataField',
            Label                : '{i18n>cleanupPotential}',
            Value                : cleanupPotential,
            ![@UI.Importance]    : #Medium,
            ![@HTML5.CssDefaults]: {width: '5rem'},
        },
        {
            $Type                : 'UI.DataFieldForAnnotation',
            Label                : '{i18n>cleanupPotential}',
            Target               : '@UI.DataPoint#CleanupPotentialPercent',
            ![@UI.Importance]    : #Medium,
            ![@HTML5.CssDefaults]: {width: '5rem'},


        },

        {
            $Type : 'UI.DataFieldForAction',
            Action: 'AdminService.EntityContainer/recalculateAllScores',
            Label : '{i18n>recalculateAllScores}',
        }
    ],
    UI.DataPoint #CleanupPotentialPercent: {
        $Type                    : 'UI.DataPointType',
        Title                    : '{i18n>CleanupPotentialPercent}',
        Value                    : cleanupPotentialPercent,
        ValueFormat              : {
            $Type                   : 'UI.NumberFormat',
            NumberOfFractionalDigits: 2,
            ScaleFactor             : 1
        },
        CriticalityRepresentation: #WithoutIcon,
        Criticality              : {$edmJson: {$If: [
            {$Lt: [
                {$Path: 'cleanupPotentialPercent'},
                5
            ]},
            3,
            {$If: [
                {$Gt: [
                    {$Path: 'cleanupPotentialPercent'},
                    50
                ]},
                1,
                {$If: [
                    {$Gt: [
                        {$Path: 'cleanupPotentialPercent'},
                        25
                    ]},
                    2,
                    0
                ]}
            ]}
        ]}}
    },
    UI.FieldGroup #GeneratedGroup1       : {
        $Type: 'UI.FieldGroupType',
        Data : [
            {
                $Type: 'UI.DataField',
                Label: '{i18n>objectType}',
                Value: objectType,
            },
            {
                $Type: 'UI.DataField',
                Label: '{i18n>objectName}',
                Value: objectName,
            },
            {
                $Type: 'UI.DataField',
                Label: '{i18n>devClass}',
                Value: devClass,
            },
            {
                $Type: 'UI.DataField',
                Label: '{i18n>languageVersion}',
                Value: languageVersion_code,
            },
            {
                $Type: 'UI.DataField',
                Label: '{i18n>score}',
                Value: score,
            },
            {
                $Type: 'UI.DataField',
                Label: '{i18n>level}',
                Value: level,
            },
            {
                $Type: 'UI.DataField',
                Label: '{i18n>potentialScore}',
                Value: potentialScore,
            },
            {
                $Type                : 'UI.DataField',
                Label                : '{i18n>potentialLevel}',
                Value                : potentialLevel,
                Criticality          : {$edmJson: {$If: [
                    {$Ne: [
                        {$Path: 'level'},
                        {$Path: 'potentialLevel'}
                    ]},
                    3,
                    0
                ]}},
                ![@HTML5.CssDefaults]: {width: '6rem'},
            }
        ],
    },
    UI.Facets                            : [
        {
            $Type : 'UI.ReferenceFacet',
            ID    : 'GeneratedFacet1',
            Label : '{i18n>generalInformation}',
            Target: '@UI.FieldGroup#GeneratedGroup1',
        },
        {
            $Type : 'UI.ReferenceFacet',
            Label : '{i18n>findings}',
            ID    : 'findingList',
            Target: 'findingListAggregated/@UI.SelectionPresentationVariant#findingList',
        },
    ]
);

annotate service.DevelopmentObjects with @(UI.SelectionFields: [
    systemId,
    devClass,
    namespace,
    objectType,
    languageVersion_code
]);

annotate service.DevelopmentObjects with {
    namespace  @Common.Label: '{i18n>namespace}';
    systemId   @Common.Label: '{i18n>systemId}';
    devClass   @Common.Label: '{i18n>devClass}';
    objectType @Common.Label: '{i18n>objectType}';
};

annotate service.DevelopmentObjects with @(UI.SelectionPresentationVariant #table: {
    $Type              : 'UI.SelectionPresentationVariantType',
    PresentationVariant: {
        $Type         : 'UI.PresentationVariantType',
        Visualizations: ['@UI.LineItem',
        ],
        GroupBy       : [],
        Total         : [score // This shit doesn't work?!
        ],
        SortOrder     : [{
            $Type     : 'Common.SortOrderType',
            Property  : score,
            Descending: true,
        }, ],
    },
    SelectionVariant   : {
        $Type        : 'UI.SelectionVariantType',
        SelectOptions: [{
            $Type       : 'UI.SelectOptionType',
            PropertyName: devClass,
            Ranges      : [{
                Sign  : #E,
                Option: #EQ,
                Low   : '$TMP',
            }, ],
        }, ],
    },
});

annotate service.FindingsAggregated with @(
    UI.LineItem #findingList                    : [
        {
            $Type                : 'UI.DataField',
            Value                : refObjectName,
            Label                : '{i18n>refObjectName}',
            ![@UI.Importance]    : #High,
            ![@HTML5.CssDefaults]: {width: '18rem'},
        },
        {
            $Type                : 'UI.DataField',
            Value                : refObjectType,
            Label                : '{i18n>refObjectType}',
            ![@UI.Importance]    : #High,
            ![@HTML5.CssDefaults]: {width: '4rem'},
        },
        {
            $Type                    : 'UI.DataField',
            Value                    : code,
            Label                    : '{i18n>rating}',
            Criticality              : criticality.criticality,
            CriticalityRepresentation: #WithoutIcon,
            ![@UI.Importance]        : #High,
            ![@HTML5.CssDefaults]    : {width: '16rem'},
        },
        {
            $Type                    : 'UI.DataField',
            Value                    : level,
            Label                    : '{i18n>level}',
            Criticality              : criticality.criticality,
            CriticalityRepresentation: #WithoutIcon,
            ![@UI.Importance]        : #Medium,
            ![@HTML5.CssDefaults]    : {width: '4rem'},
        },
        {
            $Type                    : 'UI.DataField',
            Value                    : score,
            Label                    : '{i18n>score}',
            Criticality              : criticality.criticality,
            CriticalityRepresentation: #WithoutIcon,
            ![@UI.Importance]        : #Medium,
            ![@HTML5.CssDefaults]    : {width: '4rem'},
        },
        {
            $Type                : 'UI.DataField',
            Value                : count,
            Label                : '{i18n>count}',
            ![@UI.Importance]    : #Medium,
            ![@HTML5.CssDefaults]: {width: '4rem'},
        },
        {
            $Type                : 'UI.DataField',
            Value                : total,
            Label                : '{i18n>total}',
            ![@UI.Importance]    : #Medium,
            ![@HTML5.CssDefaults]: {width: '6rem'},
        },
        {
            $Type                : 'UI.DataFieldForAnnotation',
            Target               : '@UI.DataPoint#totalPercentage',
            Label                : '{i18n>totalPercentage}',
            ![@UI.Importance]    : #Medium,
            ![@HTML5.CssDefaults]: {width: '6rem'},

        },
        {
            $Type                : 'UI.DataField',
            Label                : '{i18n>potentialScore}',
            Value                : potentialScore,
            ![@HTML5.CssDefaults]: {width: '4rem'},
        },
        {
            $Type                : 'UI.DataField',
            Label                : '{i18n>potentialLevel}',
            Value                : potentialLevel,
            Criticality          : {$edmJson: {$If: [
                {$Eq: [
                    {$Path: 'potentialLevel'},
                    'Open'
                ]},
                1,
                3
            ]}},


            ![@HTML5.CssDefaults]: {width: '6rem'},
        }
    ],
    UI.SelectionPresentationVariant #findingList: {
        $Type              : 'UI.SelectionPresentationVariantType',
        PresentationVariant: {
            $Type         : 'UI.PresentationVariantType',
            Visualizations: ['@UI.LineItem#findingList',
            ],
            SortOrder     : [{
                $Type     : 'Common.SortOrderType',
                Property  : total,
                Descending: true,
            }, ],
        },
        SelectionVariant   : {
            $Type        : 'UI.SelectionVariantType',
            SelectOptions: [],
        },
    },
    UI.DataPoint #totalPercentage               : {
        Value        : totalPercentage,
        Visualization: #Progress,
        TargetValue  : 100,
    },
);

annotate service.DevelopmentObjects with @(UI.HeaderInfo: {
    Title         : {
        $Type: 'UI.DataField',
        Value: '{objectType} - {objectName}',
    },
    TypeName      : '',
    TypeNamePlural: '',
});

annotate service.DevelopmentObjects with {
    languageVersion_code @Common.Text: {
        $value                : languageVersion.title,
        ![@UI.TextArrangement]: #TextFirst,
    }
};
