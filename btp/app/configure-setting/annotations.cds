using AdminService as service from '../../srv/admin-service';

annotate service.Settings with @(
    UI.DeleteHidden                  : true,
    UI.HeaderInfo                    : {
        TypeName      : '{i18n>setting}',
        TypeNamePlural: '{i18n>settings}',
    },
    UI.FieldGroup #generalInformation: {
        $Type: 'UI.FieldGroupType',
        Data : [
            {
                $Type: 'UI.DataField',
                Value: modifiedBy,
            },
            {
                $Type: 'UI.DataField',
                Value: modifiedAt,
            },
            {
                $Type: 'UI.DataField',
                Value: createdBy,
            },
            {
                $Type: 'UI.DataField',
                Value: createdAt,
            }
        ],
    },
    UI.Facets                        : [
        {
            $Type : 'UI.ReferenceFacet',
            Label : '{i18n>generalInformation}',
            ID    : 'generalInformation',
            Target: '@UI.FieldGroup#generalInformation',
        },
        {
            $Type : 'UI.ReferenceFacet',
            Label : '{i18n>customers}',
            ID    : 'customerList',
            Target: 'customerList/@UI.LineItem',
        },
        {
            $Type : 'UI.ReferenceFacet',
            Label : '{i18n>systems}',
            ID    : 'systemList',
            Target: 'systemList/@UI.LineItem',
        },
        {
            $Type : 'UI.ReferenceFacet',
            Label : '{i18n>ratings}',
            ID    : 'ratingList',
            Target: 'ratingList/@UI.LineItem',
        },
        {
            $Type : 'UI.ReferenceFacet',
            Label : '{i18n>frameworks}',
            ID    : 'frameworkList',
            Target: 'frameworkList/@UI.LineItem',
        }
    ],
    UI.Identification                : [{
        $Type      : 'UI.DataFieldForAction',
        Action     : 'AdminService.createInitialData',
        Label      : '{i18n>createInitialData}',
        Criticality: #Negative,

    }, ],
);

annotate service.inInitialData with {
    @assert.format: '^$|([(http(s)?):\/\/(www\.)?a-zA-Z0-9@:%._\+~#=]{2,256}\.[a-z]{2,6}\b([-a-zA-Z0-9@:%_\+.~#?&//=]*)(.json))'
    configUrl @Common.Label: '{i18n>configUrl}';
}

annotate service.Settings with {
    modifiedBy @Common.Label: '{i18n>modifiedBy}';
    modifiedAt @Common.Label: '{i18n>modifiedAt}';
    createdBy  @Common.Label: '{i18n>createdBy}';
    createdAt  @Common.Label: '{i18n>createdAt}';
};

annotate service.Customers with @(UI.LineItem: [
    {
        $Type: 'UI.DataField',
        Value: title,
        Label: '{i18n>title}',
    },
    {
        $Type: 'UI.DataField',
        Value: prefix,
        Label: '{i18n>prefix}',
    },
    {
        $Type: 'UI.DataField',
        Value: contact,
        Label: '{i18n>contactPerson}'
    }
]);

annotate service.Customers with @(UI.HeaderInfo: {
    TypeName      : '{i18n>customer}',
    TypeNamePlural: '{i18n>customes}',
    Title         : {
        $Type: 'UI.DataField',
        Value: title,
        Label: '{i18n>title}',
    },
});


annotate AdminService.Customers with @(UI: {
    Facets             : [
        {
            $Type : 'UI.ReferenceFacet',
            Label : '{i18n>generalInformation}',
            Target: '@UI.FieldGroup#General'
        },
        {
            $Type : 'UI.ReferenceFacet',
            Label : '{i18n>admin}',
            Target: '@UI.FieldGroup#Admin'
        }
    ],
    FieldGroup #General: {Data: [
        {
            Value: title,
            Label: '{i18n>title}',
        },
        {
            Value: prefix,
            Label: '{i18n>sid}',
        },
        {
            Value: contact,
            Label: '{i18n>contactPerson}'
        }
    ]},
    FieldGroup #Admin  : {Data: [
        {
            Value: createdBy,
            Label: '{i18n>createdBy}',
        },
        {
            Value: createdAt,
            Label: '{i18n>createdAt}',
        },
        {
            Value: modifiedBy,
            Label: '{i18n>modifiedBy}',
        },
        {
            Value: modifiedAt,
            Label: '{i18n>modifiedAt}',
        }
    ]}
});

annotate AdminService.Systems with @(
    UI               : {
        Facets             : [
            {
                $Type : 'UI.ReferenceFacet',
                Label : '{i18n>generalInformation}',
                Target: '@UI.FieldGroup#General'
            },
            {
                $Type : 'UI.ReferenceFacet',
                Label : '{i18n>btp}',
                Target: '@UI.FieldGroup#BTP'
            },
            {
                $Type : 'UI.ReferenceFacet',
                Label : '{i18n>admin}',
                Target: '@UI.FieldGroup#Admin'
            }
        ],
        FieldGroup #General: {Data: [
            {
                Value: title,
                Label: '{i18n>title}',
            },
            {
                Value: sid,
                Label: '{i18n>sid}',
            },
            {
                Value: title,
                Label: '{i18n>title}'
            },
            {
                Value: customer_ID,
                Label: '{i18n>customer}'
            }
        ]},
        FieldGroup #BTP    : {Data: [
            {
                Value: destination,
                Label: '{i18n>destination}',
            },
            {
                Value: project.description,
                Label: '{i18n>project}',
            },
            {
                Value: project.statusDescription,
                Label: '{i18n>statusDescription}',
            },
            {
                Value: project.runStateText,
                Label: '{i18n>runStatusDescription}',
            },
            {
                $Type: 'UI.DataField',
                Value: project.totalObjectCount,
                Label: '{i18n>totalObjectCount}',
            },
            {
                $Type: 'UI.DataField',
                Value: project.findingCount,
                Label: '{i18n>findingCount}',
            },
        ]},
        FieldGroup #Admin  : {Data: [
            {
                Value: createdBy,
                Label: '{i18n>createdBy}',
            },
            {
                Value: createdAt,
                Label: '{i18n>createdAt}',
            },
            {
                Value: modifiedBy,
                Label: '{i18n>modifiedBy}',
            },
            {
                Value: modifiedAt,
                Label: '{i18n>modifiedAt}',
            }
        ]}
    },
    UI.Identification: [
        {
            $Type        : 'UI.DataFieldForAction',
            Action       : 'AdminService.setupSystem',
            Label        : '{i18n>setupSystem}',
            ![@UI.Hidden]: setupDone
        },
        {
            $Type        : 'UI.DataFieldForAction',
            Action       : 'AdminService.triggerATCRun',
            Label        : '{i18n>triggerATCRun}',
            ![@UI.Hidden]: setupNotDone
        },
    ],
);

annotate service.Systems with @(UI.LineItem: [
    {
        $Type: 'UI.DataField',
        Value: sid,
        Label: '{i18n>sid}',
    },
    {
        $Type: 'UI.DataField',
        Value: title,
        Label: '{i18n>title}',
    },
    {
        $Type: 'UI.DataField',
        Value: customer.title,
        Label: '{i18n>customer}',
    },
    {
        $Type: 'UI.DataField',
        Value: comment,
        Label: '{i18n>comment}',
    },
]);

annotate service.Systems with @(UI.HeaderInfo: {
    TypeName      : '{i18n>system}',
    TypeNamePlural: '{i18n>systems}',
    Title         : {
        $Type: 'UI.DataField',
        Value: title,
        Label: '{i18n>title}',
    },
});

annotate service.Systems with {
    customer_ID @Common.Text: {
        $value                : customer.title,
        ![@UI.TextArrangement]: #TextOnly
    }
};


annotate AdminService.Ratings with @(
    UI                                    : {
        Facets             : [
            {
                $Type : 'UI.ReferenceFacet',
                Label : '{i18n>generalInformation}',
                Target: '@UI.FieldGroup#General'
            },
            {
                $Type : 'UI.ReferenceFacet',
                Label : '{i18n>admin}',
                Target: '@UI.FieldGroup#Admin'
            }
        ],
        FieldGroup #General: {Data: [
            {
                Value: title,
                Label: '{i18n>title}',
            },
            {
                Value: code,
                Label: '{i18n>code}',
            },
            {
                Value: criticality_code,
                Label: '{i18n>criticality}'
            },
            {
                $Type                    : 'UI.DataField',
                Value                    : score,
                Label                    : '{i18n>score}',
                Criticality              : criticality.criticality,
                CriticalityRepresentation: #WithoutIcon,
            },
            {
                Value: level,
                Label: '{i18n>cleanCoreLevel}'
            },
            {
                Value: usableInClassification,
                Label: '{i18n>usableInClassification}'
            },
        ]},
        FieldGroup #Admin  : {Data: [
            {
                Value: createdBy,
                Label: '{i18n>createdBy}',
            },
            {
                Value: createdAt,
                Label: '{i18n>createdAt}',
            },
            {
                Value: modifiedBy,
                Label: '{i18n>modifiedBy}',
            },
            {
                Value: modifiedAt,
                Label: '{i18n>modifiedAt}',
            }
        ]}
    },
    UI.SelectionPresentationVariant #table: {
        $Type              : 'UI.SelectionPresentationVariantType',
        PresentationVariant: {
            $Type         : 'UI.PresentationVariantType',
            Visualizations: ['@UI.LineItem',
            ],
            SortOrder     : [{
                $Type     : 'Common.SortOrderType',
                Property  : code,
                Descending: false,
            }, ],
        },
        SelectionVariant   : {
            $Type        : 'UI.SelectionVariantType',
            SelectOptions: [],
        },
    },
);

annotate service.Ratings with @(UI.LineItem: [
    {
        $Type: 'UI.DataField',
        Value: code,
        Label: '{i18n>code}',
    },
    {
        $Type: 'UI.DataField',
        Value: title,
        Label: '{i18n>title}',
    },
    {
        $Type: 'UI.DataField',
        Value: criticality_code,
        Label: '{i18n>criticality}',
    },
    {
        $Type            : 'UI.DataField',
        Value            : score,
        Label            : '{i18n>score}',
        ![@UI.Importance]: #High,
    },
    {
        $Type            : 'UI.DataField',
        Value            : level,
        Label            : '{i18n>cleanCoreLevel}',
        ![@UI.Importance]: #High,
    }
]);

annotate service.Ratings with @(UI.HeaderInfo: {
    TypeName      : '{i18n>rating}',
    TypeNamePlural: '{i18n>ratings}',
    Title         : {
        $Type: 'UI.DataField',
        Value: title,
        Label: '{i18n>title}',
    },
});

annotate AdminService.Frameworks with @(UI: {
    Facets             : [
        {
            $Type : 'UI.ReferenceFacet',
            Label : '{i18n>generalInformation}',
            Target: '@UI.FieldGroup#General'
        },
        {
            $Type : 'UI.ReferenceFacet',
            Label : '{i18n>admin}',
            Target: '@UI.FieldGroup#Admin'
        },
    ],
    FieldGroup #General: {Data: [
        {
            Value                  : title,
            ![@Common.FieldControl]: #Mandatory,
            Label                  : '{i18n>title}',

        },
        {
            Value                  : code,
            ![@Common.FieldControl]: #Mandatory,
            Label                  : '{i18n>code}',
        },
        {
            Value: criticality_code,
            Label: '{i18n>criticality}'
        },
        {
            Value: frameworkType_code,
            Label: '{i18n>frameworkType}'
        },
    ]},
    FieldGroup #Admin  : {Data: [
        {
            Value: createdBy,
            Label: '{i18n>createdBy}',
        },
        {
            Value: createdAt,
            Label: '{i18n>createdAt}',
        },
        {
            Value: modifiedBy,
            Label: '{i18n>modifiedBy}',
        },
        {
            Value: modifiedAt,
            Label: '{i18n>modifiedAt}',
        }
    ]}
});

annotate service.Frameworks with @(UI.LineItem: [
    {
        $Type                  : 'UI.DataField',
        Value                  : code,
        ![@Common.FieldControl]: #Mandatory,
        Label                  : '{i18n>code}',
    },
    {
        $Type: 'UI.DataField',
        Value: title,
        Label: '{i18n>title}',
    },
    {
        $Type: 'UI.DataField',
        Value: criticality_code,
        Label: '{i18n>criticality}',
    },
    {
        $Type: 'UI.DataField',
        Value: frameworkType.title,
        Label: '{i18n>frameworkType}',
    },
]);

annotate service.Frameworks with @(UI.HeaderInfo: {
    TypeName      : '{i18n>framework}',
    TypeNamePlural: '{i18n>frameworks}',
    Title         : {
        $Type: 'UI.DataField',
        Value: title,
        Label: '{i18n>title}',
    },
});

annotate service.Frameworks with {
    frameworkType_code @Common.Text: {
        $value                : frameworkType.title,
        ![@UI.TextArrangement]: #TextOnly
    }
};
